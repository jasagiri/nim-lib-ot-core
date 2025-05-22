# Nim-lib-ot-core Examples

このドキュメントでは、nim-lib-ot-coreライブラリの様々な使用例を紹介します。基本的な操作から高度なユースケースまで、幅広いサンプルを網羅しています。

## 基本的な例

### 1. 基本操作
基本的な挿入、削除、保持操作の作成と適用

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations

# 新しいテキスト操作を作成
var op = newTextOperation()
op.retain(5)      # 最初の5文字を変更せずに保持
op.delete(3)      # 3文字を削除
op.insert("新しい")  # "新しい"を挿入
op.retain(7)      # 次の7文字を変更せずに保持

# ドキュメントに適用
let doc = newDocument("こんにちは世界、元気ですか？")
let result = doc.apply(op)
if result.isOk:
  echo result.get().content  # "こんにち新しい、元気ですか？"
```

### 2. 操作の変換
同時編集を処理するためのtransform関数の使用

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/transform

# ドキュメントの作成
let doc = newDocument("こんにちは世界")

# ユーザー1の操作: "こんにちは" の後に "美しい" を挿入
var op1 = newTextOperation()
op1.retain(5)
op1.insert("美しい")
op1.retain(2)

# ユーザー2の操作: "こんにちは" の後に "素晴らしい" を挿入
var op2 = newTextOperation()
op2.retain(5)
op2.insert("素晴らしい")
op2.retain(2)

# 操作を変換
let transformResult = transform(op1, op2)
if transformResult.isOk:
  let (op1prime, op2prime) = transformResult.get()
  
  # 一方の順序で適用
  let result1 = doc.apply(op1)
  if result1.isOk:
    let result1a = result1.get().apply(op2prime)
    if result1a.isOk:
      echo "op1 → op2'を適用: ", result1a.get().content
  
  # もう一方の順序で適用
  let result2 = doc.apply(op2)
  if result2.isOk:
    let result2a = result2.get().apply(op1prime)
    if result2a.isOk:
      echo "op2 → op1'を適用: ", result2a.get().content
  
  # 両方の結果は同じになるはず（収束性）
```

### 3. 操作の合成
複数の操作を単一の操作に結合

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations

# ドキュメントの作成
let doc = newDocument("こんにちは世界")

# 最初の操作: "こんにちは" の後に "美しい" を挿入
var op1 = newTextOperation()
op1.retain(5)
op1.insert("美しい")
op1.retain(2)

# 二番目の操作: "美しい" の後に "素晴らしい" を挿入
var op2 = newTextOperation()
op2.retain(8)
op2.insert("素晴らしい")
op2.retain(2)

# 操作を合成
let composeResult = compose(op1, op2)
if composeResult.isOk:
  let composedOp = composeResult.get()
  
  # 合成された操作を適用
  let result = doc.apply(composedOp)
  if result.isOk:
    echo "合成操作の結果: ", result.get().content  # "こんにちは美しい素晴らしい世界"
```

## クライアント-サーバーの例

### 4. 基本的なクライアント-サーバーのセットアップ
クライアントとサーバーの基本的なセットアップ

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/client
import nim_lib_ot_core/server

# 初期テキスト
let initialText = "こんにちは世界"

# サーバーのセットアップ
let server = newOTServer(initialText)
let clientId = "client1"
discard server.registerClient(clientId)

# クライアントのセットアップ
let client = newOTClient(initialText)

# クライアントが編集を行う
var op = newTextOperation()
op.retain(5)
op.insert("美しい")
op.retain(2)

# ローカルで操作を適用
let clientResult = client.applyLocal(op)
if clientResult.isOk:
  echo "クライアントのドキュメント: ", client.document.content
  
  # サーバーに送信
  let serverResult = server.receiveOperation(clientId, clientResult.get(), 0)
  if serverResult.isOk:
    let (transformedOp, revision) = serverResult.get()
    echo "サーバーのドキュメント: ", server.getDocument().content
```

