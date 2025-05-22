## Protocol for client-server communication
## Defines message types and serialization/deserialization

import ./types
import json
import options

type
  MessageType* = enum
    mtClientId = "client_id"           # Server -> Client: assign client ID
    mtOperation = "operation"          # Client -> Server: send operation
    mtAck = "ack"                     # Server -> Client: acknowledge operation
    mtRemoteOperation = "remote_op"    # Server -> Client: broadcast remote operation
    mtConnectionRequest = "connect"    # Client -> Server: request connection
    mtConnectionAccept = "accept"      # Server -> Client: accept connection
    mtError = "error"                 # Server -> Client: error message
    mtSync = "sync"                   # Client -> Server: request sync
    mtSyncResponse = "sync_response"   # Server -> Client: sync response
  
  Message* = ref object
    case kind*: MessageType
    of mtClientId:
      clientId*: string
    of mtOperation:
      operation*: TextOperation
      revision*: int
    of mtAck:
      operationId*: string  # ID of acknowledged operation
      newRevision*: int
    of mtRemoteOperation:
      remoteOp*: TextOperation
      fromClient*: string
      serverRevision*: int
    of mtConnectionRequest:
      protocolVersion*: string
    of mtConnectionAccept:
      assignedId*: string
      initialRevision*: int
      documentContent*: string
    of mtError:
      errorCode*: string
      errorMessage*: string
    of mtSync:
      lastKnownRevision*: int
    of mtSyncResponse:
      currentRevision*: int
      currentContent*: string
      missedOperations*: seq[TextOperation]

proc toJson*(msg: Message): JsonNode =
  ## Serialize a message to JSON
  result = newJObject()
  result["type"] = %($msg.kind)
  
  case msg.kind
  of mtClientId:
    result["clientId"] = %msg.clientId
  
  of mtOperation:
    result["operation"] = msg.operation.toJson()
    result["revision"] = %msg.revision
  
  of mtAck:
    result["operationId"] = %msg.operationId
    result["newRevision"] = %msg.newRevision
  
  of mtRemoteOperation:
    result["remoteOp"] = msg.remoteOp.toJson()
    result["fromClient"] = %msg.fromClient
    result["serverRevision"] = %msg.serverRevision
  
  of mtConnectionRequest:
    result["protocolVersion"] = %msg.protocolVersion
  
  of mtConnectionAccept:
    result["assignedId"] = %msg.assignedId
    result["initialRevision"] = %msg.initialRevision
    result["documentContent"] = %msg.documentContent
  
  of mtError:
    result["errorCode"] = %msg.errorCode
    result["errorMessage"] = %msg.errorMessage
  
  of mtSync:
    result["lastKnownRevision"] = %msg.lastKnownRevision
  
  of mtSyncResponse:
    result["currentRevision"] = %msg.currentRevision
    result["currentContent"] = %msg.currentContent
    result["missedOperations"] = newJArray()
    for op in msg.missedOperations:
      result["missedOperations"].add(op.toJson())

proc parseMessageType(s: string): Option[MessageType] =
  ## Parse message type from string
  case s
  of "client_id": some(mtClientId)
  of "operation": some(mtOperation)
  of "ack": some(mtAck)
  of "remote_op": some(mtRemoteOperation)
  of "connect": some(mtConnectionRequest)
  of "accept": some(mtConnectionAccept)
  of "error": some(mtError)
  of "sync": some(mtSync)
  of "sync_response": some(mtSyncResponse)
  else: none(MessageType)

