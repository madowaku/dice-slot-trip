# アマゾン・ボス戦 製品品質化

## Objective

既存の「瀑竜アクアフォール」戦を、ルールが読み取れ、判断に手応えがあり、保存復帰と再挑戦が壊れず、縦長モバイル画面で気持ちよく遊べる製品品質へ引き上げる。

## Goal Kind

`open_ended`

## Current Tranche

現行実装と仕様を調査し、最も効果が高く安全に検証できる最初の改善スライスを選び、ロジック・表示・回帰テストまで実装する。Godot の自動テストと 720×1280 の実画面QAを通し、残課題を監査して次のスライスへつなげる。

## Non-Negotiable Constraints

- ユーザーの既存未コミット変更を保持し、アマゾンボス戦に必要なファイルだけを編集する。
- 既存の旅、LIFE、ハートルーレット、周回契約を壊さない。
- 5レーン、端反射、1ロール最大1ダメージ、3投スロット役、4周ごとの難度上昇という正規仕様を維持する。
- 主要操作と危険予告を 720×1280 の縦長モバイル画面で判読・タップ可能にする。
- 実装完了は自動テストと実画面QAの両方で判断する。

## Stop Rule

Stop when the tranche audit passes, all safe local work is blocked, or continuing would require owner input, credentials, destructive operations, or strategy the board cannot decide.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated.

## Canonical Board

Machine truth lives at:

`docs/goals/amazon-boss-product-quality/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/amazon-boss-product-quality/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Assign Scout, Judge, Worker, or PM according to the task.
5. Write a compact task receipt.
6. Update the board.
7. If Judge selected a safe Worker task with `allowed_files`, `verify`, and `stop_if`, activate it and continue unless blocked.
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome.
