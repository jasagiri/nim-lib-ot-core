import src/nim_lib_ot/[types, operations, transform]
import results

# Test to understand the conceptual issue

echo "=== CONCEPTUAL TEST ==="

# Simple retain-delete case
var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "Operations:"
echo "op1:", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2:", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength

# Document transformations
let doc = newDocument("abcdefgh")
echo "\nDirect transformations:"
echo "Original: '", doc.content, "'"

let afterOp1 = doc.apply(op1).get
echo "After op1: '", afterOp1.content, "'"

let afterOp2 = doc.apply(op2).get  
echo "After op2: '", afterOp2.content, "'"

# Transform
let result = transform(op1, op2)
let (op1p, op2p) = result.get

echo "\nTransform result:"
echo "op1p:", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
echo "op2p:", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength

# Test what they produce
echo "\nApplying transformed operations:"

# Path 1: op1 → op2p
let path1Result = afterOp1.apply(op2p)
if path1Result.isOk:
  echo "op1 → op2p: '", path1Result.get.content, "'"
else:
  echo "op1 → op2p: ERROR - ", path1Result.error
  # Let's check what's wrong
  echo "  afterOp1.content: '", afterOp1.content, "' (len=", afterOp1.content.len, ")"
  echo "  op2p.baseLength: ", op2p.baseLength
  echo "  op2p.ops: ", op2p.ops
  # Calculate actual base length needed
  var neededBase = 0
  for op in op2p.ops:
    case op.kind
    of opRetain: neededBase += op.n
    of opDelete: neededBase += op.n
    of opInsert: discard
  echo "  Actual base needed: ", neededBase

# Path 2: op2 → op1p
let path2Result = afterOp2.apply(op1p)
if path2Result.isOk:
  echo "op2 → op1p: '", path2Result.get.content, "'"
else:
  echo "op2 → op1p: ERROR - ", path2Result.error
  # Let's check what's wrong
  echo "  afterOp2.content: '", afterOp2.content, "' (len=", afterOp2.content.len, ")"
  echo "  op1p.baseLength: ", op1p.baseLength
  echo "  op1p.ops: ", op1p.ops
  # Calculate actual base length needed
  var neededBase = 0
  for op in op1p.ops:
    case op.kind
    of opRetain: neededBase += op.n
    of opDelete: neededBase += op.n
    of opInsert: discard
  echo "  Actual base needed: ", neededBase

echo "\nConclusion:"
echo "The issue is that the operations have the wrong base length!"
echo "op1p needs base=6 but has base=4"
echo "op2p needs base=4 but has base=6"
echo "The base lengths are swapped!"