### 5. 複数クライアントによる共同編集
同じドキュメントを編集する複数のクライアント

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/client
import nim_lib_ot_core/server

# 初期テキスト
let initialText = "こんにちは世界"

# サーバーのセットアップ
let server = newOTServer(initialText)
let clientId1 = "client1"
let clientId2 = "client2"
discard server.registerClient(clientId1)
discard server.registerClient(clientId2)

# クライアントのセットアップ
let client1 = newOTClient(initialText)
let client2 = newOTClient(initialText)

# クライアント1が編集を行う
var op1 = newTextOperation()
op1.retain(5)
op1.insert("美しい")
op1.retain(2)

let clientResult1 = client1.applyLocal(op1)
if clientResult1.isOk:
  echo "クライアント1のドキュメント: ", client1.document.content
  
  # サーバーに送信
  let serverResult1 = server.receiveOperation(clientId1, clientResult1.get(), 0)
  if serverResult1.isOk:
    let (transformedOp1, revision1) = serverResult1.get()
    echo "サーバーのドキュメント: ", server.getDocument().content
    
    # サーバーがクライアント2にブロードキャスト
    let broadcasts1 = server.broadcast(clientId1, transformedOp1, revision1)
    for broadcast in broadcasts1:
      if broadcast.clientId == clientId2:
        let client2Result = client2.applyServer(broadcast.op, revision1)
        if client2Result.isOk:
          echo "クライアント2のドキュメント: ", client2.document.content

# クライアント2が編集を行う
var op2 = newTextOperation()
op2.retain(8)
op2.insert("素晴らしい")
op2.retain(2)

let clientResult2 = client2.applyLocal(op2)
if clientResult2.isOk:
  echo "ローカル編集後のクライアント2のドキュメント: ", client2.document.content
  
  # サーバーに送信
  let serverResult2 = server.receiveOperation(clientId2, clientResult2.get(), 1)
  if serverResult2.isOk:
    let (transformedOp2, revision2) = serverResult2.get()
    echo "サーバーのドキュメント: ", server.getDocument().content
    
    # サーバーがクライアント1にブロードキャスト
    let broadcasts2 = server.broadcast(clientId2, transformedOp2, revision2)
    for broadcast in broadcasts2:
      if broadcast.clientId == clientId1:
        let client1Result = client1.applyServer(broadcast.op, revision2)
        if client1Result.isOk:
          echo "リモート編集後のクライアント1のドキュメント: ", client1.document.content
```

### 6. ネットワークプロトコルメッセージ
シリアライズ用のプロトコルメッセージの操作

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/protocol
import json

# テキスト操作の作成
var op = newTextOperation()
op.retain(5)
op.insert("美しい")
op.retain(2)

# 操作をシリアライズ
let serialized = op.toJson()
echo "シリアライズされた操作: ", serialized

# クライアントメッセージの作成
let clientMsg = ClientMessage(
  messageType: ClientMessageType.Operation,
  clientId: "client1",
  operation: op,
  revision: 0
)

# メッセージをシリアライズ
let serializedMsg = clientMsg.toJson()
echo "シリアライズされたメッセージ: ", serializedMsg

# メッセージをデシリアライズ
let deserializedMsg = parseClientMessage(serializedMsg)
if deserializedMsg.isOk:
  let msg = deserializedMsg.get()
  echo "デシリアライズされたメッセージタイプ: ", msg.messageType
  echo "デシリアライズされたクライアントID: ", msg.clientId
```

## 高度な機能

### 7. カーソルの追跡
共同編集中のカーソル位置の追跡と変換

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/cursor

# ドキュメントの作成
let doc = newDocument("こんにちは世界")
var cursorPos = 5  # "こんにちは" の後のカーソル位置

echo "初期ドキュメント: ", doc.content
echo "初期カーソル位置: ", cursorPos

# カーソル位置に "美しい" を挿入する操作を作成
var op = newTextOperation()
op.retain(5)
op.insert("美しい")
op.retain(2)

# カーソル位置を変換
let newCursorPos = transformCursor(cursorPos, op, true)  # trueは自分自身の操作であることを示す

