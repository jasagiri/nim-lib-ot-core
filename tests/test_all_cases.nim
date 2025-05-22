import src/nim_lib_ot/[types, operations, transform]
import results

# Test all transformation cases to understand the pattern

proc testCase(name: string, op1, op2: TextOperation, expected: string) =
  echo "\n=== ", name, " ==="
  echo "op1: ", op1.ops
  echo "op2: ", op2.ops
  
  let result = transform(op1, op2)
  if result.isErr:
    echo "Transform error: ", result.error
    return
    
  let (op1p, op2p) = result.get
  echo "op1p: ", op1p.ops, " base=", op1p.baseLength
  echo "op2p: ", op2p.ops, " base=", op2p.baseLength
  
  # Test convergence
  let doc = newDocument("abcdefgh"[0 ..< op1.baseLength])
  
  # Path 1
  let r1 = doc.apply(op1)
  if r1.isErr:
    echo "Error applying op1: ", r1.error
    return
  let r2 = r1.get.apply(op2p)
  if r2.isErr:
    echo "Error applying op2p: ", r2.error
    return
    
  # Path 2  
  let r3 = doc.apply(op2)
  if r3.isErr:
    echo "Error applying op2: ", r3.error
    return
  let r4 = r3.get.apply(op1p)
  if r4.isErr:
    echo "Error applying op1p: ", r4.error
    return
    
  echo "Path 1 result: '", r2.get.content, "'"
  echo "Path 2 result: '", r4.get.content, "'"
  echo "Expected: '", expected, "'"
  echo "Match: ", r2.get.content == r4.get.content and r2.get.content == expected

# Test insert-insert
var op1 = newTextOperation()
op1.insert("A") 
op1.retain(5)

var op2 = newTextOperation()
op2.insert("B")
op2.retain(5)

testCase("Insert-Insert", op1, op2, "ABhello")

# Test retain-delete
op1 = newTextOperation()
op1.retain(3)
op1.delete(2)
op1.retain(3)

op2 = newTextOperation()  
op2.retain(1)
op2.delete(4)
op2.retain(3)

testCase("Retain-Delete", op1, op2, "afgh")

# Test insert-delete
op1 = newTextOperation()
op1.retain(2)
op1.insert("xyz")
op1.retain(3)

op2 = newTextOperation()
op2.retain(1)  
op2.delete(3)
op2.retain(1)

testCase("Insert-Delete", op1, op2, "axyze")

# Test with priority false
op1 = newTextOperation()
op1.insert("A")
op1.retain(5)

op2 = newTextOperation()
op2.insert("B")
op2.retain(5)

echo "\n=== Insert-Insert (priority=false) ==="
let result = transform(op1, op2, false)  
let (op1p, op2p) = result.get
echo "op1p: ", op1p.ops
echo "op2p: ", op2p.ops
let doc = newDocument("hello")
let r1 = doc.apply(op2).get.apply(op1p)
let r2 = doc.apply(op1).get.apply(op2p)
echo "Results: '", r1.get.content, "' and '", r2.get.content, "'"
echo "Expected: 'BAhello' (B first when priority=false)"