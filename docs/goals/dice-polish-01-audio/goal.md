# DICE-POLISH-01 ダイス物理SE

## Objective

制御型2.5Dダイスへ、反復しても疲れにくいlaunch／roll／contact／land／lockの物理音を追加し、早止めと複数ダイスの重量感を高める。

## Goal Kind

`specific`

## Current Tranche

共有音声プール、15音源、音量・ピッチ揺らぎ、発音上限、設定・DEBUG、桃鉄風の前方投射軌道、回帰QAを実装してJudge監査する。

## Non-Negotiable Constraints

- 役成立音、振動、角丸モデル、革テクスチャは対象外。
- 5ダイスでもroll同時2音、contact最大4回、音量急増を防ぐ。
- 出目、役、移動、保存、早止め結果へ音が影響しない。
- SE音量0またはミュートでもゲームが正常に進む。
- 既存M3/M4A/RISK回帰を維持する。

## Canonical Board

`docs/goals/dice-polish-01-audio/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-polish-01-audio/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
