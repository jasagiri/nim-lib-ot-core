# Manual Walk Through Insert-Insert

## Initial State
- op1: [insert("A"), retain(5)]
- op2: [insert("B"), retain(5)]
- i1 = 0, i2 = 0
- op1Amount = 0, op2Amount = 0

## Step 1: Get first operations
- op1Amount == 0, so getNextOp(ops1, i1, op1, op1Amount)
  - i1 = 0, op1 = insert("A"), op1Amount = 0, i1++ = 1
- op1Amount == 0 (insert has no amount), check if op2Amount == 0
- op2Amount == 0, so getNextOp(ops2, i2, op2, op2Amount)
  - i2 = 0, op2 = insert("B"), op2Amount = 0, i2++ = 1

## Step 2: Process inserts
- op1.kind == opInsert, so:
  - operation1prime.insert("A")
  - operation2prime.retain(1)
  - op1Amount = 0
  - continue (back to top of loop)

## Step 3: Back at top of loop
- op1Amount == 0, so getNextOp(ops1, i1, op1, op1Amount)
  - i1 = 1, op1 = retain(5), op1Amount = 5, i1++ = 2
- Now op1Amount == 5 (not 0)
- But wait! We need to check op2Amount too
- op2Amount == 0, so getNextOp(ops2, i2, op2, op2Amount)  
  - i2 = 1, op2 = retain(5), op2Amount = 5, i2++ = 2

## The Bug!
At this point:
- op1 = retain(5)
- op2 = retain(5) (but we never processed insert("B")!)

The issue is that after processing op1's insert, we immediately get the next operations for both. This skips processing op2's insert!