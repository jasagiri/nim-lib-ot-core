import src/nim_lib_ot/[types, operations, transform]
import results

# Let's understand exactly what's happening

echo "=== TRANSFORM DEBUG ==="

# Create the operations
var op1 = newTextOperation()
op1.retain(3)
op1.delete(2)  
op1.retain(3)

var op2 = newTextOperation()
op2.retain(1)
op2.delete(4)
op2.retain(3)

echo "Input operations:"
echo "op1: ", op1.ops, " (base=", op1.baseLength, " target=", op1.targetLength, ")"
echo "op2: ", op2.ops, " (base=", op2.baseLength, " target=", op2.targetLength, ")"
echo ""

# Test direct application
let doc = newDocument("abcdefgh")
echo "Test direct application:"
echo "Original: '", doc.content, "' (len=", doc.content.len, ")"

let r1 = doc.apply(op1)
echo "After op1: '", r1.get.content, "' (len=", r1.get.content.len, ")"

let r2 = doc.apply(op2)
echo "After op2: '", r2.get.content, "' (len=", r2.get.content.len, ")"
echo ""

# Transform
echo "Transforming..."
let result = transform(op1, op2)
let (op1p, op2p) = result.get

echo "Result:"
echo "op1p: ", op1p.ops, " (base=", op1p.baseLength, " target=", op1p.targetLength, ")"
echo "op2p: ", op2p.ops, " (base=", op2p.baseLength, " target=", op2p.targetLength, ")"
echo ""

# The issue is that op1p's operations don't match its base length
# Let's manually trace what the operations should be

echo "Manual calculation of what op1p should be:"
echo "op1p takes input from op2's result: 'afgh' (len=4)"
echo "op1p should produce the same result as op1+op2 on original"
echo ""

# What happens with current op1p?
echo "Current op1p operations on 'afgh':"
echo "- retain(1): keep 'a'"
echo "- delete(2): try to delete 'fg' (positions 1-2)"
echo "- retain(3): try to retain 3 chars starting at position 3"
echo "  But we only have 1 char left ('h') at position 3!"
echo "This causes the length mismatch error"
echo ""

# What should op1p be?
echo "What op1p SHOULD be:"
echo "Input: 'afgh' (result of op2)"
echo "Output: 'afgh' (final result of op1+op2)"
echo "Since input equals output, op1p should be: retain(4)"
echo ""

# What about op2p?
echo "What op2p SHOULD be:"
echo "Input: 'abcfgh' (result of op1)"
echo "Output: 'afgh' (final result of op1+op2)"
echo "Need to delete 'bc' at positions 1-2"
echo "So op2p should be: retain(1), delete(2), retain(3)"
echo ""

echo "The operations are correct but assigned to the wrong variables!"
echo "It looks like op1p and op2p are swapped in the implementation"