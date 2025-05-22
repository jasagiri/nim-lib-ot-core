## Basic usage example of the nim-lib-ot-core library

import ../src/nim_lib_ot_core/types
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/client
import ../src/nim_lib_ot_core/server
import ../src/nim_lib_ot_core/cursor
import ../src/nim_lib_ot_core/history

proc buildOp(op: proc(o: var TextOperation)): TextOperation =
  var operation = newTextOperation()
  op(operation)
  result = operation

proc example_basic_operations() =
  echo "--- Basic Operations Example ---"
  
  # Create a document
  let doc = newDocument("Hello world")
  echo "Initial document: ", doc.content
  
  # Create an operation to insert " beautiful" after "Hello"
  var op = newTextOperation()
  op.retain(5)
  op.insert(" beautiful")
  op.retain(6)
  
  # Apply the operation
  let result = doc.apply(op)
  if result.isOk:
    echo "Document after insert: ", result.get().content
  else:
    echo "Failed to apply operation: ", result.error
  
  # Create an operation to delete "beautiful "
  var op2 = buildOp(proc(o: var TextOperation) =
    o.retain(6)
    o.delete(10)
    o.retain(6)
  )
  
  # Apply the second operation
  let doc2 = result.get()
  let result2 = doc2.apply(op2)
  if result2.isOk:
    echo "Document after delete: ", result2.get().content
  else:
    echo "Failed to apply operation: ", result2.error

proc example_transform() =
  echo "\n--- Transform Example ---"
  
  # Create a document
  let doc = newDocument("Hello world")
  echo "Initial document: ", doc.content
  
  # User 1 inserts " beautiful" after "Hello"
  let op1 = buildOp(proc(o: var TextOperation) =
    o.retain(5)
    o.insert(" beautiful")
    o.retain(6)
  )
  
  # User 2 inserts " amazing" after "Hello"
  let op2 = buildOp(proc(o: var TextOperation) =
    o.retain(5)
    o.insert(" amazing")
    o.retain(6)
  )
  
  # Transform the operations
  let transformResult = transform(op1, op2)
  if transformResult.isOk:
    let (op1prime, op2prime) = transformResult.get()
    
    # Apply in one order
    let result1 = doc.apply(op1)
    if result1.isOk:
      let result1a = result1.get().apply(op2prime)
      if result1a.isOk:
        echo "Applied op1 then op2': ", result1a.get().content
    
    # Apply in another order
    let result2 = doc.apply(op2)
    if result2.isOk:
      let result2a = result2.get().apply(op1prime)
      if result2a.isOk:
        echo "Applied op2 then op1': ", result2a.get().content
    
    # Both should yield the same result (convergence)
  else:
    echo "Failed to transform: ", transformResult.error

proc example_client_server() =
  echo "\n--- Client-Server Example ---"
  
  let initialText = "Hello world"
  
  # Set up server
  let server = newOTServer(initialText)
  let clientId1 = "client1"
  let clientId2 = "client2"
  discard server.registerClient(clientId1)
  discard server.registerClient(clientId2)
  
  echo "Server initialized with: ", server.getDocument().content
  
  # Set up clients
  let client1 = newOTClient(initialText)
  let client2 = newOTClient(initialText)
  
  # Client 1 makes an edit
  let op1 = buildOp(proc(o: var TextOperation) =
    o.retain(5)
    o.insert(" beautiful")
    o.retain(6)
  )
  
  let clientResult1 = client1.applyLocal(op1)
  if clientResult1.isOk:
    echo "Client 1 document: ", client1.document.content
    
    # Send to server
    let serverResult = server.receiveOperation(clientId1, clientResult1.get(), 0)
    if serverResult.isOk:
      let (transformedOp, revision) = serverResult.get()
      echo "Server document: ", server.getDocument().content
      
      # Server broadcasts to client 2
      let broadcasts = server.broadcast(clientId1, transformedOp, revision)
      for broadcast in broadcasts:
        if broadcast.clientId == clientId2:
          let client2Result = client2.applyServer(broadcast.op, revision)
          if client2Result.isOk:
            echo "Client 2 document: ", client2.document.content
  
  # Client 2 makes an edit
  let op2 = buildOp(proc(o: var TextOperation) =
    o.retain(12)
    o.insert(" amazing")
    o.retain(6)
  )
  
  let clientResult2 = client2.applyLocal(op2)
  if clientResult2.isOk:
    echo "Client 2 document after local edit: ", client2.document.content
    
    # Send to server
    let serverResult = server.receiveOperation(clientId2, clientResult2.get(), 1)
    if serverResult.isOk:
      let (transformedOp, revision) = serverResult.get()
      echo "Server document: ", server.getDocument().content
      
      # Server broadcasts to client 1
      let broadcasts = server.broadcast(clientId2, transformedOp, revision)
      for broadcast in broadcasts:
        if broadcast.clientId == clientId1:
          let client1Result = client1.applyServer(broadcast.op, revision)
          if client1Result.isOk:
            echo "Client 1 document after remote edit: ", client1.document.content

