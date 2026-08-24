# Amazon 通常マップ 京都・カイロ UI 統一

## Objective

Amazon 通常ステージ「翠雨の大瀑布」の通常マップ画面を、京都を正解見本とする現在地＋前方6マス型UIへ安全に統一し、Amazon固有のコース・FLOW・分岐・EVENT・秘密洞窟・ボス導線を維持する。

## Goal Kind

`specific`

## Current Tranche

現状と検証経路を把握し、Amazon通常マップのHUD・中央7カード・共通アイコン・下部操作UI・ミッションを限定差分で実装する。Amazon固有挙動と京都・カイロの回帰を検証し、可能なら同条件キャプチャを残して完成監査まで行う。

## Non-Negotiable Constraints

- 京都の通常画面を正解見本とし、Amazon専用の別UI文法を新設しない。
- Amazonの120マス、コースJSON、FLOW、分岐、EVENT、秘密洞窟、背景、ボス「瀑流」と遷移を維持する。
- 京都の分岐・御朱印・ボス、カイロのミッション・ボス、共通ダイス/ITEM/SKILLを壊さない。
- ボス専用UIとゲーム内容を変更しない。
- 大規模リファクタリング、全面分割、基盤再設計を行わない。
- 既存のユーザー変更と未追跡ファイルを保持し、無関係な差分を変更しない。
- Solが統合・監査を担当し、利用可能なら `stealth/ox-alpha` を読み取り調査および境界付き実装サブエージェントとして使用する。

## Stop Rule

完成監査が通る、すべての安全なローカル作業が阻害される、または認証・破壊的操作・製品判断が必要になった時点で停止する。

計画・調査・実装候補の選定だけでは停止しない。

## Canonical Board

Machine truth lives at:

`docs/goals/amazon-kyoto-cairo-ui-parity/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/amazon-kyoto-cairo-ui-parity/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active task.
3. Keep write ownership bounded to the active Worker.
4. Record evidence and verification in each receipt.
5. Continue through final Judge/PM audit unless blocked.
