## Performance benchmarks for nim-lib-ot-core library

import ../src/nim_lib_ot_core/types
import ../src/nim_lib_ot_core/operations
import ../src/nim_lib_ot_core/transform
import ../src/nim_lib_ot_core/client
import ../src/nim_lib_ot_core/server
import ../src/nim_lib_ot_core/history
import times
import random
import strformat

const 
  ITERATIONS = 1000
  DOC_SIZE = 10000

proc generateRandomString(length: int): string =
  result = newString(length)
  for i in 0..<length:
    result[i] = char(rand(26) + ord('a'))

proc generateRandomInsertOperation(doc: Document): TextOperation =
  var op = newTextOperation()
  let pos = rand(doc.content.len)
  if pos > 0:
    op.retain(pos)
  op.insert(generateRandomString(rand(5) + 1))
  if doc.content.len - pos > 0:
    op.retain(doc.content.len - pos)
  result = op

proc generateRandomDeleteOperation(doc: Document): TextOperation =
  var op = newTextOperation()
  let pos = rand(doc.content.len)
  if pos > 0:
    op.retain(pos)
  let deleteLen = min(rand(10) + 1, doc.content.len - pos)
  if deleteLen > 0:
    op.delete(deleteLen)
  if doc.content.len - pos - deleteLen > 0:
    op.retain(doc.content.len - pos - deleteLen)
  result = op

proc generateRandomOperation(doc: Document): TextOperation =
  if rand(1.0) < 0.7:  # 70% chance of insert
    return generateRandomInsertOperation(doc)
  else:
    return generateRandomDeleteOperation(doc)

proc benchmarkApply() =
  echo "Benchmarking apply operations..."
  let initialDoc = newDocument(generateRandomString(DOC_SIZE))
  var doc = initialDoc
  
  let start = cpuTime()
  for i in 1..ITERATIONS:
    let op = generateRandomOperation(doc)
    let result = doc.apply(op)
    if result.isOk:
      doc = result.get()
    else:
      echo "Apply failed at iteration ", i
  
  let duration = cpuTime() - start
  echo &"Applied {ITERATIONS} operations in {duration:.6f} seconds"
  echo &"Average time per operation: {(duration / float(ITERATIONS)) * 1000:.6f} ms"

proc benchmarkTransform() =
  echo "\nBenchmarking transform operations..."
  let initialDoc = newDocument(generateRandomString(DOC_SIZE))
  var operations: seq[TextOperation] = @[]
  
  # Generate operations
  for i in 1..ITERATIONS:
    operations.add(generateRandomOperation(initialDoc))
  
  let start = cpuTime()
  for i in 0..<ITERATIONS-1:
    let a = operations[i]
    let b = operations[i+1]
    discard transform(a, b)
  
  let duration = cpuTime() - start
  echo &"Transformed {ITERATIONS-1} operation pairs in {duration:.6f} seconds"
  echo &"Average time per transform: {(duration / float(ITERATIONS-1)) * 1000:.6f} ms"

proc benchmarkCompose() =
  echo "\nBenchmarking compose operations..."
  let initialDoc = newDocument(generateRandomString(DOC_SIZE))
  var operations: seq[TextOperation] = @[]
  
  # Generate operations
  for i in 1..ITERATIONS:
    operations.add(generateRandomOperation(initialDoc))
  
  let start = cpuTime()
  var composed = operations[0]
  for i in 1..<ITERATIONS:
    let composeResult = compose(composed, operations[i])
    if composeResult.isOk:
      composed = composeResult.get()
    else:
      echo "Compose failed at iteration ", i
  
  let duration = cpuTime() - start
  echo &"Composed {ITERATIONS} operations in {duration:.6f} seconds"
  echo &"Average time per compose: {(duration / float(ITERATIONS-1)) * 1000:.6f} ms"

proc benchmarkClientServer() =
  echo "\nBenchmarking client-server operations..."
  let initialContent = generateRandomString(DOC_SIZE)
  let server = newOTServer(initialContent)
  let clients = 5
  var clientObjs: seq[OTClient] = @[]
  var clientIds: seq[string] = @[]
  
  # Set up clients
  for i in 1..clients:
    let clientId = "client" & $i
    clientIds.add(clientId)
    clientObjs.add(newOTClient(initialContent))
    discard server.registerClient(clientId)
  
  let start = cpuTime()
  for i in 1..ITERATIONS div clients:
    for c in 0..<clients:
      # Client makes an edit
      let op = generateRandomOperation(clientObjs[c].document)
      let clientResult = clientObjs[c].applyLocal(op)
      
      if clientResult.isOk:
        # Send to server
        let clientStateResult = server.getClientState(clientIds[c])
        if clientStateResult.isErr:
          continue
        
        let clientState = clientStateResult.get()
        let clientRevision = clientState.lastRevision
        let serverResult = server.receiveOperation(clientIds[c], clientResult.get(), clientRevision)
        
        if serverResult.isOk:
          let (transformedOp, revision) = serverResult.get()
          
          # Server broadcasts to other clients
          let broadcasts = server.broadcast(clientIds[c], transformedOp, revision)
          for broadcast in broadcasts:
            # Find the target client index
            var targetClientIndex = -1
            for i, id in clientIds:
              if id == broadcast.clientId:
                targetClientIndex = i
                break
            
            if targetClientIndex >= 0:
              discard clientObjs[targetClientIndex].applyServer(broadcast.op, revision)
  
  let duration = cpuTime() - start
  let totalOps = ITERATIONS
  echo &"Processed {totalOps} client-server operations in {duration:.6f} seconds"
  echo &"Average time per client-server operation: {(duration / float(totalOps)) * 1000:.6f} ms"

proc benchmarkHistory() =
  echo "\nBenchmarking history operations..."
  let initialDoc = newDocument(generateRandomString(DOC_SIZE))
  let history = newEditHistory(initialDoc)
  var operations: seq[TextOperation] = @[]
  
  # Generate operations
  for i in 1..ITERATIONS:
    operations.add(generateRandomOperation(initialDoc))
  
  let start = cpuTime()
  
  # Add all operations to history
  for i in 0..<ITERATIONS:
    discard history.pushOperation(operations[i])
  
  # Undo half the operations
  for i in 0..<(ITERATIONS div 2):
    discard history.undo()
  
  # Redo a quarter
  for i in 0..<(ITERATIONS div 4):
    discard history.redo()
  
  let duration = cpuTime() - start
  let totalOps = ITERATIONS + (ITERATIONS div 2) + (ITERATIONS div 4)
  echo &"Processed {totalOps} history operations in {duration:.6f} seconds"
  echo &"Average time per history operation: {(duration / float(totalOps)) * 1000:.6f} ms"

when isMainModule:
  randomize()
  echo "=== nim-lib-ot-core Performance Benchmark ==="
  echo &"Running {ITERATIONS} iterations with document size {DOC_SIZE}"
  
  benchmarkApply()
  benchmarkTransform()
  benchmarkCompose()
  benchmarkClientServer()
  benchmarkHistory()