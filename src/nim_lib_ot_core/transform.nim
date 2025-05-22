## Transform Implementation
## Correctly handles all OT transform cases including insert-insert
## Based on the reference algorithm from ot.js

import ./types
import ./operations
import results

type
  TransformResult* = tuple[a: TextOperation, b: TextOperation]

proc transform*(a, b: TextOperation): OpResult[TransformResult] =
  ## Transform two operations based on ot.js reference algorithm
  ## 
  ## Given two operations that were applied to the same document state,
  ## this produces two operations that can be applied to the result of the other.
  ## 
  ## Args:
  ##   a: First operation
  ##   b: Second operation
  ## 
  ## Returns:
  ##   A tuple (a', b') where:
  ##   - a' is the transform of a against b
  ##   - b' is the transform of b against a
  ##   Such that applying a then b' gives the same result as b then a'
  
  if a.baseLength != b.baseLength:
    return err(LengthMismatch)
  
  var operation1prime = newTextOperation()
  var operation2prime = newTextOperation()
  
  var ops1 = a.ops
  var ops2 = b.ops
  var i1 = 0
  var i2 = 0
  
  # Pre-load first operations
  var op1: Operation
  var op2: Operation
  var op1Valid = false
  var op2Valid = false
  
  if i1 < ops1.len:
    op1 = ops1[i1]
    i1 += 1
    op1Valid = true
  
  if i2 < ops2.len:
    op2 = ops2[i2]
    i2 += 1
    op2Valid = true
  
  # Track remaining amounts for retain/delete operations
  var op1Amount = 0
  var op2Amount = 0
  
  if op1Valid:
    case op1.kind:
    of opRetain, opDelete:
      op1Amount = op1.n
    else:
      discard
  
  if op2Valid:
    case op2.kind:
    of opRetain, opDelete:
      op2Amount = op2.n
    else:
      discard
  
  while op1Valid or op2Valid:
    # End condition: both ops processed
    if not op1Valid and not op2Valid:
      break
    
    # Process remaining operations
    if not op1Valid:
      # Only op2 left
      case op2.kind:
      of opInsert:
        operation2prime.insert(op2.s)
      of opRetain:
        operation2prime.retain(op2Amount)
      of opDelete:
        # Nothing to delete
        discard
      
      # Get next op2
      if i2 < ops2.len:
        op2 = ops2[i2]
        i2 += 1
        case op2.kind:
        of opRetain, opDelete:
          op2Amount = op2.n
        of opInsert:
          op2Amount = 0
      else:
        op2Valid = false
      continue
    
    if not op2Valid:
      # Only op1 left
      case op1.kind:
      of opInsert:
        operation1prime.insert(op1.s)
      of opRetain:
        operation1prime.retain(op1Amount)
      of opDelete:
        # Nothing to delete
        discard
      
      # Get next op1
      if i1 < ops1.len:
        op1 = ops1[i1]
        i1 += 1
        case op1.kind:
        of opRetain, opDelete:
          op1Amount = op1.n
        of opInsert:
          op1Amount = 0
      else:
        op1Valid = false
      continue
    
    # Handle insert operations first (they don't consume input)
    if op1.kind == opInsert:
      operation1prime.insert(op1.s)
      operation2prime.retain(op1.s.len)
      
      # Get next op1 only
      if i1 < ops1.len:
        op1 = ops1[i1]
        i1 += 1
        case op1.kind:
        of opRetain, opDelete:
          op1Amount = op1.n
        of opInsert:
          op1Amount = 0
      else:
        op1Valid = false
      continue
    
    if op2.kind == opInsert:
      operation1prime.retain(op2.s.len)
      operation2prime.insert(op2.s)
      
      # Get next op2 only
      if i2 < ops2.len:
        op2 = ops2[i2]
        i2 += 1
        case op2.kind:
        of opRetain, opDelete:
          op2Amount = op2.n
        of opInsert:
          op2Amount = 0
      else:
        op2Valid = false
      continue
    
    # Both operations must be retain or delete
    var minl: int
    
    if op1.kind == opRetain and op2.kind == opRetain:
      # Both retain
      if op1Amount > op2Amount:
        minl = op2Amount
        op1Amount = op1Amount - op2Amount
        op2Amount = 0
      elif op1Amount == op2Amount:
        minl = op1Amount
        op1Amount = 0
        op2Amount = 0
      else:
        minl = op1Amount
        op2Amount = op2Amount - op1Amount
        op1Amount = 0
      
      operation1prime.retain(minl)
      operation2prime.retain(minl)
    
    elif op1.kind == opDelete and op2.kind == opDelete:
      # Both delete - skip over the common part
      if op1Amount > op2Amount:
        op1Amount = op1Amount - op2Amount
        op2Amount = 0
      elif op1Amount == op2Amount:
        op1Amount = 0
        op2Amount = 0
      else:
        op2Amount = op2Amount - op1Amount
        op1Amount = 0
    
    elif op1.kind == opDelete and op2.kind == opRetain:
      # op1 deletes, op2 retains
      if op1Amount > op2Amount:
        minl = op2Amount
        op1Amount = op1Amount - op2Amount
        op2Amount = 0
      elif op1Amount == op2Amount:
        minl = op2Amount
        op1Amount = 0
        op2Amount = 0
      else:
        minl = op1Amount
        op2Amount = op2Amount - op1Amount
        op1Amount = 0
      
      operation1prime.delete(minl)
    
    elif op1.kind == opRetain and op2.kind == opDelete:
      # op1 retains, op2 deletes
      if op1Amount > op2Amount:
        minl = op2Amount
        op1Amount = op1Amount - op2Amount
        op2Amount = 0
      elif op1Amount == op2Amount:
        minl = op1Amount
        op1Amount = 0
        op2Amount = 0
      else:
        minl = op1Amount
        op2Amount = op2Amount - op1Amount
        op1Amount = 0
      
      operation2prime.delete(minl)
    
    else:
      return err(InvalidOperation)
    
    # Check if we need to advance to next operation
    if op1Amount == 0 and op1Valid:
      if i1 < ops1.len:
        op1 = ops1[i1]
        i1 += 1
        case op1.kind:
        of opRetain, opDelete:
          op1Amount = op1.n
        of opInsert:
          op1Amount = 0
      else:
        op1Valid = false
    
    if op2Amount == 0 and op2Valid:
      if i2 < ops2.len:
        op2 = ops2[i2]
        i2 += 1
        case op2.kind:
        of opRetain, opDelete:
          op2Amount = op2.n
        of opInsert:
          op2Amount = 0
      else:
        op2Valid = false
  
  # Set base lengths correctly
  operation1prime.baseLength = b.targetLength
  operation2prime.baseLength = a.targetLength
  
  # Calculate target lengths
  operation1prime.targetLength = operation1prime.baseLength
  operation2prime.targetLength = operation2prime.baseLength
  
  for op in operation1prime.ops:
    case op.kind:
    of opInsert:
      operation1prime.targetLength += op.s.len
    of opDelete:
      operation1prime.targetLength -= op.n
    else:
      discard
  
  for op in operation2prime.ops:
    case op.kind:
    of opInsert:
      operation2prime.targetLength += op.s.len
    of opDelete:
      operation2prime.targetLength -= op.n
    else:
      discard
  
  # Validate the transformed operations
  let validation1 = operation1prime.validate()
  if validation1.isErr:
    return err(validation1.error)
  
  let validation2 = operation2prime.validate()
  if validation2.isErr:
    return err(validation2.error)
  
  ok((operation1prime, operation2prime))