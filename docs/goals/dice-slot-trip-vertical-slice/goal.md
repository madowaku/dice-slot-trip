# DICE SLOT TRIP 縦切りプロトタイプ

## Objective

`Dice_Slot_Trip_仕様書.md` を正として、Godot 4.x / GDScript で Android 縦持ち向けの実際に遊べる縦切りを構築する。最初の実装スライスでは M0〜M2 を完成させ、生成素材を差し替え可能な構造で組み込む。

## Goal Kind

`specific`

## Current Tranche

仕様・参照画像・環境を確認し、M0〜M2 の安全な実装範囲を確定したうえで、縦画面のプロジェクト土台、90マスの単一ループ、3ダイス移動、周回判定、PAIR / STRAIGHT / TRIPLE / ALL ODD / ALL EVEN、1ダイスと5ダイス、主要着地マスを実装・検証し、次の M3 へ渡せる状態にする。

## Non-Negotiable Constraints

- 仕様書と3枚のコンセプト画像をデザイン・挙動の正とする。
- 基本は3個の6面ダイス、約90マスの閉じた一本道ループとする。
- 通常時は静かで低彩度、役や予兆だけ短く高揚させる。
- 720 x 1280 の縦画面、片手操作、オフライン、中断再開を前提にする。
- GDScriptは可能な範囲で静的型付けし、コンテンツをデータへ分離する。
- 生成画像内の文字をUIとして使わず、Godot Control上に描画する。
- 各マイルストーンで起動し、Debugger / Output / 表示を確認する。
- 現在のGodot MCPが報告する実行環境は4.6.1のため、4.7専用APIへ依存せず、最終的な4.7確認を別途行う。

## Stop Rule

トランシェ監査が通る、すべての安全なローカル作業がブロックされる、または継続に所有者入力・資格情報・破壊的操作・ボードで決められない戦略判断が必要になった時点で停止する。

計画や調査だけでは停止せず、安全なWorkerタスクが確定したら実装・検証・監査まで進める。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-vertical-slice/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-vertical-slice/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. このcharterと `state.yaml` を読む。
2. active task だけを作業する。
3. Scout / Judge / Worker のreceiptを記録する。
4. 安全なWorker範囲が決まれば実装と検証へ進む。
5. 最後に仕様・受け入れ条件へ照合する。
