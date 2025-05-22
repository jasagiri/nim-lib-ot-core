# nim-lib-ot API Documentation

This document provides a detailed reference of the nim-lib-ot API.

## Table of Contents

1. [Types Module](#types-module)
2. [Operations Module](#operations-module)
3. [Transform Module](#transform-module)
4. [Cursor Module](#cursor-module)
5. [Client Module](#client-module)
6. [Server Module](#server-module)
7. [Protocol Module](#protocol-module)
8. [History Module](#history-module)

## Types Module

The `types` module defines the core data structures used throughout the library.

### Types

#### `OperationKind`

Enum representing the kind of operation:
- `opRetain`: Keep characters unchanged
- `opInsert`: Insert characters
- `opDelete`: Delete characters

#### `Operation`

Represents a single operation:

```nim
Operation* = object
  case kind*: OperationKind
  of opRetain, opDelete:
    n*: int               # Number of characters to retain or delete
  of opInsert:
    s*: string            # String to insert
```

#### `TextOperation`

Represents a sequence of operations:

```nim
TextOperation* = object
  ops*: seq[Operation]    # Sequence of operations
  baseLength*: int        # Length of document before operation
  targetLength*: int      # Length of document after operation
```

#### `Document`

Represents a text document:

```nim
Document* = object
  content*: string        # Document content
```

#### `OpError`

Enum representing operation errors:
- `InvalidOperation`: The operation is malformed
- `LengthMismatch`: The operation length doesn't match the document
- `BaseTargetMismatch`: Base and target lengths don't match
- `TransformError`: Error during transform

#### `OpResult[T]`

Result type used for operations that can fail:

```nim
OpResult*[T] = Result[T, OpError]
```

### Functions

#### `newTextOperation(): TextOperation`

Creates a new empty text operation.

#### `validate(op: TextOperation): OpResult[void]`

Validates that a text operation is well-formed.

#### `newDocument(content: string): Document`

Creates a new document with the given content.

## Operations Module

The `operations` module provides functions for creating and manipulating operations.

### Functions

#### `retain(n: int): Operation`

Creates a retain operation for `n` characters.

#### `insert(s: string): Operation`

Creates an insert operation for string `s`.

#### `delete(n: int): Operation`

Creates a delete operation for `n` characters.

#### `retain(op: var TextOperation, n: int)`

Adds a retain operation to a TextOperation.

#### `insert(op: var TextOperation, s: string)`

Adds an insert operation to a TextOperation.

#### `delete(op: var TextOperation, n: int)`

Adds a delete operation to a TextOperation.

#### `isNoop(op: TextOperation): bool`

Checks if an operation has no effect.

#### `apply(doc: Document, op: TextOperation): OpResult[Document]`

Applies an operation to a document, returning a new document.

#### `compose(op1, op2: TextOperation): OpResult[TextOperation]`

Composes two operations into one.

#### `invert(op: TextOperation, doc: Document): OpResult[TextOperation]`

Creates an operation that undoes the effect of the given operation.

## Transform Module

The `transform` module provides functions for operational transformation.

### Functions

#### `transform(a, b: TextOperation): OpResult[tuple[a, b: TextOperation]]`

Transforms two operations that were applied to the same document state.

```nim
let result = transform(a, b)
if result.isOk:
  let (aPrime, bPrime) = result.get()
  # aPrime is a transformed against b
  # bPrime is b transformed against a
```

## Cursor Module

The `cursor` module provides functions for cursor transformation.

### Functions

#### `transformCursor(cursor: int, op: TextOperation, isOwn: bool = false): int`

Transforms a cursor position through an operation.

- `cursor`: The cursor position
- `op`: The operation to transform through
- `isOwn`: Whether the operation is owned by the cursor (affects behavior with inserts at cursor position)

#### `transformCursors(cursors: seq[int], op: TextOperation, isOwn: bool = false): seq[int]`

Transforms multiple cursor positions through an operation.

## Client Module

The `client` module provides the client-side implementation for collaborative editing.

### Types

#### `ClientState`

Enum representing the client state:
- `csSynchronized`: Client is synchronized with server
- `csAwaitingConfirm`: Client is waiting for confirmation of an operation
- `csAwaitingWithBuffer`: Client is waiting for confirmation and has buffered operations

#### `OTClient`

Client object with document and state management:

```nim
OTClient* = ref object
  state*: ClientState
  document*: Document
  revision*: int
  pending*: Option[TextOperation]
  buffer*: Option[TextOperation]
```

#### `ClientError`

Enum representing client errors:
- `InvalidState`: The client is in an invalid state
- `OperationMismatch`: Operation revision mismatch
- `TransformError`: Failed to transform operations

#### `ClientResult[T]`

Result type for client operations:

```nim
ClientResult*[T] = Result[T, ClientError]
```

### Functions

#### `newOTClient(content: string): OTClient`

Creates a new OT client.

#### `applyLocal(client: OTClient, op: TextOperation): ClientResult[TextOperation]`

Applies a local operation to the client.

#### `applyServer(client: OTClient, op: TextOperation, serverRevision: int): ClientResult[Option[TextOperation]]`

Applies a server operation to the client.

#### `serverAck(client: OTClient): ClientResult[Option[TextOperation]]`

Acknowledges that the server has received the client's operation.

## Server Module

The `server` module provides the server-side implementation for collaborative editing.

### Types

#### `ClientId`

String identifier for a client.

#### `DocumentState`

The server's document state:

```nim
DocumentState* = object
  content*: string
  revision*: int
```

#### `ClientState`

The server's view of a client's state:

```nim
ClientState* = object
  lastRevision*: int
  pendingOps*: seq[TextOperation]
```

#### `OTServer`

Server object managing document and clients:

```nim
OTServer* = ref object
  document*: DocumentState
  clients*: Table[ClientId, ClientState]
  revision*: int
  operationHistory*: seq[TextOperation]
```

#### `ServerError`

Enum representing server errors:
- `InvalidRevision`: Invalid operation revision
- `UnknownClient`: Unknown client
- `TransformError`: Failed to transform operations
- `InvalidOperation`: Invalid operation

#### `ServerResult[T]`

Result type for server operations:

```nim
ServerResult*[T] = Result[T, ServerError]
```

### Functions

#### `newOTServer(initialContent: string = ""): OTServer`

Creates a new OT server.

#### `registerClient(server: OTServer, clientId: ClientId): ServerResult[int]`

Registers a new client and returns the current revision.

#### `unregisterClient(server: OTServer, clientId: ClientId): ServerResult[void]`

Removes a client from the server.

#### `receiveOperation(server: OTServer, clientId: ClientId, op: TextOperation, clientRevision: int): ServerResult[tuple[transformed: TextOperation, revision: int]]`

Receives an operation from a client and transforms it if necessary.

#### `getDocument(server: OTServer): DocumentState`

Gets the current document state.

#### `getRevision(server: OTServer): int`

Gets the current revision number.

#### `getClients(server: OTServer): seq[ClientId]`

Gets list of connected clients.

#### `broadcast(server: OTServer, sourceClient: ClientId, op: TextOperation, revision: int): seq[tuple[clientId: ClientId, op: TextOperation]]`

Prepares operations to broadcast to all other clients.

## Protocol Module

The `protocol` module provides message formats for client-server communication.

### Types

#### `MessageType`

Enum representing message types:
- `mtClientId`: Server assigns client ID
- `mtOperation`: Client sends operation
- `mtAck`: Server acknowledges operation
- `mtRemoteOperation`: Server broadcasts remote operation
- `mtConnectionRequest`: Client requests connection
- `mtConnectionAccept`: Server accepts connection
- `mtError`: Server sends error message
- `mtSync`: Client requests sync
- `mtSyncResponse`: Server sends sync response

#### `Message`

Variant object representing different message types.

### Functions

#### `toJson(msg: Message): JsonNode`

Serializes a message to JSON.

#### `parseMessage(json: JsonNode): Option[Message]`

Deserializes a message from JSON.

#### Helper constructors for each message type:
- `newClientIdMessage`
- `newOperationMessage`
- `newAckMessage`
- `newRemoteOperationMessage`
- `newConnectionRequestMessage`
- `newConnectionAcceptMessage`
- `newErrorMessage`
- `newSyncMessage`
- `newSyncResponseMessage`

## History Module

The `history` module provides undo/redo functionality.

### Types

#### `HistoryError`

Enum representing history errors:
- `NothingToUndo`: Nothing to undo
- `NothingToRedo`: Nothing to redo
- `OperationInvalid`: Operation is invalid

#### `HistoryResult[T]`

Result type for history operations:

```nim
HistoryResult*[T] = Result[T, HistoryError]
```

#### `HistoryEntry`

A single operation in the history:

```nim
HistoryEntry* = object
  operation*: TextOperation
  inverse*: TextOperation
  timestamp*: int64
  metadata*: JsonNode
```

#### `EditHistory`

Tracks document operation history:

```nim
EditHistory* = ref object
  document*: Document
  undoStack*: seq[HistoryEntry]
  redoStack*: seq[HistoryEntry]
  maxSize*: int
```

### Functions

#### `newEditHistory(initialDoc: Document, maxSize: int = MAX_HISTORY_SIZE): EditHistory`

Creates a new edit history for a document.

#### `pushOperation(history: EditHistory, op: TextOperation, metadata: JsonNode = nil): HistoryResult[void]`

Adds an operation to the history.

#### `undo(history: EditHistory): HistoryResult[Document]`

Undoes the last operation.

#### `redo(history: EditHistory): HistoryResult[Document]`

Redoes the last undone operation.

#### `canUndo(history: EditHistory): bool`

Checks if an undo operation is available.

#### `canRedo(history: EditHistory): bool`

Checks if a redo operation is available.

#### `peekUndo(history: EditHistory): Option[HistoryEntry]`

Looks at the operation that would be undone next.

#### `peekRedo(history: EditHistory): Option[HistoryEntry]`

Looks at the operation that would be redone next.

#### `clear(history: EditHistory)`

Clears the history.