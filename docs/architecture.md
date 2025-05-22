# nim-lib-ot アーキテクチャ

このドキュメントでは、nim-lib-ot ライブラリの全体的なアーキテクチャと各コンポーネントの役割について説明します。

## 全体構造

nim-lib-ot は以下のコンポーネントで構成されています：

```
nim-lib-ot/
├── src/                    # ソースコード
│   ├── nim_lib_ot.nim      # メインモジュール
│   └── nim_lib_ot/         # サブモジュール
│       ├── types.nim       # コア型定義
│       ├── operations.nim  # 基本操作
│       ├── transform.nim   # 変換アルゴリズム
│       ├── client.nim      # クライアント実装
│       ├── server.nim      # サーバー実装
│       ├── cursor.nim      # カーソル変換
│       ├── protocol.nim    # ネットワークプロトコル
│       ├── history.nim     # 履歴管理（undo/redo）
│       └── experimental/   # 実験的実装
│           ├── transform_alt.nim   # 代替変換アルゴリズム
│           ├── transform_debug.nim # デバッグ向け実装
│           └── benchmark.nim       # パフォーマンス比較ツール
├── tests/                  # テストファイル
│   ├── specs/              # BDDスタイルの機能仕様
│   │   ├── operations.feature
│   │   ├── transform.feature
│   │   ├── client_server.feature
│   │   ├── cursor.feature
│   │   ├── history.feature
│   │   └── protocol.feature
│   ├── test_operations.nim # 単体テスト
│   └── ...
├── examples/               # 例
│   ├── basic_usage.nim
│   └── benchmark.nim
├── benchmarks/             # パフォーマンスベンチマーク
│   └── bench_all.nim
└── docs/                   # ドキュメント
    ├── api.md              # API リファレンス
    ├── architecture.md     # アーキテクチャドキュメント
    ├── experimental.md     # 実験的実装のガイド
    └── design/             # 設計ドキュメント
```

## コンポーネント

### 1. コア型 (`types.nim`)

基本的なデータ型と構造を定義します：

- `OperationKind`: 操作の種類（Retain, Insert, Delete）
- `Operation`: 単一の操作
- `TextOperation`: 操作のシーケンス
- `Document`: テキストドキュメント
- エラー型とリザルト型

### 2. 基本操作 (`operations.nim`)

操作の作成と適用に関する機能を提供します：

- 操作の作成（retain, insert, delete）
- ドキュメントへの操作の適用
- 操作の合成
- 操作の反転

### 3. 変換 (`transform.nim`)

並行操作の変換アルゴリズムを実装します：

- 同時に発生した操作の変換
- 操作の競合解決
- 変換後の操作の検証

### 4. クライアント (`client.nim`)

クライアント側の実装：

- 状態管理（同期、確認待ち、バッファ付き確認待ち）
- ローカル操作の処理
- リモート操作の適用

### 5. サーバー (`server.nim`)

サーバー側の実装：

- クライアント接続管理
- 操作の受信と検証
- 操作のブロードキャスト

### 6. カーソル (`cursor.nim`)

カーソル位置の変換機能：

- 操作を通じたカーソル位置の変換
- 複数カーソルのサポート

### 7. プロトコル (`protocol.nim`)

クライアント・サーバー間の通信プロトコル：

- メッセージフォーマット
- シリアライズ/デシリアライズ
- 各種メッセージタイプ

### 8. 履歴 (`history.nim`)

操作履歴の管理：

- undo/redo 機能
- メタデータのサポート
- 履歴の制限管理

### 9. 実験的実装 (`experimental/`)

代替実装と開発ツール：

- `transform_alt.nim`: 代替変換アルゴリズム
- `transform_debug.nim`: デバッグ用の詳細ログ実装
- `benchmark.nim`: パフォーマンス比較ツール

## データフロー

1. クライアントでユーザーが編集を行う
2. `operations.nim` がテキスト操作を作成
3. クライアントは `client.nim` を通じてローカル操作を適用
4. 操作はサーバーに送信される
5. サーバーは `transform.nim` を使用して操作を変換
6. 変換された操作は他のクライアントにブロードキャストされる
7. クライアントは `cursor.nim` を使用してカーソル位置を更新

## 設計原則

1. 型安全性の確保
2. 明確なエラーハンドリング（Result型の使用）
3. 純粋関数の活用
4. 既存実装との互換性
5. 高いテストカバレッジ

## パフォーマンス特性

10,000文字のドキュメントでのベンチマーク（リリースビルド）：
- 操作の適用: 0.072ms/操作
- 操作の変換: 0.0014ms/変換
- クライアント-サーバー操作: 0.109ms/操作
- 履歴操作: 0.0057ms/操作

## テスト戦略

1. 単体テスト（unittest フレームワーク使用）
2. BDD スタイルのテスト仕様（tests/specs/ ディレクトリ）
3. パフォーマンステスト（benchmarks/ ディレクトリ）

## ビルドと実行

```bash
# ビルド
nimble build

# テスト実行
nimble test

# ベンチマーク実行
nimble benchmark

# ビルド成果物クリーンアップ
nimble clean
```