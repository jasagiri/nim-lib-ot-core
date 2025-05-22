import unittest
import ../src/nim_lib_ot_core/client
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import std/options
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

suite "OT Client Tests":
  test "Initial state":
    let client = newOTClient("Hello")
    
    check client.state == csSynchronized
    check client.revision == 0
    check client.document.content == "Hello"
    check client.pending.isNone
    check client.buffer.isNone

  test "Apply local operation when synchronized":
    let client = newOTClient("Hello")
    
    # Create an insertion operation
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let result = client.applyLocal(op)
    check result.isOk
    
    check client.state == csAwaitingConfirm
    check client.document.content == "Hello World"
    check client.pending.isSome
    check client.pending.get() == op
    check client.buffer.isNone

  test "Apply local operation when awaiting confirm":
    let client = newOTClient("Hello")
    
    # First operation
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    discard client.applyLocal(op1)
    
    # Second operation while awaiting
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert("!"))
    
    let result = client.applyLocal(op2)
    check result.isOk
    
    check client.state == csAwaitingWithBuffer
    check client.document.content == "Hello World!"
    check client.pending.isSome
    check client.pending.get() == op1
    check client.buffer.isSome
    check client.buffer.get() == op2

  test "Apply local operation when awaiting with buffer":
    let client = newOTClient("Hello")
    
    # Setup: get to awaiting with buffer state
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert("!"))
    
    discard client.applyLocal(op1)
    discard client.applyLocal(op2)
    
    # Try to apply third operation
    let op3 = buildOp(proc(o: var TextOperation) =
      o.delete(1)
      o.retain(11))
    
    let result = client.applyLocal(op3)
    check result.isOk
    
    # Should still be in awaiting with buffer, but buffer should be composed
    check client.state == csAwaitingWithBuffer
    check client.document.content == "ello World!"
    check client.pending.isSome
    check client.pending.get() == op1
    check client.buffer.isSome
    
    # Buffer should be composition of op2 and op3
    let expectedBuffer = op2.compose(op3).get()
    check client.buffer.get() == expectedBuffer

  test "Server acknowledges operation when awaiting confirm":
    let client = newOTClient("Hello")
    
    # Apply local operation
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    discard client.applyLocal(op)
    
    # Server acknowledges
    let ackResult = client.serverAck()
    check ackResult.isOk
    
    check client.state == csSynchronized
    check client.revision == 1
    check client.pending.isNone
    check client.buffer.isNone

  test "Server acknowledges operation when awaiting with buffer":
    let client = newOTClient("Hello")
    
    # Setup: get to awaiting with buffer state
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert("!"))
    
    discard client.applyLocal(op1)
    discard client.applyLocal(op2)
    
    # Server acknowledges first operation
    let ackResult = client.serverAck()
    check ackResult.isOk
    
    check client.state == csAwaitingConfirm
    check client.revision == 1
    check client.pending.isSome
    check client.pending.get() == op2
    check client.buffer.isNone

  test "Apply remote operation when synchronized":
    let client = newOTClient("Hello")
    
    # Remote operation
    let remoteOp = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Remote"))
    
    let result = client.applyServer(remoteOp, 0)
    check result.isOk
    
    check client.state == csSynchronized
    check client.revision == 1
    check client.document.content == "Hello Remote"

  test "Apply remote operation when awaiting confirm":
    let client = newOTClient("Hello")
    
    # Local operation
    let localOp = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Local"))
    
    discard client.applyLocal(localOp)
    
    # Remote operation arrives
    let remoteOp = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Remote"))
    
    let result = client.applyServer(remoteOp, 0)
    check result.isOk
    
    check client.state == csAwaitingConfirm
    check client.revision == 1
    
    # Document should have both operations applied
    # The local operation was applied first, then the server operation
    # was transformed to accommodate it
    check client.document.content == "Hello Local Remote"
    
    # Pending operation should be transformed
    check client.pending.isSome
    let transformedLocal = client.pending.get()
    check transformedLocal.targetLength == 18  # Length after remote op

  test "Apply remote operation when awaiting with buffer":
    let client = newOTClient("Hello")
    
    # Setup: get to awaiting with buffer state
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" First"))
    
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert(" Second"))
    
    discard client.applyLocal(op1)
    discard client.applyLocal(op2)
    
    check client.state == csAwaitingWithBuffer
    
    # Remote operation arrives
    let remoteOp = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Remote"))
    
    let result = client.applyServer(remoteOp, 0)
    check result.isOk
    
    check client.state == csAwaitingWithBuffer
    check client.revision == 1
    
    # Document should have all operations applied
    # The document should have all operations applied in the order they were
    # transformed. First -> Second -> Remote (transformed to the end)
    check client.document.content == "Hello First Second Remote"
    
    # Both pending and buffer should be transformed
    check client.pending.isSome
    check client.buffer.isSome