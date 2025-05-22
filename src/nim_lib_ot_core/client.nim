## Client-side implementation for OT
## Manages client state and handles local/remote operations

import ./types
import ./operations
import ./transform
import results
import options

type
  ClientState* = enum
    csSynchronized = "synchronized"
    csAwaitingConfirm = "awaiting_confirm"
    csAwaitingWithBuffer = "awaiting_with_buffer"
  
  OTClient* = ref object
    state*: ClientState
    document*: Document
    revision*: int
    
    # Operations pending confirmation
    pending*: Option[TextOperation]
    
    # Operations buffered while waiting
    buffer*: Option[TextOperation]
  
  ClientError* = enum
    InvalidState = "Invalid client state"
    OperationMismatch = "Operation revision mismatch"
    TransformError = "Failed to transform operations"
  
  ClientResult*[T] = Result[T, ClientError]

proc newOTClient*(content: string = "", revision: int = 0): OTClient =
  ## Create a new OT client
  OTClient(
    state: csSynchronized,
    document: newDocument(content),
    revision: revision,
    pending: none(TextOperation),
    buffer: none(TextOperation)
  )

proc applyLocal*(client: OTClient, op: TextOperation): ClientResult[TextOperation] =
  ## Apply a local operation to the client
  case client.state:
  of csSynchronized:
    # Apply operation to document
    let applyResult = client.document.apply(op)
    if applyResult.isErr:
      return err(InvalidState)
    
    client.document = applyResult.get()
    client.state = csAwaitingConfirm
    client.pending = some(op)
    
    ok(op)
  
  of csAwaitingConfirm:
    # Buffer the operation
    if client.buffer.isNone:
      client.buffer = some(op)
    else:
      # Compose with existing buffer
      let composeResult = compose(client.buffer.get(), op)
      if composeResult.isErr:
        return err(TransformError)
      client.buffer = some(composeResult.get())
    
    client.state = csAwaitingWithBuffer
    
    # Apply to document
    let applyResult = client.document.apply(op)
    if applyResult.isErr:
      return err(InvalidState)
    client.document = applyResult.get()
    
    ok(op)
  
  of csAwaitingWithBuffer:
    # Compose with buffer
    if client.buffer.isNone:
      return err(InvalidState)
    
    let composeResult = compose(client.buffer.get(), op)
    if composeResult.isErr:
      return err(TransformError)
    
    client.buffer = some(composeResult.get())
    
    # Apply to document
    let applyResult = client.document.apply(op)
    if applyResult.isErr:
      return err(InvalidState)
    client.document = applyResult.get()
    
    ok(op)

proc applyServer*(client: OTClient, op: TextOperation, serverRevision: int): ClientResult[Option[TextOperation]] =
  ## Apply a server operation to the client
  ## Returns the operation to send back to server if needed
  
  # Check revision
  if serverRevision < client.revision:
    return err(OperationMismatch)
  
  client.revision = serverRevision + 1
  
  case client.state:
  of csSynchronized:
    # Simply apply the server operation
    let applyResult = client.document.apply(op)
    if applyResult.isErr:
      return err(InvalidState)
    client.document = applyResult.get()
    ok(none(TextOperation))
  
  of csAwaitingConfirm:
    if client.pending.isNone:
      return err(InvalidState)
    
    
    # Transform server op with pending op
    let transformResult = transform(client.pending.get(), op)
    if transformResult.isErr:
      return err(TransformError)
    
    let (pendingPrime, serverPrime) = transformResult.get()
    
    
    # Apply transformed server op
    let applyResult = client.document.apply(serverPrime)
    if applyResult.isErr:
      return err(InvalidState)
    client.document = applyResult.get()
    
    # Update pending operation
    client.pending = some(pendingPrime)
    
    ok(none(TextOperation))
  
  of csAwaitingWithBuffer:
    if client.pending.isNone or client.buffer.isNone:
      return err(InvalidState)
    
    # Transform server op with pending op
    let transformResult1 = transform(client.pending.get(), op)
    if transformResult1.isErr:
      return err(TransformError)
    
    let (pendingPrime, serverPrime1) = transformResult1.get()
    
    # Transform result with buffer
    let transformResult2 = transform(client.buffer.get(), serverPrime1)
    if transformResult2.isErr:
      return err(TransformError)
    
    let (bufferPrime, serverPrime2) = transformResult2.get()
    
    # Apply final transformed server op
    let applyResult = client.document.apply(serverPrime2)
    if applyResult.isErr:
      return err(InvalidState)
    client.document = applyResult.get()
    
    # Update pending and buffer
    client.pending = some(pendingPrime)
    client.buffer = some(bufferPrime)
    
    ok(none(TextOperation))

proc serverAck*(client: OTClient): ClientResult[Option[TextOperation]] =
  ## Handle server acknowledgment of pending operation
  ## Returns buffered operation if any
  
  case client.state:
  of csSynchronized:
    err(InvalidState)
  
  of csAwaitingConfirm:
    client.state = csSynchronized
    client.pending = none(TextOperation)
    client.revision += 1
    ok(none(TextOperation))
  
  of csAwaitingWithBuffer:
    if client.buffer.isNone:
      return err(InvalidState)
    
    # Move buffer to pending
    let buffered = client.buffer.get()
    client.pending = some(buffered)
    client.buffer = none(TextOperation)
    client.state = csAwaitingConfirm
    client.revision += 1
    
    ok(some(buffered))

proc resync*(client: OTClient, document: Document, revision: int) =
  ## Resynchronize client with server state
  client.document = document
  client.revision = revision
  client.state = csSynchronized
  client.pending = none(TextOperation)
  client.buffer = none(TextOperation)

proc getContent*(client: OTClient): string =
  ## Get current document content
  client.document.content

proc getRevision*(client: OTClient): int =
  ## Get current revision number
  client.revision

proc isWaiting*(client: OTClient): bool =
  ## Check if client is waiting for server confirmation
  client.state != csSynchronized