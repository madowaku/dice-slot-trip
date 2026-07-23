# Premium UI Design QA

基準画像: `ステージ画面イメージ.png`
実装証跡: `docs/reference/runtime-premium-ui-one.png`、`two.png`、`three.png`、`risk.png`、`rolling.png`

## 比較結果

| 観点 | 参考画像の意図 | 現在の実装 | 判定 |
|---|---|---|---|
| 情報階層 | 周回・コイン、ボス、全体マップ、盤面、ダイスの順 | lap/coin pill、ボスカード、独立minimap、大型盤面リボン、革trayへ分離 | Passed |
| 現在地 | キャラクターと前後マスを大きく見せる | 現在±5の11マスを番号・色・記号付き連続タイルで表示 | Passed |
| 全体位置 | 90マスループを常時確認 | ボスカード横の独立カードに全90マスと現在地を維持 | Passed |
| ボス交流 | 肖像・名前・実ゲージを一枚のカードに統合 | parchment card、portrait、ProgressBar、交流率・気配・スタンプ | Passed |
| ダイス状態 | 出目、役、次の操作を一目で理解 | 立体ダイス、role、NORMAL / DOUBLE CHANCE / DICE SLOT indicator、主CTA | Passed |
| リスク | 目押し前に危険マスを予告 | 赤い`!`、番号、NEXT表示、現在地の`!`を大型リボンで表示 | Passed |
| モバイル到達性 | 主操作を下部へ固定 | roll、左停止、一括停止を革tray下端へ配置 | Passed |

## 修正監査

- P0 fixed: 状態名が狭い領域で縦組みになっていた。固定幅・折返しなしへ変更。
- P0 fixed: 旧モード選択Buttonを廃止し、操作不能な3段階progress indicatorへ変更。
- P1 fixed: 点線ルートの単純拡大を、大型連続タイルリボンへ変更。
- P1 fixed: ボス情報をテキスト一行から肖像・名前・実ProgressBar付きカードへ変更。
- P1 fixed: 暗い仮設trayと強い黄橙planeを、丸い砂革panel・淡い革plane・金縁へ変更。
- P1 fixed: 3Dダイスを約1.24倍、1ダイス時約1.48倍へ拡大。プレイヤーも拡大。
- P2 fixed: 背景artの不透明度を上げ、文字は不透明度の高いpanel上へ集約。
- P2 fixed: Compatibility rendererの静止2ダイス証跡は安定capture経路で再取得。

## 360 × 640 判定

- one / two / three / risk / rolling の全証跡で、ボスカード、minimap、盤面、tray、主CTA、ターン情報が画面内。
- rolling時も「左から止める」と「残りを一括停止」が同じ横列にあり到達可能。
- boss/event/risk modalは既存CanvasLayerを維持し、盤面・ダイス入力を遮断する。

## 残課題（P3）

- 参考画像の立体的な石畳パースや個別アイテムアイコンは、専用アート制作を伴う後続polish候補。
- 小型画面では図鑑・ショップ常設ショートカットを盤面へ追加する余白がないため、情報過密を避けて未配置。
- 3Dダイスの角丸・革tray固有テクスチャは、現在のBoxMesh／単色材質から将来差し替え可能。

結論: P0〜P2を解消し、M3/M4A/RISK/早止めを保ったGoogle Play有料級の第一UIスライスとしてPassed。
# T036 atlas carousel QA (2026-07-19)

- Normal main and bypass travel use a seven-slot open-left C carousel, scaled from the canonical 640x605 atlas-local geometry.
- Slot 0 is the fixed cat-feet/current anchor; slots 1-6 hold future spaces. Future radius is 30px and current radius is 34px at design size.
- A one-step hop lasts 0.18s. The cat jump/land strip and lift animate in place while tiles shift clockwise; the previous current tile exits left.
- Loop travel and MAP overview retain the world/camera graph. Main teal-solid and bypass rust-dashed treatments remain distinct.
- Bypass carousel order follows traversable topology: remaining bypass tiles, then main tiles beginning at the canonical rejoin. Its line changes from rust dashed to teal solid after rejoin instead of painting the mixed path as one accent.
- Main and bypass terminal views show every remaining forward successor first. Only when fewer than five successors exist do older tiles fill the frame as context; those backfilled tiles are not promised future movement.
- Targeted visual-asset and play-screen suites pass. A headless PNG recapture was unavailable (renderer did not complete); no reference image was replaced.

# T037 Kenney tile-kind icon QA (2026-07-19)

