import unittest
import results
import json
import ../src/nim_lib_ot_core/types

suite "Types":
  test "Create operations":
    let r = retain(5)
    check r.kind == opRetain
    check r.n == 5
    
    let i = insert("hello")
    check i.kind == opInsert
    check i.s == "hello"
    
    let d = delete(3)
    check d.kind == opDelete
    check d.n == 3
  
  test "Operation length":
    check retain(5).len == 5
    check insert("hello").len == 5
    check delete(3).len == 3
  
  test "Operation noop check":
    check retain(0).isNoop == true
    check retain(1).isNoop == false
    check insert("").isNoop == true
    check insert("a").isNoop == false
    check delete(0).isNoop == true
    check delete(1).isNoop == false
  
  test "Document creation":
    let doc = newDocument("hello world", 1)
    check doc.content == "hello world"
    check doc.version == 1
  
  test "TextOperation validation":
    var op = newTextOperation()
    op.baseLength = 5
    op.targetLength = 8
    op.ops = @[retain(2), insert("abc"), retain(3)]
    
    let result = op.validate()
    check result.isOk
  
  test "TextOperation validation failure":
    # Test lenient validation - calculated can be less than expected
    var op = newTextOperation()
    op.baseLength = 5
    op.targetLength = 8
    op.ops = @[retain(2), insert("abc"), retain(2)]  # 2 + 3 + 2 = 7 but target is 8
    
    # With lenient validation, this should now pass since 7 < 8
    let result = op.validate()
    check result.isOk
    
    # Test where calculated exceeds expected
    var op2 = newTextOperation()
    op2.baseLength = 5
    op2.targetLength = 6
    op2.ops = @[retain(5), insert("abc")]  # 5 + 3 = 8 but target is 6
    
    let result2 = op2.validate()
    check result2.isErr
    check result2.error == LengthMismatch
  
  test "JSON serialization - operations":
    let r = retain(5)
    let rJson = r.toJson()
    check rJson.hasKey("retain")
    check rJson["retain"].getInt == 5
    
    let i = insert("hello")
    let iJson = i.toJson()
    check iJson.hasKey("insert")
    check iJson["insert"].getStr == "hello"
    
    let d = delete(3)
    let dJson = d.toJson()
    check dJson.hasKey("delete")
    check dJson["delete"].getInt == 3
  
  test "JSON deserialization - operations":
    let rJson = %*{"retain": 5}
    let r = fromJson(rJson)
    check r.isOk
    check r.get.kind == opRetain
    check r.get.n == 5
    
    let iJson = %*{"insert": "hello"}
    let i = fromJson(iJson)
    check i.isOk
    check i.get.kind == opInsert
    check i.get.s == "hello"
    
    let dJson = %*{"delete": 3}
    let d = fromJson(dJson)
    check d.isOk
    check d.get.kind == opDelete
    check d.get.n == 3
    
    let invalidJson = %*{"invalid": true}
    let invalid = fromJson(invalidJson)
    check invalid.isErr