import src/nim_lib_ot/[types, operations, transform]
import results
import std/strformat

# Detailed debug of retain-delete transform

echo "=== RETAIN-DELETE DETAILED DEBUG ==="

# Operations from the test
var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "Operations:"
echo fmt"op1: {op1.ops} (base={op1.baseLength} target={op1.targetLength})"
echo fmt"op2: {op2.ops} (base={op2.baseLength} target={op2.targetLength})"

# Let's trace what they do:
echo "\nWhat they do to 'abcdefgh':"
echo "op1: retain(3)='abc', delete(2)='de', retain(3)='fgh' -> 'abcfgh'"
echo "op2: retain(1)='a', delete(4)='bcde', retain(3)='fgh' -> 'afgh'"
echo "Final result should be: 'afgh'"

# Transform
let result = transform(op1, op2)
let (op1p, op2p) = result.get

echo "\nTransform result:"
echo fmt"op1p: {op1p.ops} (base={op1p.baseLength} target={op1p.targetLength})"
echo fmt"op2p: {op2p.ops} (base={op2p.baseLength} target={op2p.targetLength})"

# Let's see what's wrong with op1p
echo "\nAnalyzing op1p:"
var baseSum = 0
var targetSum = 0
for op in op1p.ops:
  case op.kind
  of opRetain:
    baseSum += op.n
    targetSum += op.n
    echo fmt"  retain({op.n}): base+={op.n}, target+={op.n}"
  of opDelete:
    baseSum += op.n
    echo fmt"  delete({op.n}): base+={op.n}, target+=0"
  of opInsert:
    targetSum += op.s.len
    echo fmt"  insert('{op.s}'): base+=0, target+={op.s.len}"
echo fmt"Total: base={baseSum}, target={targetSum}"
echo fmt"Expected: base={op1p.baseLength}, target={op1p.targetLength}"
echo if baseSum != op1p.baseLength: "Mismatch!" else: "Match!"

# What op1p SHOULD be
echo "\nWhat op1p SHOULD be:"
echo "Input: 'afgh' (result of op2, length 4)"
echo "Output: 'afgh' (final result)"
echo "Operation: retain(4)"

# What op2p SHOULD be  
echo "\nWhat op2p SHOULD be:"
echo "Input: 'abcfgh' (result of op1, length 6)"
echo "Output: 'afgh' (final result)"
echo "Operation: retain(1), delete(2), retain(3)"

echo "\n\nThe issue: The algorithm is building the operations with wrong indices!"
echo "When we transform retain-delete operations, the indices need to be adjusted"
echo "based on what has already been deleted by the other operation."