proc example_cursor_transformation() =
  echo "\n--- Cursor Transformation Example ---"
  
  let doc = newDocument("Hello world")
  var cursorPos = 5  # Cursor after "Hello"
  
  echo "Initial document: ", doc.content
  echo "Initial cursor position: ", cursorPos
  
  # Create an operation to insert " beautiful" at cursor position
  let op = buildOp(proc(o: var TextOperation) =
    o.retain(5)
    o.insert(" beautiful")
    o.retain(6)
  )
  
  # Transform cursor
  let newCursorPos = transformCursor(cursorPos, op, true)  # true because it's our own operation
  
  # Apply operation
  let result = doc.apply(op)
  if result.isOk:
    echo "Document after insert: ", result.get().content
    echo "New cursor position: ", newCursorPos
  
  # Another user inserts " and amazing" at position 16 (after "beautiful")
  let op2 = buildOp(proc(o: var TextOperation) =
    o.retain(16)
    o.insert(" and amazing")
    o.retain(6)
  )
  
  # Transform cursor through other user's operation
  let newerCursorPos = transformCursor(newCursorPos, op2, false)  # false because it's not our operation
  
  # Apply operation
  let result2 = result.get().apply(op2)
  if result2.isOk:
    echo "Document after second insert: ", result2.get().content
    echo "Final cursor position: ", newerCursorPos

proc example_undo_redo() =
  echo "\n--- Undo/Redo Example ---"
  
  let doc = newDocument("Hello world")
  let history = newEditHistory(doc)
  
  echo "Initial document: ", history.document.content
  
  # Make first edit
  let op1 = buildOp(proc(o: var TextOperation) =
    o.retain(5)
    o.insert(" beautiful")
    o.retain(6)
  )
  
  discard history.pushOperation(op1)
  echo "After first edit: ", history.document.content
  
  # Make second edit
  let op2 = buildOp(proc(o: var TextOperation) =
    o.retain(16)
    o.insert(" and amazing")
    o.retain(6)
  )
  
  discard history.pushOperation(op2)
  echo "After second edit: ", history.document.content
  
  # Undo last edit
  if history.canUndo():
    let undoResult = history.undo()
    if undoResult.isOk:
      echo "After undo: ", history.document.content
  
  # Redo
  if history.canRedo():
    let redoResult = history.redo()
    if redoResult.isOk:
      echo "After redo: ", history.document.content
  
  # Undo both edits
  if history.canUndo():
    discard history.undo()
    echo "After undo first edit again: ", history.document.content
  
  if history.canUndo():
    discard history.undo()
    echo "After undo second edit: ", history.document.content
  
  echo "Undo stack size: ", history.undoCount()
  echo "Redo stack size: ", history.redoCount()

when isMainModule:
  example_basic_operations()
  example_transform()
  example_client_server()
  example_cursor_transformation()
  example_undo_redo()