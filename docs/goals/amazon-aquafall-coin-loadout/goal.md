# Amazon 瀑流 COIN装備ショップ

## Objective

Amazon通常マップのCOINショップを旅用品とボス準備用品に整理し、流木よけの盾・先行ロープ・川止めの杭・水読みのコンパスを購入して最大2個まで瀑流へ持ち込めるようにする。

## Goal Kind

`specific`

## Current Tranche

既存COINショップ、Amazonセーブ状態、Aquafallターン順を調査し、4商品・装備2枠・購入/交換・ボス内使用・消費・save/loadを最小差分で実装する。Amazon通常/ボス、京都、Cairo差分外を検証し、720x1280でショップとボス操作を確認して完成監査する。

## Non-Negotiable Constraints

- 商品は流木よけの盾3、先行ロープ4、川止めの杭5、水読みのコンパス4 COIN。
- ボス装備枠は最大2。同一商品の重複購入・装備は禁止。
- 盾は最初の衝突1回、ロープは開始高度+3、杭は任意1ターンの丸太下降停止、コンパスは次ターン配置の1回予告。
- 未使用品もボス終了、RUN OVER、周回終了時に消滅する。
- 既存の旅用品、COIN獲得、FLOW、分岐、EVENT、秘密洞窟、通常ダイスを壊さない。
- Aquafallの5レーン、反射移動、丸太生成、難易度、BGM、チュートリアルの基本内容を維持する。
- 京都/CairoへAmazon装備状態やUIを漏らさない。
- 小回りブーツ±1と残り20マス通知は今回の必須範囲外。
- 既存ユーザー差分と未追跡ファイルを保持する。

## Stop Rule

完成監査が通る、すべての安全なローカル作業が阻害される、または新しい製品判断・破壊的操作が必要になった時点で停止する。計画・調査だけでは停止しない。

## Canonical Board

`docs/goals/amazon-aquafall-coin-loadout/state.yaml`

## Run Command

```text
/goal Follow docs/goals/amazon-aquafall-coin-loadout/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active task.
3. Keep write ownership bounded to the active Worker.
4. Record evidence and verification in each receipt.
5. Continue through final audit unless blocked.
