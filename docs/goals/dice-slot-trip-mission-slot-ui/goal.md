# DICE SLOT TRIP MISSION and SLOT UI

## Objective

カイロを基準に、提示された「MISSION欄 新UIワイヤー案 v1.0」と「SLOTリーチ演出 UIワイヤー案 v1.0」を、初見で意味が分かり、次に狙う出目が明確で、全ステージへ展開しやすい実装へ落とし込む。既存のコイン画面UI差分は保持し、MISSION/SLOTの安全な実装スライスを検証する。

## Goal Kind

`specific`

## Current Tranche

MISSIONの1周1件表示、進捗とTRIP COIN報酬の常設表示、2投目時点のSLOTリーチ案内、役成立時の短いCOIN演出、MISSIONとのダブルチャンス表示を、現行セーブ・周回・ボス遷移を壊さない範囲で実装する。

## Non-Negotiable Constraints

- カイロのV06 runtimeを基準にし、京都ボスの再設計は行わない。
- ユーザー指定のワイヤー文言・優先順位を実装仕様の根拠にする。ただし現行コードと矛盾する箇所は、セーブ互換と既存回帰を優先して明示的に扱う。
- MISSIONは常設1件、内容・進捗数値・視覚進捗・TRIP COIN報酬を同時に理解できること。
- SLOTは2投目のあとに狙い数字と役、報酬COINを短く示す。MISSION対象と重なる場合はダブルチャンスを示す。
- 演出は短く、360x640相当で主要操作と重ならないこと。
- SCOREは累計歩数の意味を変えない。既存コイン画面の未コミット差分を保全する。
- SAVE、周回、ボス遷移、ITEM、ゲームオーバーの回帰を検証する。
- Lunaは監査・試算・テスト設計のみ。実装はSolのWorker作業として行う。

## Stop Rule

セーブ形式の不確実性、既存テストの新規回帰、または必要ファイルがWorkerの許可範囲を超え、かつ安全な縮小スライスへ切り替えられない場合は止める。計画だけで止めず、安全なWorker実装が確定したら実装・検証まで進める。

## Canonical Board

`docs/goals/dice-slot-trip-mission-slot-ui/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-mission-slot-ui/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