- T029の6外形・色・優先順位、および構造マス記号を維持し、中央グリフだけを Kenney Board Game Icons の採用原本へ置換。
- 128×128白マスクは共通100〜108px光学ボックス、縦横比維持、1pxアルファ膨張で決定論的に生成。360幅換算の最大不透明辺は全6種16〜22pxの回帰ゲートを通過。
- AMD Radeon / OpenGL Compatibility の実機GPUで `docs/reference/v06-current-runtime/kenney-tile-kinds-720x1280.png` を取得。arrow、tokens、campfire、skull、pouch、book は全て外形内で欠けず、色に依存せず判別可能。
- Board Game Icons / Board Game Info / Boardgame Pack の公式アーカイブSHA-256、CC0ライセンス、入手元を保存。Preview・logo・sampleは未収録。
- `run_v06_visual_asset_tests.gd` と `run_v06_play_screen_tests.gd` は全件Passed。

# Current QA — semicircle carousel + Kenney tile symbols (2026-07-19)

- Source visual truth: `C:/Users/hiro/Documents/bamboo-gambit/.codex-remote-attachments/019f7302-171d-7e83-b62c-7e7b91d5009a/f77afa50-7999-4a54-9cc3-33b98eb1b7d1/1-Photo-1.jpg`
- Implementation screenshot: `docs/reference/v06-current-runtime/kenney-tile-kinds-720x1280.png`
- Full-view comparison: `docs/reference/v06-current-runtime/semicircle-sketch-vs-runtime-720.png`
- Focused icon comparison: `docs/reference/v06-current-runtime/tile-kinds-procedural-vs-kenney-grayscale-720.png`
- Viewports: 720×1280 and 360×640
- State: Cairo main route, LAP 4, HP 2/3, position 18/58, slots [6,6,_], six-kind QA preview

## Required fidelity surfaces

- Fonts and typography: existing Noto Sans JP HUD/tray hierarchy is unchanged; 360 capture has no clipping or unintended wrapping.
- Spacing and layout rhythm: current plus six forward spaces form the sketch's open-left fold; all tiles remain inside the atlas and non-overlapping at 720 and 360. HUD and fixed tray geometry are unchanged.
- Colors and tokens: parchment, teal main line, rust bypass line, and every T029 kind color/outer silhouette remain unchanged. Strong light is still reserved for boss state.
- Image quality and assets: approved production cat and environment art are unchanged. Kenney glyphs use normalized 128×128 transparent masks with 16–22px opaque bounds at 360; no crop, preview, logo, or sample asset is shipped.
- Copy and content: canonical HUD, progress, route, hint, tray, and return labels are unchanged.

## Comparison history

1. Initial evidence used a straight route row and procedural diamond/star/heart/warning/bag/scroll marks. Relative to the owner sketch, the route did not fold around the fixed player and several marks were abstract.
2. T036 moved main/bypass travel to a fixed-cat seven-slot C carousel, enlarged tiles to about 91.5px forward / 103.7px current, and reduced one-step motion to 0.18s. GPU capture confirmed the six forward spaces fit.
3. T037 replaced only the six center marks with arrow/tokens/campfire/skull/pouch/open-book masks. The focused grayscale comparison confirms stronger concrete meaning while the T029 outer system remains intact.

## Findings

- No actionable P0/P1/P2 mismatch remains for the requested layout and icon slice.
- P3: a short recorded motion preview would make the clockwise movement easier to review outside the running game; automated invariants currently verify the fixed anchor, slot order, and duration.

## Interaction and regression evidence

- GPU-rendered Godot capture succeeded on AMD Radeon/OpenGL Compatibility.
- Play-screen tests cover fixed tray, MAP open/close and pause/resume, loop eight-space switch, boss overlay ordering, carousel mode, fixed cat anchor, clockwise slot order, and 0.18-second hop.
- Visual tests cover exact Kenney mappings, texture loading, T029 outer shapes, structural symbols, and 360 opaque-bound thresholds.

# T040 bypass horizon QA (2026-07-19)

- At bypass B1 through B4, the six future slots exactly follow the canonical route: remaining bypass spaces first, then main-route spaces from rejoin tile 21 onward.
- The carousel connector remains rust dashed through the bypass-to-rejoin segment and changes to teal solid for subsequent main-route segments.
- `future_successor_count()` distinguishes actual forward successors from terminal behind-fill context. Main and bypass terminal frames retain the existing five-space minimum without implying that backfilled tiles are upcoming.
- GPU references: `docs/reference/v06-current-runtime/bypass-rejoin-720x1280.png` and Lanczos-derived `docs/reference/v06-current-runtime/bypass-rejoin-360x640.png`.
- Targeted visual-asset and play-screen suites pass, including exact ordered arrays for bypass indices 0–3 and six successor slots at each index.

