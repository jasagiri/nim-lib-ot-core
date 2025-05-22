import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations  
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Test the exact case that's failing
let op1 = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

let op2 = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "op1: base=", op1.baseLength, " target=", op1.targetLength, " ops=", op1.ops
echo "op2: base=", op2.baseLength, " target=", op2.targetLength, " ops=", op2.ops

# Validate the input operations
echo "\nValidating input operations:"
let v1 = op1.validate()
if v1.isErr:
  echo "op1 invalid: ", v1.error
else:
  echo "op1 valid"

let v2 = op2.validate()
if v2.isErr:
  echo "op2 invalid: ", v2.error
else:
  echo "op2 valid"

# Try transform
echo "\nTransforming..."
let result = transform(op1, op2)
if result.isErr:
  echo "Transform failed: ", result.error
else:
  echo "Transform succeeded"
  let (op1p, op2p) = result.get()
  echo "op1': base=", op1p.baseLength, " target=", op1p.targetLength, " ops=", op1p.ops
  echo "op2': base=", op2p.baseLength, " target=", op2p.targetLength, " ops=", op2p.ops