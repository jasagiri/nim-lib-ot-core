## Debug-friendly Transform Implementation
## Includes detailed logging for each step of the transformation process
##
## This implementation is useful for debugging operational transformation issues
## and understanding the algorithm's behavior on complex cases.

import ../types
import ../operations
import results
import strformat

type
  TransformResult* = tuple[a: TextOperation, b: TextOperation]

proc transform*(a, b: TextOperation, debug: bool = true): OpResult[TransformResult] =
  ## Transform two operations with detailed debug output
  ## 
  ## Args:
  ##   a: First operation
  ##   b: Second operation
  ##   debug: Whether to output debug information (default: true)
  ##
  ## Returns:
  ##   A tuple (a', b') where:
  ##   - a' is the transform of a against b
  ##   - b' is the transform of b against a
  
  if debug:
    echo "=== Transform Debug ==="
    echo "Operation A: ", a.ops
    echo "Base length: ", a.baseLength, ", Target length: ", a.targetLength
    echo "Operation B: ", b.ops 
    echo "Base length: ", b.baseLength, ", Target length: ", b.targetLength
    echo "===================="
  
  if a.baseLength != b.baseLength:
    if debug:
      echo "Error: Base length mismatch (", a.baseLength, " vs ", b.baseLength, ")"
    return err(LengthMismatch)
  
  var aResult = newTextOperation()
  var bResult = newTextOperation()
  
  var aIndex = 0
  var bIndex = 0
  
  # Track remaining amounts for partial operations
  var aRemaining = 0
  var bRemaining = 0
  
  if debug:
    echo "\nStarting transform loop:"
  
  while aIndex < a.ops.len or bIndex < b.ops.len:
    # Handle end cases
    if aIndex >= a.ops.len and bIndex >= b.ops.len:
      if debug:
        echo "Both operations fully processed"
      break
    
    if aIndex >= a.ops.len:
      # Only B operations left
      let bOp = b.ops[bIndex]
      var amount = 0
      
      if bOp.kind == opRetain or bOp.kind == opDelete:
        amount = if bRemaining > 0: bRemaining else: bOp.n
      
      if debug:
        echo &"Only B left: op={bOp.kind}"
      
      case bOp.kind:
      of opRetain:
        bResult.retain(amount)
        if debug:
          echo &"  B retains {amount} -> bResult.retain({amount})"
      of opInsert:
        bResult.insert(bOp.s)
        if debug:
          echo &"  B inserts '{bOp.s}' -> bResult.insert('{bOp.s}')"
      of opDelete:
        # Nothing to delete in A's context
        if debug:
          echo &"  B deletes {amount} -> no-op (already deleted)"
      
      bRemaining = 0
      bIndex += 1
      continue
    
    if bIndex >= b.ops.len:
      # Only A operations left
      let aOp = a.ops[aIndex]
      var amount = 0
      
      if aOp.kind == opRetain or aOp.kind == opDelete:
        amount = if aRemaining > 0: aRemaining else: aOp.n
      
      if debug:
        echo &"Only A left: op={aOp.kind}"
      
      case aOp.kind:
      of opRetain:
        aResult.retain(amount)
        if debug:
          echo &"  A retains {amount} -> aResult.retain({amount})"
      of opInsert:
        aResult.insert(aOp.s)
        if debug:
          echo &"  A inserts '{aOp.s}' -> aResult.insert('{aOp.s}')"
      of opDelete:
        # Nothing to delete in B's context
        if debug:
          echo &"  A deletes {amount} -> no-op (already deleted)"
      
      aRemaining = 0
      aIndex += 1
      continue
    
    let aOp = a.ops[aIndex]
    let bOp = b.ops[bIndex]
    
    # Use remaining amounts if any
    let aAmount = if aRemaining > 0: aRemaining else: 
                 case aOp.kind:
                 of opRetain, opDelete: aOp.n
                 of opInsert: 0
    
    let bAmount = if bRemaining > 0: bRemaining else:
                 case bOp.kind:
                 of opRetain, opDelete: bOp.n
                 of opInsert: 0
    
    if debug:
      echo &"Processing: A[{aIndex}]={aOp.kind} (remaining: {aAmount}) B[{bIndex}]={bOp.kind} (remaining: {bAmount})"
    
    # Handle operation combinations
    case aOp.kind:
    of opInsert:
      # A inserts characters that B doesn't know about
      aResult.insert(aOp.s)
      bResult.retain(aOp.s.len)
      aIndex += 1
      aRemaining = 0
      if debug:
        echo &"  A inserts '{aOp.s}' -> aResult.insert('{aOp.s}'), bResult.retain({aOp.s.len})"
    
    of opRetain:
      case bOp.kind:
      of opInsert:
        # B inserts while A retains
        aResult.retain(bOp.s.len)
        bResult.insert(bOp.s)
        bIndex += 1
        bRemaining = 0
        if debug:
          echo &"  B inserts '{bOp.s}' -> aResult.retain({bOp.s.len}), bResult.insert('{bOp.s}')"
      
      of opRetain:
        # Both retain
        let n = min(aAmount, bAmount)
        aResult.retain(n)
        bResult.retain(n)
        
        aRemaining = aAmount - n
        bRemaining = bAmount - n
        
        if aRemaining == 0:
          aIndex += 1
        if bRemaining == 0:
          bIndex += 1
        
        if debug:
          echo &"  Both retain {n} -> aResult.retain({n}), bResult.retain({n})"
      
      of opDelete:
        # A retains, B deletes
        let n = min(aAmount, bAmount)
        aResult.delete(n)
        # bResult gets nothing (already deleted)
        
        aRemaining = aAmount - n
        bRemaining = bAmount - n
        
        if aRemaining == 0:
          aIndex += 1
        if bRemaining == 0:
          bIndex += 1
        
        if debug:
          echo &"  A retains, B deletes {n} -> aResult.delete({n})"
    
    of opDelete:
      case bOp.kind:
      of opInsert:
        # A deletes, B inserts
        aResult.retain(bOp.s.len)
        bResult.insert(bOp.s)
        bIndex += 1
        bRemaining = 0
        if debug:
          echo &"  A deletes, B inserts '{bOp.s}' -> aResult.retain({bOp.s.len}), bResult.insert('{bOp.s}')"
      
      of opRetain:
        # A deletes, B retains
        let n = min(aAmount, bAmount)
        # aResult gets nothing (already deleted)
        bResult.delete(n)
        
        aRemaining = aAmount - n
        bRemaining = bAmount - n
        
        if aRemaining == 0:
          aIndex += 1
        if bRemaining == 0:
          bIndex += 1
          
        if debug:
          echo &"  A deletes, B retains {n} -> bResult.delete({n})"
      
      of opDelete:
        # Both delete
        let n = min(aAmount, bAmount)
        # Neither gets anything (already deleted by both)
        
        aRemaining = aAmount - n
        bRemaining = bAmount - n
        
        if aRemaining == 0:
          aIndex += 1  
        if bRemaining == 0:
          bIndex += 1
          
        if debug:
          echo &"  Both delete {n} -> no-op (already deleted by both)"
  
  # Set base lengths correctly
  aResult.baseLength = b.targetLength
  bResult.baseLength = a.targetLength
  
  # Calculate target lengths
  var aTarget = aResult.baseLength
  var bTarget = bResult.baseLength
  
  for op in aResult.ops:
    case op.kind:
    of opInsert:
      aTarget += op.s.len
    of opDelete:
      aTarget -= op.n
    else:
      discard
  
  for op in bResult.ops:
    case op.kind:
    of opInsert:
      bTarget += op.s.len
    of opDelete:
      bTarget -= op.n
    else:
      discard
  
  aResult.targetLength = aTarget
  bResult.targetLength = bTarget
  
  if debug:
    echo "\nFinal results:"
    echo &"aResult: {aResult.ops} base={aResult.baseLength} target={aResult.targetLength}"
    echo &"bResult: {bResult.ops} base={bResult.baseLength} target={bResult.targetLength}"
  
  ok((aResult, bResult))