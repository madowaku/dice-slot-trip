# T002: Implementation Decision

Task: `T002`
Kind: `judge`
Status: `done`

## Summary

新規ImageGenは不要。TREASURE 21の4状態宝箱はbuilt-in ImageGenのprovenance、256×256 RGBA、実alpha、同一silhouette/anchorを満たし、HEAD `6668a2f` で実装・push済み。最初の安全なsliceは製品コードを再変更せず、結果reveal完了後の正本キャプチャとasset/state契約を固めるvisual acceptance hardeningとする。

## Evidence

- `art_source/treasure_21/chest_animation/provenance.json`はprovider、raw/edit/cutout、prompt、project-generated licenseを記録。
- `assets/casino/treasure_21/chest_frames/01.png`～`04.png`は256×256 RGBA、透明背景、文字・watermark・風景なし。
- setup / TOTAL 12 / 17 / 20の候補は製品品質として採用可能。
- result正本だけが0.26秒reveal途中の6フレームで撮影され、暗く見える。runtime assetではなくrecorderの問題。
- Judge時点で `HEAD == origin/codex/dice-roulette-bgm == 6668a2f`、staged casino filesは0件。

## Decision

T003は以下に限定する。

- result captureを0.26秒reveal完了後に行う。
- 4 chest texturesのload、256×256寸法、状態割当、主要Control boundsを検証する。
- 360×800と720×1280のcanonical QA画像を再生成する。
- economy、transaction、game rules、production layout、PNG、provenance、model、bankを変更しない。

## Deferred

- VAULT result asset再利用
- TOWER overlay hierarchy
- CTA・残高語彙統一
- ROULETTE密度調整
- 新規画像生成
- economy / transaction / rules変更

## Eventual Commit Scope

- T003で変更したrecorder、test、canonical QA画像、`docs/treasure-21-design-qa.md`
- PM管理の `docs/goals/las-vegas-product-ui-final-audit/**`
- `artifacts/qa/treasure21-product/360x800/` は旧重複captureのため除外
- Las Vegas BGM、DICE RACE、city-cardの `.import`、Phase B/C `.uid`、duplicate `expansion*` は別途由来確認

## Board Receipt Snippet

```yaml
receipt:
  result: done
  note: notes/T002-implementation-decision.md
  decision: "TREASURE 21 visual acceptance hardeningを実施。新規ImageGenとproduction変更は不要。"
  next_allowed_task: T003
```
