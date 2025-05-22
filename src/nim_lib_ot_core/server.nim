## Server-side implementation for OT
## Manages server state and handles operations from multiple clients

import ./types
import ./operations
import ./transform
import results
import options
import tables
import sequtils

type
  ClientId* = string
  
  DocumentState* = object
    content*: string
    revision*: int
  
  ClientState* = object
    lastRevision*: int
    pendingOps*: seq[TextOperation]
  
  OTServer* = ref object
    document*: DocumentState
    clients*: Table[ClientId, ClientState]
    revision*: int
    operationHistory*: seq[TextOperation]
  
  ServerError* = enum
    InvalidRevision = "Invalid operation revision"
    UnknownClient = "Unknown client"
    TransformError = "Failed to transform operations"
    InvalidOperation = "Invalid operation"

type
  ServerResult*[T] = Result[T, ServerError]

proc newOTServer*(initialContent: string = ""): OTServer =
  ## Create a new OT server
  OTServer(
    document: DocumentState(content: initialContent, revision: 0),
    clients: initTable[ClientId, ClientState](),
    revision: 0,
    operationHistory: @[]
  )

proc registerClient*(server: OTServer, clientId: ClientId): ServerResult[int] =
  ## Register a new client and return the current revision
  server.clients[clientId] = ClientState(
    lastRevision: server.revision,
    pendingOps: @[]
  )
  ok(server.revision)

proc unregisterClient*(server: OTServer, clientId: ClientId): ServerResult[void] =
  ## Remove a client from the server
  if clientId notin server.clients:
    return err(UnknownClient)
  server.clients.del(clientId)
  ok()

proc receiveOperation*(server: OTServer, clientId: ClientId, op: TextOperation, 
                     clientRevision: int): ServerResult[tuple[transformed: TextOperation, revision: int]] =
  ## Receive an operation from a client
  ## Returns the transformed operation and new revision
  
  # Check if client is registered
  if clientId notin server.clients:
    return err(UnknownClient)
  
  # Validate the operation
  let validateResult = op.validate()
  if validateResult.isErr:
    return err(InvalidOperation)
  
  # Check client revision
  if clientRevision < 0 or clientRevision > server.revision:
    return err(InvalidRevision)
  
  # Transform against operations since client's revision
  var transformedOp = op
  
  # Apply all operations from client's revision to current revision
  for i in clientRevision ..< server.revision:
    let historicalOp = server.operationHistory[i]
    let transformResult = transform(transformedOp, historicalOp)
    if transformResult.isErr:
      return err(TransformError)
    transformedOp = transformResult.get().a
  
  # Apply the transformed operation to the document
  let doc = newDocument(server.document.content)
  let applyResult = doc.apply(transformedOp)
  if applyResult.isErr:
    return err(InvalidOperation)
  
  # Update server state
  server.document.content = applyResult.get().content
  server.revision += 1
  server.document.revision = server.revision
  server.operationHistory.add(transformedOp)
  
  # Update client state
  server.clients[clientId].lastRevision = server.revision
  
  ok((transformed: transformedOp, revision: server.revision))

proc getDocument*(server: OTServer): DocumentState =
  ## Get the current document state
  server.document

proc getRevision*(server: OTServer): int =
  ## Get the current revision number
  server.revision

proc getClients*(server: OTServer): seq[ClientId] =
  ## Get list of connected clients
  toSeq(server.clients.keys)

proc getClientState*(server: OTServer, clientId: ClientId): ServerResult[ClientState] =
  ## Get state for a specific client
  if clientId notin server.clients:
    return err(UnknownClient)
  ok(server.clients[clientId])

proc broadcast*(server: OTServer, sourceClient: ClientId, op: TextOperation, 
                revision: int): seq[tuple[clientId: ClientId, op: TextOperation]] =
  ## Prepare operations to broadcast to all other clients
  ## Returns list of (clientId, transformed operation) pairs
  result = @[]
  
  for clientId, state in server.clients.pairs:
    if clientId != sourceClient:
      # Transform the operation for this client's state
      var transformedOp = op
      
      # If client is behind, transform through the operations they haven't seen
      if state.lastRevision < revision:
        for i in state.lastRevision ..< revision:
          if i < server.operationHistory.len:
            let historicalOp = server.operationHistory[i]
            let transformResult = transform(transformedOp, historicalOp)
            if transformResult.isOk:
              transformedOp = transformResult.get().a
      
      result.add((clientId: clientId, op: transformedOp))