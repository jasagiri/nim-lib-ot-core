# OT実装の分析

## 1. コアデータ構造

### 基本的な操作 (Operations)
全ての実装で共通する基本操作:
- **Retain(n)**: カーソルをn文字進める
- **Insert(s)**: 文字列sを現在位置に挿入
- **Delete(n)**: 現在位置からn文字削除

### JavaScript (ot.js)
```javascript
// ops配列に操作を格納
this.ops = [];
this.baseLength = 0;    // 適用可能な文字列の長さ
this.targetLength = 0;  // 操作適用後の文字列の長さ
```

### Rust (operational-transform-rs)
```rust
pub enum Operation {
    Delete(u64),
    Retain(u64),
    Insert(String),
}

pub struct OperationSeq {
    ops: Vec<Operation>,
    base_len: usize,
    target_len: usize,
}
```

### Go (ot.go)
```go
type Op struct {
    N int      // 正: Retain, 負: Delete
    S []rune   // Insert操作の文字列
}

type Operation struct {
    Ops       []*Op
    BaseLen   int
    TargetLen int
    Meta      interface{}
}
```

### Ruby (ot.rb)
```ruby
# 操作は整数（Retain/Delete）または文字列（Insert）として格納
@ops = []
@base_length = 0
@target_length = 0
```

## 2. 変換アルゴリズム

### Transform関数のコアロジック
1. 同時に発生した2つの操作A、Bを受け取る
2. A'、B'を生成し `apply(apply(S, A), B') = apply(apply(S, B), A')` を満たす
3. 操作タイプの組み合わせごとに処理:
   - Insert/Insert: A'にAのInsertを含み、B'にはAの長さ分のRetain
   - Retain/Retain: 短い方を両方に適用
   - Delete/Delete: 重複部分をスキップ
   - Delete/Retain, Retain/Delete: 適切な調整を実施

### JavaScript実装の例
```javascript
if (isInsert(op1)) {
    operation1prime.insert(op1);
    operation2prime.retain(op1.length);
    op1 = ops1[i1++];
    continue;
}
```

## 3. クライアント・サーバーアーキテクチャ

### 共通パターン
1. **クライアント状態管理**
   - `Synchronized`: サーバーと同期済み
   - `AwaitingConfirm`: 操作送信済み、確認待ち
   - `AwaitingWithBuffer`: 確認待ち中に新しい操作が発生

2. **サーバー処理フロー**
   - クライアントから操作とリビジョン番号を受信
   - 並行操作に対してtransformを実行
   - 文書に適用し、履歴に保存
   - 他のクライアントにブロードキャスト

### ShareDBの高度な機能
- プレゼンス（カーソル位置の共有）
- クエリサブスクリプション
- ミドルウェアシステム
- ドキュメントのスナップショット管理

## 4. テスト戦略

### 共通のテストパターン
1. **ランダムテスト**: ランダムな操作列を生成して性質を検証
2. **変換の性質テスト**:
   - 可換性: `transform(A, B) = transform(B, A)`の逆
   - 一貫性: `apply(apply(S, A), B') = apply(apply(S, B), A')`
3. **逆操作テスト**: `apply(apply(S, op), invert(op)) = S`
4. **合成テスト**: `apply(apply(S, A), B) = apply(S, compose(A, B))`

## 5. API設計

### 操作構築（Fluent Interface）
```javascript
// JavaScript
operation.retain(5).insert("hello").delete(3);
```

```go
// Go
op.Retain(5).Insert("hello").Delete(3)
```

```ruby
# Ruby
operation.retain(5).insert("hello").delete(3)
```

### 主要メソッド
- `apply(document)`: 文書に操作を適用
- `compose(op1, op2)`: 2つの操作を合成
- `transform(op1, op2)`: 並行操作を変換
- `invert(document)`: 逆操作を生成

## 6. 特徴的な設計判断

### UTF-16対応 (Go実装)
文字エンコーディングの違いを処理するための抽象化

### シリアライゼーション形式
- Retain(n): `n`
- Delete(n): `-n`
- Insert(s): `"s"`または`{s: "..."}`

### メタデータサポート
操作にカスタムメタデータを添付可能（選択範囲など）

## Nimライブラリへの推奨事項

1. **型安全性**: Nimの型システムを活用し、操作タイプを明確に定義
2. **パフォーマンス**: 文字列操作をUTF-8で効率的に実装
3. **エラーハンドling**: Result型やOption型を使用してエラーを明示的に処理
4. **テスト**: プロパティベーステストフレームワークを使用
5. **API**: 他の実装と互換性のあるインターフェース設計
6. **並行性**: Nimのasync/awaitを活用した非同期通信サポート