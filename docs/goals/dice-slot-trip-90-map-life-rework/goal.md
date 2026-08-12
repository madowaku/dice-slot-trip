# DICE SLOT TRIP 新90マップ・HP/LIFE再設計

## Objective

`DICE SLOT TRIP 改善実装指示.md`を現行V06実装へ安全に反映し、新しい90マスの旅、HP3固定とLIFE3、回復専用ハートルーレット、後半寄りEVENT配置、直感的な探検猫スキルUIを、旧V06セーブ移行と実画面検証を含めて製品品質で成立させる。

## Goal Kind

`specific`

## Current Tranche

現行のコース・セッション・セーブ・UI・テストを調査し、指示書と構造上の衝突を解決する。Judgeが選んだ最初の安全な実装スライスを実装・検証し、全体改修へ継続可能な状態か監査する。安全なWorkerタスクが確定した場合は計画だけで止めない。

## Non-Negotiable Constraints

- 現在のdirty / untracked差分をユーザー作業として保護し、branch切替、merge、rebase、reset、restore、checkoutを行わない。
- 現行V06コードと自動テストを実装上の正とし、古いREADMEや旧90マスをそのまま復活させない。
- 新メインルートは0〜89の90マス、START=0、BOSS_GATE=89、EVENTは30未満に置かない。
- 既存の8マス円環、EXIT距離表示、3回目救済、順序付きSTRAIGHT、ボス20マス鏡面レース、ダイス速度・停止契約を維持する。
- HPは常に最大3、LIFEは0〜3の復活ストックとし、コイン5枚の緊急復帰を廃止する。
- 開始時LIFE3は「現在HPとは別にあと3回復活できる」仕様として、HUDでも誤解しにくく表示する。
- 10周ごとのLIFE回復は最大3。満タン時も節目の達成感を損なわない短い表示を検討するが、恒久的な追加報酬は作らない。
- 回復ルーレットは既存6分割・STOP・ゴール差速度を維持し、`HP +1 / HP +2 / HP +1 / FULL / HP +1 / HP +2`だけを持つ。
- 旧V06途中セーブは累積SCORE、BEST、LAP、発見履歴、初回説明、設定を守り、新90マスSTARTへ安全に移行する。
- LIFE表示に絵文字フォントを使わず、既存のゲーム内猫画像または適切な既存ラスター資産を使う。
- 720×1280、720×1600、360×640相当で中央マップと主操作を保護する。
- 必要のない全面リファクタリングや対象外UI改修を行わない。
- 近道1は分岐32から本線41へ合流する9対5マス構成を第一候補、近道2は分岐71から本線83へ合流する12対6マス構成を第一候補とし、Scout/Judgeが接続整合性を確認する。

## Stop Rule

Stop when the tranche audit passes, all safe local work is blocked, or continuing would require owner input, credentials, destructive operations, or strategy the board cannot decide.

Do not stop after planning, discovery, or Judge selection if the user asked for working software and a safe Worker task can be activated.

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-90-map-life-rework/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-90-map-life-rework/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Assign Scout, Judge, Worker, or PM according to the task.
5. Write a compact task receipt.
6. Update the board.
7. If Judge selected a safe Worker task with `allowed_files`, `verify`, and `stop_if`, activate it and continue unless blocked.
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original user outcome.