proc parseMessage*(json: JsonNode): Option[Message] =
  ## Deserialize a message from JSON
  if not json.hasKey("type"):
    return none(Message)
  
  let msgTypeOpt = parseMessageType(json["type"].getStr())
  if msgTypeOpt.isNone:
    return none(Message)
  
  let msgType = msgTypeOpt.get()
  var msg: Message
  
  case msgType
  of mtClientId:
    if not json.hasKey("clientId"):
      return none(Message)
    msg = Message(kind: mtClientId, clientId: json["clientId"].getStr())
  
  of mtOperation:
    if not json.hasKey("operation") or not json.hasKey("revision"):
      return none(Message)
    let opOpt = json["operation"].fromJsonTextOperation()
    if opOpt.isNone:
      return none(Message)
    msg = Message(
      kind: mtOperation,
      operation: opOpt.get(),
      revision: json["revision"].getInt()
    )
  
  of mtAck:
    if not json.hasKey("operationId") or not json.hasKey("newRevision"):
      return none(Message)
    msg = Message(
      kind: mtAck,
      operationId: json["operationId"].getStr(),
      newRevision: json["newRevision"].getInt()
    )
  
  of mtRemoteOperation:
    if not json.hasKey("remoteOp") or not json.hasKey("fromClient") or not json.hasKey("serverRevision"):
      return none(Message)
    let opOpt = json["remoteOp"].fromJsonTextOperation()
    if opOpt.isNone:
      return none(Message)
    msg = Message(
      kind: mtRemoteOperation,
      remoteOp: opOpt.get(),
      fromClient: json["fromClient"].getStr(),
      serverRevision: json["serverRevision"].getInt()
    )
  
  of mtConnectionRequest:
    if not json.hasKey("protocolVersion"):
      return none(Message)
    msg = Message(
      kind: mtConnectionRequest,
      protocolVersion: json["protocolVersion"].getStr()
    )
  
  of mtConnectionAccept:
    if not json.hasKey("assignedId") or not json.hasKey("initialRevision") or not json.hasKey("documentContent"):
      return none(Message)
    msg = Message(
      kind: mtConnectionAccept,
      assignedId: json["assignedId"].getStr(),
      initialRevision: json["initialRevision"].getInt(),
      documentContent: json["documentContent"].getStr()
    )
  
  of mtError:
    if not json.hasKey("errorCode") or not json.hasKey("errorMessage"):
      return none(Message)
    msg = Message(
      kind: mtError,
      errorCode: json["errorCode"].getStr(),
      errorMessage: json["errorMessage"].getStr()
    )
  
  of mtSync:
    if not json.hasKey("lastKnownRevision"):
      return none(Message)
    msg = Message(
      kind: mtSync,
      lastKnownRevision: json["lastKnownRevision"].getInt()
    )
  
  of mtSyncResponse:
    if not json.hasKey("currentRevision") or not json.hasKey("currentContent") or not json.hasKey("missedOperations"):
      return none(Message)
    
    var missedOps: seq[TextOperation] = @[]
    for opJson in json["missedOperations"]:
      let opOpt = opJson.fromJsonTextOperation()
      if opOpt.isNone:
        return none(Message)
      missedOps.add(opOpt.get())
    
    msg = Message(
      kind: mtSyncResponse,
      currentRevision: json["currentRevision"].getInt(),
      currentContent: json["currentContent"].getStr(),
      missedOperations: missedOps
    )
  
  some(msg)

# Helper constructors
proc newClientIdMessage*(clientId: string): Message =
  Message(kind: mtClientId, clientId: clientId)

proc newOperationMessage*(op: TextOperation, revision: int): Message =
  Message(kind: mtOperation, operation: op, revision: revision)

proc newAckMessage*(operationId: string, newRevision: int): Message =
  Message(kind: mtAck, operationId: operationId, newRevision: newRevision)

proc newRemoteOperationMessage*(op: TextOperation, fromClient: string, serverRevision: int): Message =
  Message(kind: mtRemoteOperation, remoteOp: op, fromClient: fromClient, serverRevision: serverRevision)

proc newConnectionRequestMessage*(protocolVersion: string = "1.0"): Message =
  Message(kind: mtConnectionRequest, protocolVersion: protocolVersion)

proc newConnectionAcceptMessage*(assignedId: string, initialRevision: int, documentContent: string): Message =
  Message(kind: mtConnectionAccept, assignedId: assignedId, initialRevision: initialRevision, documentContent: documentContent)

proc newErrorMessage*(errorCode: string, errorMessage: string): Message =
  Message(kind: mtError, errorCode: errorCode, errorMessage: errorMessage)

proc newSyncMessage*(lastKnownRevision: int): Message =
  Message(kind: mtSync, lastKnownRevision: lastKnownRevision)

proc newSyncResponseMessage*(currentRevision: int, currentContent: string, missedOperations: seq[TextOperation]): Message =
  Message(kind: mtSyncResponse, currentRevision: currentRevision, currentContent: currentContent, missedOperations: missedOperations)