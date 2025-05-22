# Insert-Insert Transform Analysis

## Input
- doc: "hello" (length 5)
- op1: [insert("A"), retain(5)] → "Ahello"
- op2: [insert("B"), retain(5)] → "Bhello"

## Expected Result
When both are applied, final doc should be either "ABhello" or "BAhello" depending on which takes precedence.

If op1 takes precedence (aIsFirst=true):
- Apply op1: "hello" → "Ahello"
- Apply op2': "Ahello" → "ABhello"
- op2' should be: [retain(1), insert("B"), retain(5)]

If op2 takes precedence (aIsFirst=false):
- Apply op2: "hello" → "Bhello"
- Apply op1': "Bhello" → "BAhello"
- op1' should be: [retain(1), insert("A"), retain(5)]

## What the algorithm produces
- op1': [insert("A"), retain(5)] 
- op2': [retain(1), retain(5)] = [retain(6)]

This is wrong! The algorithm is treating both inserts at the beginning, so:
- op1' inserts "A" first
- op2' needs to account for the "A" by retaining it, then insert "B"

But op2' is missing the insert!

## The Bug
When op1 is an insert, the algorithm does:
```
operation1prime.insert(op1.s)
operation2prime.retain(op1.s.len)
```

This is correct. But then when op2 is an insert, it needs to be added to operation2prime, not just retained in operation1prime!