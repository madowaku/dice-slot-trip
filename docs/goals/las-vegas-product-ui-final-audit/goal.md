# Las Vegas Product UI Final Audit

## Objective

Phase C後のLas Vegas 6施設を実画面で総合監査し、製品UIクオリティを阻害する最大の残存課題を特定する。既存素材と小規模コード調整で足りない場合に限り、画像生成モデルで一貫した新規アセットを制作・実装し、360×800実描画と回帰テストで検証する。

## Goal Kind

`audit`

## Current Tranche

Phase Cの実装済み画面・キャプチャ・UIコード・既存アセットを比較し、最も高いレバレッジを持つ安全な改善を1スライス選ぶ。必要なら新規画像を1系統だけ生成して実装し、Godot 4.7実描画、360×800比較、Las Vegas回帰、独立コミットとpushまで完了して再監査する。

## Non-Negotiable Constraints

- 経済、RTP、BET、transaction、勝敗ロジック、ゲームルールを変更しない。
- 監査開始前からの未コミット差分253件のうち、ラスベガス／カジノ関連と証拠で判定できるものはユーザーの追加指示によりレビュー後にコミット対象へ含めてよい。APK、他都市、無関係な音源・import・export設定は変更・ステージ・コミットしない。
- 画像生成は、既存素材やコードネイティブ表現では製品品質に届かないと監査で判定した箇所だけに限定する。
- 新規アセットは既存Las Vegasのネオン、真鍮、深色背景、Noto Sans JPの方向性に合わせ、プロンプトと由来を残す。
- 360×800で可読性、タップ領域、結果理解、施設差別化を維持する。
- 大規模UI再構築、メタシステム、新ゲーム、新ルールは行わない。

## Stop Rule

トランシェ監査が合格したとき、すべての安全なローカル作業がblockedになったとき、または継続にユーザー判断・資格情報・破壊的操作・製品戦略が必要になったときに停止する。

計画、発見、Judge選定だけでは停止しない。安全なWorkerタスクが選ばれた場合は実装・検証・再監査まで進める。

## Canonical Board

Machine truth lives at:

`docs/goals/las-vegas-product-ui-final-audit/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/las-vegas-product-ui-final-audit/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
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
