# DICE SLOT TRIP M3 ループボス交流

## Objective

既存のM0〜M2縦切りへ、同じスフィンクス個体との遭遇、二択交流、交流ゲージ、ゲット、図鑑登録、次個体、保存復元を追加する。ボスは戦闘相手ではなく、旅の途中で少しずつ警戒が解ける存在として扱う。

## Goal Kind

`specific`

## Current Tranche

カイロの3個体をデータ駆動で実装し、通常マスの遭遇抽選・救済・TRIPLE確定・PAIR一回ボーナス、交流モーダル、100%の登録と結果、図鑑、旧セーブ移行を、Godot 4.7上で自動QAと画面キャプチャまで完了させる。

## Non-Negotiable Constraints

- M0〜M2の90マス、3/1/5ダイス、役、早止め、現在地拡大盤面、ミニマップ、保存を維持する。
- HP、攻撃、防御、撃破、討伐、捕獲の概念や表現を使わない。
- 交流は短い状況文と軽い二択で、結果が悪くても最低限のゲージは増える。
- 同じ個体のゲージ・遭遇数・登録状態はセッションと再起動をまたいで保存する。
- 旧セーブは初期個体へ安全に移行する。
- 生成素材とGodot Controlの文字を分離する。

## Stop Rule

Judge監査がM3完了と判断する、または全ての安全なローカル作業が外部入力待ちになった時点で停止する。

## Canonical Board

`docs/goals/dice-slot-trip-m3-loop-boss/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-m3-loop-boss/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```
