## History management for undo/redo functionality
## Tracks operation history and provides undo/redo capabilities

import ./types
import ./operations
import options
import results
export results
import json
import times

const 
  MAX_HISTORY_SIZE = 100

type
  HistoryError* = enum
    NothingToUndo = "Nothing to undo"
    NothingToRedo = "Nothing to redo"
    OperationInvalid = "Operation is invalid"
  
  HistoryResult*[T] = Result[T, HistoryError]
  
  HistoryEntry* = object
    ## A single operation in the history
    operation*: TextOperation         # Operation that was applied
    inverse*: TextOperation          # Inverse operation for undo
    timestamp*: int64                # When the operation was applied
    metadata*: JsonNode              # Optional metadata (e.g., author info)
  
  EditHistory* = ref object
    ## Tracks document operation history for undo/redo
    document*: Document
    undoStack*: seq[HistoryEntry]    # Operations that can be undone
    redoStack*: seq[HistoryEntry]    # Operations that were undone and can be redone
    maxSize*: int                    # Maximum history size

proc newEditHistory*(initialDoc: Document, maxSize: int = MAX_HISTORY_SIZE): EditHistory =
  ## Create a new edit history for a document
  EditHistory(
    document: initialDoc,
    undoStack: @[],
    redoStack: @[],
    maxSize: maxSize
  )

proc pushOperation*(history: EditHistory, op: TextOperation, metadata: JsonNode = nil): HistoryResult[void] =
  ## Add an operation to the history
  
  # Validate operation
  let validateResult = op.validate()
  if validateResult.isErr:
    return err(OperationInvalid)
  
  # Apply the operation
  let applyResult = history.document.apply(op)
  if applyResult.isErr:
    return err(OperationInvalid)
  
  # Create inverse operation for undo
  let inverseResult = invert(op, history.document)
  if inverseResult.isErr:
    return err(OperationInvalid)
  let inverse = inverseResult.get()
  
  # Update the document
  history.document = applyResult.get()
  
  # Create history entry
  let entry = HistoryEntry(
    operation: op,
    inverse: inverse,
    timestamp: getTime().toUnix(),
    metadata: metadata
  )
  
  # Add to undo stack
  history.undoStack.add(entry)
  
  # Clear redo stack since we've made a new change
  history.redoStack = @[]
  
  # Trim history if needed
  if history.undoStack.len > history.maxSize:
    history.undoStack.delete(0)
  
  ok()

proc undo*(history: EditHistory): HistoryResult[Document] =
  ## Undo the last operation
  if history.undoStack.len == 0:
    return err(NothingToUndo)
  
  # Get the last operation
  let lastEntry = history.undoStack.pop()
  
  # Apply the inverse operation
  let applyResult = history.document.apply(lastEntry.inverse)
  if applyResult.isErr:
    # This shouldn't happen with properly formed inverse operations
    # But just in case, we'll restore the entry to the undo stack
    history.undoStack.add(lastEntry)
    return err(OperationInvalid)
  
  # Update document
  history.document = applyResult.get()
  
  # Add to redo stack
  history.redoStack.add(lastEntry)
  
  # Trim redo stack if needed
  if history.redoStack.len > history.maxSize:
    history.redoStack.delete(0)
  
  ok(history.document)

proc redo*(history: EditHistory): HistoryResult[Document] =
  ## Redo the last undone operation
  if history.redoStack.len == 0:
    return err(NothingToRedo)
  
  # Get the last undone operation
  let lastEntry = history.redoStack.pop()
  
  # Apply the original operation
  let applyResult = history.document.apply(lastEntry.operation)
  if applyResult.isErr:
    # This shouldn't happen with properly formed operations
    # But just in case, we'll restore the entry to the redo stack
    history.redoStack.add(lastEntry)
    return err(OperationInvalid)
  
  # Update document
  history.document = applyResult.get()
  
  # Add back to undo stack
  history.undoStack.add(lastEntry)
  
  ok(history.document)

proc canUndo*(history: EditHistory): bool =
  ## Check if an undo operation is available
  history.undoStack.len > 0

proc canRedo*(history: EditHistory): bool =
  ## Check if a redo operation is available
  history.redoStack.len > 0

proc peekUndo*(history: EditHistory): Option[HistoryEntry] =
  ## Look at the operation that would be undone next
  if history.undoStack.len == 0:
    none(HistoryEntry)
  else:
    some(history.undoStack[^1])

proc peekRedo*(history: EditHistory): Option[HistoryEntry] =
  ## Look at the operation that would be redone next
  if history.redoStack.len == 0:
    none(HistoryEntry)
  else:
    some(history.redoStack[^1])

proc undoCount*(history: EditHistory): int =
  ## Get the number of operations that can be undone
  history.undoStack.len

proc redoCount*(history: EditHistory): int =
  ## Get the number of operations that can be redone
  history.redoStack.len

proc clear*(history: EditHistory) =
  ## Clear the history
  history.undoStack = @[]
  history.redoStack = @[]