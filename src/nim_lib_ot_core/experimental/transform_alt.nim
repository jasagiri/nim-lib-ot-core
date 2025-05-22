## Alternative Transform Implementation
## Based on an approach focusing on clarity and readability
## 
## Note: This is an experimental implementation that may handle certain edge cases
## differently from the main implementation. It's provided for research and
## comparison purposes.

import ../types
import ../operations
import results

type
  TransformResult* = tuple[a: TextOperation, b: TextOperation]

proc transform*(a, b: TextOperation): OpResult[TransformResult] =
  ## Transform two operations to work in their proper contexts
  ## aResult transforms from b's output to final state
  ## bResult transforms from a's output to final state
  
  if a.baseLength != b.baseLength:
    return err(LengthMismatch)
  
  var aResult = newTextOperation()
  var bResult = newTextOperation()
  
  var aIndex = 0
  var bIndex = 0
  
  # Track remaining amounts
  var aRemaining = 0
  var bRemaining = 0
  
  while aIndex < a.ops.len or bIndex < b.ops.len:
    # Handle end cases
    if aIndex >= a.ops.len and bIndex >= b.ops.len:
      break
    
    if aIndex >= a.ops.len:
      # Only B operations left
      if bRemaining == 0 and bIndex < b.ops.len:
        let bOp = b.ops[bIndex]
        case bOp.kind:
        of opRetain:
          bRemaining = bOp.n
        of opInsert:
          bResult.insert(bOp.s)
          bIndex += 1
          continue
        of opDelete:
          bRemaining = bOp.n
        bIndex += 1
      
      if bRemaining > 0:
        let bOp = b.ops[bIndex - 1]
        case bOp.kind:
        of opRetain:
          bResult.retain(bRemaining)
        of opDelete:
          # Nothing to delete
          discard
        else:
          discard
        bRemaining = 0
      continue
    
    if bIndex >= b.ops.len:
      # Only A operations left
      if aRemaining == 0 and aIndex < a.ops.len:
        let aOp = a.ops[aIndex]
        case aOp.kind:
        of opRetain:
          aRemaining = aOp.n
        of opInsert:
          aResult.insert(aOp.s)
          aIndex += 1
          continue
        of opDelete:
          aRemaining = aOp.n
        aIndex += 1
      
      if aRemaining > 0:
        let aOp = a.ops[aIndex - 1]
        case aOp.kind:
        of opRetain:
          aResult.retain(aRemaining)
        of opDelete:
          # Nothing to delete
          discard
        else:
          discard
        aRemaining = 0
      continue
    
    # Get current operations
    let aOp = a.ops[aIndex]
    let bOp = b.ops[bIndex]
    
    # Handle insertions immediately
    case aOp.kind:
    of opInsert:
      aResult.insert(aOp.s)
      bResult.retain(aOp.s.len)
      aIndex += 1
      continue
    else:
      discard
    
    case bOp.kind:
    of opInsert:
      aResult.retain(bOp.s.len)
      bResult.insert(bOp.s)
      bIndex += 1
      continue
    else:
      discard
    
    # Set amounts if not already set
    if aRemaining == 0:
      case aOp.kind:
      of opRetain, opDelete:
        aRemaining = aOp.n
      else:
        discard
    
    if bRemaining == 0:
      case bOp.kind:
      of opRetain, opDelete:
        bRemaining = bOp.n
      else:
        discard
    
    # Process retain/delete combinations
    let amount = min(aRemaining, bRemaining)
    
    if aOp.kind == opRetain and bOp.kind == opRetain:
      aResult.retain(amount)
      bResult.retain(amount)
    
    elif aOp.kind == opRetain and bOp.kind == opDelete:
      # A retains what B deletes
      aResult.delete(amount)
      # B already deleted
    
    elif aOp.kind == opDelete and bOp.kind == opRetain:
      # A deletes what B retains
      # A already deleted
      bResult.delete(amount)
    
    elif aOp.kind == opDelete and bOp.kind == opDelete:
      # Both delete the same content
      # Nothing to add to either
      discard
    
    else:
      # Should not reach here
      discard
    
    # Update remaining amounts
    aRemaining -= amount
    bRemaining -= amount
    
    # Move to next operation if current is exhausted
    if aRemaining == 0:
      aIndex += 1
    if bRemaining == 0:
      bIndex += 1
  
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
  
  ok((aResult, bResult))