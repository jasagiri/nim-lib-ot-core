# nim-lib-ot-core

A comprehensive Operational Transformation (OT) library for Nim, providing real-time collaborative editing capabilities.

## Overview

nim-lib-ot-core is a full-featured Operational Transformation library that enables real-time collaborative editing in Nim applications. The library is designed with a focus on correctness, performance, and ease of use.

### Performance

Performance benchmarks (on a 10,000 character document, release build):
- Apply operations: 0.072ms per operation
- Transform operations: 0.0014ms per transform
- Client-server operations: 0.109ms per operation
- History operations: 0.0057ms per operation

Key features:
- Core OT operations: insert, delete, retain
- Transform function for handling concurrent edits
- Client-side and server-side implementations
- Cursor transformation for collaborative editing
- Undo/redo functionality with history management
- Serialization/deserialization for network communication
- Comprehensive test suite

## Installation

```bash
nimble install nim_lib_ot_core
```

Or add to your .nimble file:

```nim
requires "nim_lib_ot_core >= 0.0.0"
```

## Usage Examples

### Basic Operations

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations

# Create a new text operation
var op = newTextOperation()
op.retain(5)      # Keep first 5 characters unchanged
op.delete(3)      # Delete 3 characters
op.insert("new")  # Insert "new"
op.retain(7)      # Keep next 7 characters unchanged

# Apply to a document
let doc = newDocument("Hello world, how are you?")
let result = doc.apply(op)
if result.isOk:
  echo result.get().content  # "Hello new, how are you?"
```

### Client-Server Architecture

The library supports a client-server architecture for collaborative editing:

```nim
import nim_lib_ot_core/client
import nim_lib_ot_core/server

# Server-side
let server = newOTServer("Initial text")
let clientId = "client1"
discard server.registerClient(clientId)

# Client-side
let client = newOTClient("Initial text")

# Client makes an edit
var localOp = newTextOperation()
localOp.retain(13)
localOp.insert("collaborative ")
let clientResult = client.applyLocal(localOp)

# Send to server
if clientResult.isOk:
  let serverResult = server.receiveOperation(clientId, clientResult.get(), 0)
  
  # Server broadcasts to other clients
  if serverResult.isOk:
    let (transformedOp, revision) = serverResult.get()
    let broadcasts = server.broadcast(clientId, transformedOp, revision)

    # Other clients receive the operation
    for (id, op) in broadcasts:
      # Apply to other clients...
```

### Undo/Redo Functionality

```nim
import nim_lib_ot_core/history

# Create a history manager for the document
let doc = newDocument("Hello")
let history = newEditHistory(doc)

# Make some changes
var op1 = newTextOperation()
op1.retain(5)
op1.insert(" World")
discard history.pushOperation(op1)

var op2 = newTextOperation()
op2.retain(11)
op2.insert("!")
discard history.pushOperation(op2)

echo history.document.content  # "Hello World!"

# Undo last operation
discard history.undo()
echo history.document.content  # "Hello World"

# Redo the operation
discard history.redo()
echo history.document.content  # "Hello World!"
```

### Cursor Transformation

```nim
import nim_lib_ot_core/cursor

# Transform cursor position through operations
let cursorPos = 5  # Cursor at position 5

var op = newTextOperation()
op.retain(3)
op.insert("abc")
op.retain(10)

# Transform cursor
let newCursorPos = transformCursor(cursorPos, op)
# If cursor was at position 5, after inserting "abc" at position 3,
# cursor is now at position 8
```

## Architecture

The library consists of several key components:

1. **Core Types (types.nim)**
   - `TextOperation`: The main operation class containing sequences of retain, insert, and delete operations
   - `Document`: Represents a text document with content

2. **Operations (operations.nim)**
   - Functions for creating and manipulating operations
   - Composition, inversion, and application of operations

3. **Transformation (transform.nim)**
   - The core transformation algorithm for concurrent operations
   - Ensures convergence and intention preservation

4. **Client (client.nim)**
   - Client-side implementation with state management
   - Handles local and remote operations

5. **Server (server.nim)**
   - Server-side implementation for operation processing
   - Manages concurrent operations and broadcasts

6. **Protocol (protocol.nim)**
   - Message formats for client-server communication
   - Serialization/deserialization to JSON

7. **Cursor (cursor.nim)**
   - Functions for transforming cursor positions through operations
   - Supports collaborative editing with multiple cursors

8. **History (history.nim)**
   - Undo/redo functionality with operation history
   - Supports metadata for operations

## Project Structure

```
nim-lib-ot-core/
├── src/                    # Source code
│   ├── nim_lib_ot_core.nim # Main module
│   └── nim_lib_ot_core/    # Sub-modules
│       ├── types.nim       # Core types
│       ├── operations.nim  # Basic operations
│       ├── transform.nim   # Transformation algorithm
│       ├── client.nim      # Client implementation
│       ├── server.nim      # Server implementation
│       ├── cursor.nim      # Cursor transformation
│       ├── protocol.nim    # Network protocol
│       ├── history.nim     # Undo/redo functionality
│       └── experimental/   # Experimental implementations
│           ├── transform_alt.nim   # Alternative transform algorithm
│           ├── transform_debug.nim # Debug-friendly implementation
│           └── benchmark.nim       # Performance comparison tools
├── tests/                  # Test files
│   ├── specs/              # BDD-style feature specifications
│   │   ├── operations.feature
│   │   ├── transform.feature
│   │   ├── client_server.feature
│   │   ├── cursor.feature
│   │   ├── history.feature
│   │   └── protocol.feature
│   ├── test_operations.nim # Unit tests
│   ├── test_transform.nim
│   ├── test_client.nim
│   └── ...
├── examples/               # Example code
│   ├── basic_usage.nim
│   └── benchmark.nim
├── benchmarks/             # Performance benchmarks
│   └── bench_all.nim
└── docs/                   # Documentation
    ├── api.md              # API reference
    ├── architecture.md     # Architecture documentation
    ├── experimental.md     # Experimental implementations guide
    └── design/             # Design documents
```

## Reference Documentation

For detailed API documentation, see the [API docs](docs/api.md). For information about experimental implementations, see [Experimental docs](docs/experimental.md).

## Development

### Building from Source

```bash
git clone https://github.com/jasagiri/nim-lib-ot-core.git
cd nim-lib-ot-core
nimble build
```

### Running Tests

```bash
nimble test
```

### Running Benchmarks

```bash
nimble benchmark
```

### Cleaning Build Artifacts

```bash
nimble clean
```

### BDD Tests

The project includes a set of behavior-driven development (BDD) specifications in Gherkin format located in the `tests/specs/` directory. These feature files describe the expected behavior of the library in a human-readable format.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

This library is inspired by:
- [ot.js](https://github.com/Operational-Transformation/ot.js)
- [ShareDB](https://github.com/share/sharedb)
- [CodeMirror](https://codemirror.net/) collaboration features