final result: passed

# T052 item / skill tool dock and generated cards (2026-07-20)

- Replaced the 96px back-only row with a 120px dark-walnut/brass tool dock. The fixed dice tray rises by 24 design pixels; the atlas remains at or above its 520px contract.
- ITEM and SKILL are 216×96 design-pixel controls with generated card thumbnails, explicit `0 / 3` capacity and `READY` state. Back remains available at 208×96 but is visually secondary.
- ITEM opens a 0/3 inventory card. SKILL opens a character-skill readiness card without inventing an unimplemented effect. Both overlays gate die input and restore it on close.
- Item artwork shows the v0.8 canteen, compass, bandage and hourglass shard as a single readable travel-kit still life. Skill artwork uses the approved explorer-cat strip as identity/costume reference and keeps motion/glow restrained.
- Generated UI text is not baked into either raster; Godot renders all Japanese labels, counts and state copy.

Runtime evidence:

- `docs/reference/v06-current-runtime/v08-tool-dock-720x1280.png`
- `docs/reference/v06-current-runtime/v08-tool-dock-360x640.png`
- `docs/reference/v06-current-runtime/v08-item-card-720x1280.png`
- `docs/reference/v06-current-runtime/v08-item-card-360x640.png`
- `docs/reference/v06-current-runtime/v08-skill-card-720x1280.png`
- `docs/reference/v06-current-runtime/v08-skill-card-360x640.png`

Asset evidence:

- Runtime cards: `assets/art/v08/cards/item-card.png`, `assets/art/v08/cards/skill-card.png` (512×512 RGB).
- Immutable sources: `docs/design/v08/art-source/item-card-imagegen-source.png`, `docs/design/v08/art-source/skill-card-imagegen-source.png` (1254×1254 RGB).
- `assets/art/v08/cards/cards.provenance.json` records built-in ImageGen, generation date, exact prompts, original output paths, source/runtime SHA-256, reference image and Lanczos normalization.
- `tools/validate_v08_cards.py` verifies the complete card contract.

Visual findings:

- 720 and exact Lanczos 360 captures keep the map, fixed tray and all three lower controls readable with no clipping or overlap.
- Modal card title, 250px artwork, body copy and 96px close action preserve hierarchy at both target sizes.
- Boss panel was reduced from 760px to 748px so the raised tray retains a visible gap while the HUD remains clear.

final result: passed
# Current QA — Tactile Travel Instrument implementation (2026-07-19)

Source visual truth: `docs/design/v07/tactile-travel-instrument-approved.png`

Implementation screenshots:

- `docs/reference/v06-current-runtime/tactile-travel-instrument-720x1280.png`
- `docs/reference/v06-current-runtime/tactile-travel-instrument-360x640.png`

Viewport and state: Godot 4.7 Compatibility renderer, native 720×1280 and exact Lanczos 360×640 derivative, Cairo main route at canonical tile 18, LAP 4, HP 2/3, PB -2.4s, `[6][6][—]`, READY.

Full-view comparison evidence: `docs/reference/v06-current-runtime/tactile-travel-instrument-comparison-720.png` places the normalized approved mock and current runtime capture side by side. It verifies the dark leather field-instrument shell, dark/brass HUD, parchment stage band and atlas, open-left C route, fixed explorer cat, die + three slots + READY tray, and quieter centered back action.

Focused-region evidence: the full comparison renders HUD and tray text at readable size. Separate focused crops were not required because both critical regions occupy the full 720px comparison width and remain legible. The 360 capture separately verifies the responsive minimum state.

## Required fidelity surfaces

- Fonts and typography: Noto Sans JP remains runtime-drawn. TIME now has a separate caption and dominant tabular value; PB, progress, stage, route and kind retain distinct hierarchy. The mock's serif ornament is intentionally not copied into operational text because the existing mobile design system requires Noto Sans JP legibility.
- Spacing and layout rhythm: 16-unit safe edge, compact 8-unit page rhythm, 116-unit HUD, expanded atlas, 226-unit fixed tray and 520×96 centered back action fit without clipping at 720 or 360. All buttons retain the 96-design-unit / 48-logical-pixel touch minimum.
- Colors and visual tokens: generated dark-walnut leather is used as a real raster background. Existing parchment, teal, rust and brass tokens are retained; normal play has no decorative glow.
- Image quality and asset fidelity: the approved explorer cat, normalized Kenney glyphs, parchment, Cairo ink and raised tiles remain production rasters. The tray reuses the existing live `DicePresentation3D`, rendered in a compact square SubViewport rather than replacing it with a flat icon.
- Copy and content: canonical Godot labels render LAP 4, HP 2/3, PB -2.4s, time, 18/58, stage/route/kind, `[6][6][—]`, READY ROLL and the Japanese back action. No generated text ships.

