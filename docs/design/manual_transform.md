# Manual Transform Calculation

## Input
- doc: "abcde"
- op1: retain(2), insert("xyz"), retain(3) → "abxyzcde"
- op2: retain(1), delete(3), retain(1) → "ae"

## Step-by-Step Manual Calculation

### Understanding the Operations

op1 transforms "abcde" to "abxyzcde":
- retain(2): Keep "ab"
- insert("xyz"): Insert "xyz"
- retain(3): Keep "cde"
- Result: "ab" + "xyz" + "cde" = "abxyzcde"

op2 transforms "abcde" to "ae":
- retain(1): Keep "a"
- delete(3): Delete "bcd"
- retain(1): Keep "e"
- Result: "a" + "" + "e" = "ae"

### Computing op1' (transforms "ae" to final result)

Starting with "ae" after op2:
- Position 0: "a" - what does op1 do here? retain(2) covers positions 0-1
  - Position 0 is retained by op1, and kept by op2 → retain in op1'
- Position 1: "e" - this was originally position 4 in "abcde"
  - Position 4 is covered by op1's retain(3) at the end
  - So we retain this too
- But wait, op1 inserts "xyz" after position 1 (after "b")
  - In the context of "ae", the insert should happen after "a"

So op1' should be:
- retain(1): Keep "a"
- insert("xyz"): Insert "xyz"
- retain(1): Keep "e"

This gives us: "a" + "xyz" + "e" = "axyze" ✓

### Computing op2' (transforms "abxyzcde" to final result)

Starting with "abxyzcde" after op1:
- Position 0: "a" - retained by op2 → retain
- Position 1: "b" - deleted by op2 → delete
- Position 2-4: "xyz" - these are inserted by op1, op2 doesn't know about them → retain
- Position 5: "c" - deleted by op2 (was position 2) → delete
- Position 6: "d" - deleted by op2 (was position 3) → delete
- Position 7: "e" - retained by op2 → retain

So op2' should be:
- retain(1): Keep "a"
- delete(1): Delete "b"
- retain(3): Keep "xyz"
- delete(2): Delete "cd"
- retain(1): Keep "e"

This gives us: "a" + "" + "xyz" + "" + "e" = "axyze" ✓

## The Correct Results

- op1': [retain(1), insert("xyz"), retain(1)]
- op2': [retain(1), delete(1), retain(3), delete(2), retain(1)]