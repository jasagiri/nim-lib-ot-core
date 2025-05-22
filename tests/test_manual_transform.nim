import src/nim_lib_ot/[types, operations]
import std/strformat

# Manual implementation of what transform should do
# op1: retain(3), delete(2), retain(3) on 'abcdefgh' -> 'abcfgh'
# op2: retain(1), delete(4), retain(3) on 'abcdefgh' -> 'afgh'

proc manualTransform() =
  echo "Manual transform implementation"
  
  # Create the operations to transform
  var op1 = newTextOperation()
  op1.addOp(retain(3))
  op1.addOp(delete(2))
  op1.addOp(retain(3))
  
  var op2 = newTextOperation()
  op2.addOp(retain(1))
  op2.addOp(delete(4))
  op2.addOp(retain(3))
  
  # Result operations
  var op1p = newTextOperation()
  var op2p = newTextOperation()
  
  # Index tracking
  var i1 = 0
  var i2 = 0
  var op1Index = 0
  var op2Index = 0
  
  # Remaining amounts for partial operations
  var op1Remaining = op1.ops[0].n
  var op2Remaining = op2.ops[0].n
  
  while op1Index < op1.ops.len or op2Index < op2.ops.len:
    echo fmt"\nIteration: op1[{op1Index}] ({op1.ops[op1Index].kind} {op1Remaining}) vs op2[{op2Index}] ({op2.ops[op2Index].kind} {op2Remaining})"
    
    # Get current operations
    let op1Current = op1.ops[op1Index]
    let op2Current = op2.ops[op2Index]
    
    case op1Current.kind
    of opRetain:
      case op2Current.kind
      of opRetain:
        # Both retain - take minimum
        let n = min(op1Remaining, op2Remaining)
        echo fmt"  Both retain: {n}"
        op1p.retain(n)
        op2p.retain(n)
        op1Remaining -= n
        op2Remaining -= n
        
      of opDelete:
        # op1 retains, op2 deletes - take minimum
        let n = min(op1Remaining, op2Remaining)
        echo fmt"  op1 retains {n}, op2 deletes {n}"
        # op1p needs to delete because op2 already deleted it
        # op2p doesn't need anything because it's already deleted
        op1p.delete(n)
        op1Remaining -= n
        op2Remaining -= n
        
      of opInsert:
        # op1 retains, op2 inserts
        echo fmt"  op1 retains, op2 inserts '{op2Current.s}'"
        op1p.retain(op2Current.s.len)
        op2p.insert(op2Current.s)
        op2Index += 1
        if op2Index < op2.ops.len:
          op2Remaining = if op2.ops[op2Index].kind == opInsert: 1 
                        else: op2.ops[op2Index].n
    
    of opDelete:
      case op2Current.kind
      of opRetain:
        # op1 deletes, op2 retains - take minimum
        let n = min(op1Remaining, op2Remaining)
        echo fmt"  op1 deletes {n}, op2 retains {n}"
        # op1p doesn't need anything because it's already deleted
        # op2p needs to delete because op1 already deleted it
        op2p.delete(n)
        op1Remaining -= n
        op2Remaining -= n
        
      of opDelete:
        # Both delete - take minimum
        let n = min(op1Remaining, op2Remaining)
        echo fmt"  Both delete: {n}"
        # Neither needs an operation since both delete the same content
        op1Remaining -= n
        op2Remaining -= n
        
      of opInsert:
        # op1 deletes, op2 inserts
        echo fmt"  op1 deletes, op2 inserts '{op2Current.s}'"
        op1p.retain(op2Current.s.len)
        op2p.insert(op2Current.s)
        op2Index += 1
        if op2Index < op2.ops.len:
          op2Remaining = if op2.ops[op2Index].kind == opInsert: 1 
                        else: op2.ops[op2Index].n
    
    of opInsert:
      # op1 inserts - op2 must retain it
      echo fmt"  op1 inserts '{op1Current.s}'"
      op1p.insert(op1Current.s)
      op2p.retain(op1Current.s.len)
      op1Index += 1
      if op1Index < op1.ops.len:
        op1Remaining = if op1.ops[op1Index].kind == opInsert: 1 
                      else: op1.ops[op1Index].n
    
    # Move to next operation if current is exhausted
    if op1Remaining == 0 and op1Index < op1.ops.len:
      op1Index += 1
      if op1Index < op1.ops.len:
        op1Remaining = if op1.ops[op1Index].kind == opInsert: 1 
                      else: op1.ops[op1Index].n
    
    if op2Remaining == 0 and op2Index < op2.ops.len:
      op2Index += 1
      if op2Index < op2.ops.len:
        op2Remaining = if op2.ops[op2Index].kind == opInsert: 1 
                      else: op2.ops[op2Index].n
    
    # Break if we've processed all operations
    if op1Index >= op1.ops.len and op2Index >= op2.ops.len:
      break
  
  echo "\nFinal results:"
  echo "op1p:", op1p.ops
  echo "op2p:", op2p.ops
  
  # Test the results
  echo "\nTesting results:"
  let doc = newDocument("abcdefgh")
  
  # Path 1: op1 then op2p
  let r1 = doc.apply(op1)
  echo "After op1: '", r1.get.content, "'"
  let r2 = r1.get.apply(op2p)
  echo "After op2p: '", r2.get.content, "'"
  
  # Path 2: op2 then op1p
  let r3 = doc.apply(op2)
  echo "After op2: '", r3.get.content, "'"
  let r4 = r3.get.apply(op1p)
  echo "After op1p: '", r4.get.content, "'"
  
  echo "\nBoth paths result in: '", r2.get.content, "' and '", r4.get.content, "'"

manualTransform()