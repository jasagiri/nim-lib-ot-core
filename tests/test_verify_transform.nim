import src/nim_lib_ot/[types, operations]
import results

# Verify what the transform produces vs what it should produce

proc verifyTransform() =
  echo "=== VERIFY TRANSFORM ==="
  
  # Current transform results (from trace)
  var currentOp1p = newTextOperation()
  currentOp1p.retain(1)
  currentOp1p.delete(2)
  currentOp1p.retain(3)
  
  var currentOp2p = newTextOperation() 
  currentOp2p.retain(4)
  
  echo "Current transform results:"
  echo "op1': ", currentOp1p.ops
  echo "op2': ", currentOp2p.ops
  echo ""
  
  # Test what these produce
  let doc1 = newDocument("afgh")  # Result of op2
  echo "Applying current op1' to 'afgh':"
  let r1 = doc1.apply(currentOp1p)
  if r1.isOk:
    echo "Result: '", r1.get.content, "'"
  else:
    echo "Error: ", r1.error
    # Let's manually calculate
    echo "Manual calculation:"
    echo "- retain(1): keep 'a'"
    echo "- delete(2): delete 'fg'"
    echo "- retain(3): keep... only 'h' remains (length 1)"
    echo "Total base needed: 1 + 2 + 3 = 6, but we only have 4"
  
  let doc2 = newDocument("abcfgh")  # Result of op1
  echo "\nApplying current op2' to 'abcfgh':"
  let r2 = doc2.apply(currentOp2p)
  if r2.isOk:
    echo "Result: '", r2.get.content, "'"
  else:
    echo "Error: ", r2.error
    
  # What they SHOULD be
  echo "\n\nWhat the operations SHOULD be:"
  
  var correctOp1p = newTextOperation()
  correctOp1p.retain(4)  # Keep all of "afgh"
  
  var correctOp2p = newTextOperation()
  correctOp2p.retain(1)   # Keep 'a'
  correctOp2p.delete(2)   # Delete 'bc'
  correctOp2p.retain(3)   # Keep 'fgh'
  
  echo "Correct op1': ", correctOp1p.ops
  echo "Correct op2': ", correctOp2p.ops
  
  # Test correct operations
  let doc3 = newDocument("afgh")
  echo "\nApplying correct op1' to 'afgh':"
  let r3 = doc3.apply(correctOp1p)
  if r3.isOk:
    echo "Result: '", r3.get.content, "'"
  else:
    echo "Error: ", r3.error
    
  let doc4 = newDocument("abcfgh")
  echo "\nApplying correct op2' to 'abcfgh':"
  let r4 = doc4.apply(correctOp2p)
  if r4.isOk:
    echo "Result: '", r4.get.content, "'"
  else:
    echo "Error: ", r4.error
  
  echo "\nConclusion: The operations are indeed swapped!"

verifyTransform()