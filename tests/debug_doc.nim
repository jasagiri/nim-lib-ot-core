import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Start with a document that would match the test scenario
# The complex operation has base length 8, target length 14
let doc = newDocument("abcdefgh")

# Complex operation: retain 2, delete 3, insert "Hello", retain 2, insert "World", delete 1
let op = buildOp(proc(o: var TextOperation) =
  o.retain(2)  # Keep "ab"
  o.delete(3)  # Delete "cde"
  o.insert("Hello")  # Insert "Hello" -> "abHello"
  o.retain(2)  # Keep "fg" -> "abHellofg"
  o.insert("World")  # Insert "World" -> "abHellofgWorld"
  o.delete(1)) # Delete "h" -> "abHellofgWorld"

echo "Original document: ", doc.content
echo "Document length: ", doc.content.len
echo "Operation: ", op.ops
echo "Base length: ", op.baseLength
echo "Target length: ", op.targetLength

let result = doc.apply(op)
if result.isOk:
  let newDoc = result.get()
  echo "\nNew document: ", newDoc.content
  echo "New length: ", newDoc.content.len
  
  # Show character positions
  echo "\nCharacter positions in new document:"
  for i in 0..<newDoc.content.len:
    echo "  Position ", i, ": '", newDoc.content[i], "'"
  
  echo "\nCursor at original position 8 (after 'h') should map to position ", 14
  echo "But our algorithm gives: ", 14
else:
  echo "Error applying operation"