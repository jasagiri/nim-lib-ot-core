import ./src/nim_lib_ot/types
import ./src/nim_lib_ot/operations
import results

type
  TransformResult* = tuple[a: TextOperation, b: TextOperation]

# Create the operations for insert-insert test
var op1 = newTextOperation()
op1.insert("A")
op1.retain(5)
op1.baseLength = 5
op1.targetLength = 6

var op2 = newTextOperation()
op2.insert("B")
op2.retain(5)
op2.baseLength = 5
op2.targetLength = 6

echo "Input operations:"
echo "op1: ", op1.ops
echo "op2: ", op2.ops
echo ""

# Step through algorithm manually
var operation1prime = newTextOperation()
var operation2prime = newTextOperation()

var ops1 = op1.ops
var ops2 = op2.ops
var i1 = 0
var i2 = 0

var op1Current: Operation
var op2Current: Operation
var op1Amount = 0
var op2Amount = 0
var op1Loaded = false
var op2Loaded = false

# Helper to get next operation
proc loadNextOp(ops: seq[Operation], index: var int, 
                op: var Operation, amount: var int, loaded: var bool): bool =
  if loaded and amount > 0:
    return true
  
  if index >= ops.len:
    return false
    
  op = ops[index]
  case op.kind:
  of opRetain, opDelete:
    amount = op.n
  of opInsert:
    amount = 0  # Inserts are handled immediately
  
  index += 1
  loaded = true
  return true

echo "=== Starting transform ==="

# Main loop
var step = 0
while true:
  step += 1
  echo "\nStep ", step, ":"
  echo "  i1=", i1, " i2=", i2
  echo "  op1Amount=", op1Amount, " op2Amount=", op2Amount
  echo "  op1Loaded=", op1Loaded, " op2Loaded=", op2Loaded
  
  # Get operations if needed
  if not op1Loaded or op1Amount == 0:
    if not loadNextOp(ops1, i1, op1Current, op1Amount, op1Loaded):
      echo "  No more ops in op1"
      if not op2Loaded or op2Amount == 0:
        if not loadNextOp(ops2, i2, op2Current, op2Amount, op2Loaded):
          echo "  No more ops in op2 either - done"
          break
      # Process remaining op2
      echo "  Only op2 left: ", op2Current
      if op2Current.kind == opInsert:
        operation2prime.insert(op2Current.s)
        echo "  B inserts (remaining): 2'+=insert(\"", op2Current.s, "\")"
      elif op2Current.kind == opRetain:
        operation2prime.retain(op2Amount)
        echo "  B retains (remaining): 2'+=retain(", op2Amount, ")"
      break
    else:
      echo "  Got op1[", i1-1, "] = ", op1Current, " amount=", op1Amount
  
  if not op2Loaded or op2Amount == 0:
    if not loadNextOp(ops2, i2, op2Current, op2Amount, op2Loaded):
      echo "  No more ops in op2"
      # Process remaining op1
      if op1Current.kind == opInsert:
        operation1prime.insert(op1Current.s)
        echo "  A inserts (remaining): 1'+=insert(\"", op1Current.s, "\")"
      elif op1Current.kind == opRetain:
        operation1prime.retain(op1Amount)
        echo "  A retains (remaining): 1'+=retain(", op1Amount, ")"
      break
    else:
      echo "  Got op2[", i2-1, "] = ", op2Current, " amount=", op2Amount
  
  echo "  Current ops: op1=", op1Current, " op2=", op2Current
  
  # Handle insert operations first
  if op1Current.kind == opInsert:
    operation1prime.insert(op1Current.s)
    operation2prime.retain(op1Current.s.len)
    echo "  A inserts: 1'+=insert(\"", op1Current.s, "\"), 2'+=retain(", op1Current.s.len, ")"
    op1Amount = 0
    op1Loaded = false
    continue
  
  if op2Current.kind == opInsert:
    operation1prime.retain(op2Current.s.len)
    operation2prime.insert(op2Current.s)
    echo "  B inserts: 1'+=retain(", op2Current.s.len, "), 2'+=insert(\"", op2Current.s, "\")"
    op2Amount = 0
    op2Loaded = false
    continue
  
  # Both retain
  if op1Current.kind == opRetain and op2Current.kind == opRetain:
    let minl = min(op1Amount, op2Amount)
    operation1prime.retain(minl)
    operation2prime.retain(minl)
    echo "  Both retain: ", minl
    
    op1Amount -= minl
    op2Amount -= minl
    
    if op1Amount == 0:
      op1Loaded = false
    if op2Amount == 0:
      op2Loaded = false

echo "\nFinal results:"
echo "operation1prime: ", operation1prime.ops
echo "operation2prime: ", operation2prime.ops