# 操作を適用
let result = doc.apply(op)
if result.isOk:
  echo "挿入後のドキュメント: ", result.get().content
  echo "新しいカーソル位置: ", newCursorPos

# 別のユーザーが "美しい" の後に "素晴らしい" を挿入
var op2 = newTextOperation()
op2.retain(8)
op2.insert("素晴らしい")
op2.retain(2)

# 他のユーザーの操作によってカーソル位置を変換
let newerCursorPos = transformCursor(newCursorPos, op2, false)  # falseは他のユーザーの操作であることを示す

# 操作を適用
let result2 = result.get().apply(op2)
if result2.isOk:
  echo "2回目の挿入後のドキュメント: ", result2.get().content
  echo "最終カーソル位置: ", newerCursorPos
```

### 8. 元に戻す/やり直し履歴
元に戻す機能とやり直し機能の実装

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/history

# ドキュメントを作成し、履歴マネージャーを設定
let doc = newDocument("こんにちは")
let history = newEditHistory(doc)

echo "初期ドキュメント: ", history.document.content

# 最初の編集
var op1 = newTextOperation()
op1.retain(5)
op1.insert("世界")
discard history.pushOperation(op1)
echo "最初の編集後: ", history.document.content

# 2回目の編集
var op2 = newTextOperation()
op2.retain(7)
op2.insert("！")
discard history.pushOperation(op2)
echo "2回目の編集後: ", history.document.content

# 最後の操作を元に戻す
if history.canUndo():
  let undoResult = history.undo()
  if undoResult.isOk:
    echo "元に戻した後: ", history.document.content

# 操作をやり直す
if history.canRedo():
  let redoResult = history.redo()
  if redoResult.isOk:
    echo "やり直した後: ", history.document.content

# 両方の編集を元に戻す
if history.canUndo():
  discard history.undo()
  echo "最初の編集を再度元に戻した後: ", history.document.content

if history.canUndo():
  discard history.undo()
  echo "2回目の編集を元に戻した後: ", history.document.content

echo "元に戻すスタックのサイズ: ", history.undoCount()
echo "やり直しスタックのサイズ: ", history.redoCount()
```

### 9. 選択範囲の変換
操作間でのテキスト選択範囲の追跡

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/cursor

# ドキュメントの作成
let doc = newDocument("こんにちは世界")

# 選択範囲 (from, to)
var selection = (2, 5)  # "んにち" を選択
echo "初期ドキュメント: ", doc.content
echo "初期選択範囲: ", selection

# "こ" の後に "美しい" を挿入する操作
var op = newTextOperation()
op.retain(1)
op.insert("美しい")
op.retain(6)

# 選択範囲を変換
let newSelectionFrom = transformCursor(selection[0], op, false)
let newSelectionTo = transformCursor(selection[1], op, false)
let newSelection = (newSelectionFrom, newSelectionTo)

# 操作を適用
let result = doc.apply(op)
if result.isOk:
  echo "挿入後のドキュメント: ", result.get().content
  echo "新しい選択範囲: ", newSelection
