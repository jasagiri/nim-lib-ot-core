## Cursor transformation for OT
## Handles cursor position tracking through operations

import ./types

proc transformCursor*(cursor: int, op: TextOperation, isOwn: bool = false): int =
  ## Transform a cursor position through an operation
  ## If isOwn is true, the cursor is from the same source as the operation
  result = cursor
  var index = 0
  
  for o in op.ops:
    case o.kind
    of opRetain:
      index += o.n
    
    of opInsert:
      # Insert shifts cursor position if it's at or after the insertion point
      if cursor >= index:
        # When cursor == index, tie-breaking depends on isOwn
        # If isOwn is true and cursor is at insert position, it moves after the insert
        if cursor > index or (cursor == index and isOwn):
          result += o.s.len
      # The index doesn't advance through the original text for inserts
      # index += o.s.len  # WRONG - inserts don't consume from original text
    
    of opDelete:
      # Delete pulls cursor back if it's after the deletion
      if cursor > index:
        # Cursor is within or after delete
        if cursor >= index + o.n:
          # Cursor is after delete
          result -= o.n
        else:
          # Cursor is within delete - move to delete position
          result = index
      # Delete consumes from original text
      index += o.n

proc transformCursors*(cursors: seq[int], op: TextOperation, isOwn: bool = false): seq[int] =
  ## Transform multiple cursor positions through an operation
  result = newSeq[int](cursors.len)
  for i, cursor in cursors:
    result[i] = transformCursor(cursor, op, isOwn)