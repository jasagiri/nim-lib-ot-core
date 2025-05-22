import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Manually create a debug transform to see what's happening
proc debugTransform(a, b: TextOperation): OpResult[TransformResult] =
  if a.baseLength != b.baseLength:
    return err(LengthMismatch)
  
  var op1prime = newTextOperation()
  var op2prime = newTextOperation()
  
  echo "=== Debug Transform ==="
  echo "Input A: base=", a.baseLength, " target=", a.targetLength
  echo "Input B: base=", b.baseLength, " target=", b.targetLength
  
  # Simple case: both operations start with retain 5
  # Then A inserts " Local", B inserts " Remote"
  
  # Process retain 5
  op1prime.retain(5)
  op2prime.retain(5)
  
  # Process inserts - they get transformed to go after each other
  op1prime.insert(" Local")  # A's insert
  op1prime.retain(7)         # Skip B's insert
  
  op2prime.retain(6)         # Skip A's insert  
  op2prime.insert(" Remote") # B's insert
  
  echo "\nTransformed operations:"
  echo "op1': ", op1prime.ops
  echo "op2': ", op2prime.ops
  
  # Set base lengths
  op1prime.baseLength = b.targetLength  # Should be 12
  op2prime.baseLength = a.targetLength  # Should be 11
  
  echo "\nBase lengths:"
  echo "op1' base: ", op1prime.baseLength, " (should be ", b.targetLength, ")"
  echo "op2' base: ", op2prime.baseLength, " (should be ", a.targetLength, ")"
  
  # Calculate base/target lengths by scanning operations
  var op1Base = 0
  var op1Target = 0
  for op in op1prime.ops:
    case op.kind:
    of opRetain:
      op1Base += op.n
      op1Target += op.n
    of opInsert:
      op1Target += op.s.len
    of opDelete:
      op1Base += op.n
  
  var op2Base = 0  
  var op2Target = 0
  for op in op2prime.ops:
    case op.kind:
    of opRetain:
      op2Base += op.n
      op2Target += op.n
    of opInsert:
      op2Target += op.s.len
    of opDelete:
      op2Base += op.n
  
  echo "\nCalculated lengths:"
  echo "op1': base=", op1Base, " target=", op1Target, " (expected base=", b.targetLength, ")"
  echo "op2': base=", op2Base, " target=", op2Target, " (expected base=", a.targetLength, ")"
  
  # Set target lengths
  op1prime.targetLength = op1Target
  op2prime.targetLength = op2Target
  
  # Validate
  echo "\nValidating..."
  let val1 = op1prime.validate()
  if val1.isErr:
    echo "op1' validation error: ", val1.error
  else:
    echo "op1' valid"
    
  let val2 = op2prime.validate()
  if val2.isErr:
    echo "op2' validation error: ", val2.error
  else:
    echo "op2' valid"
  
  if val1.isOk and val2.isOk:
    ok((op1prime, op2prime))
  else:
    err(InvalidOperation)

# Test the problem case
let localOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

let remoteOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "Testing with debug transform:"
let debugResult = debugTransform(localOp, remoteOp)
if debugResult.isErr:
  echo "Debug transform failed"
else:
  echo "Debug transform succeeded"
  let (dp1, dp2) = debugResult.get()
  echo "Result op1': base=", dp1.baseLength, " target=", dp1.targetLength
  echo "Result op2': base=", dp2.baseLength, " target=", dp2.targetLength

echo "\n\nTesting with actual transform:"
let actualResult = transform(localOp, remoteOp)
if actualResult.isErr:
  echo "Actual transform failed: ", actualResult.error
else:
  echo "Actual transform succeeded"
  let (ap1, ap2) = actualResult.get()
  echo "Result op1': base=", ap1.baseLength, " target=", ap1.targetLength
  echo "Result op2': base=", ap2.baseLength, " target=", ap2.targetLength