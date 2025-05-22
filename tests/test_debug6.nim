import src/nim_lib_ot/[types, operations, transform]
import results

# Let's manually verify what the transform result should be
# and check if lengths are calculated correctly

var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)  
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "Original operations:"
echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength

let result = transform(op1, op2)
let (op1p, op2p) = result.get

echo "\nTransformed operations:"
echo "op1p: ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
echo "op2p: ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength

# Manually calculate expected lengths
var op1pExpectedBase = 0
var op1pExpectedTarget = 0
for op in op1p.ops:
  case op.kind
  of opRetain:
    op1pExpectedBase += op.n
    op1pExpectedTarget += op.n
  of opDelete:
    op1pExpectedBase += op.n
  of opInsert:
    op1pExpectedTarget += op.s.len

echo "\nop1p expected: base=", op1pExpectedBase, " target=", op1pExpectedTarget

var op2pExpectedBase = 0
var op2pExpectedTarget = 0
for op in op2p.ops:
  case op.kind
  of opRetain:
    op2pExpectedBase += op.n
    op2pExpectedTarget += op.n
  of opDelete:
    op2pExpectedBase += op.n
  of opInsert:
    op2pExpectedTarget += op.s.len

echo "op2p expected: base=", op2pExpectedBase, " target=", op2pExpectedTarget

# Now let's apply them
let doc = newDocument("abcdefgh")
echo "\nApplying operations:"
echo "Original: '", doc.content, "'"

# Path 1
let r1 = doc.apply(op1)
echo "After op1: '", r1.get.content, "'"
let r2 = r1.get.apply(op2p)
if r2.isErr:
  echo "Error applying op2p: ", r2.error
else:
  echo "After op2p: '", r2.get.content, "'"

# Path 2  
let r3 = doc.apply(op2)
echo "After op2: '", r3.get.content, "'"
let r4 = r3.get.apply(op1p)
if r4.isErr:
  echo "Error applying op1p: ", r4.error
else:
  echo "After op1p: '", r4.get.content, "'"