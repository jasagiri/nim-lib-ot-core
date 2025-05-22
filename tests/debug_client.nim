import ../src/nim_lib_ot_core/client
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import std/options
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

let myclient = newOTClient("Hello")
echo "Initial state: ", myclient.document.content

# Local operation
let localOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

echo "Local op base length: ", localOp.baseLength
echo "Local op target length: ", localOp.targetLength

let localResult = myclient.applyLocal(localOp)
echo "After local apply: ", myclient.document.content
echo "Client state: ", myclient.state

# Remote operation arrives
let remoteOp = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "\nRemote op base length: ", remoteOp.baseLength
echo "Remote op target length: ", remoteOp.targetLength

echo "\nAttempting to apply remote operation..."
let result = myclient.applyServer(remoteOp, 0)
if result.isErr:
  echo "Error: ", result.error
else:
  echo "Success"
  echo "Document: ", myclient.document.content