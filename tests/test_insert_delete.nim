import unittest
import ../src/nim_lib_ot_core/[types, operations, transform]
import results

suite "Transform Insert-Delete":
  test "Transform insert-delete":
    var op1 = newTextOperation()
    op1.retain(2)
    op1.insert("xyz")
    op1.retain(3)
    
    var op2 = newTextOperation()
    op2.retain(1)
    op2.delete(3)
    op2.retain(1)
    
    echo "\nOriginal operations:"
    echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
    echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength
    
    let result = transform(op1, op2)
    check result.isOk
    
    let (op1p, op2p) = result.get
    
    echo "\nTransformed operations:"
    echo "op1p: ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
    echo "op2p: ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength
    
    # Test what the operations actually do
    let doc = newDocument("abcde")
    
    # Path 1: op1 then op2p
    let r1 = doc.apply(op1)
    check r1.isOk
    echo "\nAfter op1: '", r1.get.content, "' (expected: 'abxyzcde')"
    
    let r2 = r1.get.apply(op2p)
    if r2.isErr:
      echo "Error applying op2p: ", r2.error
      echo "Trying to apply ", op2p.ops, " to '", r1.get.content, "' (len=", r1.get.content.len, ")"
      echo "op2p base=", op2p.baseLength, " but doc len=", r1.get.content.len
    check r2.isOk
    
    # Path 2: op2 then op1p
    let r3 = doc.apply(op2)
    check r3.isOk
    echo "\nAfter op2: '", r3.get.content, "' (expected: 'ae')"
    
    let r4 = r3.get.apply(op1p)
    if r4.isErr:
      echo "Error applying op1p: ", r4.error
      echo "Trying to apply ", op1p.ops, " to '", r3.get.content, "' (len=", r3.get.content.len, ")"
      echo "op1p base=", op1p.baseLength, " but doc len=", r3.get.content.len
    check r4.isOk
    
    # Both paths should produce the same result
    if r2.isOk and r4.isOk:
      echo "\nFinal results:"
      echo "Path 1 (op1 -> op2p): '", r2.get.content, "'"
      echo "Path 2 (op2 -> op1p): '", r4.get.content, "'"
      check r2.get.content == r4.get.content