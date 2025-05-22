import ../src/nim_lib_ot_core/operations  
import ../src/nim_lib_ot_core/types
import results

proc buildOp(factory: proc(op: var TextOperation)): TextOperation =
  ## Helper to build operations in tests
  result = newTextOperation()
  factory(result)

# Test case that's failing: both operations do retain 5, then insert
let op1 = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Local"))

let op2 = buildOp(proc(o: var TextOperation) =
  o.retain(5)
  o.insert(" Remote"))

echo "Input operations:"
echo "op1: base=", op1.baseLength, " target=", op1.targetLength, " ops=", op1.ops
echo "op2: base=", op2.baseLength, " target=", op2.targetLength, " ops=", op2.ops

# What the transformed operations should be:
# op1' should handle the base document (5 chars) + op2's insert (7 chars) = base length 12
# op2' should handle the base document (5 chars) + op1's insert (6 chars) = base length 11

# Create the correct transformed operations manually
var op1Prime = newTextOperation()
op1Prime.retain(5)       # Keep first 5 chars
op1Prime.insert(" Local") # Insert our text  
op1Prime.retain(7)       # Skip past op2's insert " Remote"

var op2Prime = newTextOperation()  
op2Prime.retain(5)        # Keep first 5 chars
op2Prime.retain(6)        # Skip past op1's insert " Local"
op2Prime.insert(" Remote") # Insert our text

# Set base lengths manually
op1Prime.baseLength = 12  # Original 5 + op2's insert 7
op2Prime.baseLength = 11  # Original 5 + op1's insert 6

# Calculate target lengths
op1Prime.targetLength = 18  # Base 12 + our insert 6
op2Prime.targetLength = 18  # Base 11 + our insert 7

echo "\nExpected transformed operations:"
echo "op1': base=", op1Prime.baseLength, " target=", op1Prime.targetLength, " ops=", op1Prime.ops
echo "op2': base=", op2Prime.baseLength, " target=", op2Prime.targetLength, " ops=", op2Prime.ops

# Validate
echo "\nValidating manually created operations:"
let v1 = op1Prime.validate()
if v1.isErr:
  echo "op1' validation failed: ", v1.error
else:
  echo "op1' valid"

let v2 = op2Prime.validate()
if v2.isErr:
  echo "op2' validation failed: ", v2.error
else:
  echo "op2' valid"

# Let's also test what happens if we just have the operations without trailing retains
echo "\nTesting without trailing retains:"
var op1Short = newTextOperation()
op1Short.retain(5)
op1Short.insert(" Local")
op1Short.baseLength = 5   # Just the original
op1Short.targetLength = 11

echo "op1Short: base=", op1Short.baseLength, " target=", op1Short.targetLength, " ops=", op1Short.ops

let vShort = op1Short.validate()
if vShort.isErr:
  echo "op1Short validation failed: ", vShort.error
else:
  echo "op1Short valid"