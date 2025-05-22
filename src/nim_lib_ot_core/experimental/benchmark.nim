## Benchmark module for OT algorithms
## Provides tools for comparing different transform implementations

import ../types
import ../operations
import ../transform as standard_transform
import ./transform_alt as alt_transform
import results
import times
import strformat

proc generateRandomOperation*(base: int, insertProb: float = 0.4, deleteProb: float = 0.3, 
                             maxInsertSize: int = 3, maxDeleteSize: int = 3,
                             retainProb: float = 0.3, maxRetainSize: int = 10): TextOperation =
  ## Generate a random operation for benchmarking
  ## 
  ## Args:
  ##   base: Base length for the operation
  ##   insertProb: Probability of insert operations
  ##   deleteProb: Probability of delete operations
  ##   retainProb: Probability of retain operations
  ##   maxInsertSize: Maximum size of insert strings
  ##   maxDeleteSize: Maximum size of delete operations
  ##   maxRetainSize: Maximum size of retain operations
  ##
  ## Returns:
  ##   A random text operation
  
  result = newTextOperation()
  var pos = 0
  
  while pos < base:
    let r = rand(1.0)
    if r < insertProb:
      # Insert
      let size = 1 + rand(maxInsertSize - 1)
      var s = ""
      for i in 1..size:
        s.add(char(97 + rand(25))) # Random lowercase letter
      result.insert(s)
    elif r < insertProb + deleteProb and pos < base:
      # Delete
      let size = min(1 + rand(maxDeleteSize - 1), base - pos)
      result.delete(size)
      pos += size
    else:
      # Retain
      let size = min(1 + rand(maxRetainSize - 1), base - pos)
      result.retain(size)
      pos += size

proc benchmarkTransform*(iterations: int = 1000, docSize: int = 1000): tuple[standardTime, altTime: float] =
  ## Compare performance of standard and alternative transform implementations
  ##
  ## Args:
  ##   iterations: Number of transform operations to perform
  ##   docSize: Size of the document to simulate
  ##
  ## Returns:
  ##   Tuple containing execution times for standard and alt implementations
  
  # Generate random operations
  var operations: seq[tuple[a, b: TextOperation]] = @[]
  
  for i in 1..iterations:
    let a = generateRandomOperation(docSize)
    let b = generateRandomOperation(docSize)
    operations.add((a, b))
  
  # Benchmark standard implementation
  let standardStart = cpuTime()
  var standardSuccess = 0
  for op in operations:
    let result = standard_transform.transform(op.a, op.b)
    if result.isOk:
      standardSuccess += 1
  let standardTime = cpuTime() - standardStart
  
  # Benchmark alternative implementation
  let altStart = cpuTime()
  var altSuccess = 0
  for op in operations:
    let result = alt_transform.transform(op.a, op.b)
    if result.isOk:
      altSuccess += 1
  let altTime = cpuTime() - altStart
  
  echo &"Standard implementation: {standardTime:.6f}s for {iterations} transforms ({standardSuccess} successful)"
  echo &"Alternative implementation: {altTime:.6f}s for {iterations} transforms ({altSuccess} successful)"
  
  return (standardTime, altTime)

proc testEdgeCases*() =
  ## Test and compare implementations on known edge cases
  
  echo "Testing edge cases:"
  
  # Case 1: Empty operations
  var emptyA = newTextOperation()
  var emptyB = newTextOperation()
  emptyA.baseLength = 10
  emptyA.targetLength = 10
  emptyB.baseLength = 10
  emptyB.targetLength = 10
  
  echo "\nCase 1: Empty operations"
  let stdResult1 = standard_transform.transform(emptyA, emptyB)
  let altResult1 = alt_transform.transform(emptyA, emptyB)
  echo "Standard: ", if stdResult1.isOk: "Success" else: "Failed: " & $stdResult1.error
  echo "Alternative: ", if altResult1.isOk: "Success" else: "Failed: " & $altResult1.error
  
  # Case 2: Insert at same position
  var insertA = newTextOperation()
  var insertB = newTextOperation()
  
  insertA.retain(5)
  insertA.insert("abc")
  insertA.retain(5)
  insertA.baseLength = 10
  insertA.targetLength = 13
  
  insertB.retain(5)
  insertB.insert("xyz")
  insertB.retain(5)
  insertB.baseLength = 10
  insertB.targetLength = 13
  
  echo "\nCase 2: Insert at same position"
  let stdResult2 = standard_transform.transform(insertA, insertB)
  let altResult2 = alt_transform.transform(insertA, insertB)
  
  echo "Standard: ", if stdResult2.isOk: "Success" else: "Failed: " & $stdResult2.error
  if stdResult2.isOk:
    let (stdA, stdB) = stdResult2.get()
    echo "  Result A: ", stdA.ops
    echo "  Result B: ", stdB.ops
  
  echo "Alternative: ", if altResult2.isOk: "Success" else: "Failed: " & $altResult2.error
  if altResult2.isOk:
    let (altA, altB) = altResult2.get()
    echo "  Result A: ", altA.ops
    echo "  Result B: ", altB.ops
  
  # Case 3: Delete ranges with overlap
  var deleteA = newTextOperation()
  var deleteB = newTextOperation()
  
  deleteA.retain(2)
  deleteA.delete(5)
  deleteA.retain(3)
  deleteA.baseLength = 10
  deleteA.targetLength = 5
  
  deleteB.retain(4)
  deleteB.delete(4)
  deleteB.retain(2)
  deleteB.baseLength = 10
  deleteB.targetLength = 6
  
  echo "\nCase 3: Overlapping deletes"
  let stdResult3 = standard_transform.transform(deleteA, deleteB)
  let altResult3 = alt_transform.transform(deleteA, deleteB)
  
  echo "Standard: ", if stdResult3.isOk: "Success" else: "Failed: " & $stdResult3.error
  if stdResult3.isOk:
    let (stdA, stdB) = stdResult3.get()
    echo "  Result A: ", stdA.ops
    echo "  Result B: ", stdB.ops
  
  echo "Alternative: ", if altResult3.isOk: "Success" else: "Failed: " & $altResult3.error
  if altResult3.isOk:
    let (altA, altB) = altResult3.get()
    echo "  Result A: ", altA.ops
    echo "  Result B: ", altB.ops

when isMainModule:
  import random
  randomize()
  
  echo "=== OT Algorithm Benchmark ==="
  let (stdTime, altTime) = benchmarkTransform(1000)
  echo &"Standard is {altTime/stdTime:.2f}x {if stdTime < altTime: 'faster' else: 'slower'} than alternative"
  
  echo "\n=== Edge Case Tests ==="
  testEdgeCases()