```

## 実世界のアプリケーション

### 10. 協調テキストエディタ
基本的な協調テキストエディタの実装サンプル

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/client
import nim_lib_ot_core/server
import nim_lib_ot_core/cursor
import nim_lib_ot_core/history

type
  Editor* = ref object
    client*: OTClient
    history*: EditHistory
    cursorPosition*: int
    selection*: tuple[from: int, to: int]
    clientId*: string

proc newEditor*(initialText: string, clientId: string): Editor =
  let client = newOTClient(initialText)
  let history = newEditHistory(newDocument(initialText))
  result = Editor(
    client: client,
    history: history,
    cursorPosition: 0,
    selection: (0, 0),
    clientId: clientId
  )

proc insertText*(editor: Editor, position: int, text: string): bool =
  # エディタに文字列を挿入
  var op = newTextOperation()
  if position > 0:
    op.retain(position)
  op.insert(text)
  if editor.client.document.content.len - position > 0:
    op.retain(editor.client.document.content.len - position)
  
  # ローカルに適用
  let clientResult = editor.client.applyLocal(op)
  if clientResult.isOk:
    # 履歴に追加
    discard editor.history.pushOperation(op)
    
    # カーソル位置を更新
    editor.cursorPosition = position + text.len
    editor.selection = (editor.cursorPosition, editor.cursorPosition)
    return true
  
  return false

proc deleteText*(editor: Editor, from: int, to: int): bool =
  # エディタからテキストを削除
  let deleteLen = to - from
  var op = newTextOperation()
  if from > 0:
    op.retain(from)
  op.delete(deleteLen)
  if editor.client.document.content.len - to > 0:
    op.retain(editor.client.document.content.len - to)
  
  # ローカルに適用
  let clientResult = editor.client.applyLocal(op)
  if clientResult.isOk:
    # 履歴に追加
    discard editor.history.pushOperation(op)
    
    # カーソル位置を更新
    editor.cursorPosition = from
    editor.selection = (from, from)
    return true
  
  return false

proc undo*(editor: Editor): bool =
  if editor.history.canUndo():
    let undoResult = editor.history.undo()
    if undoResult.isOk:
      # クライアントのドキュメントも更新
      editor.client.document = editor.history.document
      return true
  
  return false

proc redo*(editor: Editor): bool =
  if editor.history.canRedo():
    let redoResult = editor.history.redo()
    if redoResult.isOk:
      # クライアントのドキュメントも更新
      editor.client.document = editor.history.document
      return true
  
  return false

proc receiveRemoteOperation*(editor: Editor, op: TextOperation, revision: int): bool =
  # リモート操作を受信して適用
  let serverResult = editor.client.applyServer(op, revision)
  if serverResult.isOk:
    # カーソル位置を変換
    editor.cursorPosition = transformCursor(editor.cursorPosition, op, false)
    editor.selection = (
      transformCursor(editor.selection.from, op, false),
      transformCursor(editor.selection.to, op, false)
    )
    return true
  
  return false

# 使用例
let editor1 = newEditor("こんにちは世界", "user1")
echo "エディタ1初期テキスト: ", editor1.client.document.content

# テキストを挿入
discard editor1.insertText(5, "美しい")
echo "挿入後のテキスト: ", editor1.client.document.content
echo "カーソル位置: ", editor1.cursorPosition

# テキストを削除
discard editor1.deleteText(8, 10)  # "い世" を削除
echo "削除後のテキスト: ", editor1.client.document.content

# 元に戻す
discard editor1.undo()
echo "元に戻した後のテキスト: ", editor1.client.document.content

# やり直す
discard editor1.redo()
echo "やり直した後のテキスト: ", editor1.client.document.content
```

## パフォーマンスとデバッグ

### 11. パフォーマンスベンチマーク
OTライブラリのパフォーマンスをテストするベンチマーク

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/transform
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

proc generateRandomOperation(doc: Document): TextOperation =
  var op = newTextOperation()
  let pos = rand(doc.content.len)
  if pos > 0:
    op.retain(pos)
  
  if rand(1.0) < 0.7:  # 70%の確率で挿入
    op.insert(generateRandomString(rand(5) + 1))
  else:  # 30%の確率で削除
    let deleteLen = min(rand(10) + 1, doc.content.len - pos)
    if deleteLen > 0:
      op.delete(deleteLen)
  
  if doc.content.len - pos - (if rand(1.0) < 0.7: 0 else: min(rand(10) + 1, doc.content.len - pos)) > 0:
    op.retain(doc.content.len - pos - (if rand(1.0) < 0.7: 0 else: min(rand(10) + 1, doc.content.len - pos)))
  
  result = op

