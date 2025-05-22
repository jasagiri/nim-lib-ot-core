## Tests for History module

import unittest
import ../src/nim_lib_ot_core/[types, operations, history]
import options
import json

proc buildOp(op: proc(o: var TextOperation)): TextOperation =
  var operation = newTextOperation()
  op(operation)
  result = operation

suite "History Management Tests":
  test "New history has empty stacks":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    check history.document.content == "Hello"
    check history.canUndo() == false
    check history.canRedo() == false
    check history.undoCount() == 0
    check history.redoCount() == 0
  
  test "Push operation":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let result = history.pushOperation(op)
    check result.isOk
    
    check history.document.content == "Hello World"
    check history.canUndo() == true
    check history.canRedo() == false
    check history.undoCount() == 1
    check history.redoCount() == 0
  
  test "Undo operation":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    discard history.pushOperation(op)
    check history.document.content == "Hello World"
    
    let undoResult = history.undo()
    check undoResult.isOk
    
    check history.document.content == "Hello"
    check history.canUndo() == false
    check history.canRedo() == true
    check history.undoCount() == 0
    check history.redoCount() == 1
  
  test "Redo operation":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    discard history.pushOperation(op)
    discard history.undo()
    
    let redoResult = history.redo()
    check redoResult.isOk
    
    check history.document.content == "Hello World"
    check history.canUndo() == true
    check history.canRedo() == false
    check history.undoCount() == 1
    check history.redoCount() == 0
  
  test "Multiple operations":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    # First operation: add " World"
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    discard history.pushOperation(op1)
    
    # Second operation: add "!"
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(11)
      o.insert("!"))
    discard history.pushOperation(op2)
    
    check history.document.content == "Hello World!"
    check history.undoCount() == 2
    
    # Undo the second operation (remove "!")
    discard history.undo()
    check history.document.content == "Hello World"
    check history.undoCount() == 1
    check history.redoCount() == 1
    
    # Undo the first operation (remove " World")
    discard history.undo()
    check history.document.content == "Hello"
    check history.undoCount() == 0
    check history.redoCount() == 2
    
    # Redo the first operation (add " World" back)
    discard history.redo()
    check history.document.content == "Hello World"
    check history.undoCount() == 1
    check history.redoCount() == 1
    
    # Redo the second operation (add "!" back)
    discard history.redo()
    check history.document.content == "Hello World!"
    check history.undoCount() == 2
    check history.redoCount() == 0
  
  test "New operation clears redo stack":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    # Add " World"
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    discard history.pushOperation(op1)
    
    # Undo
    discard history.undo()
    check history.redoCount() == 1
    
    # Add something else
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" Universe"))
    discard history.pushOperation(op2)
    
    # Redo stack should be cleared
    check history.document.content == "Hello Universe"
    check history.redoCount() == 0
  
  test "Peek undo/redo operations":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    # Initially both peek operations should return none
    check history.peekUndo().isNone
    check history.peekRedo().isNone
    
    # Push operation
    discard history.pushOperation(op)
    
    # Should be able to peek at the undo operation
    let undoEntry = history.peekUndo()
    check undoEntry.isSome
    
    # Undo the operation
    discard history.undo()
    
    # Should be able to peek at the redo operation
    let redoEntry = history.peekRedo()
    check redoEntry.isSome
    
    # Should be the same operation
    check undoEntry.get().operation.ops.len == redoEntry.get().operation.ops.len
  
  test "History with metadata":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    
    let metadata = %*{"author": "User 1", "timestamp": 1623456789}
    discard history.pushOperation(op, metadata)
    
    let entry = history.peekUndo()
    check entry.isSome
    check entry.get().metadata == metadata
  
  test "Undo with nothing to undo":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let result = history.undo()
    check result.isErr
    check result.error == NothingToUndo
  
  test "Redo with nothing to redo":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    let result = history.redo()
    check result.isErr
    check result.error == NothingToRedo
  
  test "Clear history":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc)
    
    # Add operations
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" World"))
    discard history.pushOperation(op1)
    
    # Undo to have operations in both stacks
    discard history.undo()
    
    check history.undoCount() == 0
    check history.redoCount() == 1
    
    # Clear history
    history.clear()
    
    check history.undoCount() == 0
    check history.redoCount() == 0
    check history.document.content == "Hello"  # Document content remains unchanged
  
  test "Max history size":
    let doc = newDocument("Hello")
    let history = newEditHistory(doc, 2)  # Only keep 2 operations
    
    # Add first operation
    let op1 = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert(" A"))
    discard history.pushOperation(op1)
    
    # Add second operation
    let op2 = buildOp(proc(o: var TextOperation) =
      o.retain(7)
      o.insert(" B"))
    discard history.pushOperation(op2)
    
    # Add third operation (should push the first one out)
    let op3 = buildOp(proc(o: var TextOperation) =
      o.retain(9)
      o.insert(" C"))
    discard history.pushOperation(op3)
    
    check history.undoCount() == 2  # Max is 2
    
    # First undo should bring us to "Hello A B"
    discard history.undo()
    check history.document.content == "Hello A B"
    
    # Second undo should bring us to "Hello A", not "Hello" since the first op was removed
    discard history.undo()
    check history.document.content == "Hello A"