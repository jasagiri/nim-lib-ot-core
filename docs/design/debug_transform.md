# Transform Algorithm Debug

## Test Case: Insert-Delete
- Original: "abcde"
- op1: retain(2), insert("xyz"), retain(3) → "abxyzcde"
- op2: retain(1), delete(3), retain(1) → "ae"
- Expected final result: "axyze"

## What should the transformed operations be?

### op1' (applied to "ae" to get "axyze"):
- Start: "ae"
- retain(1): Keep "a"
- insert("xyz"): Insert "xyz" → "axyze"
- retain(1): Keep "e"
- Result: "axyze" ✓

So op1' should be: [(retain 1), (insert "xyz"), (retain 1)]

### op2' (applied to "abxyzcde" to get "axyze"):
- Start: "abxyzcde"
- retain(1): Keep "a"
- delete(1): Delete "b" → "axyzcde"
- retain(3): Keep "xyz" → "axyzcde" (unchanged)
- delete(2): Delete "cd" → "axyze"
- retain(1): Keep "e"
- Result: "axyze" ✓

So op2' should be: [(retain 1), (delete 1), (retain 3), (delete 2), (retain 1)]

## Current algorithm output:
- op1': [(retain 5)] - WRONG!
- op2': [(retain 1), (delete 1), (insert "xyz"), (delete 2), (retain 1)] - Has insert, which is wrong!

## Analysis of the algorithm:

The current algorithm processes operations pairwise:
1. retain(2) vs retain(1) → min(2,1)=1, both retain 1
2. retain(1) vs delete(3) → A retains 1, B deletes, so A' deletes 1
3. insert("xyz") vs delete(2) → A inserts, B deletes remaining
4. retain(3) vs delete(2) → A retains 3, B still deleting
5. retain(1) vs retain(1) → both retain 1

The issue is in step 3: when A inserts and B deletes, the algorithm adds:
- To A': insert("xyz")
- To B': retain(3) 

But B' shouldn't retain the insert! It should continue with its delete operation adjusted for the insert.