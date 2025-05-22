import src/nim_lib_ot/[types, operations, transform]
import results

# Debug the insert-insert transform issue

echo "=== INSERT-INSERT TRANSFORM ==="

# From the test
var op1 = newTextOperation()
op1.retain(1)
op1.insert("A")
op1.retain(5)

var op2 = newTextOperation()
op2.retain(2)
op2.insert("B")
op2.retain(4)

echo "Input operations:"
echo "op1: ", op1.ops, " base=", op1.baseLength, " target=", op1.targetLength
echo "op2: ", op2.ops, " base=", op2.baseLength, " target=", op2.targetLength

# Test direct application
let doc = newDocument("hello")
echo "\nDirect application on 'hello':"

let r1 = doc.apply(op1)
echo "After op1: '", r1.get.content, "'"

let r2 = doc.apply(op2)  
echo "After op2: '", r2.get.content, "'"

# Transform
let result = transform(op1, op2)
let (op1p, op2p) = result.get

echo "\nTransform result:"
echo "op1p: ", op1p.ops, " base=", op1p.baseLength, " target=", op1p.targetLength
echo "op2p: ", op2p.ops, " base=", op2p.baseLength, " target=", op2p.targetLength

# Test convergence
echo "\nTesting convergence:"

# Path 1: op1 then op2p
let path1_1 = doc.apply(op1)
echo "After op1: '", path1_1.get.content, "'"
let path1_2 = path1_1.get.apply(op2p)
if path1_2.isOk:
  echo "After op2p: '", path1_2.get.content, "'"
else:
  echo "Error applying op2p: ", path1_2.error

# Path 2: op2 then op1p  
let path2_1 = doc.apply(op2)
echo "After op2: '", path2_1.get.content, "'"
let path2_2 = path2_1.get.apply(op1p)
if path2_2.isOk:
  echo "After op1p: '", path2_2.get.content, "'"
else:
  echo "Error applying op1p: ", path2_2.error

echo "\nExpected final result: 'hABllo'"
echo "But we're getting different results for each path!"

# Let's trace what should happen
echo "\n\nManual calculation:"
echo "op1 on 'hello': retain(1)='h', insert 'A', retain(5)='ello' -> 'hAello'"
echo "op2 on 'hello': retain(2)='he', insert 'B', retain(4)='llo' -> 'heBllo'"
echo ""
echo "For convergence to 'hABllo':"
echo "op1p on 'heBllo' should: retain(1)='h', insert 'A', retain('eBllo')=5 -> 'hAeBllo'"
echo "  But this gives 'hAeBllo', not 'hABllo'!"
echo ""
echo "Actually, let's think about this differently..."
echo "If both inserts happen, the final result depends on their order."
echo "Standard OT convention: earlier position wins (op1's insert comes first)"
echo "So final should be: 'hABello' (A at position 1, B at position 2)"