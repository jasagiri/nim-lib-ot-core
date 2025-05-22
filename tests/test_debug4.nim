import src/nim_lib_ot/[types, operations, transform]
import results

echo "Manual transform calculation"

# Let's manually calculate what the transform should be
# op1: retain(3), delete(2), retain(3) on 'abcdefgh' -> 'abcfgh'
# op2: retain(1), delete(4), retain(3) on 'abcdefgh' -> 'afgh'

# To get from 'afgh' to the final result (which should be 'afgh'), op1p should be:
# - 'afgh' is the result after op2
# - We need to find what op1 would do to 'afgh' that gives the same result as op1,op2 on 'abcdefgh'

# Let's trace through character by character:
# Original: a b c d e f g h
# After op1: a b c _ _ f g h -> 'abcfgh'
# After op2: a _ _ _ _ f g h -> 'afgh'

# Now, what does op2 do to 'abcfgh'?
# 'abcfgh': retain(1)='a', delete(4)='bcfg', retain(3) would need 3 chars but only 'h' remains
# This is incorrect! Let's recalculate...

# op2 on 'abcfgh':
# retain(1) = 'a'
# delete(4) would delete 'bcfg' (4 chars)
# retain(3) would need 3 chars but only 'h' remains - ERROR

echo "Original document: 'abcdefgh'"
echo "After op1: 'abcfgh'"
echo "After op2: 'afgh'"
echo ""
echo "Trying to apply op2 to result of op1:"
echo "Input: 'abcfgh' (length 6)"
echo "op2: retain(1), delete(4), retain(3)"
echo "- retain(1): keep 'a'"
echo "- delete(4): delete 'bcfg'"
echo "- retain(3): need to keep 3 chars, but only 'h' remains"
echo "ERROR: Not enough characters to retain"

# The problem is that op2's operations are for the original document
# We need to transform op2 to work on the result of op1

echo "\nCorrect transformation:"
echo "op2 needs to be transformed to work on 'abcfgh' (result of op1)"
echo "To go from 'abcfgh' to 'afgh':"
echo "- retain(1): keep 'a'"
echo "- delete(3): delete 'bcf'"
echo "- retain(2): keep 'gh'"
echo "So op2p should be: retain(1), delete(3), retain(2)"

# Similarly for op1p
echo "\nop1 needs to be transformed to work on 'afgh' (result of op2)"
echo "To go from 'afgh' to 'afgh' (no change):"
echo "- retain(4): keep all 'afgh'"
echo "So op1p should be: retain(4)"