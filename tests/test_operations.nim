import unittest
import results
import ../src/nim_lib_ot_core/[types, operations]

suite "Operations":
  test "Normalize operations":
    let ops = @[
      retain(2),
      retain(3),
      insert("hello"),
      insert(" world"),
      delete(1),
      delete(2)
    ]
    
    let normalized = normalizeOps(ops)
    check normalized.len == 3
    check normalized[0].kind == opRetain
    check normalized[0].n == 5
    check normalized[1].kind == opInsert
    check normalized[1].s == "hello world"
    check normalized[2].kind == opDelete
    check normalized[2].n == 3
  
  test "Add operations to TextOperation":
    var op = newTextOperation()
    op.retain(5)
    op.insert("hello")
    op.delete(3)
    
    check op.ops.len == 3
    check op.baseLength == 8
    check op.targetLength == 10
  
  test "Apply operation - insert":
    let doc = newDocument("hello")
    var op = newTextOperation()
    op.insert(" world")
    op.retain(5)
    
    let result = doc.apply(op)
    check result.isOk
    check result.get.content == " worldhello"
    check result.get.version == 1
  
  test "Apply operation - delete":
    let doc = newDocument("hello world")
    var op = newTextOperation()
    op.retain(5)
    op.delete(6)
    
    let result = doc.apply(op)
    check result.isOk
    check result.get.content == "hello"
  
  test "Apply operation - mixed":
    let doc = newDocument("hello world")
    var op = newTextOperation()
    op.retain(6)  # "hello "
    op.delete(5)  # Remove "world"
    op.insert("Nim")
    
    let result = doc.apply(op)
    check result.isOk
    check result.get.content == "hello Nim"
  
  test "Apply operation - error on length mismatch":
    let doc = newDocument("hello")
    var op = newTextOperation()
    op.retain(10)  # Document is only 5 chars
    
    let result = doc.apply(op)
    check result.isErr
    check result.error == LengthMismatch
  
  test "Compose operations":
    var op1 = newTextOperation()
    op1.retain(5)
    op1.insert(" beautiful")
    op1.retain(6)
    
    var op2 = newTextOperation()
    op2.retain(5)
    op2.delete(10)
    op2.insert(" awesome")
    op2.retain(6)
    
    let composed = compose(op1, op2)
    check composed.isOk
    
    let doc = newDocument("hello world")
    let result1 = doc.apply(op1)
    check result1.isOk
    let result2 = result1.get.apply(op2)
    check result2.isOk
    
    let directResult = doc.apply(composed.get)
    check directResult.isOk
    check directResult.get.content == result2.get.content
  
  test "Invert operation":
    let doc = newDocument("hello world")
    var op = newTextOperation()
    op.retain(6)
    op.delete(5)
    op.insert("Nim")
    
    let inverted = op.invert(doc)
    check inverted.isOk
    
    let result1 = doc.apply(op)
    check result1.isOk
    
    let result2 = result1.get.apply(inverted.get)
    check result2.isOk
    check result2.get.content == doc.content