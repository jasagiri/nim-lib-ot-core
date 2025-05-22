import src/nim_lib_ot/[types, operations, transform]
import results

echo "Debug transform lengths"

# Original operations
var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "Original ops:"
echo "op1: base=", op1.baseLength, " target=", op1.targetLength, " ops=", op1.ops
echo "op2: base=", op2.baseLength, " target=", op2.targetLength, " ops=", op2.ops

# Transform
let result = transform(op1, op2)
if result.isErr:
  echo "Transform error: ", result.error
else:
  let (op1p, op2p) = result.get
  echo "\nTransformed ops:"
  echo "op1p: base=", op1p.baseLength, " target=", op1p.targetLength, " ops=", op1p.ops
  echo "op2p: base=", op2p.baseLength, " target=", op2p.targetLength, " ops=", op2p.ops
  
  # Manually calculate what the operations should be
  echo "\nExpected:"
  echo "op1p should transform document of length 4 to length 4"
  echo "op2p should transform document of length 6 to length 4"
  
  # Let's think step by step
  echo "\nStep-by-step transform:"
  echo "op1: retain(3), delete(2), retain(3) on 'abcdefgh' -> 'abcfgh'"
  echo "op2: retain(1), delete(4), retain(3) on 'abcdefgh' -> 'afgh'"
  echo ""
  echo "op1p should be applied to 'afgh' (result of op2) to get the same final result"
  echo "op2p should be applied to 'abcfgh' (result of op1) to get the same final result"