import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

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

# What happens if we just skip the validation?
# Create operations that work regardless of the base length issue

# The key insight: after transforming, the operations work on different documents
# Local' works on: original + remote's changes
# Remote' works on: original + local's changes

var localPrime = newTextOperation()
localPrime.retain(5)
localPrime.insert(" Local")
# Don't add trailing retain - it's implicit

var remotePrime = newTextOperation()
remotePrime.retain(5)
remotePrime.retain(6)  # Skip local's insert
remotePrime.insert(" Remote")
# Don't add trailing retain - it's implicit

echo "\nManually created transform:"
echo "Local':  ops=", localPrime.ops
echo "Remote': ops=", remotePrime.ops

# Apply in order: local, remotePrime
let r1 = doc.apply(localOp)
if r1.isOk:
  let d1 = r1.get()
  echo "\nAfter local: ", d1.content, " (length ", d1.content.len, ")"
  
  # Apply remote' without worrying about base length
  var newContent = ""
  var index = 0
  
  for op in remotePrime.ops:
    case op.kind:
    of opRetain:
      if index + op.n <= d1.content.len:
        newContent &= d1.content[index ..< index + op.n]
      else:
        newContent &= d1.content[index ..< d1.content.len]
      index += op.n
    of opInsert:
      newContent &= op.s
    of opDelete:
      index += op.n
  
  # Add any remaining content
  if index < d1.content.len:
    newContent &= d1.content[index ..< d1.content.len]
    
  echo "After remote': ", newContent

# Apply in reverse order: remote, localPrime  
let r3 = doc.apply(remoteOp)
if r3.isOk:
  let d3 = r3.get()
  echo "\nAfter remote: ", d3.content, " (length ", d3.content.len, ")"
  
  # Apply local' without worrying about base length
  var newContent = ""
  var index = 0
  
  for op in localPrime.ops:
    case op.kind:
    of opRetain:
      if index + op.n <= d3.content.len:
        newContent &= d3.content[index ..< index + op.n]
      else:
        newContent &= d3.content[index ..< d3.content.len]
      index += op.n
    of opInsert:
      newContent &= op.s
    of opDelete:
      index += op.n
  
  # Add any remaining content
  if index < d3.content.len:
    newContent &= d3.content[index ..< d3.content.len]
    
  echo "After local': ", newContent