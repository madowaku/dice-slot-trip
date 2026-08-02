# DICE SLOT TRIP 2026-08 製品化ブラッシュアップ

## Objective

2026-08-01 の録画・スクリーンショット・詳細フィードバックを現行 Godot 実装へ照合し、プレイヤーが酔いや座標ずれを感じるボスレースの一投処理を最優先で安定化する。その後、通常マップの情報設計、操作面、初回説明、メニュー、円環救済、アイテム・スキル・ポストカード図鑑を、検証可能な小さな実装単位で製品品質へ進める。

## Goal Kind

`open_ended`

## Current Tranche

通常マップのロールボタンとスロット操作を、見えているボタン本体と実際の押下領域が一致するモバイル向けControl構造へ整える。常時表示の小説明文を減らし、主操作は「振る」、スロットは3リールと残り回数が瞬時に読める状態へ整理する。既存のカメラ・盤面・固定3ミッション・ボス画面を保護しながら、720×1280 / 360×640 の入力・レイアウト・視覚証拠を監査する。

## Non-Negotiable Constraints

- 現在の `main`、HEAD `6322e1d`、既存の大量の dirty / untracked 差分をユーザー作業として保護し、reset、restore、checkout、rebase、merge を行わない。
- 2026-08-01 のユーザー指示と添付録画を、古い goal receipt や旧設計書より優先する。
- ボスレースの一投処理中、カメラの最終目標決定は最大一回とし、移動中に競合する tween・smooth follow・逐次再センタリングを併用しない。
- 効果アイコンまたは短時間ポップアップは対象のワールド位置または同じ盤面階層へ結び、HUD / Control のローカル座標と Node2D のワールド座標を混在させない。
- カメラを動かさなくても両者が安全領域に収まる場合は盤面を固定する。
- Godot 4.7、Android 縦持ち 720×1280、360×640 の縮小確認、片手操作、既存セーブ互換を維持する。
- 新しいラスター素材はこのトランシェでは生成しない。カメラ、座標、Control / Node2D 構造、ラベルで解決する。
- ミッションは旅／スロット／挑戦から各1本を選び、同一ステージでも攻略ルートが変わる選出を保つ。
- 報酬は score event ID で冪等化し、既存の `awarded_score_event_ids` とセーブ互換を壊さない。
- 通常マップではロール入力を1つの主ボタンへ集約し、二重タップ・移動中入力を無効化する。
- ロールボタンとスロットの見た目／Control寸法／押下領域を一致させ、48px以上の片手タッチ領域を維持する。
- このトランシェでは新しいラスター素材を生成せず、既存アートとGodotのControl／状態表示で解決する。
- Worker は明示された `allowed_files` だけを変更し、既存差分を巻き戻さない。

## Follow-on Backlog

1. 常時表示の小説明文と誤説明を撤去し、確定時だけ大きな「Nマス進む」を表示する。
2. マス番号を「現在」と `+1〜+6` に整理し、`#02〜#07` を撤去する。
3. 上部ステータスを整理し、現在位置 `1 / 58` と進行バーを明確化する。
4. ロール / スロットの見た目と実押下領域を一致させる。
5. 初回マス説明をユーザー操作で閉じるカードにする。
6. ステージ離脱を確認付きメニュー内へ移す。
7. 円環出口の形・矢印・発光と 3〜4 周目救済を実装する。
8. 日本語 / 英語翻訳基盤、勝利画面、演出軽減、復帰 / オートセーブを仕上げる。
9. アイテム、探検猫スキル、マス図鑑、旅で得たポストカード図鑑を製品化する。

## Stop Rule

現在トランシェの監査が通る、すべての安全なローカル作業がブロックされる、または継続に所有者入力・資格情報・破壊的操作・プロダクト戦略判断が必要になった時点で停止する。計画・調査・Judge 選定だけでは停止しない。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-2026-08-product-polish/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-2026-08-product-polish/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active board task.
3. Assign Scout, Judge, Worker, or PM according to the task.
4. Write a compact task receipt immediately after each task.
5. Activate a safe Worker selected by Judge and continue unless blocked.
6. Finish the tranche only after Judge / PM audit maps implementation and verification to the recording and user feedback.
