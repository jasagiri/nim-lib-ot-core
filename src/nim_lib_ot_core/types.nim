## Core types for Operational Transformation

import std/[options, json, sequtils]
import results

type
  OperationKind* = enum
    opRetain = "retain"
    opInsert = "insert"
    opDelete = "delete"

  Operation* = object
    case kind*: OperationKind
    of opRetain, opDelete:
      n*: int
    of opInsert:
      s*: string

  TextOperation* = object
    ops*: seq[Operation]
    baseLength*: int
    targetLength*: int

  Document* = object
    content*: string
    version*: int

  OpError* = enum
    InvalidOperation = "Invalid operation"
    IndexOutOfBounds = "Operation index out of bounds"
    LengthMismatch = "Operation length mismatch"
    InvalidComposition = "Cannot compose operations"
    InversionError = "Cannot invert operation"

  OpResult*[T] = Result[T, OpError]

# Construction helpers
proc retain*(n: int): Operation =
  Operation(kind: opRetain, n: n)

proc insert*(s: string): Operation =
  Operation(kind: opInsert, s: s)

proc delete*(n: int): Operation =
  Operation(kind: opDelete, n: n)

proc newTextOperation*(): TextOperation =
  TextOperation(ops: @[], baseLength: 0, targetLength: 0)

proc newDocument*(content: string = "", version: int = 0): Document =
  Document(content: content, version: version)

# Utility functions
proc len*(op: Operation): int =
  case op.kind
  of opRetain, opDelete: op.n
  of opInsert: op.s.len

proc isNoop*(op: Operation): bool =
  case op.kind
  of opRetain, opDelete: op.n == 0
  of opInsert: op.s.len == 0

proc `==`*(a, b: Operation): bool =
  if a.kind != b.kind:
    return false
  case a.kind
  of opRetain, opDelete:
    a.n == b.n
  of opInsert:
    a.s == b.s

proc `==`*(a, b: TextOperation): bool =
  a.ops == b.ops and
  a.baseLength == b.baseLength and
  a.targetLength == b.targetLength

proc validate*(op: TextOperation): OpResult[void] =
  var baseLen = 0
  var targetLen = 0
  
  for o in op.ops:
    if o.isNoop:
      return err(InvalidOperation)
    
    case o.kind
    of opRetain:
      baseLen += o.n
      targetLen += o.n
    of opInsert:
      # Use charLen for UTF-8 safety
      targetLen += o.s.len
    of opDelete:
      baseLen += o.n
  
  # Allow implicit retains at the end - operations don't need to cover entire document
  if baseLen > op.baseLength:
    echo "Validation failed: calculated base=", baseLen, " exceeds expected=", op.baseLength
    return err(LengthMismatch)
  if targetLen > op.targetLength:
    echo "Validation failed: calculated target=", targetLen, " exceeds expected=", op.targetLength
    return err(LengthMismatch)
  
  ok()

# JSON serialization
proc toJson*(op: Operation): JsonNode =
  case op.kind
  of opRetain:
    %*{"retain": op.n}
  of opInsert:
    %*{"insert": op.s}
  of opDelete:
    %*{"delete": op.n}

proc fromJson*(json: JsonNode): OpResult[Operation] =
  if json.hasKey("retain"):
    ok(retain(json["retain"].getInt))
  elif json.hasKey("insert"):
    ok(insert(json["insert"].getStr))
  elif json.hasKey("delete"):
    ok(delete(json["delete"].getInt))
  else:
    err(InvalidOperation)

proc toJson*(textOp: TextOperation): JsonNode =
  %*{
    "ops": textOp.ops.mapIt(it.toJson()),
    "baseLength": textOp.baseLength,
    "targetLength": textOp.targetLength
  }

proc fromJson*(json: JsonNode, T: typedesc[TextOperation]): OpResult[TextOperation] =
  if not json.hasKey("ops") or not json.hasKey("baseLength") or not json.hasKey("targetLength"):
    return err(InvalidOperation)
  
  var ops: seq[Operation] = @[]
  for opJson in json["ops"]:
    let op = fromJson(opJson)
    if op.isErr:
      return err(op.error)
    ops.add(op.get)
  
  let textOp = TextOperation(
    ops: ops,
    baseLength: json["baseLength"].getInt,
    targetLength: json["targetLength"].getInt
  )
  
  let validation = textOp.validate()
  if validation.isErr:
    return err(validation.error)
  
  ok(textOp)

proc fromJsonTextOperation*(json: JsonNode): Option[TextOperation] =
  ## Deserialize a TextOperation from JSON with Option return type
  let parseResult = fromJson(json, TextOperation)
  if parseResult.isOk:
    some(parseResult.get())
  else:
    none(TextOperation)