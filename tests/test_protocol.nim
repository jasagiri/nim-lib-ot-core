## Tests for OT Protocol

import unittest
import ../src/nim_lib_ot_core/[protocol, types, operations]
import json
import options

suite "OT Protocol Tests":
  test "Client ID message serialization/deserialization":
    let msg = newClientIdMessage("client123")
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtClientId
    check parsed.get().clientId == "client123"
  
  test "Operation message serialization/deserialization":
    var op = newTextOperation()
    op.retain(5)
    op.insert("Hello")
    
    let msg = newOperationMessage(op, 10)
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtOperation
    check parsed.get().revision == 10
    
    # Check operation
    let parsedOp = parsed.get().operation
    check parsedOp.baseLength == 5
    check parsedOp.ops.len == 2
    check parsedOp.ops[0].kind == opRetain
    check parsedOp.ops[0].n == 5
    check parsedOp.ops[1].kind == opInsert
    check parsedOp.ops[1].s == "Hello"
  
  test "Ack message serialization/deserialization":
    let msg = newAckMessage("op123", 5)
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtAck
    check parsed.get().operationId == "op123"
    check parsed.get().newRevision == 5
  
  test "Remote operation message serialization/deserialization":
    var op = newTextOperation()
    op.retain(2)
    op.delete(3)
    op.insert("World")
    
    let msg = newRemoteOperationMessage(op, "client456", 7)
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtRemoteOperation
    check parsed.get().fromClient == "client456"
    check parsed.get().serverRevision == 7
    
    # Check operation
    let parsedOp = parsed.get().remoteOp
    check parsedOp.ops.len == 3
    check parsedOp.ops[0].kind == opRetain
    check parsedOp.ops[1].kind == opDelete
    check parsedOp.ops[2].kind == opInsert
  
  test "Connection request message serialization/deserialization":
    let msg = newConnectionRequestMessage("1.0")
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtConnectionRequest
    check parsed.get().protocolVersion == "1.0"
  
  test "Connection accept message serialization/deserialization":
    let msg = newConnectionAcceptMessage("client789", 0, "Initial content")
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtConnectionAccept
    check parsed.get().assignedId == "client789"
    check parsed.get().initialRevision == 0
    check parsed.get().documentContent == "Initial content"
  
  test "Error message serialization/deserialization":
    let msg = newErrorMessage("INVALID_OP", "Operation is invalid")
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtError
    check parsed.get().errorCode == "INVALID_OP"
    check parsed.get().errorMessage == "Operation is invalid"
  
  test "Sync message serialization/deserialization":
    let msg = newSyncMessage(15)
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtSync
    check parsed.get().lastKnownRevision == 15
  
  test "Sync response message serialization/deserialization":
    var op1 = newTextOperation()
    op1.retain(5)
    op1.insert("A")
    
    var op2 = newTextOperation()
    op2.delete(2)
    
    let missedOps = @[op1, op2]
    let msg = newSyncResponseMessage(20, "Current content", missedOps)
    let json = msg.toJson()
    let parsed = json.parseMessage()
    
    check parsed.isSome
    check parsed.get().kind == mtSyncResponse
    check parsed.get().currentRevision == 20
    check parsed.get().currentContent == "Current content"
    check parsed.get().missedOperations.len == 2
  
  test "Invalid message parsing":
    let emptyJson = parseJson("{}")
    check emptyJson.parseMessage().isNone
    
    let missingType = parseJson("""{"revision": 5}""")
    check missingType.parseMessage().isNone
    
    let invalidType = parseJson("""{"type": "invalid_type"}""")
    check invalidType.parseMessage().isNone
    
    let incompleteMessage = parseJson("""{"type": "operation"}""")  # Missing operation field
    check incompleteMessage.parseMessage().isNone