# ベンチマークの実行
proc runTransformBenchmark() =
  let initialDoc = newDocument(generateRandomString(DOC_SIZE))
  var operations: seq[TextOperation] = @[]
  
  # 操作を生成
  for i in 1..ITERATIONS:
    operations.add(generateRandomOperation(initialDoc))
  
  let start = cpuTime()
  for i in 0..<ITERATIONS-1:
    let a = operations[i]
    let b = operations[i+1]
    discard transform(a, b)
  
  let duration = cpuTime() - start
  echo &"{ITERATIONS-1}対の操作を{duration:.6f}秒で変換"
  echo &"1回の変換あたりの平均時間: {(duration / float(ITERATIONS-1)) * 1000:.6f} ms"

# ベンチマークの実行
randomize()
runTransformBenchmark()
```

### 12. 操作の検証
操作の正確性を検証

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/transform

proc validateOperation(op: TextOperation, docLength: int): bool =
  # 操作の長さがドキュメントの長さと一致するか確認
  var totalLength = 0
  for component in op.components:
    case component.kind
    of RetainOp:
      totalLength += component.chars
    of InsertOp:
      # 挿入はドキュメントの長さには影響しない
      discard
    of DeleteOp:
      totalLength += component.chars
  
  return totalLength == docLength

proc validateTransform(a, b: TextOperation, docLength: int): bool =
  # 変換後の操作が元のドキュメントの長さに対して有効か確認
  if not validateOperation(a, docLength) or not validateOperation(b, docLength):
    return false
  
  let transformResult = transform(a, b)
  if transformResult.isErr:
    return false
  
  let (aPrime, bPrime) = transformResult.get()
  
  # a'がbを経由したドキュメントに対して有効かチェック
  let docLengthAfterB = docLength - getTotalDeleteCount(b) + getTotalInsertLength(b)
  if not validateOperation(aPrime, docLengthAfterB):
    return false
  
  # b'がaを経由したドキュメントに対して有効かチェック
  let docLengthAfterA = docLength - getTotalDeleteCount(a) + getTotalInsertLength(a)
  if not validateOperation(bPrime, docLengthAfterA):
    return false
  
  return true

# 削除操作の合計文字数を取得
proc getTotalDeleteCount(op: TextOperation): int =
  for component in op.components:
    if component.kind == DeleteOp:
      result += component.chars

# 挿入操作の合計文字列長を取得
proc getTotalInsertLength(op: TextOperation): int =
  for component in op.components:
    if component.kind == InsertOp:
      result += component.text.len

# 使用例
let doc = newDocument("こんにちは世界")
let docLength = doc.content.len

var op1 = newTextOperation()
op1.retain(5)
op1.insert("美しい")
op1.retain(2)

var op2 = newTextOperation()
op2.retain(5)
op2.insert("素晴らしい")
op2.retain(2)

echo "op1は有効か: ", validateOperation(op1, docLength)
echo "op2は有効か: ", validateOperation(op2, docLength)
echo "変換後の操作は有効か: ", validateTransform(op1, op2, docLength)
```

## 実験的な機能

### 13. 代替変換アルゴリズム
実験的な変換実装の使用

```nim
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/experimental/transform_alt

# ドキュメントの作成
let doc = newDocument("こんにちは世界")

# 2つの同時操作
var op1 = newTextOperation()
op1.retain(5)
op1.insert("美しい")
op1.retain(2)

var op2 = newTextOperation()
op2.retain(5)
op2.insert("素晴らしい")
op2.retain(2)

# 代替変換アルゴリズムを使用して変換
let transformResult = transformAlt(op1, op2)
if transformResult.isOk:
  let (op1prime, op2prime) = transformResult.get()
  
  # 一方の順序で適用
  let result1 = doc.apply(op1)
  if result1.isOk:
    let result1a = result1.get().apply(op2prime)
    if result1a.isOk:
      echo "op1 → op2'を適用 (代替アルゴリズム): ", result1a.get().content
  
  # もう一方の順序で適用
  let result2 = doc.apply(op2)
  if result2.isOk:
    let result2a = result2.get().apply(op1prime)
    if result2a.isOk:
      echo "op2 → op1'を適用 (代替アルゴリズム): ", result2a.get().content
```

## 統合例

### 14. WebSocketによる通信
リアルタイムコミュニケーションのためのWebSocketの使用