## Comparison history

- P1 — the first runtime pass omitted the selected mock's dominant time hierarchy. Fixed by splitting TIME into a caption and larger numeric value; post-fix evidence is the current 720/360 capture.
- P2 — the first runtime pass left the back action full-width and visually competitive with the tray. Fixed by centering it at 520×96 while preserving the touch minimum.
- P1 — the pre-T042 runtime had no visible rolling die inside the v0.7 tray. Fixed by integrating one compact live 3D die well before the three history slots. Automated evidence confirms the die enters `ROLLING` on the first tap.
- P1 — the pre-T042 semicircle visually terminated at tiles 24 and 18. Fixed with two same-weight teal segments that exit the left viewport without closing the C into a ring.

## T044 asset and scope recovery

- `assets/art/v07/ui/dark-walnut-leather.provenance.json` preserves the built-in ImageGen provider, generation date, verbatim prompt, original output location, durable workspace source path, decoded metadata, intended role and review flags.
- The generated source is retained at `docs/design/v07/art-source/dark-walnut-leather-imagegen-source.png`; it and the runtime PNG are exact-byte copies with SHA-256 `b3e725a7407d37378fd485a8094ee98f93e1d2574e98adcb89478138f2ae2add`. No resize, crop, recompression or color conversion is claimed.
- `tools/validate_v07_ui_assets.py` checks schema, prompt, paths, hashes, byte counts, 1254×1254 RGB decoding, exact-copy normalization, Godot import and bounded opposite-edge evidence. The texture is sampled as a cover image, so mathematical repetition is neither required nor claimed.
- T044 explicitly owns `scripts/game/dice_presentation_3d.gd`; the compact single-die viewport and first-tap `ROLLING` synchronization are revalidated by the play-screen suite.

## Findings

No actionable P0/P1/P2 mismatch remains. The simplified brass frame ornament and omission of redundant heart pictograms are intentional low-stimulation/accessibility choices; they preserve the selected material direction without reducing map area or duplicating the readable `HP 2/3` value.

## T048 semantic readability polish (2026-07-20)

- NORMAL now uses a project-owned ImageGen trail-stone glyph rather than a directional arrow. The three-stone silhouette reads as a neutral walkable path marker while preserving the T029 rounded-square plate, color, optical envelope, and no-topology rule.
- RISK keeps the T029 red triangle outer shape and Kenney skull source, with the skull enlarged to a controlled 0.82 icon scale so the warning meaning survives 360px rendering.
- The current tile receives a stronger but restrained focus treatment: larger/darker foot shadow plus a teal accent ring and warm inner ring. The cat remains the focal point without turning the normal map into a glow-heavy state.
- Runtime evidence was regenerated at `720×1280`, exact Lanczos `360×640`, and grayscale `720×1280`/`360×640`. The approved mock and current runtime remain side-by-side in `docs/reference/v06-current-runtime/tactile-travel-instrument-comparison-720.png`.
- `assets/art/v06/tile_kind_icons/normal-trail-stones.provenance.json` records ImageGen source, chroma cleanup, dimensions, hashes, normalization, semantic review, and the fact that Kenney is a style reference only. `tools/validate_v07_tile_icon.py` passes with `failures=0`.

## T048 verification

- Godot 4.7 editor parse/import: passed.
- Visual asset suite: `V06_VISUAL_ASSET_TESTS failures=0`.
- Play-screen, boss, session, battle, roll-set, course, asset-pack, cat, and legacy suites: all `failures=0` (legacy retains the known resource-in-use exit warning only).
- `tools/validate_v07_ui_assets.py`, `tools/validate_v07_tile_icon.py`, and `tools/validate_v06_asset_pack.py`: passed; the environment pack remains `405/0`.
- `git diff --check`: passed with existing LF/CRLF normalization warnings only.

## Follow-up polish

- P3: capture a short real-device 60 fps clip to judge compact-die edge aliasing and touch-to-motion latency.
- P3: consider a dedicated rounded die mesh only if the existing production 3D die reads too angular on physical 360-wide hardware.

final result: passed
