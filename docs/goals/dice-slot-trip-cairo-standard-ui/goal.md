# DICE SLOT TRIP Cairo Standard Core UI v1.0

## Objective

カイロ完成版のコアUIを、MISSION・SLOT・通常盤面がすべて「次の1投で何を狙うか」へ収束する標準レイアウトとして実装する。既存のMISSION/SLOT trancheとコイン画面差分を保全し、360x640相当で初見の家族が判断できることを基準にする。

## Goal Kind

`specific`

## Current Tranche

提示されたMISSION候補12本、周回別の難易度抽選、MISSION/SLOT/MAPの一致・競合ナビ、通常画面の3階層再配置を、カイロV06の現行セーブ・周回・ボス遷移を壊さない順序で監査し、最初の安全な統合実装まで進める。

## Non-Negotiable Constraints

- 1周1MISSION。初期12本は EASY 4 / NORMAL 6 / HARD 2 の候補を基準にする。
- 報酬は EASY 8 / NORMAL 12 / HARD 18 TRIP COIN を試算対象にする。
- 1〜2周目 EASY70/NORMAL30/HARD0、3〜5周目 EASY35/NORMAL55/HARD10、6周目以降 EASY20/NORMAL60/HARD20 を初期抽選率として検証する。
- MISSION・SLOT・MAPが一致したときは強く示す。競合時は最大2行で重要な候補を並べ、単一の「おすすめ」を出して判断を奪わない。
- 3要素一致、MISSION+SLOT、MISSION+MAP、SLOT+MAP、競合、SLOTのみ、MISSIONのみ、何もなしの表示優先順位を明示的な純粋ロジックでテストする。
- 通常画面は「上:旅の状態 / 中:着地点 / 下:狙いナビ+SLOT+ROLL」。全体MAPは常設せずボタンから開く。
- 通常表示はHUD・MISSION・盤面・狙いナビ・SLOT・ROLL・4ボタンに絞り、判断がないターンは静かにする。
- SCOREは累計歩数の意味を変えない。通常SLOT報酬はPA​​IR +1 / STRAIGHT +3 / TRIPLE +5、ボスに通常報酬を付けない。
- 旧schema2 SAVE、周回、ボス、ITEM、GAME OVER、既知のプレイ画面QAベースラインを保全する。
- 京都再設計、CASINO CHIP、広域経済再調整はこのtrancheの範囲外。

## Stop Rule

既存SAVEの意味を壊す、360x640で主要情報が重なる、競合ロジックが「おすすめ」を強制する、または必要ファイルがWorkerの許可範囲を超え、安全な小分けへ切り替えられない場合は止める。計画だけで終えず、最初の安全な縦切りが確定したら実装・検証まで進める。

## Canonical Board

`docs/goals/dice-slot-trip-cairo-standard-ui/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-cairo-standard-ui/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
