import src/nim_lib_ot/[types, operations, transform]
import results

echo "Debug retain-delete test"

# Create operations
var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "op1: base=", op1.baseLength, " target=", op1.targetLength
echo "op2: base=", op2.baseLength, " target=", op2.targetLength

# Transform
let result = transform(op1, op2)
if result.isErr:
  echo "Transform error: ", result.error
else:
  let (op1p, op2p) = result.get
  echo "op1p: base=", op1p.baseLength, " target=", op1p.targetLength
  echo "op1p ops: ", op1p.ops
  echo "op2p: base=", op2p.baseLength, " target=", op2p.targetLength
  echo "op2p ops: ", op2p.ops
  
  # Apply operations
  let doc = newDocument("abcdefgh")
  echo "Original doc: '", doc.content, "'"
  
  # Apply op1 then op2p
  let r1 = doc.apply(op1)
  if r1.isErr:
    echo "r1 error: ", r1.error
  else:
    echo "After op1: '", r1.get.content, "' len=", r1.get.content.charLen
    let r2 = r1.get.apply(op2p)
    if r2.isErr:
      echo "r2 error: ", r2.error
      echo "op2p expects base=", op2p.baseLength, " but got len=", r1.get.content.charLen
    else:
      echo "After op2p: '", r2.get.content, "'"
  
  # Apply op2 then op1p
  let r3 = doc.apply(op2)
  if r3.isErr:
    echo "r3 error: ", r3.error
  else:
    echo "After op2: '", r3.get.content, "' len=", r3.get.content.charLen
    let r4 = r3.get.apply(op1p)
    if r4.isErr:
      echo "r4 error: ", r4.error
      echo "op1p expects base=", op1p.baseLength, " but got len=", r3.get.content.charLen
    else:
      echo "After op1p: '", r4.get.content, "'"