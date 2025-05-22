以下に、Operational Transformation（OT）とConflict-free Replicated Data Type（CRDT）の主な相違点をまとめます。両者は分散・リアルタイム共同編集のための代表的アルゴリズムですが、アーキテクチャや整合性確保、性能特性、実装の複雑さなど多くの点で異なります。本稿では、理論的アプローチ、システム構成、整合性モデル、性能・スケーラビリティ、オフライン対応、実装の複雑さという観点から比較します。

## 理論的アプローチの違い

### OTのアプローチ

OTは「操作（Operation）」を中心に据え、各編集操作を変換（Transformation）して適用順序のズレを補正する手法です。受信した操作に対し、既に適用済みの他操作を考慮してInsert/Deleteの位置を調整し、一貫性を維持します ([ウィキペディア][1]).

### CRDTのアプローチ

CRDTは操作や状態の可換性（commutativity）をデータ構造側で保証し、競合解消のためのマージ関数を不要にします。Replica間で操作をそのまま適用しても最終的に収束（eventual convergence）を実現できる点が特徴です ([ウィキペディア][2]).

## システム構成とトポロジー

* **OT**：中央サーバーによる操作の序列化・調整が前提となる集中型アーキテクチャが主流です ([Stack Overflow][3]).
* **CRDT**：P2Pや分散ノード間での直接同期が可能で、ネットワーク分断（partition）にも耐性があります ([Stack Overflow][3]).

## 整合性モデル（Consistency）

* **OT**は「因果関係の保存（Causality Preservation）」と「収束性（Convergence）」、さらに「意図の保存（Intention Preservation）」を順序変換アルゴリズムで担保します ([ウィキペディア][1]).
* **CRDT**は操作自体の可換性により「出現順に依存しない同一最終状態」を保証し、因果関係はベクタークロック等でトラッキングします ([ウィキペディア][2]).

## 性能とスケーラビリティ

* **OT**は、操作履歴（H）に依存する変換処理が多く、文書長（N）に比して履歴が大きいとO(H²)の処理が発生する場合があります ([Hacker News][4]).
* **CRDT**は多くの設計でO(log N)やO(N)メタデータサイズとなり、ガーベジコレクション不要な手法（Logoot, LSEQなど）では特に高性能を示します ([Hacker News][4]).

## オフライン対応

* **OT**は中央サーバー依存のため、完全なオフライン操作を行うとサーバー再接続後の操作調整が複雑になります ([https:/thom.ee/][5]).
* **CRDT**はローカルでの操作蓄積と後続マージを前提とし、オフライン編集→オンライン同期のワークフローに自然に対応します ([https:/thom.ee/][5]).

## 実装の複雑さとメタデータ

* **OT**では変換アルゴリズム（IT/ET）の設計と正当性検証が難易度高く、多数のプロパティチェックが必要です ([arXiv][6]).
* **CRDT**は操作／状態の合併ロジックをデータ型に組み込みますが、複雑なデータ構造やメタデータ（タイムスタンプ、ユニークIDなど）が肥大化しがちです ([Fiberplane][7]).

## 採用例とユースケース

* **OT**はGoogle DocsやShareDB、Apache Waveなど、大規模なリアルタイム共同編集プロダクトで広く採用されています ([ADS][8]).
* **CRDT**は分散データストア（Redis、Riak、Cosmos DB）、オフラインファーストのチャットアプリ、分散キャッシュ用途などで強みを発揮しています ([ウィキペディア][2]).

---

OTは中央集権的な順序調整に強みがあり、リアルタイム編集で実績が豊富です。一方CRDTは分散・オフライン性に優れつつ、データ構造の可換性でシンプルな同期を可能にします。要件に応じて、性能・オフライン対応性・実装難易度・システム構成を比較した上で選択するのがよいでしょう。

[1]: https://en.wikipedia.org/wiki/Operational_transformation?utm_source=chatgpt.com "Operational transformation"
[2]: https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type?utm_source=chatgpt.com "Conflict-free replicated data type"
[3]: https://stackoverflow.com/questions/26694359/differences-between-ot-and-crdt?utm_source=chatgpt.com "algorithm - Differences between OT and CRDT - Stack Overflow"
[4]: https://news.ycombinator.com/item?id=18191867&utm_source=chatgpt.com "Real Differences Between OT and CRDT for Co-Editors - Hacker News"
[5]: https://thom.ee/blog/crdt-vs-operational-transformation/?utm_source=chatgpt.com "Deciding between CRDTs and OT for data synchronization - Tom's site"
[6]: https://arxiv.org/abs/1905.01518?utm_source=chatgpt.com "Real Differences between OT and CRDT under a General Transformation Framework for Consistency Maintenance in Co-Editors"
[7]: https://fiberplane.com/blog/why-we-at-fiberplane-use-operational-transformation-instead-of-crdt/?utm_source=chatgpt.com "Why we at Fiberplane use Operational Transformation instead of ..."
[8]: https://ui.adsabs.harvard.edu/abs/2018arXiv181002137S/abstract?utm_source=chatgpt.com "Real Differences between OT and CRDT for Co-Editors - ADS"
