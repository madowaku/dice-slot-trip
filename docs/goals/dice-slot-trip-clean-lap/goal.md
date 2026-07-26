# CLEANラップ実装スライス

## Objective

既存のLAP POINT・名所発展・RISK・セーブv6を維持しながら、実害ベースのCLEAN判定、連続達成倍率、危険マスでの即時状態表示、周回結果と次目標表示を、保存復元を含む遊べる縦切りとして完成させる。

## Goal Kind

`specific`

## Current Tranche

CLEANのみを実装し、通常周回・WARP周回・RISK成功/非実害/実害・完全防御・旧セーブ移行・360×640 UI・既存M3/M4A/ダイス/名所回帰を検証してJudge監査を通す。

## Non-Negotiable Constraints

- デメリットを実際に受けた時だけ `current_lap_clean` をfalseにする。
- 完全防御、危険マス通過、挑戦成功、通常のダイス遷移、アイテム購入ではCLEANを失わない。
- 周回ポイントは `floor((100 + lap_bonus) * clean_multiplier)`、最低100。倍率は仕様の連続数テーブルに従う。
- 同一周回解決IDでCLEAN連続数、ポイント、報酬を二重反映しない。
- 旧セーブとM3/M4A/1・2・3・5ダイス/RISK/名所の既存挙動を壊さない。
- FLOW、Health Connect、旅の窓、追加景観画像は別スライスとする。
- 既存アーキテクチャへ局所統合し、大規模リファクタリングを行わない。

## Stop Rule

Judge監査が通るか、すべての安全なローカル作業が詰まるか、オーナー判断が必要になった時に停止する。安全なWorkerがある限り計画だけで止めない。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-clean-lap/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-clean-lap/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active task.
3. Record Scout, Judge, Worker receipts immediately.
4. Keep exactly one active task and one write-capable Worker.
5. Complete only after final Judge audit maps implementation and verification to the objective.
