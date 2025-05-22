## Basic operations for Operational Transformation

import ./types
import std/[unicode, options]
import results

proc charLen*(s: string): int =
  ## UTF-8 aware character length
  s.runeLen


proc substring*(s: string, start: int, length: int = -1): string =
  ## UTF-8 aware substring
  var runeStart = 0
  var byteStart = 0
  
  # Find byte position of start
  while runeStart < start and byteStart < s.len:
    var r: Rune
    fastRuneAt(s, byteStart, r)
    inc runeStart
  
  if length == -1:
    return s[byteStart..^1]
  
  # Find byte position of end
  var runeEnd = runeStart
  var byteEnd = byteStart
  while runeEnd < runeStart + length and byteEnd < s.len:
    var r: Rune
    fastRuneAt(s, byteEnd, r)
    inc runeEnd
  
  return s[byteStart..<byteEnd]

proc normalizeOps*(ops: seq[Operation]): seq[Operation] =
  ## Normalize operations by merging consecutive same-type operations
  if ops.len == 0:
    return @[]
  
  result = @[]
  var current = ops[0]
  
  for i in 1..<ops.len:
    let op = ops[i]
    if current.kind == op.kind:
      case current.kind
      of opRetain, opDelete:
        current.n += op.n
      of opInsert:
        current.s &= op.s
    else:
      if not current.isNoop:
        result.add(current)
      current = op
  
  if not current.isNoop:
    result.add(current)

proc addOp*(textOp: var TextOperation, op: Operation) =
  ## Add an operation to the text operation
  if op.isNoop:
    return
  
  case op.kind
  of opRetain:
    textOp.baseLength += op.n
    textOp.targetLength += op.n
  of opInsert:
    textOp.targetLength += op.s.charLen
  of opDelete:
    textOp.baseLength += op.n
  
  textOp.ops.add(op)

proc retain*(textOp: var TextOperation, n: int) =
  ## Add a retain operation
  textOp.addOp(retain(n))

proc insert*(textOp: var TextOperation, s: string) =
  ## Add an insert operation
  textOp.addOp(insert(s))

proc delete*(textOp: var TextOperation, n: int) =
  ## Add a delete operation
  textOp.addOp(delete(n))

proc apply*(doc: Document, textOp: TextOperation): OpResult[Document] =
  ## Apply a text operation to a document
  let validation = textOp.validate()
  if validation.isErr:
    return err(validation.error)
  
  if doc.content.charLen != textOp.baseLength:
    return err(LengthMismatch)
  
  var newContent = ""
  var index = 0
  
  for op in textOp.ops:
    case op.kind
    of opRetain:
      if index + op.n > doc.content.charLen:
        return err(IndexOutOfBounds)
      newContent &= doc.content.substring(index, op.n)
      index += op.n
    
    of opInsert:
      newContent &= op.s
    
    of opDelete:
      if index + op.n > doc.content.charLen:
        return err(IndexOutOfBounds)
      index += op.n
  
  # Add any remaining content
  if index < doc.content.charLen:
    newContent &= doc.content.substring(index)
  
  ok(Document(content: newContent, version: doc.version + 1))

proc compose*(a, b: TextOperation): OpResult[TextOperation] =
  ## Compose two operations into a single operation
  if a.targetLength != b.baseLength:
    return err(InvalidComposition)
  
  var composed = newTextOperation()
  var aIndex = 0
  var bIndex = 0
  
  var aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
  var bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
  
  while aOp.isSome or bOp.isSome:
    if aOp.isSome and aOp.get.kind == opDelete:
      composed.addOp(aOp.get)
      aIndex += 1
      aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
      continue
    
    if bOp.isSome and bOp.get.kind == opInsert:
      composed.addOp(bOp.get)
      bIndex += 1
      bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
      continue
    
    if aOp.isNone or bOp.isNone:
      return err(InvalidComposition)
    
    let opA = aOp.get
    let opB = bOp.get
    
    if opA.kind == opRetain and opB.kind == opRetain:
      let n = min(opA.n, opB.n)
      composed.retain(n)
      
      if opA.n > n:
        aOp = some(retain(opA.n - n))
      else:
        aIndex += 1
        aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
      
      if opB.n > n:
        bOp = some(retain(opB.n - n))
      else:
        bIndex += 1
        bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
    
    elif opA.kind == opInsert and opB.kind == opRetain:
      let n = min(opA.s.charLen, opB.n)
      composed.insert(opA.s.substring(0, n))
      
      if opA.s.charLen > n:
        aOp = some(insert(opA.s.substring(n)))
      else:
        aIndex += 1
        aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
      
      if opB.n > n:
        bOp = some(retain(opB.n - n))
      else:
        bIndex += 1
        bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
    
    elif opA.kind == opInsert and opB.kind == opDelete:
      let n = min(opA.s.charLen, opB.n)
      
      if opA.s.charLen > n:
        aOp = some(insert(opA.s.substring(n)))
      else:
        aIndex += 1
        aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
      
      if opB.n > n:
        bOp = some(delete(opB.n - n))
      else:
        bIndex += 1
        bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
    
    elif opA.kind == opRetain and opB.kind == opDelete:
      let n = min(opA.n, opB.n)
      composed.delete(n)
      
      if opA.n > n:
        aOp = some(retain(opA.n - n))
      else:
        aIndex += 1
        aOp = if aIndex < a.ops.len: some(a.ops[aIndex]) else: none(Operation)
      
      if opB.n > n:
        bOp = some(delete(opB.n - n))
      else:
        bIndex += 1
        bOp = if bIndex < b.ops.len: some(b.ops[bIndex]) else: none(Operation)
    
    else:
      return err(InvalidComposition)
  
  composed.ops = normalizeOps(composed.ops)
  ok(composed)

proc invert*(textOp: TextOperation, doc: Document): OpResult[TextOperation] =
  ## Invert an operation relative to a document
  if doc.content.charLen != textOp.baseLength:
    return err(LengthMismatch)
  
  var inverted = newTextOperation()
  var index = 0
  
  for op in textOp.ops:
    case op.kind
    of opRetain:
      inverted.retain(op.n)
      index += op.n
    
    of opInsert:
      inverted.delete(op.s.charLen)
    
    of opDelete:
      if index + op.n > doc.content.charLen:
        return err(IndexOutOfBounds)
      inverted.insert(doc.content.substring(index, op.n))
      index += op.n
  
  ok(inverted)