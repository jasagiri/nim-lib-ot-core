import src/nim_lib_ot/[types, operations, transform]
import results

echo "Trace through operations"

# Original: abcdefgh (positions 0-7)
# op1: retain(3), delete(2), retain(3)
#   - retain(3): keep 'abc' (positions 0-2)
#   - delete(2): remove 'de' (positions 3-4)
#   - retain(3): keep 'fgh' (positions 5-7)
#   Result: 'abcfgh'

# op2: retain(1), delete(4), retain(3)
#   - retain(1): keep 'a' (position 0)
#   - delete(4): remove 'bcde' (positions 1-4)
#   - retain(3): keep 'fgh' (positions 5-7)
#   Result: 'afgh'

# Final result after both: ?
# We need to figure out what happens when we apply both operations

echo "Original: 'abcdefgh'"
echo "op1 result: 'abcfgh'"
echo "op2 result: 'afgh'"
echo ""

# Let's trace character by character
echo "Character trace:"
echo "Position: 0 1 2 3 4 5 6 7"
echo "Original: a b c d e f g h"
echo "op1:      a b c - - f g h -> 'abcfgh'"
echo "op2:      a - - - - f g h -> 'afgh'"
echo ""

# The final result should be the intersection of both operations
echo "Final result should be: 'afgh'"
echo "Because:"
echo "- Position 0 (a): kept by both"
echo "- Position 1-2 (bc): kept by op1, deleted by op2 -> deleted"
echo "- Position 3-4 (de): deleted by op1, deleted by op2 -> deleted"
echo "- Position 5-7 (fgh): kept by both"
echo ""

# So the transformation should be:
echo "To get from 'abcfgh' to 'afgh' (op2p):"
echo "- retain(1): keep 'a'"
echo "- delete(2): delete 'bc'"
echo "- retain(3): keep 'fgh'"
echo ""

echo "To get from 'afgh' to 'afgh' (op1p):"
echo "- retain(4): keep all"

# Let's also check the current incorrect result
echo "\nCurrent incorrect op1p: retain(1), delete(2), retain(3)"
echo "Applied to 'afgh':"
echo "- retain(1): keep 'a' (ok)"
echo "- delete(2): delete 'fg' (wrong! we want to keep these)"
echo "- retain(3): keep ??? (error - not enough chars)"