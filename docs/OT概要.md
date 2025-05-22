以下では、Operational Transformation（OT）の概要をまとめます。まず冒頭でOTの目的と特徴を簡潔に紹介し、その後に歴史的背景、基本概念、核となるアルゴリズム、代表的な用途やライブラリまでを解説します。

## 概要まとめ

Operational Transformation（OT）は、複数ユーザーが同時に同一ドキュメントを編集する際に発生する競合（コンフリクト）をリアルタイムに解消し、一貫性のある最終状態を保証する分散アルゴリズムです。各ユーザーの操作（挿入・削除など）を“操作(OP)”として扱い、受信順や生成元が異なる操作同士を相互に変換（Transformation）して適用順序のズレを補正します。これにより、全てのクライアントが同じ状態でドキュメントを保ちつつ、ローカルレイテンシーを最小限に抑えたリアルタイム共同編集が可能となります。

## 1. 背景と歴史

### 1.1 発祥と発展

* 1989年にスイス連邦工科大学のC. EllisとS. Gibbsが提唱した「Undo à la carte」研究が嚆矢とされる。
* 1990年代にはDSM（Distributed Shared Memory）環境で研究が進み、1995年のRAS (Real-time Application Sharing) などで実装例が登場。
* 2000年代に入ると、Xerox PARC や CMU、Microsoft Research などで重要な改良や理論的整理が行われ、Google Docs（2006年〜）など商用サービスへ導入された。

### 1.2 OT vs. CRDT

* OTは「操作の順序変換」によって整合性を取る手法で、従来型の集中型サーバーアーキテクチャと親和性が高い。
* 対してCRDT（Conflict-free Replicated Data Type）は、各操作が可換性を持つようにデータ構造を設計し、分散ノード間での同期を容易にする手法。
* OTはリアルタイム編集で長く実績を積んでいる一方、CRDTはオフライン編集やピアツーピア構成での利用に強みがある。

## 2. 基本概念

### 2.1 操作（Operation）

* **Insert(pos, text)**：指定位置に文字列を挿入
* **Delete(pos, length)**：指定位置から一定長を削除
* これらをイベントとしてクライアント→サーバー間またはクライアント同士で送受信

### 2.2 コンテキスト（Context）

* 各操作には、どのバージョン（バージョンベクターやシーケンス番号）から派生したものかを示す「コンテキスト情報」が付与される
* コンテキストを基に、他ユーザー操作との競合を検出

### 2.3 変換（Transformation）

* 受信操作に対し、自身が既に適用済みのローカル操作を考慮して位置情報を調整
* **Inclusion Transformation (IT)**：後から来た操作を、先着のローカル操作に合わせて変換
* **Exclusion Transformation (ET)**：既に適用された操作を、後から来た操作に合わせて巻き戻す

### 2.4 整合性モデル

* **Convergence**：全クライアントが同一最終状態に到達
* **Causality Preservation**：因果関係を壊さず、生成順序を尊重
* **Intention Preservation**：ユーザーが意図した編集結果を維持

## 3. OTアルゴリズムの流れ

1. **ローカル操作の生成**
   ユーザーが編集すると、即座にローカルに反映しつつ操作イベントを生成。
2. **操作の送信**
   サーバーもしくはピアに操作を送る。
3. **操作受信と変換**
   受信側では、未適用のローカル操作群に対してIT／ETを適用し、操作を調整。
4. **操作の適用**
   変換後の操作をドキュメントに反映し、バージョンをインクリメント。
5. **ACKとバージョン管理**
   サーバーはACKを返し、クライアントはリモート適用済みの操作をリストから削除。

## 4. 代表的なOTライブラリ

### 4.1 ShareDB（JavaScript/Node.js）

* MongoDBと連携したリアルタイム編集サーバー
* クライアントには `ot.js` をバンドルし、ブラウザ上でOTを適用

### 4.2 ot.js（JavaScript）

* ShareDBの基盤となるライブラリ
* シンプルなInsert/Delete操作の変換関数を提供

### 4.3 ShareJS（古典的な実装）

* ShareDBの前身
* WebSocket ベースでシンプルに動作
* 現在はメンテナンスフェーズ

### 4.4 Apache Wave（Java/Go）

* Google Waveをオープンソース化したプロジェクト
* OTに基づくリアルタイムコラボレーション機能を提供

### 4.5 ot-diff-match-patch（多言語）

* Googleの diff-match-patch をベースにOT機能を追加した実装
* Go、Python、Java、JavaScriptなどマルチ言語対応

## 5. 簡易サンプル（JavaScript）

```javascript
import { TextOperation, Client } from 'ot';

const doc = 'Hello World';
const client = new Client(0); // バージョン0から開始

// ローカル挿入操作
const op1 = new TextOperation()
  .retain(6)
  .insert('Beautiful ')
  .retain(5);

client.applyClient(op1);
console.log(client.document); // -> "Hello Beautiful World"

// サーバーからの操作受信（Delete "World"）
const op2 = new TextOperation()
  .retain(6)
  .delete(5)
  .insert('Universe');

client.applyServer(op2);
console.log(client.document); // -> "Hello Beautiful Universe"
```

## 6. 注意点とベストプラクティス

* **遅延と順序**：ネットワーク遅延や順序入れ替わりに強い設計が必須
* **バージョン管理**：バージョンベクトル vs. 単一インクリメント
* **スケーラビリティ**：サーバー負荷軽減のため、操作ログのガーベジコレクション
* **セキュリティ**：悪意ある操作の検証や認証・認可

---

この概要を踏まえ、次ステップとして具体的なライブラリの選定とサンプル実装を進めるとスムーズです。ご要望に応じて、より詳細なアルゴリズム解説や他言語でのサンプルコードもご用意いたします。
