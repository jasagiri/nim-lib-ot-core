# Operational Transformation Library Specification

## 1. 基本操作仕様 (Basic Operations)

### 1.1 Operation型
```
Given: テキスト操作を表現する型
When: 操作を定義するとき
Then: 以下の3つの操作がサポートされる
  - Retain(n): n文字をスキップ
  - Insert(s): 文字列sを挿入
  - Delete(n): n文字を削除
```

### 1.2 TextOperation
```
Given: 複数の操作を連続して表現する型
When: ドキュメントを編集するとき
Then: 
  - 操作のシーケンスとして表現される
  - baseLength（元のドキュメント長）を持つ
  - targetLength（結果のドキュメント長）を持つ
```

### 1.3 apply関数
```
Given: Document と TextOperation
When: 操作をドキュメントに適用するとき
Then: 新しいドキュメントが生成される
  例: "hello" + Insert(5, " world") = "hello world"
```

## 2. 変換仕様 (Transformation)

### 2.1 transform関数
```
Given: 同時に発生した2つの操作 op1, op2
When: transform(op1, op2)を実行するとき
Then: (op1', op2')が返される
  - apply(apply(doc, op1), op2') = apply(apply(doc, op2), op1')
  - 収束性が保証される
```

### 2.2 compose関数
```
Given: 2つの連続した操作 op1, op2
When: compose(op1, op2)を実行するとき
Then: 合成された1つの操作が返される
  - apply(apply(doc, op1), op2) = apply(doc, compose(op1, op2))
```

### 2.3 invert関数
```
Given: 任意の操作 op
When: invert(op)を実行するとき
Then: 逆操作が返される
  - apply(apply(doc, op), invert(op)) = doc
```

## 3. クライアント仕様 (Client)

### 3.1 クライアント状態
```
Given: ネットワーク接続されたクライアント
When: 編集操作を行うとき
Then: 以下の状態を遷移する
  - Synchronized: サーバーと同期済み
  - AwaitingConfirm: 送信済み、確認待ち
  - AwaitingWithBuffer: 確認待ち＋バッファあり
```

### 3.2 ローカル編集
```
Given: 同期済みのクライアント
When: ユーザーが編集するとき
Then:
  - 即座にローカルに反映
  - 操作をサーバーに送信
  - 状態をAwaitingConfirmに変更
```

### 3.3 リモート操作の受信
```
Given: クライアントがサーバーから操作を受信
When: 未確認のローカル操作が存在するとき
Then:
  - リモート操作をローカル操作に対して変換
  - 変換後の操作を適用
  - ローカル操作も変換して保持
```

## 4. サーバー仕様 (Server)

### 4.1 操作の受信
```
Given: クライアントからの操作
When: サーバーが受信するとき
Then:
  - 操作のバージョンを確認
  - 同時操作に対して変換
  - ドキュメントに適用
  - 全クライアントにブロードキャスト
```

### 4.2 同時編集の処理
```
Given: 複数のクライアントからの同時操作
When: サーバーが処理するとき
Then:
  - 操作を順序付け
  - 各操作を既存操作に対して変換
  - 最終的に全クライアントが同じ状態に収束
```

## 5. プロトコル仕様 (Protocol)

### 5.1 メッセージフォーマット
```
Given: クライアント-サーバー間通信
When: メッセージを送信するとき
Then: JSON形式で以下を含む
  - type: "operation" | "ack" | "sync"
  - version: 整数
  - ops: 操作配列（オプション）
  - clientId: クライアント識別子
```

### 5.2 同期プロトコル
```
Given: 接続開始時
When: クライアントが接続するとき
Then:
  - サーバーは現在のドキュメント状態を送信
  - クライアントはローカル状態を同期
  - バージョン番号を合わせる
```

## 6. エラー処理仕様

### 6.1 無効な操作
```
Given: 不正な操作（範囲外のインデックス等）
When: 操作を適用しようとするとき
Then: Result[T, Error]型でエラーを返す
```

### 6.2 ネットワークエラー
```
Given: ネットワーク切断
When: 操作の送受信中
Then:
  - 操作をキューイング
  - 再接続時に同期
  - データロストを防ぐ
```

## 7. パフォーマンス仕様

### 7.1 時間計算量
```
Given: n文字のドキュメント、m個の操作
When: 各関数を実行するとき
Then:
  - apply: O(n + m)
  - transform: O(m1 + m2)
  - compose: O(m1 + m2)
```

### 7.2 空間計算量
```
Given: 操作履歴の保持
When: nバージョンの履歴
Then: O(n × 平均操作サイズ)のメモリ使用量
```