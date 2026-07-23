# DICE SLOT TRIP v0.7 製品化

## Objective

`docs/改善統合仕様書 v0.6.md` と追加仕様 `docs/Dice_Slot_Trip_画面レイアウト_ステージ設計仕様書_v0.7.md` を現行の正として、現在の Godot プロトタイプを Google Play の有料ゲームとして納得感のある製品品質へ移行する。ゲームループ、片手操作、UI/UX、旅情のあるアート、スプライト、サウンド、性能、Android 検証を一体で改善する。

## Goal Kind

`open_ended`

## Current Tranche

v0.7の更新を優先し、固定32マス前提を廃止して、土地ごとの長さをデータで表現する。カイロを58マス級の標準旅行ステージへ拡張し、通常画面を「キャラクターをほぼ固定・進行方向6マス・固定トレイ」の視線設計へ移行する。実装後は円環全体表示、ボス前後、720×1280/360×640の操作と可読性を検証する。

## Non-Negotiable Constraints

- ゲームルールと優先順位は `docs/改善統合仕様書 v0.6.md` と v0.7追加仕様を正とし、旧仕様との衝突を黙って混在させない。
- Godot 4.7、Android 縦持ち 720 x 1280、片手操作、オフライン、中断再開を維持する。
- ユーザーの既存変更と完了済み Goal Maker ボードを保持し、無関係な差分を巻き戻さない。
- 長時間の反復プレイで視線・酔い・入力疲労を増やさず、マップ中央と固定ダイストレイを最優先する。
- 製品版UIは汎用アプリ風ダッシュボードにせず、カイロを旅する周回型ダイスアドベンチャー固有の素材感と階層を持たせる。
- 新規ラスター素材は Kenney の利用条件を確認した素材、または ImageGen によるオリジナル素材を使う。出典・プロンプト・加工手順を追跡可能にする。
- キャラクターやアニメーションは承認済みの基準フレームから全ストリップを生成し、共通スケール・共通アンカーで正規化する。
- 画像生成物をUI文字として使わず、読ませる文字と数値は Godot の Control / Label と Noto Sans JP で描画する。
- Figma参照が供給された場合はデザインコンテキストとスクリーンショットの両方を取得してから実装する。参照が無い段階でFigma準拠を装わない。
- visual target を選ぶ前に製品UIを実装しない。まず比較可能な3案を作り、選定後に image-to-code の忠実実装へ進む。
- 各 Worker は許可されたファイルだけを変更し、Godot parse、ロジックテスト、操作スモーク、同一viewportの画面比較を実施する。

## Stop Rule

トランシェ監査が通る、すべての安全なローカル作業がブロックされる、または継続に所有者入力・資格情報・破壊的操作・ボードで決められない戦略判断が必要になった時点で停止する。

計画・調査・Judge選定だけでは停止しない。ただし、Product Design の3案から visual target を選ぶ段階では所有者の選択を待つ。

## Canonical Board

Machine truth lives at:

`docs/goals/dice-slot-trip-v06-productization/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/dice-slot-trip-v06-productization/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. この charter と `state.yaml` を読む。
2. active task だけを作業する。
3. Scout / Judge / Worker / PM をタスクの assignee に従って割り当てる。
4. 各タスク完了時に compact receipt を書く。
5. visual target 未選定なら3案を生成して所有者の選択を待つ。
6. 選定後、安全な Worker 範囲が確定したら実装と検証へ進む。
7. 最後に Judge / PM 監査で v0.6 と元の依頼へ照合する。
