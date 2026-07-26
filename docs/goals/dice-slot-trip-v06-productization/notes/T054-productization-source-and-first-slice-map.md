# T054: 製品化ソース監査と最初の実装スライス

Task: `T054`
Kind: `scout`
Status: `current`

## Summary

2026-07-25のローカル設計書、5つのGoogle Docs、現行dirty差分、既存ビジュアルとテストを照合した。通常直線本線の7カード、1マスジャンプ、着地後カメラ追従、追従完了までの入力ゲートは現行差分と専用テストで概ね成立している。一方、3DサイコロはEuler角とY軸主回転を使い、最新仕様のQuaternion上面契約と全1〜6の実上面テストを欠く。3ROLL SLOTはSTRAIGHT/MIX、報酬状態、非モーダル進行をまだ欠く。

## Source Authority And Conflicts

| 優先 | ソース | 採用内容 | 衝突時の裁定 |
|---:|---|---|---|
| 1 | 現在のユーザー指示 | dirty保護、main不使用、挙動安定化優先 | 絶対条件 |
| 2 | `GooglePlay有料級にブラッシュアップしていこう！.md` | Quaternion上面、RESULT_LOCK限定highlight、MIX自動進行 | 下位ソースを上書き |
| 2 | `各画面UI.md` | 共通UI文法と画面改修順 | 挙動安定化後に適用 |
| 3 | 現行検証済み実装 | 直線移動、着地、camera、input gate | 最新MDとの衝突箇所は仕様根拠にしない |
| 4 | 探検猫スキル Doc | READY予約、速度65%、bounce/drift 80%、結果補正なし | ROLLING中highlightは不採用 |
| 4 | 3ROLL SLOT Doc | 毎投転写、4役、非モーダル進行 | 現行ack overlayは要改修 |
| 4 | 素材生成リスト Doc | 既存監査優先、UI文字・枠・光はGodot描画 | 最初の挙動sliceにImageGen不要 |
| 4 | ボス戦 Doc | `boss_roll = 7 - player_roll` | 最初のsliceでは変更しない |
| 4 | カイロコース Doc | 58マス、前方6、円環・分岐・ボス | 最初のsliceは通常直線のみ |
| 5 | 旧repo docs | 補助資料 | 上位と衝突時は不採用 |

Google Driveでは5文書の本文を取得済み。ただしネイティブ表構造、コメント、改訂履歴は今回の実装判断に不要なため監査対象外とした。

## Implementation Matrix

| 領域 | 実装済み | 欠落・衝突 |
|---|---|---|
| Die | 1〜6のpip面法線、6停止姿勢、SETTLING | Quaternion状態、実上面判定、全1〜6上面test。Euler補間＋Y軸主回転は最新仕様に反する |
| Slot | 3枠、停止値転写、rolling preview | STRAIGHT/MIX、ゲージ、COIN+1、次ROLL開始時clear。preview値は実上面と独立 |
| Straight route | 現在地＋前方6の7カード、通常main限定 | RESULT_LOCKの明示状態はない |
| Landing | 種別別ring/result、最終hop後に実行 | 視覚証拠を追加できる余地あり |
| Camera | landing後0.42秒follow、7カード維持 | 端点・全1〜6の追加証拠余地あり |
| Input gate | movement/rolling中のROLL・MAP・utility遮断 | back操作のrolling中gateを追加確認したい |
| MIX | distinct setは`ROLE_NONE` | MIX判定、COIN+1、約300ms表示、自動MOVE_PREP、次ROLL時clear。現状は確認tapを要求 |

## Dirty Diff Risk Map

| File | Dirty scope | Risk |
|---|---|---|
| `scenes/app/V06PlayScreen.tscn` | die relocation、slot/action/tool dock | 高 |
| `scripts/app/v06_play_screen.gd` | 二段tap、slot preview、straight orchestration、gate | 非常に高 |
| `scripts/game/dice_presentation_3d.gd` | compact viewport、Y主回転 | 高。今回の最有力修復対象 |
| `scripts/game/v06_atlas_view.gd` | 7-card straight、landing、camera、cancel | 非常に高。現行成立部分を保護 |
| `scripts/game/v06_play_session.gd` | roll counter | 中 |
| `tests/run_v06_play_screen_tests.gd` | straight/die/tool dock回帰 | 高 |

## Visual Targets And ImageGen

- `docs/design/v06/d-selected-atlas-living-map.png`: gameplay構造の選定方向。
- `docs/design/v07/tactile-travel-instrument-approved.png`: gameplay素材・階層のapproved target。
- `docs/reference/v06-current-runtime/tactile-travel-instrument-v08-720x1280.png`: v0.8 runtime reference。
- `docs/reference/v06-current-runtime/tactile-travel-instrument-v08-360x640.png`: compact runtime reference。
- `build/card-route-ui-stability-capture.png`: 現在dirty差分の720×1280証拠。
- `docs/reference/runtime-title.png`、`runtime-stage-select.png`、`runtime-character-select.png`: 現状参照であり、redesignのexact targetではない。

推奨behavior sliceにImageGen gapはない。die、ring、highlight、数字、文字はGodotで描画できる。将来のタイトル、ステージ、キャラクター、結果、図鑑にはexact redesign targetがないため、image-to-code前に比較可能な3案とowner選定が必要。

## Ranked First-Slice Candidates

### 1. Die上面Quaternion契約

Recommended.

Allowed files:

- `scripts/game/dice_presentation_3d.gd`
- `tests/run_tests.gd`
- `tests/run_v06_play_screen_tests.gd`

Verify:

- Godot 4.7 editor parse。
- `tests/run_v06_play_screen_tests.gd`。
- `tests/run_tests.gd`。
- scoped `git diff --check`。
- 720×1280/360×640のROLLING/LOCKED capture。
- 全1〜6で論理出目と上面一致。回転中に複数上面が現れる。

Stop if:

- pip面法線が現行の対面契約と一致しない。
- allowed files外のAPI変更が必要。
- compact viewportや二段tapを巻き戻す必要がある。
- 同一原因で検証が2回失敗する。
- GPU captureで上面変化を確認できない。

### 2. RESULT_LOCK限定Highlight

Allowed files:

- `scripts/app/v06_play_screen.gd`
- `scripts/game/v06_atlas_view.gd`
- `tests/run_v06_play_screen_tests.gd`

Sessionへの新phase、分岐・円環・ボス描画変更、既存straight sliceの巻き戻しが必要なら停止する。

### 3. MIX非モーダル進行

Allowed files:

- `scripts/game/v06_roll_set.gd`
- `scripts/game/v06_play_session.gd`
- `scripts/app/v06_play_screen.gd`
- 対応する3つの専用テスト

COIN/skill gaugeの正規所有者が範囲内で決まらない、STRAIGHTまで同時導入が必要、分岐・円環・ボスへ波及する場合は停止する。

## Recommended Worker

現行compact 3D dieのpip面法線を固定し、回転・停止姿勢をQuaternionで管理する。回転中はX/Zを含む主回転で複数の上面が現れ、停止時は論理出目1〜6の面が必ず`Vector3.UP`を向くことをdeterministic testと720×1280/360×640 captureで証明する。compact viewport、既存二段tap、slot、route、branch、loop、boss挙動は変更しない。

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T054-productization-source-and-first-slice-map.md
  summary: "直線7カード・hop・landing後follow・input gateは成立。最大の欠落はdieのQuaternion上面契約で、MIX非モーダルが次点。"
```
