# Debug Insert-Delete Transform

## Input Operations
- doc: "abcde" (length 5)
- op1: [retain(2), insert("xyz"), retain(3)]
  - Produces: "abxyzcde" (length 8)
- op2: [retain(1), delete(3), retain(1)]
  - Produces: "ae" (length 2)

## Step-by-Step Transformation

Initial state:
- aIndex = 0, bIndex = 0
- aOp = retain(2), bOp = retain(1)

### Step 1: retain(2) vs retain(1)
- Take min(2,1) = 1
- aResult += retain(1)
- bResult += retain(1)
- aRemaining = retain(1)
- bIndex++ → bOp = delete(3)

### Step 2: retain(1) vs delete(3)
- A retains while B deletes
- Take min(1,3) = 1
- aResult += delete(1)
- bResult gets nothing
- aIndex++ → aOp = insert("xyz")
- bRemaining = delete(2)

### Step 3: insert("xyz") vs delete(2)
- A inserts while B deletes
- aResult += insert("xyz")
- bResult += retain(3)  ← This is the issue!
- aIndex++ → aOp = retain(3)
- bRemaining = delete(2)

The issue is in Step 3. When A inserts during B's delete:
- The insert should go through to aResult ✓
- But bResult shouldn't just retain the insert length
- B's delete operation should continue after accounting for the insert

## What Should Happen

After transforming:
- op1' should transform "ae" to "axyze"
  - Operations: [retain(1), insert("xyz"), retain(1)]
- op2' should transform "abxyzcde" to "axyze"
  - Operations: [retain(1), delete(1), retain(3), delete(2), retain(1)]

## Current Algorithm Issue

The algorithm treats insert as atomic and makes the other operation retain it entirely. But when an insert happens during a delete, the delete should be "split" around the insert:
1. Delete up to the insert point
2. Retain the inserted content
3. Continue deleting after the insert

The current algorithm just does step 2, missing steps 1 and 3.