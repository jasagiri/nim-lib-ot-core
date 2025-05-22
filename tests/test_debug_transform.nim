import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import ./src/nim_lib_ot/transform_debug
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

echo "=== Insert-Insert Test ==="
let result = transform(op1, op2)

if result.isErr:
  echo "Transform failed: ", result.error
else:
  echo "Transform succeeded"