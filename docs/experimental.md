# Experimental Implementations

This document describes the experimental implementations available in nim-lib-ot and how to use them.

## Overview

The nim-lib-ot library includes several experimental implementations of the Operational Transformation algorithms, primarily for research, debugging, and performance comparison purposes. These implementations are located in the `src/nim_lib_ot/experimental` directory.

## Available Implementations

### Alternative Transform (`transform_alt.nim`)

This implementation takes a different approach to the transformation algorithm, focusing on clarity and readability. It may handle certain edge cases differently from the main implementation.

Key characteristics:
- More explicit state handling
- Different control flow for processing operations
- Potentially better handling of specific edge cases
- May have different performance characteristics

### Debug Transform (`transform_debug.nim`)

A debug-focused implementation that produces detailed logs of each step in the transformation process. This is invaluable for understanding how the algorithm works and for diagnosing issues in complex transformation scenarios.

Features:
- Detailed step-by-step logging
- Visualization of operation processing
- Explicit state tracking
- Configurable debugging output

### Benchmarking Tools (`benchmark.nim`)

A utility module for benchmarking and comparing different transform implementations. It provides tools for:
- Generating random operations for testing
- Timing the performance of different implementations
- Testing specific edge cases
- Comparing transformation results for correctness

## Usage Examples

### Using Alternative Transform

```nim
import nim_lib_ot/types
import nim_lib_ot/operations
import nim_lib_ot/experimental/transform_alt as transform

# Create operations
var op1 = newTextOperation()
op1.retain(3)
op1.insert("hello")
op1.retain(5)

var op2 = newTextOperation()
op2.retain(5)
op2.delete(2)
op2.retain(1)

# Transform using alternative implementation
let result = transform(op1, op2)
if result.isOk:
  let (op1prime, op2prime) = result.get()
  # Use transformed operations...
```

### Debugging Transformations

```nim
import nim_lib_ot/types
import nim_lib_ot/operations
import nim_lib_ot/experimental/transform_debug

# Create operations
var op1 = newTextOperation()
op1.insert("A")
op1.retain(5)

var op2 = newTextOperation()
op2.insert("B")
op2.retain(5)

# Transform with debug output
let result = transform(op1, op2, debug=true)
if result.isOk:
  let (op1prime, op2prime) = result.get()
  # Use transformed operations...
```

### Running Benchmarks

```nim
import nim_lib_ot/experimental/benchmark

# Run benchmarks with 1000 random operations
let (stdTime, altTime) = benchmarkTransform(1000)
echo "Performance ratio: ", altTime/stdTime

# Test edge cases
testEdgeCases()
```

## When to Use Experimental Implementations

Consider using these experimental implementations in the following scenarios:

1. **Debugging Issues**: When you encounter unexpected behavior in the transformation process, the debug implementation can help identify the cause.

2. **Education and Understanding**: For learning about OT algorithms, the debug and alternative implementations provide valuable insights.

3. **Performance Optimization**: If performance is critical in your application, you may want to benchmark different implementations to find the one that works best for your specific use case.

4. **Edge Cases**: If you're dealing with complex operational transformation scenarios, the alternative implementation might handle certain edge cases better.

## Caution

These experimental implementations are not guaranteed to be as thoroughly tested as the main implementation. They may contain bugs or inconsistencies that could affect the correctness of your application. Use them with caution in production environments.

If you discover improvements or optimizations in the experimental implementations that you believe should be incorporated into the main implementation, please consider contributing them back to the library.