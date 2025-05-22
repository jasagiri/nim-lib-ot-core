import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Manually validate an operation
proc manualValidate(op: TextOperation): (int, int) =
  var baseLen = 0
  var targetLen = 0
  
  for o in op.ops:
    case o.kind
    of opRetain:
      baseLen += o.n
      targetLen += o.n
    of opInsert:
      targetLen += o.s.len
    of opDelete:
      baseLen += o.n
  
  return (baseLen, targetLen)

# Local operation
let localOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

# Remote operation  
let remoteOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "Local op:  base=", localOp.baseLength, " target=", localOp.targetLength
echo "Remote op: base=", remoteOp.baseLength, " target=", remoteOp.targetLength

# Manually check the transform
let (localBase, localTarget) = manualValidate(localOp)
let (remoteBase, remoteTarget) = manualValidate(remoteOp)

echo "Manual validation:"
echo "Local:  base=", localBase, " target=", localTarget
echo "Remote: base=", remoteBase, " target=", remoteTarget

# Try transform
echo "\nTransforming..."
let transformResult = transform(localOp, remoteOp)
if transformResult.isOk:
  let (localPrime, remotePrime) = transformResult.get()
  
  echo "\nResult:"
  echo "Local'  ops: ", localPrime.ops
  echo "Remote' ops: ", remotePrime.ops
  
  echo "\nLocal' lengths:  base=", localPrime.baseLength, " target=", localPrime.targetLength
  echo "Remote' lengths: base=", remotePrime.baseLength, " target=", remotePrime.targetLength
  
  # Manual check
  let (lp_base, lp_target) = manualValidate(localPrime)
  let (rp_base, rp_target) = manualValidate(remotePrime)
  
  echo "\nManual check of transformed ops:"
  echo "Local':  base=", lp_base, " target=", lp_target
  echo "Remote': base=", rp_base, " target=", rp_target
  
  # Validate each
  echo "\nValidating local'..."
  let lval = localPrime.validate()
  if lval.isErr:
    echo "Local' validation error: ", lval.error
  else:
    echo "Local' valid"
    
  echo "\nValidating remote'..."
  let rval = remotePrime.validate()
  if rval.isErr:
    echo "Remote' validation error: ", rval.error
  else:
    echo "Remote' valid"
else:
  echo "Transform failed: ", transformResult.error