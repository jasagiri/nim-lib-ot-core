# Correct Transformation for Insert-Delete

## Input
- doc: "abcde"
- op1: retain(2), insert("xyz"), retain(3) → "abxyzcde"  
- op2: retain(1), delete(3), retain(1) → "ae"

## Expected Result
If we apply both operations, the result should be "axyze":
- Keep "a"
- Delete "bcd" but insert "xyz" after "b" position
- Keep "e"

## Required Transformed Operations

### op1' (transforms "ae" to "axyze")
- Input: "ae" (length 2)
- Output: "axyze" (length 5)
- Operations: retain(1), insert("xyz"), retain(1)

### op2' (transforms "abxyzcde" to "axyze")
- Input: "abxyzcde" (length 8)
- Output: "axyze" (length 5)
- Operations: retain(1), delete(1), retain(3), delete(2), retain(1)

## Current Algorithm Output
- op1': [(retain 5)]
- op2': [(retain 1), (delete 1), (insert "xyz"), (delete 2), (retain 1)]

The swapping is correct (op1' and op2' are swapped), but the content is wrong.

## Issue Analysis

Looking at the raw output before swap:
- aResult: [(retain 1), (delete 1), (insert "xyz"), (delete 2), (retain 1)]
- bResult: [(retain 5)]

This looks correct! But after swapping:
- op1p gets bResult → [(retain 5)]
- op2p gets aResult → [(retain 1), (delete 1), (insert "xyz"), (delete 2), (retain 1)]

The base lengths are:
- op1p.baseLength = 2 (correct - it takes "ae")
- op2p.baseLength = 8 (correct - it takes "abxyzcde")

But [(retain 5)] can't be applied to a document of length 2!

## The Real Issue

The algorithm is producing the correct operations but not adjusting them properly for the swapped context. The bResult [(retain 5)] was built assuming it would be applied after op1 (which produces "abxyzcde" of length 8), but after swapping it's being applied after op2 (which produces "ae" of length 2).

The solution is to not swap, or to adjust the operations after swapping to match their new contexts.