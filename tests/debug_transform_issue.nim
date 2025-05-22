import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

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

let transformResult = transform(localOp, remoteOp)
if transformResult.isOk:
  let (localPrime, remotePrime) = transformResult.get()
  echo "\nAfter transform:"
  echo "Local':  base=", localPrime.baseLength, " target=", localPrime.targetLength
  echo "Remote': base=", remotePrime.baseLength, " target=", remotePrime.targetLength
  
  # The transformed operations should have these properties:
  # - localPrime.baseLength should equal remoteOp.targetLength
  # - remotePrime.baseLength should equal localOp.targetLength
  echo "\nExpected:"
  echo "Local' base should be ", remoteOp.targetLength
  echo "Remote' base should be ", localOp.targetLength
else:
  echo "Transform failed"