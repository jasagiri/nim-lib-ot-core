import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

# Create a version of transform without validation
proc transformNoValidation*(a, b: TextOperation): OpResult[TransformResult] =
  ## Transform without length validation
  if a.baseLength != b.baseLength:
    return err(LengthMismatch)
  
  var operation1prime = newTextOperation()
  var operation2prime = newTextOperation()
  
  # Copy the transform logic (simplified)
  for op in a.ops:
    case op.kind:
    of opRetain:
      operation1prime.retain(op.n)
    of opInsert:
      operation1prime.insert(op.s)
      operation2prime.retain(op.s.len)
    of opDelete:
      operation2prime.delete(op.n)
  
  for op in b.ops:
    case op.kind:
    of opRetain:
      # Already handled
      discard
    of opInsert:
      operation1prime.retain(op.s.len)
      operation2prime.insert(op.s)
    of opDelete:
      operation1prime.delete(op.n)
  
  # Set base lengths
  operation1prime.baseLength = b.targetLength
  operation2prime.baseLength = a.targetLength
  
  # Set target lengths (simplified)
  operation1prime.targetLength = b.targetLength + a.targetLength - a.baseLength
  operation2prime.targetLength = a.targetLength + b.targetLength - b.baseLength
  
  ok((operation1prime, operation2prime))

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Test with the failing case
let doc = newDocument("Hello")

let localOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

let remoteOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "Starting document: ", doc.content
echo "Local op: ", localOp.ops
echo "Remote op: ", remoteOp.ops

# Apply operations in different orders
let result1 = doc.apply(localOp)
if result1.isOk:
  let doc1 = result1.get()
  echo "\nAfter local: ", doc1.content
  
  let result2 = doc1.apply(remoteOp)
  if result2.isOk:
    echo "Then remote: ERROR - can't apply"
  else:
    echo "Then remote: Expected error - ", result2.error

# Try with transform
echo "\nUsing transform:"
let transformResult = transformNoValidation(localOp, remoteOp)
if transformResult.isOk:
  let (localPrime, remotePrime) = transformResult.get()
  echo "Local':  ops=", localPrime.ops, " base=", localPrime.baseLength
  echo "Remote': ops=", remotePrime.ops, " base=", remotePrime.baseLength
  
  # Apply in order: local, remotePrime
  let r1 = doc.apply(localOp)
  if r1.isOk:
    let d1 = r1.get()
    echo "\nAfter local: ", d1.content
    
    # Temporarily set the base length to match the document
    remotePrime.baseLength = d1.content.len
    
    let r2 = d1.apply(remotePrime)
    if r2.isOk:
      let d2 = r2.get()
      echo "After remote': ", d2.content
    else:
      echo "Remote' error: ", r2.error
  
  # Apply in reverse order: remote, localPrime
  let r3 = doc.apply(remoteOp)
  if r3.isOk:
    let d3 = r3.get()
    echo "\nAfter remote: ", d3.content
    
    # Temporarily set the base length to match the document
    localPrime.baseLength = d3.content.len
    
    let r4 = d3.apply(localPrime)
    if r4.isOk:
      let d4 = r4.get()
      echo "After local': ", d4.content
    else:
      echo "Local' error: ", r4.error
else:
  echo "Transform failed: ", transformResult.error