import ../src/nim_lib_ot_core/cursor
import ../src/nim_lib_ot_core/types
import ../src/nim_lib_ot_core/operations

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Complex operation: retain 2, delete 3, insert "Hello", retain 2, insert "World", delete 1
let op = buildOp(proc(o: var TextOperation) =
  o.retain(2)
  o.delete(3)
  o.insert("Hello")
  o.retain(2)
  o.insert("World")
  o.delete(1))

echo "Operation: ", op.ops
echo "Base length: ", op.baseLength
echo "Target length: ", op.targetLength

# Test cursor transformation step by step
proc debugTransformCursor(cursor: int, op: TextOperation): int =
  result = cursor
  var index = 0
  
  echo "\nTransforming cursor at position ", cursor
  
  for i, o in op.ops:
    echo "  Step ", i+1, ": ", o
    echo "    Index before: ", index, ", Cursor result: ", result
    
    case o.kind
    of opRetain:
      index += o.n
    
    of opInsert:
      if cursor >= index:
        if cursor > index:
          result += o.s.len
          echo "    Cursor shifted by ", o.s.len
    
    of opDelete:
      if cursor > index:
        if cursor >= index + o.n:
          result -= o.n
          echo "    Cursor shifted left by ", o.n
        else:
          result = index
          echo "    Cursor moved to delete position"
      index += o.n
    
    echo "    Index after: ", index, ", Cursor result: ", result

# Test with cursor at position 8
echo "\n=== Testing cursor at position 8 ==="
let result = debugTransformCursor(8, op)
echo "Final result: ", result
echo "Expected: 15"

# Also test the actual function
let actualResult = transformCursor(8, op)
echo "\nActual transformCursor result: ", actualResult