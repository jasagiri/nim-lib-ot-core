import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import ./src/nim_lib_ot/transform
import results

# Create the operations for insert-insert test
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
  
  # Debug validation details
  var checkBase1 = 0
  for op in op1p.ops:
    case op.kind:
    of opRetain: checkBase1 += op.n
    of opDelete: checkBase1 += op.n
    else: discard
  echo "op1' calculated base: ", checkBase1
  
  var checkBase2 = 0
  for op in op2p.ops:
    case op.kind:
    of opRetain: checkBase2 += op.n
    of opDelete: checkBase2 += op.n
    else: discard
  echo "op2' calculated base: ", checkBase2