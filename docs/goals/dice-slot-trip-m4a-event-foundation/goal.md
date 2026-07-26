# DICE SLOT TRIP M4A イベント基盤

## Objective

カイロの地区別イベント抽選、共通イベント状態機械、RewardResolver、二択、追加1／3／5ダイス、ボス交流引き継ぎ、保存復元を実装し、代表10イベントを最後まで遊べる状態にする。

## Goal Kind

`specific`

## Current Tranche

M4A詳細仕様の代表10イベントと共通基盤を実装し、20件の必須テスト、M0〜M3回帰、実画面キャプチャを通してJudge監査を完了する。

## Non-Negotiable Constraints

- Godot 4.7、既存90マス、1／3／5ダイス、早止め、M3ボス交流、保存互換を維持する。
- イベント固有コードから直接報酬を変更せず、共通RewardResolverを通す。
- resolution_idによる二重適用防止を保存復元後も維持する。
- 追加ダイスは移動せず、到着時ロール情報を上書きしない。
- 1ターンのボス遭遇は最大1回とする。
- 5〜15秒の短い挿話というテンポを維持し、過剰な汎用化や大規模リファクタリングを避ける。

## Stop Rule

M4A監査が合格するか、すべての安全なローカル作業がブロックされるか、ユーザー判断が必要になった時点で停止する。安全なWorker作業がある限り、計画だけで止めない。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-m4a-event-foundation/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-m4a-event-foundation/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
