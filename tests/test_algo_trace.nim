import src/nim_lib_ot/[types, operations]
import std/[options, strformat]

# Manual trace of the algorithm to find the bug

echo "=== ALGORITHM TRACE ==="

var op1 = newTextOperation()
op1.addOp(retain(3))
op1.addOp(delete(2))
op1.addOp(retain(3))

var op2 = newTextOperation()
op2.addOp(retain(1))
op2.addOp(delete(4))
op2.addOp(retain(3))

echo fmt"op1: {op1.ops}"
echo fmt"op2: {op2.ops}"
echo ""

var aResult = newTextOperation()
var bResult = newTextOperation()

var aIndex = 0
var bIndex = 0

var aRemaining = some(op1.ops[0])
var bRemaining = some(op2.ops[0])

var iteration = 0
while aRemaining.isSome or bRemaining.isSome:
  iteration += 1
  echo fmt"Iteration {iteration}:"
  
  if aRemaining.isSome:
    let aOp = aRemaining.get
    let aVal = if aOp.kind == opInsert: aOp.s else: $aOp.n
    echo fmt"  A: {aOp.kind} {aVal}"
  else:
    echo "  A: none"
    
  if bRemaining.isSome:
    let bOp = bRemaining.get
    let bVal = if bOp.kind == opInsert: bOp.s else: $bOp.n
    echo fmt"  B: {bOp.kind} {bVal}"
  else:
    echo "  B: none"
  
  if aRemaining.isNone:
    bResult.addOp(bRemaining.get)
    bIndex += 1
    bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
    echo fmt"  -> B gets: {bResult.ops[^1]}"
    continue
  
  if bRemaining.isNone:
    aResult.addOp(aRemaining.get)
    aIndex += 1
    aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
    echo fmt"  -> A gets: {aResult.ops[^1]}"
    continue
  
  let aOp = aRemaining.get
  let bOp = bRemaining.get
  
  case aOp.kind
  of opRetain:
    case bOp.kind
    of opRetain:
      let n = min(aOp.n, bOp.n)
      echo fmt"  Both retain: min({aOp.n}, {bOp.n}) = {n}"
      aResult.retain(n)
      bResult.retain(n)
      echo fmt"  -> A: retain({n}), B: retain({n})"
      
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
      echo fmt"  A retains {aOp.n}, B deletes {bOp.n}: min = {n}"
      echo "  A wants to retain chars that B deleted, so A must delete them too"
      aResult.delete(n)
      echo fmt"  -> A: delete({n}), B: nothing"
      
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
      echo fmt"  A retains, B inserts '{bOp.s}'"
      aResult.retain(bOp.s.len)
      bResult.insert(bOp.s)
      echo fmt"  -> A: retain({bOp.s.len}), B: insert('{bOp.s}')"
      bIndex += 1
      bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
  
  of opDelete:
    case bOp.kind
    of opRetain:
      let n = min(aOp.n, bOp.n)
      echo fmt"  A deletes {aOp.n}, B retains {bOp.n}: min = {n}"
      echo "  B wants to retain chars that A deleted, so B must delete them too"
      bResult.delete(n)
      echo fmt"  -> A: nothing, B: delete({n})"
      
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
      echo fmt"  Both delete: min({aOp.n}, {bOp.n}) = {n}"
      echo "  Both delete same chars, no operations needed"
      
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
      echo fmt"  A deletes, B inserts '{bOp.s}'"
      aResult.retain(bOp.s.len)
      bResult.insert(bOp.s)
      echo fmt"  -> A: retain({bOp.s.len}), B: insert('{bOp.s}')"
      bIndex += 1
      bRemaining = if bIndex < op2.ops.len: some(op2.ops[bIndex]) else: none(Operation)
  
  of opInsert:
    echo fmt"  A inserts '{aOp.s}', B any"
    aResult.insert(aOp.s)
    bResult.retain(aOp.s.len)
    echo fmt"  -> A: insert('{aOp.s}'), B: retain({aOp.s.len})"
    aIndex += 1
    aRemaining = if aIndex < op1.ops.len: some(op1.ops[aIndex]) else: none(Operation)
  
  echo ""

echo "Final results:"
echo fmt"aResult (op1'): {aResult.ops}"
echo fmt"bResult (op2'): {bResult.ops}"

echo "\nExpected results:"
echo "op1' should be: retain(4)"
echo "op2' should be: retain(1), delete(2), retain(3)"

echo "\nActual vs Expected:"
echo fmt"op1' is {aResult.ops} but should be retain(4)"
echo fmt"op2' is {bResult.ops} but should be retain(1), delete(2), retain(3)"