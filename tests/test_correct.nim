import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import ./src/nim_lib_ot/transform_correct
import results

# Create the operations
var op1 = newTextOperation()
op1.retain(2)
op1.insert("xyz")
op1.retain(3)
op1.baseLength = 5
op1.targetLength = 8

var op2 = newTextOperation()
op2.retain(1)
op2.delete(3)
op2.retain(1)
op2.baseLength = 5
op2.targetLength = 2

echo "Input operations:"
echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength
echo ""

# Transform
let result = transform(op1, op2)

if result.isErr:
  echo "Transform error: ", result.error
else:
  let (op1p, op2p) = result.get()
  
  echo "Transformed operations:"
  echo "op1': ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
  echo "op2': ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength
  
  # Check expected results
  echo "\nExpected:"
  echo "op1': [retain(1), insert(\"xyz\"), retain(1)] base=2 target=5"
  echo "op2': [retain(1), delete(1), retain(3), delete(2), retain(1)] base=8 target=5"