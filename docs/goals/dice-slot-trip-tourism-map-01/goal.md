# TOURMAP-01 観光マップ基盤

## Objective

既存90マス、LAP/CLEAN、名所、RISK、1/2/3/5ダイス、早止め、セーブv6を変更せず、現在地周辺を曲線・簡易遠近・地区景観で見せる新しいTourismMapViewをDEBUG切り替え可能な縦切りとして実装する。

## Goal Kind

`specific`

## Current Tranche

市場地区を対象に、Classic Viewを残したままTourism Viewへ切り替え、現在地周辺11〜17マス、前方重視の到達範囲、危険・名所・メリット、拡大した旅人、既存香辛料市場景観が360×640で読みやすく共存するところまで実装・検証する。

## Non-Negotiable Constraints

- 90マスのindex、マス効果、移動、周回、ダイス結果、保存意味論を変更しない。
- Classic Viewを削除せず、DEBUGで `BOARD_VIEW_CLASSIC` / `BOARD_VIEW_TOURISM` を切り替えられる。
- 観光マップは表示専用。マップ入力や新しい衝突判定を追加しない。
- 表示は現在地を必ず含み、周回境界90→1を自然に扱う。
- 危険、現在地、到達可能範囲を景観より優先する。
- 既存の香辛料市場Lv0〜3景観を±5マス方針のまま再利用する。
- TOURMAP-03のマップ上ダイス、TOURMAP-04カメラ、TOURMAP-05 FLOW演出は混ぜない。
- CLEANスライスの未コミット変更と無関係な未追跡資料を保持する。

## Map Pipeline

- `visual_model`: existing layered/baked scenic raster + project-native vector route
- `runtime_object_model`: separate display-only route/tile/player layers
- `collision_model`: none
- `engine_target`: Godot project-native CanvasItem
- `art_style`: existing clean HD parchment Cairo art
- `visual_asset_source`: existing assets for TOURMAP-01

## Stop Rule

Judge監査が通るか、安全なローカル作業が尽きるか、既存ロジック変更・新規アセット方針・オーナー判断が必要になった時に停止する。安全なWorkerがある限り計画だけで止めない。

## Canonical Board

`docs/goals/dice-slot-trip-tourism-map-01/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-tourism-map-01/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read charter and board.
2. Work only on the active task.
3. Record Scout/Judge/Worker receipts.
4. Keep exactly one active task and one write-capable Worker.
5. Complete only after final Judge audit maps fresh captures and regressions to the objective.
