import src/nim_lib_ot/[types, operations]
import results

echo "Debug simple retain test"

# Create a simple operation
var op = newTextOperation()
op.retain(4)

echo "op: base=", op.baseLength, " target=", op.targetLength
echo "op.ops: ", op.ops

# Validate
let valid = op.validate()
if valid.isErr:
  echo "Validation error: ", valid.error
else:
  echo "Validation OK"

# Create document with exact length
let doc = newDocument("afgh")
echo "doc.content: '", doc.content, "' len=", doc.content.charLen

# Apply
let result = doc.apply(op)
if result.isErr:
  echo "Apply error: ", result.error
else:
  echo "Apply OK: '", result.get.content, "'"