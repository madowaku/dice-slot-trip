# LAP・FLOW・名所景観成長

## Objective

90マス周回に、危険を避けて加速をつなぐLAP／CLEAN／FLOW進行と、狙って止まるほど盤面が育つカイロ名所発展を統合し、保存復元を含む商品品質の縦切りとして遊べるようにする。

## Goal Kind

`specific`

## Current Tranche

既存M3・M4A・1／2／3／5ダイスを維持しながら、仕様と現行アーキテクチャを監査し、最初の安全な統合スライスを実装・視覚比較・Judge監査まで完了する。

## Non-Negotiable Constraints

- `docs/周回ポイント・クリーンラップ・加速連鎖仕様 v0.1.md` と `docs/名所発展・景観成長仕様 v0.1.md` をデータ基準にする。
- 周回ポイントはデメリットで減らさず、どの周回でも最低100を保証する。
- FLOWは1ターン1回だけ更新し、実害を受けた場合だけ0へ戻す。
- 名所は停止時だけ1段階発展し、Lv3を超えず、景観が盤面・危険・現在地を隠さない。
- 現行セーブを破壊せず、欠損フィールドを安全な既定値へ移行する。
- 既存のボス交流、イベント、RISK、ダイス進行、早止め、保存を回帰させない。
- 360×640で主要操作と情報がクリップしない。
- 生成画像は権利上安全なオリジナルとし、用途寸法に合わせてプロジェクト内へ配置する。
- 大規模リファクタリングより、テスト可能なカイロ縦切りを優先する。

## Visual Direction

- `ステージ画面2.png` を構図・階層・質感の主要リファレンスとする。
- 砂岩、羊皮紙、真鍮、青緑を既存UIへ接続し、危険は赤茶、メリットは青緑・金で区別する。
- 大型11マス表示では景観成長を詳しく、全体ミニマップでは軽量な段階印だけを見せる。
- LAP POINT、FLOW、CLEAN、名所レベルは装飾ではなく実データを表示する。

## Canonical Board

`docs/goals/dice-slot-trip-lap-landmark-growth/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-lap-landmark-growth/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
