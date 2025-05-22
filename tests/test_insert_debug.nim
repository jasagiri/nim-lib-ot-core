import src/nim_lib_ot/[types, operations, transform]
import results

# Debug the actual insert-insert test

echo "=== INSERT-INSERT TEST DEBUG ==="

# From the actual test
var op1 = newTextOperation()
op1.insert("A")
op1.retain(5)

var op2 = newTextOperation()
op2.insert("B")
op2.retain(5)

echo "Operations:"
echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength

# Transform with aIsFirst=true
let result = transform(op1, op2, true)
let (op1p, op2p) = result.get

echo "\nTransform result:"
echo "op1p: ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
echo "op2p: ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength

# Test
let doc = newDocument("hello")

# Path 1: op1 then op2p
echo "\nPath 1: op1 then op2p"
let r1 = doc.apply(op1)
echo "After op1: '", r1.get.content, "'"
let r2 = r1.get.apply(op2p)
if r2.isOk:
  echo "After op2p: '", r2.get.content, "'"
else:
  echo "Error: ", r2.error

# Path 2: op2 then op1p  
echo "\nPath 2: op2 then op1p"
let r3 = doc.apply(op2)
echo "After op2: '", r3.get.content, "'"
let r4 = r3.get.apply(op1p)
if r4.isOk:
  echo "After op1p: '", r4.get.content, "'"
else:
  echo "Error: ", r4.error

echo "\nExpected: 'ABhello' (with A before B since aIsFirst=true)"
echo "But we're getting different results!"

# Let's manually trace what should happen
echo "\n\nManual trace:"
echo "Both insert at position 0"
echo "Since aIsFirst=true, A should go first"
echo "So transformed operations should be:"
echo "- op1p: insert('A'), retain(6) - applied to 'Bhello' -> 'ABhello'"
echo "- op2p: retain(1), insert('B'), retain(5) - applied to 'Ahello' -> 'ABhello'"