```nim
# 注: これは概念的な例です。実際の実装にはWebSocketライブラリが必要です
import nim_lib_ot_core/types
import nim_lib_ot_core/operations
import nim_lib_ot_core/client
import nim_lib_ot_core/protocol
import json

type
  WebSocketClient = ref object
    # WebSocketクライアントの実装
    otClient: OTClient
    clientId: string
    serverUrl: string
    connected: bool

proc newWebSocketClient(initialText: string, clientId: string, serverUrl: string): WebSocketClient =
  result = WebSocketClient(
    otClient: newOTClient(initialText),
    clientId: clientId,
    serverUrl: serverUrl,
    connected: false
  )

proc connect(client: WebSocketClient) =
  # WebSocketサーバーに接続する処理
  echo "WebSocketサーバーに接続中: ", client.serverUrl
  # 実際の接続コード
  client.connected = true
  echo "接続成功"

proc disconnect(client: WebSocketClient) =
  # WebSocketサーバーから切断する処理
  if client.connected:
    echo "WebSocketサーバーから切断中"
    # 実際の切断コード
    client.connected = false
    echo "切断成功"

proc sendOperation(client: WebSocketClient, op: TextOperation) =
  # 操作をサーバーに送信
  if not client.connected:
    echo "サーバーに接続されていません"
    return
  
  # クライアントでローカルに適用
  let clientResult = client.otClient.applyLocal(op)
  if clientResult.isOk:
    echo "ローカルで適用: ", client.otClient.document.content
    
    # サーバーに送信するメッセージを作成
    let msg = ClientMessage(
      messageType: ClientMessageType.Operation,
      clientId: client.clientId,
      operation: clientResult.get(),
      revision: client.otClient.revision
    )
    
    # メッセージをシリアライズしてサーバーに送信
    let serializedMsg = msg.toJson()
    echo "サーバーに送信: ", serializedMsg
    # 実際のWebSocket送信コード

proc receiveMessage(client: WebSocketClient, jsonMsg: string) =
  # サーバーからのメッセージを受信して処理
  echo "サーバーからメッセージを受信: ", jsonMsg
  
  let serverMsg = parseServerMessage(jsonMsg)
  if serverMsg.isOk:
    let msg = serverMsg.get()
    
    case msg.messageType
    of ServerMessageType.Acknowledgement:
      echo "確認応答を受信: リビジョン ", msg.revision
    
    of ServerMessageType.Operation:
      echo "操作を受信: ", msg.operation
      # サーバーからの操作を適用
      let result = client.otClient.applyServer(msg.operation, msg.revision)
      if result.isOk:
        echo "リモート操作を適用: ", client.otClient.document.content
    
    of ServerMessageType.Error:
      echo "エラーを受信: ", msg.error
  else:
    echo "メッセージの解析に失敗: ", serverMsg.error

# 使用例
let wsClient = newWebSocketClient("こんにちは世界", "user1", "ws://example.com/ot")
wsClient.connect()

# テキストを挿入する操作
var op = newTextOperation()
op.retain(5)
op.insert("美しい")
op.retain(2)
wsClient.sendOperation(op)

# サーバーからのメッセージをシミュレート
let serverJson = """
{
  "messageType": "operation",
  "clientId": "user2",
  "operation": {
    "components": [
      {"kind": "retain", "chars": 8},
      {"kind": "insert", "text": "素晴らしい"},
      {"kind": "retain", "chars": 2}
    ]
  },
  "revision": 2
}
"""
wsClient.receiveMessage(serverJson)

# 切断
wsClient.disconnect()
```

## まとめ

このドキュメントでは、nim-lib-ot-coreライブラリの使用例を紹介しました。基本的な操作から、クライアント-サーバーの設定、カーソルの追跡、元に戻す/やり直し機能まで、様々なOT機能を実装するコード例を含んでいます。

これらの例を参考にして、独自の協調編集アプリケーションを構築する際の基礎として活用してください。より高度なユースケースやパフォーマンスの最適化については、ライブラリのソースコードや実験的な実装を参照することをお勧めします。