# DICE SLOT TRIP ダイス成長スライス

## Objective

新規旅を1ダイスから始め、アイテムマスとイベント報酬で2・3ダイスへ成長させ、3ダイス到達時にスロット役を解禁する。既存M4Aイベント、M3ボス交流、保存互換、目押し操作を維持する。

## Goal Kind

`specific`

## Current Tranche

新規旅のダイス成長、2・3ダイス解禁報酬、3ダイス時の役解禁、旧セーブ移行、DEBUG、通常／イベント／リスクマス回帰を実装し、Judge監査を完了する。

## Non-Negotiable Constraints

- 新規ゲームは1ダイスから開始する。
- アイテムマスまたはイベント報酬で最大3ダイスまで増える。
- 3ダイス到達前は役を成立させない。
- 3ダイス到達時にPAIR／STRAIGHT／TRIPLE等のスロット役を解禁する。
- 5ダイスは既存の特別イベント／アイテム専用で、通常の成長数には含めない。
- 旧M0〜M4Aセーブは3ダイス解禁済みとして安全に移行する。
- 目押しの左停止、一括停止、自動停止、M4A追加ダイスを壊さない。

## Stop Rule

ダイス成長スライスの実装・回帰・Judge監査が完了した時点で停止する。キャラクター固有スキルや20アイテムの完全実装は別Goalへ分離する。

## Canonical Board

`docs/goals/dice-slot-trip-dice-progression/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-dice-progression/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
