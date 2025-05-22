import unittest
import ../src/nim_lib_ot_core/cursor
import ../src/nim_lib_ot_core/types
import ../src/nim_lib_ot_core/operations

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

suite "Cursor Transformation Tests":
  test "Transform cursor through retain":
    # Cursor at position 5, retain 10 chars
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(10))
    
    # Cursor position shouldn't change for retain
    check transformCursor(0, op) == 0
    check transformCursor(5, op) == 5
    check transformCursor(10, op) == 10

  test "Transform cursor through insert before cursor":
    # Insert "Hello" at position 2, cursor at position 5
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(2)
      o.insert("Hello")
      o.retain(8))
    
    # Cursor should shift right by insert length
    check transformCursor(0, op) == 0  # Before insert, no change
    check transformCursor(2, op) == 2  # At insert position
    check transformCursor(5, op) == 10  # After insert, shifted by 5
    check transformCursor(10, op) == 15  # After insert, shifted by 5

  test "Transform cursor through insert after cursor":
    # Insert "World" at position 8, cursor at position 3
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(8)
      o.insert("World")
      o.retain(2))
    
    # Cursor before insert shouldn't change
    check transformCursor(3, op) == 3
    check transformCursor(8, op) == 8  # At insert position
    check transformCursor(10, op) == 15  # After insert, shifted

  test "Transform cursor through delete before cursor":
    # Delete 3 characters starting at position 2, cursor at position 7
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(2)
      o.delete(3)
      o.retain(5))
    
    # Cursor should shift left after delete
    check transformCursor(0, op) == 0  # Before delete
    check transformCursor(2, op) == 2  # At delete start
    check transformCursor(4, op) == 2  # Within delete range -> delete start
    check transformCursor(5, op) == 2  # At delete end -> delete start
    check transformCursor(7, op) == 4  # After delete, shifted left by 3

  test "Transform cursor through delete after cursor":
    # Delete 4 characters starting at position 8, cursor at position 3
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(8)
      o.delete(4))
    
    # Cursor before delete shouldn't change
    check transformCursor(3, op) == 3
    check transformCursor(8, op) == 8  # At delete position

  test "Transform cursor through delete containing cursor":
    # Delete 5 characters starting at position 2, cursor at position 4
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(2)
      o.delete(5)
      o.retain(3))
    
    # Cursor within delete range should move to delete start
    check transformCursor(4, op) == 2  # Within delete -> start of delete
    check transformCursor(2, op) == 2  # Start of delete
    check transformCursor(6, op) == 2  # Within delete -> start of delete
    check transformCursor(7, op) == 2  # End of delete -> start of delete
    check transformCursor(8, op) == 3  # After delete, shifted left

  test "Transform cursor with isOwn true":
    # When the operation is from the same source as the cursor
    # Insert tie-breaking favors the cursor position
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(5)
      o.insert("Test")
      o.retain(5))
    
    # Without isOwn, cursor at insert position stays there
    check transformCursor(5, op, false) == 5
    # With isOwn, cursor at insert position moves after the insert
    check transformCursor(5, op, true) == 9

  test "Transform cursor through complex operation":
    # Complex operation: retain 2, delete 3, insert "Hello", retain 2, insert "World", delete 1
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(2)
      o.delete(3)
      o.insert("Hello")
      o.retain(2)
      o.insert("World")
      o.delete(1))
    
    # Test various cursor positions
    check transformCursor(0, op) == 0  # Start
    check transformCursor(2, op) == 2  # At first operation
    check transformCursor(4, op) == 2  # Within delete -> delete start
    check transformCursor(5, op) == 2  # End of delete -> delete start
    check transformCursor(6, op) == 8  # After delete+insert
    check transformCursor(7, op) == 9  # After delete+insert+retain
    check transformCursor(8, op) == 14  # End of original doc -> end of new doc
    check transformCursor(9, op) == 15  # Past original doc

  test "Transform cursor array":
    let cursors = @[0, 3, 5, 8, 10]
    let op = buildOp(proc(o: var TextOperation) =
      o.retain(3)
      o.insert("---")
      o.retain(7))
    
    let transformed = transformCursors(cursors, op)
    
    check transformed == @[0, 3, 8, 11, 13]

  test "Transform empty cursor array":
    let cursors: seq[int] = @[]
    let op = buildOp(proc(o: var TextOperation) =
      o.insert("Test"))
    
    let transformed = transformCursors(cursors, op)
    
    check transformed == newSeq[int]()