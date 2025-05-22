import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import results

# Manual trace of insert-insert transform
echo "=== Manual Trace ==="

# Input operations
# op1: [insert("A"), retain(5)]
# op2: [insert("B"), retain(5)]

echo "Initial state:"
echo "  i1=0, i2=0"
echo "  op1[0] = insert(\"A\")"
echo "  op2[0] = insert(\"B\")"
echo ""

echo "Step 1: Process op1 insert"
echo "  op1[0] is insert(\"A\")"
echo "  -> operation1prime.insert(\"A\")"
echo "  -> operation2prime.retain(1)"
echo "  -> i1++ (now i1=1)"
echo "  -> op1[1] = retain(5)"
echo ""

echo "Step 2: Check op2"
echo "  op2[0] is still insert(\"B\")"
echo "  -> operation1prime.retain(1)"
echo "  -> operation2prime.insert(\"B\")"
echo "  -> i2++ (now i2=1)"
echo "  -> op2[1] = retain(5)"
echo ""

echo "Step 3: Both are now retain(5)"
echo "  -> both retain(5)"
echo "  -> operation1prime.retain(5)"
echo "  -> operation2prime.retain(5)"
echo ""

echo "Final operations:"
echo "  operation1prime: [insert(\"A\"), retain(1), retain(5)]"
echo "  operation2prime: [retain(1), insert(\"B\"), retain(5)]"