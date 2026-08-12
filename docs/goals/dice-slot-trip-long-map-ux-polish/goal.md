# DICE SLOT TRIP 長距離マップ向けUX調整

## Objective

90マス化後のプレイ時間と画面密度に合わせて、MISSION目標、HP/LIFE HUD、全体マップ操作、ボスレース開始位置を分かりやすく気持ちよく調整する。

## Goal Kind

`specific`

## Current Tranche

4要件の現行所有箇所と回帰リスクを調査し、安全な実装順を決定し、必要な変更と自動・実画面検証を完了して監査する。

## Non-Negotiable Constraints

- COIN mission target is 12 and role-completion target is 5 unless an existing mode-specific invariant proves this unsafe.
- LIFE is visually above HP; HP hearts appear directly below it without increasing persistent HUD height or shrinking the playfield.
- The full-map surface must support direct finger drag/pan to reach every map region, with bounded content and no interaction leak to gameplay behind the modal.
- Boss-race start alignment must be corrected from runtime evidence, keeping both racers visible and the camera synchronized at the true start state.
- Preserve the completed 90-map, HP/LIFE, save-migration, EVENT, skill, and recovery-roulette contracts.
- Preserve existing dirty work and avoid unrelated redesign.

## Stop Rule

Stop when all four requirements have implementation, regression tests, native mobile visual evidence, and a final Judge audit; or when every safe local next action is blocked.

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-long-map-ux-polish/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-long-map-ux-polish/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active task.
3. Record receipts and verification immediately.
4. Continue from Scout/Judge into safe Worker execution unless blocked.
5. Complete only after requirement-by-requirement audit.
