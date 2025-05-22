import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import ./src/nim_lib_ot/transform_fixed
import results

# Test insert-insert
echo "=== Insert-Insert Test ==="
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

echo "Input operations:"
echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength

let result = transform(op1, op2)

if result.isErr:
  echo "Transform error: ", result.error
else:
  let (op1p, op2p) = result.get()
  echo "\nTransformed operations:"
  echo "op1': ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
  echo "op2': ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength

# Test insert-delete
echo "\n=== Insert-Delete Test ==="
var op3 = newTextOperation()
op3.retain(2)
op3.insert("xyz")
op3.retain(3)
op3.baseLength = 5
op3.targetLength = 8

var op4 = newTextOperation()
op4.retain(1)
op4.delete(3)
op4.retain(1)
op4.baseLength = 5
op4.targetLength = 2

echo "Input operations:"
echo "op3: ", op3.ops, " base=", op3.baseLength, " target=", op3.targetLength
echo "op4: ", op4.ops, " base=", op4.baseLength, " target=", op4.targetLength

let result2 = transform(op3, op4)

if result2.isErr:
  echo "Transform error: ", result2.error
else:
  let (op3p, op4p) = result2.get()
  echo "\nTransformed operations:"
  echo "op3': ", op3p.ops, " base=", op3p.baseLength, " target=", op3p.targetLength
  echo "op4': ", op4p.ops, " base=", op4p.baseLength, " target=", op4p.targetLength