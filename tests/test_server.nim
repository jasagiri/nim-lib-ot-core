## Tests for OT Server

import unittest
import ../src/nim_lib_ot_core/[server, types, operations]
import results

proc buildOp(op: proc(o: var TextOperation)): TextOperation =
  var operation = newTextOperation()
  op(operation)
  result = operation

suite "OT Server Tests":
  test "Initial server state":
    let server = newOTServer("Hello")
    check server.getDocument().content == "Hello"
    check server.getRevision() == 0
    check server.getClients().len == 0
  
  test "Register client":
    let server = newOTServer()
    let result = server.registerClient("client1")
    
    check result.isOk
    check result.get() == 0  # Initial revision
    check server.getClients().len == 1
    check "client1" in server.getClients()
  
  test "Unregister client":
    let server = newOTServer()
    discard server.registerClient("client1")
    
    let result = server.unregisterClient("client1")
    check result.isOk
    check server.getClients().len == 0
    
    # Try to unregister non-existent client
    let result2 = server.unregisterClient("client2")
    check result2.isErr
    check result2.error == UnknownClient
  
  test "Receive operation from registered client":
    let server = newOTServer("Hello")
    discard server.registerClient("client1")
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let result = server.receiveOperation("client1", op, 0)
    
    check result.isOk
    let (_, revision) = result.get() # Ignoring transformedOp as it's not needed for this test
    check revision == 1
    check server.getDocument().content == "Hello World"
    check server.getRevision() == 1
  
  test "Receive operation from unknown client":
    let server = newOTServer("Hello")
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let result = server.receiveOperation("unknown", op, 0)
    check result.isErr
    check result.error == UnknownClient
  
  test "Receive operation with invalid revision":
    let server = newOTServer("Hello")
    discard server.registerClient("client1")
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    # Try with future revision
    let result = server.receiveOperation("client1", op, 5)
    check result.isErr
    check result.error == InvalidRevision
    
    # Try with negative revision
    let result2 = server.receiveOperation("client1", op, -1)
    check result2.isErr
    check result2.error == InvalidRevision
  
  test "Concurrent operations from multiple clients":
    let server = newOTServer("Hello")
    discard server.registerClient("client1")
    discard server.registerClient("client2")
    
    # Client1 adds " World"
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let result1 = server.receiveOperation("client1", op1, 0)
    check result1.isOk
    check server.getDocument().content == "Hello World"
    check server.getRevision() == 1
    
    # Client2 adds "!" (based on old revision)
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert("!"))
    
    let result2 = server.receiveOperation("client2", op2, 0)
    check result2.isOk
    check server.getDocument().content == "Hello! World"
    check server.getRevision() == 2
  
  test "Transform through multiple operations":
    let server = newOTServer("Hello")
    discard server.registerClient("client1")
    discard server.registerClient("client2")
    
    # Apply several operations
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    discard server.receiveOperation("client1", op1, 0)
    
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert("!"))
    discard server.receiveOperation("client1", op2, 1)
    
    # Now client2 sends an operation based on revision 0
    let op3 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Beautiful"))
    
    let result = server.receiveOperation("client2", op3, 0)
    check result.isOk
    check server.getDocument().content == "Hello Beautiful World!"
    check server.getRevision() == 3
  
  test "Broadcast operation to other clients":
    let server = newOTServer("Hello")
    discard server.registerClient("client1")
    discard server.registerClient("client2")
    discard server.registerClient("client3")
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    discard server.receiveOperation("client1", op, 0)
    
    # Broadcast to other clients
    let broadcasts = server.broadcast("client1", server.operationHistory[0], 1)
    
    check broadcasts.len == 2
    check broadcasts[0].clientId in ["client2", "client3"]
    check broadcasts[1].clientId in ["client2", "client3"]
    check broadcasts[0].clientId != broadcasts[1].clientId
  
  test "Get client state":
    let server = newOTServer()
    discard server.registerClient("client1")
    
    let stateResult = server.getClientState("client1")
    check stateResult.isOk
    
    let state = stateResult.get()
    check state.lastRevision == 0
    check state.pendingOps.len == 0
    
    # Non-existent client
    let stateResult2 = server.getClientState("unknown")
    check stateResult2.isErr
    check stateResult2.error == UnknownClient