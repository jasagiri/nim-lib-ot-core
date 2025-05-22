# Transform Analysis for Insert-Delete

## Input Operations
- op1: retain(2), insert("xyz"), retain(3) on "abcde"
- op2: retain(1), delete(3), retain(1) on "abcde"

## Step-by-step Analysis

### Initial State
- Document: "abcde" 
- Position in op1: 0
- Position in op2: 0

### Step 1: retain(2) vs retain(1)
- Take min(2,1) = 1
- Both operations retain 1
- op1' gets: retain(1)
- op2' gets: retain(1)
- Remaining: op1 has retain(1), op2 moves to delete(3)

### Step 2: retain(1) vs delete(3)
- op1 retains while op2 deletes
- op1' gets: delete(1) (deletes what op2 deletes)
- op2' gets: nothing (op1 doesn't change anything)
- Remaining: op1 moves to insert("xyz"), op2 has delete(2)

### Step 3: insert("xyz") vs delete(2)
- op1 inserts while op2 deletes
- This is the key case!
- op1' gets: insert("xyz") (insert happens)
- op2' should get: retain(3) then continue deleting
- But that's not right...

## The Issue

The current algorithm produces:
- op1': retain(1), delete(1), insert("xyz"), delete(2), retain(1)
- op2': retain(5)

But op1' has base operations totaling 5, while it should have base 2 (the length of "ae").

## Correct Transformation

For op1' (transforms "ae" to "axyze"):
- retain(1) - keep "a"
- insert("xyz") - insert the text
- retain(1) - keep "e"
Total: retain(1) + retain(1) = base length 2 ✓

For op2' (transforms "abxyzcde" to "axyze"):
- retain(1) - keep "a"
- delete(1) - delete "b"
- retain(3) - keep "xyz"
- delete(2) - delete "cd"
- retain(1) - keep "e"
Total: retain(1) + delete(1) + retain(3) + delete(2) + retain(1) = base length 8 ✓

## The Root Cause

The algorithm is not correctly handling the case where an insert happens in the middle of a delete operation. It needs to track positions more carefully and split operations appropriately.