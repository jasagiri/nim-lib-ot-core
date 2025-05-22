import src/nim_lib_ot/[types, operations, transform]
import results
import std/strformat

# Focused test to fix the transform issues

proc debugTransform() =
  echo "=== FIXING TRANSFORM ISSUES ==="
  
  # Retain-Delete case that's failing
  var op1 = newTextOperation()
  op1.retain(3)
  op1.delete(2)
  op1.retain(3)
  
  var op2 = newTextOperation()
  op2.retain(1)
  op2.delete(4)
  op2.retain(3)
  
  echo fmt"op1: {op1.ops} (base={op1.baseLength} target={op1.targetLength})"
  echo fmt"op2: {op2.ops} (base={op2.baseLength} target={op2.targetLength})"
  
  # What should happen:
  # Original: "abcdefgh" (8 chars)
  # op1: retain(3), delete(2), retain(3) -> "abcfgh" (6 chars)
  # op2: retain(1), delete(4), retain(3) -> "afgh" (4 chars)
  
  # For convergence:
  # op1' should transform "afgh" (4 chars) to final state
  # op2' should transform "abcfgh" (6 chars) to final state
  # Final state is "afgh" (both operations combined)
  
  echo "\nExpected transformations:"
  echo "op1' on 'afgh' (4 chars) -> 'afgh' (no change) = retain(4)"
  echo "op2' on 'abcfgh' (6 chars) -> 'afgh' (delete 'bc') = retain(1), delete(2), retain(3)"
  
  # Transform with current implementation
  let result = transform(op1, op2)
  let (op1p, op2p) = result.get
  
  echo "\nActual result:"
  echo fmt"op1': {op1p.ops} (base={op1p.baseLength} target={op1p.targetLength})"
  echo fmt"op2': {op2p.ops} (base={op2p.baseLength} target={op2p.targetLength})"
  
  # The issue: op1p has operations that sum to base=6, but baseLength is set to 4
  # op2p has operations that sum to base=4, but baseLength is set to 6
  
  echo "\nThe problem:"
  echo "op1' operations: retain(1) + delete(2) + retain(3) = base 6"
  echo "op1' baseLength: 4"
  echo "op2' operations: retain(4) = base 4"
  echo "op2' baseLength: 6"
  echo "They're swapped!"
  
  # Let's look at the algorithm to understand why
  echo "\n\nAlgorithm trace (simplified):"
  echo "When A retains and B deletes: aResult gets delete"
  echo "When A deletes and B retains: bResult gets delete"
  echo "This is correct! But the operations end up in the wrong result."
  
  # The real issue might be in our understanding of what op1' and op2' should be
  echo "\n\nRethinking the problem:"
  echo "In OT, transform(A, B) produces (A', B') where:"
  echo "- A' is what to do to result of B to get final state"
  echo "- B' is what to do to result of A to get final state"
  
  echo "\nSo:"
  echo "- op1' transforms result of op2 ('afgh') to final state"
  echo "- op2' transforms result of op1 ('abcfgh') to final state"
  
  echo "\nOur algorithm produces:"
  echo "- aResult = what we expect for op2'"
  echo "- bResult = what we expect for op1'"
  echo "They ARE swapped in the algorithm!"

debugTransform()