## Main benchmark for nim-lib-ot-core
## This file imports and runs all benchmarks

import times, strformat

# Import experimental benchmark module
import ../src/nim_lib_ot_core/experimental/benchmark

# Additional benchmarks can be added here
# import ./bench_operations
# import ./bench_transform
# etc.

when isMainModule:
  echo "=== nim-lib-ot-core Benchmarks ==="
  echo "Running benchmarks..."
  
  # Run standard benchmarks from the experimental module
  echo "\n== Core Algorithm Benchmarks =="
  let iterations = 1000
  let (stdTime, altTime) = benchmarkTransform(iterations)
  
  echo &"\nStandard implementation: {stdTime:.6f}s for {iterations} transforms"
  echo &"Alternative implementation: {altTime:.6f}s for {iterations} transforms"
  
  if stdTime < altTime:
    echo &"Standard implementation is {altTime/stdTime:.2f}x faster"
  else:
    echo &"Alternative implementation is {stdTime/altTime:.2f}x faster"
  
  # Run edge case tests
  echo "\n== Edge Case Tests =="
  testEdgeCases()
  
  # Additional benchmarks would be run here
  
  echo "\nBenchmark complete!"