import ../src/nim_lib_ot_core/cursor
import ../src/nim_lib_ot_core/types
import ../src/nim_lib_ot_core/operations

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Document: "abcdefgh"
# Complex operation: retain 2, delete 3, insert "Hello", retain 2, insert "World", delete 1
# Result should be: "abHellofgWorld"

let op = buildOp(proc(o: var TextOperation) =
  o.retain(2)
  o.delete(3)
  o.insert("Hello")
  o.retain(2)
  o.insert("World")
  o.delete(1))

# Debug cursor at positions 8 and 9
proc traceTransform(cursor: int, op: TextOperation): int =
  result = cursor
  var index = 0  # Index in original document
  
  echo "\nTracing cursor at original position ", cursor
  
  for i, o in op.ops:
    echo "  Op ", i+1, ": ", o
    echo "    Original index: ", index, ", Result cursor: ", result
    
    case o.kind
    of opRetain:
      index += o.n
      echo "    After retain: index=", index
    
    of opInsert:
      if cursor >= index:
        if cursor > index or false:  # isOwn = false
          result += o.s.len
          echo "    Cursor >= index, shifting by ", o.s.len
      # Insert doesn't consume from original document
      echo "    After insert: index=", index
    
    of opDelete:
      if cursor > index:
        if cursor >= index + o.n:
          result -= o.n
          echo "    Cursor after delete, shifting left by ", o.n
        else:
          result = index
          echo "    Cursor within delete, moving to start"
      index += o.n
      echo "    After delete: index=", index

echo "Original document: 'abcdefgh' (length 8)"
echo "\nOperation:"
for i, o in op.ops:
  echo "  ", i+1, ": ", o

echo "\nFinal document: 'abHellofgWorld' (length 14)"

# Test cursor at various positions
let positions = @[0, 2, 4, 5, 7, 8, 9]
for pos in positions:
  let result = traceTransform(pos, op)
  let actual = transformCursor(pos, op)
  echo "\nCursor ", pos, " -> ", actual, " (expected ", result, ")"

# The issue with position 8 and 9
echo "\n=== Issue Analysis ==="
echo "Position 8: end of original document, should map to position 14 (end of new document)"
echo "Position 9: past end of original document"
echo "\nOriginal: 'a b c d e f g h'"
echo "Position:  0 1 2 3 4 5 6 7 8"
echo "\nFinal:    'a b H e l l o f g W o r l d'"
echo "Position:  0 1 2 3 4 5 6 7 8 9 0 1 2 3 14"