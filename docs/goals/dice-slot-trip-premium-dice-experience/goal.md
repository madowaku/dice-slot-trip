# DICE SLOT TRIP プレミアム・ダイス体験

## Objective

新しいダイス獲得・消費ループと2.5Dサイコロ演出をGodot 4.7へ統合し、カイロ盤面をGoogle Playの有料作品として通用する視認性・手触り・情報階層へ磨く。

## Goal Kind

`specific`

## Current Tranche

1／2／3ダイスの状態遷移、DOUBLEとDice Slotの消費・継続、改訂90マス配分と主要ダイス供給、制御された2.5Dダイス表示、プレミアム縦画面UIを実装し、既存M0〜M4Aと保存互換を監査する。

## Non-Negotiable Constraints

- 新規旅は1ダイス。2ダイスはDOUBLE CHANCE、3ダイスはDICE SLOTとして原則1ロールで消費する。
- 5ダイスは一時的なDICE FESTIVALであり、通常所持数を変更しない。
- 左から順の早止め、一括停止、自動停止、DEBUG固定出目を維持する。
- 出目はゲームロジックが決定し、見た目の物理へ依存させない。
- 90マス、M3ボス交流、M4Aイベント、保存・旧セーブ移行を壊さない。
- Compatibility rendererとAndroidを前提に、最大5ダイスでも軽量にする。
- 参考画面の砂色・ターコイズ・金縁・カイロ旅行絵本の方向を維持する。

## Stop Rule

第一実装トランシェのゲーム状態、盤面、2.5Dダイス、UI、回帰、画面証跡をJudgeがcompleteと判定した時点で停止する。20アイテム全操作画面や全30イベントの完全実装は後続Goalへ分離できる。

## Canonical Board

`docs/goals/dice-slot-trip-premium-dice-experience/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-premium-dice-experience/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
