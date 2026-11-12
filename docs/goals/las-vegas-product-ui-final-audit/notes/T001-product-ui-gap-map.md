# T001: Las Vegas Product UI Gap Map

Task: `T001`
Kind: `scout`
Status: `done`

## Summary

Phase C後のRACE / TOWER / ROULETTE / POKERは主画面の製品品質が高い。一方、TREASURE 21のsetup/resultは中央パネルの大半が無地で、施設固有の「宝を持ち帰る／開ける」感情が文字だけに依存している。機能・回帰込みのPhase C 94/100に対し、純粋なproduct UI readinessは約89/100。画像生成が正当化されるのはTREASURE 21の4状態宝箱だけで、同じfamilyの候補は既に作業ツリー内に存在するため追加生成は不要。

## P1

### TREASURE 21 product UI

- Phase C正本:
  - `artifacts/audit/las-vegas-phase-c-after/expansion-console-gui/treasure-setup-360x800.png`
  - `artifacts/audit/las-vegas-phase-c-after/results/treasure-result-360x800.png`
- 問題種別: layout/copyではなくasset deficiency。setupとresultの大面積が暗い無地背景で、固有hero momentがない。
- 正当化されるasset family:
  - closed → charged → opening → fully openの4状態
  - 各256×256 RGBA PNG
  - deep emerald leather、antique brass/gold、champagne glow、控えめなruby/sapphire
  - 同一カメラ、同一silhouette、bottom-center anchor
  - 透明背景、文字・数字・UI枠・風景・watermarkなし
- 既存候補:
  - `assets/casino/treasure_21/chest_frames/01.png`～`04.png`
  - `art_source/treasure_21/chest_animation/provenance.json`
  - `scripts/app/treasure_21_screen.gd`
  - `tests/record_treasure_21_product_ui.gd`
  - `artifacts/qa/treasure21-product/final-360x800/`
- 候補QAではsetup、TOTAL 12、17、20、resultの施設固有性と画面占有が大きく改善している。
- result recorderはreveal完了前の6フレームで撮影している可能性があり、20～24フレーム待って再撮影が必要。

## P2

1. VAULT結果の視覚的連続性: 新規生成不要。既存 `assets/casino/vault_break/ui/vault-door-brass-v1.png` をresultへ再利用可能。
2. TOWER結果overlay: dimが弱く背後CTAが操作可能に見える。素材ではなくoverlay hierarchyの問題。
3. CTA・残高語彙: `NEW RACE` / `PLAY AGAIN` / `同じBETでSPIN` / `NEW VAULT` と `CHIP` / `CASINO CHIP` / `所持チップ`。横断token整理候補。
4. ROULETTE 360幅: BET表、side bet、固定action dockの同時表示で補助文字が小さい。段階表示・caption整理候補。

## P3

- POKER setup/result下半分の暗い未使用領域。
- HUBのPRIZE COUNTERが施設選択より強く見える。
- RACE resultの順位、RETURN/NET、出目関係図が同時に強い。

## Candidate Safe Slices

1. TREASURE 21の既存4状態宝箱候補を所有権確認後に採用し、setup・進行・resultへ限定統合する。
2. VAULT resultへ既存vault doorを再利用する。
3. TOWER result overlayのdim/hierarchyをXS調整する。
4. 同額再戦・BET変更・退出と残高headingを横断整理する。

## Verification

- `tests/run_treasure_21_tests.gd`
- `tests/run_casino_ui_tests.gd`
- `tests/run_las_vegas_phase_c_visual_tests.gd`
- `tests/record_treasure_21_product_ui.gd`によるsetup / TOTAL 12 / 17 / 20 / resultの360×800実描画
- resultはreveal完了後20～24フレームで撮影

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T001-product-ui-gap-map.md
  summary: "TREASURE 21の空白主体setup/resultを唯一のP1と特定。4状態宝箱は生成済み候補があるため追加生成不要。"
```
