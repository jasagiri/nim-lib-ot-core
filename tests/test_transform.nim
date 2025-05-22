import unittest
import results
import ../src/nim_lib_ot_core/[types, operations, transform]

suite "Transform":
  test "Transform insert-insert":
    var op1 = newTextOperation()
    op1.insert("A")
    op1.retain(5)
    op1.baseLength = 5
    op1.targetLength = 6
    
    var op2 = newTextOperation()
    op2.insert("B")
    op2.retain(5)
    op2.baseLength = 5
    op2.targetLength = 6
    
    # Check base operations are correctly formed
    check op1.baseLength == 5
    check op1.targetLength == 6
    check op2.baseLength == 5
    check op2.targetLength == 6
    
    let result = transform(op1, op2)
    if not result.isOk:
      echo "Transform error: ", result.error
    check result.isOk
    
    let (op1p, op2p) = result.get
    
    # Debug transform results
    echo "op1p: baseLength=", op1p.baseLength, " targetLength=", op1p.targetLength
    echo "op1p ops: ", op1p.ops
    echo "op2p: baseLength=", op2p.baseLength, " targetLength=", op2p.targetLength
    echo "op2p ops: ", op2p.ops
    
    # Apply both original ops to doc
    let doc = newDocument("hello")
    let r1 = doc.apply(op1)
    check r1.isOk
    echo "after op1: ", r1.get.content
    let r2 = r1.get.apply(op2p)
    if not r2.isOk:
      echo "r2 error: ", r2.error
      echo "r1.get.content.len: ", r1.get.content.charLen
      echo "op2p.baseLength: ", op2p.baseLength
    check r2.isOk
    
    # Apply transformed ops in opposite order
    let r3 = doc.apply(op2)
    check r3.isOk
    let r4 = r3.get.apply(op1p)
    check r4.isOk
    
    # Both should result in same document
    check r2.get.content == r4.get.content
    check r2.get.content == "ABhello"
  
  test "Transform retain-delete":
    var op1 = newTextOperation()
    op1.retain(3)
    op1.delete(2)
    op1.retain(3)
    op1.baseLength = 8
    op1.targetLength = 6
    
    var op2 = newTextOperation()
    op2.retain(1)
    op2.delete(4)
    op2.retain(3)
    op2.baseLength = 8
    op2.targetLength = 4
    
    let result = transform(op1, op2)
    check result.isOk
    
    let (op1p, op2p) = result.get
    
    # Test convergence
    let doc = newDocument("abcdefgh")
    let r1 = doc.apply(op1)
    check r1.isOk
    let r2 = r1.get.apply(op2p)
    check r2.isOk
    
    let r3 = doc.apply(op2)
    check r3.isOk
    let r4 = r3.get.apply(op1p)
    check r4.isOk
    
    check r2.get.content == r4.get.content
  
  test "Transform insert-delete":
    var op1 = newTextOperation()
    op1.retain(2)
    op1.insert("xyz")
    op1.retain(3)
    
    var op2 = newTextOperation()
    op2.retain(1)
    op2.delete(3)
    op2.retain(1)
    
    let result = transform(op1, op2)
    check result.isOk
    
    let (op1p, op2p) = result.get
    
    echo "op1p: ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
    echo "op2p: ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength
    
    let doc = newDocument("abcde")
    let r1 = doc.apply(op1)
    check r1.isOk
    echo "After op1: ", r1.get.content
    let r2 = r1.get.apply(op2p)
    if not r2.isOk:
      echo "Error applying op2p: ", r2.error
    check r2.isOk
    
    let r3 = doc.apply(op2)
    check r3.isOk
    echo "After op2: ", r3.get.content
    let r4 = r3.get.apply(op1p)
    if not r4.isOk:
      echo "Error applying op1p: ", r4.error
    check r4.isOk
    
    check r2.get.content == r4.get.content
  
  # TODO: Implement transformCursor function
  # test "Transform cursor position - insert":
  #   var op = newTextOperation()
  #   op.retain(2)
  #   op.insert("xyz")
  #   op.retain(3)
  #   
  #   # Cursor before insertion
  #   check transformCursor(1, op) == 1
  #   
  #   # Cursor at insertion point
  #   check transformCursor(2, op) == 5
  #   check transformCursor(2, op, true) == 5  # Own operation
  #   
  #   # Cursor after insertion
  #   check transformCursor(3, op) == 6
  # 
  # test "Transform cursor position - delete":
  #   var op = newTextOperation()
  #   op.retain(2)
  #   op.delete(3)
  #   op.retain(2)
  #   
  #   # Cursor before deletion
  #   check transformCursor(1, op) == 1
  #   
  #   # Cursor in deleted region
  #   check transformCursor(3, op) == 2
  #   check transformCursor(4, op) == 2
  #   
  #   # Cursor after deletion
  #   check transformCursor(5, op) == 2
  #   check transformCursor(6, op) == 3