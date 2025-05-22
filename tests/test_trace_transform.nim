import src/nim_lib_ot/[types, operations]
import std/[options]
import results

# Let's manually trace through the transform algorithm to find the bug

proc traceTransform() =
  echo "=== MANUAL TRANSFORM TRACE ==="
  
  # Create operations
  var op1 = newTextOperation()
  op1.retain(3)
  op1.delete(2)  
  op1.retain(3)
  
  var op2 = newTextOperation()
  op2.retain(1)
  op2.delete(4)
  op2.retain(3)
  
  echo "op1: ", op1.ops
  echo "op2: ", op2.ops
  echo ""
  
  # Initialize results
  var aResult = newTextOperation()
  var bResult = newTextOperation()
  
  var aIndex = 0
  var bIndex = 0
  
  var aRemaining = some(op1.ops[0])
  var bRemaining = some(op2.ops[0])
  
  var iteration = 0
  while aRemaining.isSome or bRemaining.isSome:
    iteration += 1
    echo "Iteration ", iteration, ":"
    
    if aRemaining.isSome:
      echo "  A: ", aRemaining.get.kind, " ", 
        if aRemaining.get.kind == opInsert: aRemaining.get.s 
        else: $aRemaining.get.n
    else:
      echo "  A: none"
      
    if bRemaining.isSome:
      echo "  B: ", bRemaining.get.kind, " ",
        if bRemaining.get.kind == opInsert: bRemaining.get.s
        else: $bRemaining.get.n
    else:
      echo "  B: none"
    
    if aRemaining.isNone:
      bResult.addOp(bRemaining.get)
      bIndex += 1
      bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
      echo "  -> Added to B: ", bResult.ops[^1]
      continue
    
    if bRemaining.isNone:
      aResult.addOp(aRemaining.get)
      aIndex += 1
      aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
      echo "  -> Added to A: ", aResult.ops[^1]
      continue
    
    let aOp = aRemaining.get
    let bOp = bRemaining.get
    
    case aOp.kind
    of opRetain:
      case bOp.kind
      of opRetain:
        let n = min(aOp.n, bOp.n)
        echo "  Both retain: min(", aOp.n, ", ", bOp.n, ") = ", n
        aResult.retain(n)
        bResult.retain(n)
        echo "  -> A: retain(", n, ")"
        echo "  -> B: retain(", n, ")"
        
        if aOp.n == n:
          aIndex += 1
          aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
        else:
          aRemaining = some(retain(aOp.n - n))
        
        if bOp.n == n:
          bIndex += 1
          bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
        else:
          bRemaining = some(retain(bOp.n - n))
      
      of opDelete:
        let n = min(aOp.n, bOp.n)
        echo "  A retains ", aOp.n, ", B deletes ", bOp.n, ": min = ", n
        aResult.delete(n)
        echo "  -> A: delete(", n, ")"
        echo "  -> B: nothing"
        
        if aOp.n == n:
          aIndex += 1
          aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
        else:
          aRemaining = some(retain(aOp.n - n))
        
        if bOp.n == n:
          bIndex += 1
          bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
        else:
          bRemaining = some(delete(bOp.n - n))
      
      of opInsert:
        echo "  A retains, B inserts '", bOp.s, "'"
        aResult.retain(bOp.s.len)
        bResult.insert(bOp.s)
        echo "  -> A: retain(", bOp.s.len, ")"
        echo "  -> B: insert('", bOp.s, "')"
        bIndex += 1
        bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
    
    of opDelete:
      case bOp.kind
      of opRetain:
        let n = min(aOp.n, bOp.n)
        echo "  A deletes ", aOp.n, ", B retains ", bOp.n, ": min = ", n
        bResult.delete(n)
        echo "  -> A: nothing"
        echo "  -> B: delete(", n, ")"
        
        if aOp.n == n:
          aIndex += 1
          aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
        else:
          aRemaining = some(delete(aOp.n - n))
        
        if bOp.n == n:
          bIndex += 1
          bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
        else:
          bRemaining = some(retain(bOp.n - n))
      
      of opDelete:
        let n = min(aOp.n, bOp.n)
        echo "  Both delete: min(", aOp.n, ", ", bOp.n, ") = ", n
        echo "  -> A: nothing"
        echo "  -> B: nothing"
        
        if aOp.n == n:
          aIndex += 1
          aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
        else:
          aRemaining = some(delete(aOp.n - n))
        
        if bOp.n == n:
          bIndex += 1
          bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
        else:
          bRemaining = some(delete(bOp.n - n))
      
      of opInsert:
        echo "  A deletes, B inserts '", bOp.s, "'"
        aResult.retain(bOp.s.len)
        bResult.insert(bOp.s)
        echo "  -> A: retain(", bOp.s.len, ")"
        echo "  -> B: insert('", bOp.s, "')"
        bIndex += 1
        bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
    
    of opInsert:
      echo "  A inserts '", aOp.s, "'"
      aResult.insert(aOp.s)
      bResult.retain(aOp.s.len)
      echo "  -> A: insert('", aOp.s, "')"
      echo "  -> B: retain(", aOp.s.len, ")"
      aIndex += 1
      aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
    
    echo ""
  
  echo "Final results:"
  echo "aResult (op1'): ", aResult.ops
  echo "bResult (op2'): ", bResult.ops
  echo ""
  
  # Test
  echo "Testing:"
  let doc = newDocument("abcdefgh")
  
  # Apply op2 then aResult
  let r1 = doc.apply(op2)
  if r1.isOk:
    echo "After op2: '", r1.get.content, "'"
  else:
    echo "Error applying op2: ", r1.error
  echo "Should apply op1' (aResult) to get final result"
  echo "aResult: ", aResult.ops
  
  # Apply op1 then bResult  
  let r2 = doc.apply(op1)
  if r2.isOk:
    echo "After op1: '", r2.get.content, "'"
  else:
    echo "Error applying op1: ", r2.error
  echo "Should apply op2' (bResult) to get final result"
  echo "bResult: ", bResult.ops

traceTransform()