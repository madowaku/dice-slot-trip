# Design QA — Cairo HUD and Mission Band

- Source visual truth: `C:/Users/hiro/Desktop/ChatGPT Image 2026年8月1日 14_15_43.png`
- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-missions-v3-idle-360x640.png`
- Full comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-missions-v3-comparison-720x640.png`
- Focused comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-missions-band-comparison-720x116.png`
- Viewport/state: normal Cairo travel, 360×640, mission toast settled/hidden
- Density normalization: source 941×1672 downsampled to 360×640; implementation captured natively at 360×640; both compared at 1:1 pixels

## Findings

No actionable P0/P1/P2 differences remain for the implemented HUD/mission slice. The mission strip now follows the source hierarchy while retaining the user-approved state semantics.

## Required fidelity surfaces

- Fonts and typography: Noto Sans JP captions and values remain readable without wrapping at native 360×640; short copy preserves a clear label/value split.
- Spacing and layout rhythm: the horizontal strip is 82 design pixels, restores the Atlas to 470 pixels, and no longer makes the Page overflow when transient movement copy appears.
- Colors and visual tokens: parchment, teal, gold, and ink match the existing game system; the earlier dark-on-dark defect is fixed.
- Image quality and asset fidelity: the three mission cells use real shield, coin, and die textures. The shield is a validated 256×256 RGBA project asset.
- Copy and content: short `無傷`, `コイン`, `役成立` copy and actual progress are correct. Failure remains visible and completion uses a gold check.

## Comparison history

1. Earlier evidence `build/qa-missions-settled-360x640.png` found unreadable dark-on-dark mission rows and generic progress toast copy.
2. T027 added the parchment/high-contrast treatment, short copy, and actual capped progress toast.
3. Post-fix evidence `build/qa-missions-v2-idle-360x640.png` confirms those fixes, while exposing the remaining vertical-budget and missing-icon P2 findings above.
4. T029 converted the band to a horizontal real-asset strip. Its first geometry gate found unequal intrinsic cell widths and Page overflow under the large transient message.
5. T031 gave the cells identical minima and moved the transient MessageLabel outside Page flow.
6. Post-fix evidence `build/qa-missions-v3-comparison-720x640.png` confirms the compact three-cell hierarchy, real icons, complete top HUD, preserved board, and stable lower controls.

## Implementation checklist

1. Completed: compact 82px horizontal mission strip.
2. Completed: shield, coin, and die texture assets.
3. Completed: mission/play/visual/full regression suites and native 360×640 Movie Writer capture.
4. Completed: normalized full-view comparison and focused mission-region review.

## Follow-up polish

- P3: the reference uses more ornate separators and bevel depth than the current shared Godot theme; this is acceptable for the incremental HUD slice.

final result: passed

---

# Design QA — 狐火追陣 UIブラッシュアップ v1.0

## Evidence

- 360×640 live composition: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-chase-qa-360x640.png`.
- 720×1280 live composition: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-chase-qa-720x1280.png`.
- SLOT completion: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/slot-triple-720x1280.png`.
- Fox-fire blockage: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-warning-720x1280.png`.
- Explicit six synchronization: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/dice-six-sync-720x1280.png`.

## Findings

No actionable P0/P1 issues remain for this pass. The top HUD has one distance hierarchy (`追いつくまで` plus the large distance), with the HP-like split gauge hidden. Secondary information is limited to fox-fire and goshuin counts; the level label no longer competes with the distance.

The central three SLOT faces are larger than both side chips, empty faces use an em dash instead of a dot, and completion retains `3/3` while the central `PAIR / STRAIGHT / TRIPLE` movement banner is visible. The explorer, white fox, and shared 3D die were enlarged within the requested ranges. The outer route is brighter than the inner field, the next route segment is highlighted, and a fox-fire cell receives a cyan fill plus two high-contrast borders in addition to the flame sprite.

The normal-map 3D die remains the sole presentation path. Automated interaction verifies first tap starts rotation, second tap stops, and the face visible at STOP is the same value committed to the controller, shown on the settled 3D die, and written to SLOT. The six face has six pips with no center pip. Native OpenGL capture confirms the same result visually.

## Verification

- 狐火追陣 core: `failures=0`.
- 狐火追陣 UI at 720×1280 and 360×640: `failures=0`.
- Six-route Kyoto boss UI regression: `failures=0`.
- Journey-stage UI regression: `failures=0`.
- P0: none. P1: none. P2: no blocker; per-cell movement, short fox-fire emergence, near-lap warning, and reason-specific defeat copy are present.

final result: passed

---

# Design QA — Kyoto PAIR feedback and 狐火追陣 pacing/chrome (2026-08-22)

- Source visual truth: `C:/Users/hiro/AppData/Local/Temp/codex-clipboard-b6d8fe12-b59a-4086-b9d8-7d22695051d6.png` (364×787; reported overlap state).
- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/host-chase-360x800.png` (native Godot 360×800 viewport, density 1).
- Full comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/design-qa-comparison.png` (720×800).
- Focused SLOT evidence: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/slot-triple-720x1280.png` (native Godot 720×1280 viewport, density 1).
- Normal-map source evidence: `C:/Users/hiro/AppData/Local/Temp/codex-clipboard-c9036a1b-69b1-4fef-93bc-06b0f9d8a29f.png` (PAIR mission and rolling-copy report).
- State: 狐火追陣 initial playable state plus a separately captured TRIPLE completion state.
- Density normalization: the 364×787 report screenshot was proportionally scaled to 360px wide and vertically padded to 360×800; the implementation remained native 360×800.

## Findings

No actionable P0/P1/P2 findings remain for this correction slice. The implementation removes the normal-map HUD, MISSION, message strip, and lower tool dock from the boss state. The boss title, advantage meter, board, SLOT, and ROLL remain unobstructed. The completed TRIPLE capture retains all three matching faces and the large result banner before movement begins.

## Required fidelity surfaces

- Fonts and typography: the existing Noto Sans JP hierarchy is preserved; the boss title, lead distance, and result banner remain readable at both captured densities.
- Spacing and layout rhythm: the full boss composition remains centered in the 360×800 host with only the shared leather backing in the tall-phone letterbox. No normal-stage band overlaps the boss surface.
- Colors and visual tokens: the established Kyoto gold, teal/red advantage meter, dark enamel panels, and warm board remain unchanged.
- Image quality and asset fidelity: the authored board, explorer cat, white fox, shared 3D die, slot tray, and roll ring remain native project assets without placeholder substitutions.
- Copy and content: the unreadable `タップで止める` sentence is removed from rolling status; `ダイス回転中` remains. PAIR now resolves on the normal Kyoto map and updates `進捗 1/4` in the same frame.

## Comparison history

1. The supplied screenshot showed normal HUD and lower tools visible behind the letterboxed 狐火追陣 composition.
2. The first post-fix capture removed the main bands but exposed the normal message strip and a deferred 御朱印 tutorial over the boss.
3. The journey chrome was then hidden at its parent container and the deferred tutorial was gated during boss phase.
4. The final 360×800 comparison shows only the dedicated boss UI; the 720×1280 focused capture confirms three completed SLOT faces remain visible during the 1.4-second result hold.

## Verification

- 狐火追陣 core/difficulty/snapshot suite: `failures=0`.
- 狐火追陣 UI suite: `failures=0`.
- Journey-stage UI regression, including PAIR mission refresh, rolling copy, and boss chrome lifecycle: `failures=0`.
- Amazon/Kyoto stage integration suite: `passed=true`.
- P0: none. P1: none. P2: none.

final result: passed

---

# Design QA — Kyoto Boss / 狐火追陣

- ImageGen target: `C:/Dev/Projects/dice-slot-trip-main-verify/art_source/fox_fire_chase/ui/fox-fire-chase-target-v1.png`
- Native captures: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-chase-qa-720x1280.png`, `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-chase-qa-360x640.png`
- Target/implementation comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-chase/fox-fire-chase-target-vs-implementation.png`
- Generated four-frame white-fox run set: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/`

## Findings

The selected hybrid direction is implemented: the teal/red advantage HUD makes the leader immediately legible; the perspective 6x6 board is the dominant surface; the explorer and white fox sit on square cells; and the compact SLOT tray preserves the three-roll role readout. The shared ivory-brass die now rotates in the unused center cell `(2,2)`, so a finger pressing ROLL cannot hide it. That center cell is outside both the outer chase ring and the one-cell-inward fox-fire detour route.

The 720x1280 and 360x640 native captures were inspected for hierarchy, board readability, piece centering, die visibility, button obstruction, safe-area fit, and touch sizing. Per-cell fox-then-player movement, the fox-fire choice sheet, reduced motion, the three-page tutorial, and the explicit result handoff remain intact. No actionable P0/P1/P2 visual issues remain.

## Verification

- Chase core, balance reference, snapshot/JSON roundtrip, SLOT roles, fires, detours, goshuin, and victory/defeat: pass, `failures=0`.
- Chase UI at 720x1280 and 360x640, including center-die placement and ROLL non-overlap: pass, `failures=0`.
- Journey-stage dispatch/save/retry regression: pass, `failures=0`.
- Existing 狐火六路陣 UI regression: pass, `failures=0`.
- P0: none. P1: none. P2: none.

final result: passed

---

# Design QA — Amazon/Kyoto Survival HUD and HP3 Boss Contract

- Amazon normal HUD: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-survival-hud.png`
- Amazon RISK state: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-risk-heart.png`
- Amazon LIFE revival state: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-revival-heart.png`
- Kyoto normal HUD: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/kyoto-survival-hud.png`

The shared Amazon/Kyoto cockpit is readable at 720×1280: the Explorer Cat icon and `復活 ×N` are separated from a three-heart line, while empty hearts remain visible as `♡`. The RISK capture reads `♥♥♡`; the revival capture reads `復活 ×2` with `♥♥♥`. The local map, six-space forecast, antique die, 3-slot tray, round roll button, and four-tool dock remain inside the viewport without overlap.

The stage model tests exercise four consecutive RISK landings for each stage: HP3/LIFE3 → HP2/LIFE3 → HP1/LIFE3 → HP3/LIFE2 → HP2/LIFE2, plus legacy HP6 save clamping. Kyoto's Fox Fire boss view and battle wrapper use the same HP3 cap. Full-health boss victories use `PERFECT! / HP FULL`; wounded victories retain the recovery-only roulette.

Verification: `AMAZON_KYOTO_TESTS passed=true`, `FOX_FIRE_SIX_ROUTES_TESTS failures=0`, `TALL_PHONE_LAYOUT_TESTS failures=0`, `V06_PLAY_SESSION_TESTS failures=0`, `V06_PLAY_SCREEN_TESTS failures=0`, and `DICE_SLOT_TRIP_TESTS failures=0`.

final result: passed

---

# Design QA — Kyoto Boss / 狐火六路陣

- Source visual truth: `C:/Dev/Projects/dice-slot-trip-main-verify/docs/design/fox-fire-six-routes-target-v1.png` (941×1672 ImageGen target)
- Implementation captures: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-six-routes/kyoto-boss-720x1280-final.png`, `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-six-routes/kyoto-boss-tutorial-720x1280.png`, `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-six-routes/kyoto-boss-input-720x1280-final.png`, and `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/fox-fire-six-routes/kyoto-boss-input-360x640-final.png`
- Viewport/state: Windows OpenGL compatibility renderer at native 720×1280 and 360×640; READY and PATH_INPUT states.
- Asset provenance: `C:/Dev/Projects/dice-slot-trip-main-verify/art_source/fox_fire_six_routes/README.md`
- Slice 6 marker asset: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/bosses/kyoto/fox-fire-special-tiles.png`
- Implementation record: `C:/Dev/Projects/dice-slot-trip-main-verify/docs/design/fox-fire-six-routes-implementation.md`

## Findings

No actionable P0/P1/P2 issues remain for the approved Slice 1–9 contract. The generated Kyoto board keeps the dominant six-by-six playfield, fox guardian, fixed A/B/C/D torii, three-roll slot tray, gold active-route trails, white-fire preview/blockers, and full-width touch targets aligned to the same bilinear board geometry. Lv6 adds restrained Sakura/Bamboo markers and a modal purification choice without changing the board footprint. The compact 360×640 capture preserves the hierarchy without clipping or overlap.

## Required fidelity surfaces and interaction checks

- State machine: INTRO/PRE_BATTLE → ROLL_SLOT → PATH_INPUT → CAT_MOVING → FOX_ACTION → TURN_END, with immediate third-seal victory and no fox action on victory. The three-card tutorial is captured separately and remains a blocking first-entry surface.
- Touch targets: every board cell uses a 78px design-space rect; the 360×640 capture confirms the logical 720px board remains tappable at half scale.
- Feedback: roll result, remaining steps, PAIR/TRIPLE role copy, undo/confirm affordances, white-fire preview, MISS, seal banner, fox action, and victory/defeat result overlay are all state-owned.
- Feedback: roll result, remaining steps, PAIR/TRIPLE role copy, undo/confirm affordances, white-fire preview, MISS, seal banner, fox action, line-cut warning, Sakura purification, city-block bonus, and victory/defeat result overlay are all state-owned.
- Runtime checks: focused FOX_FIRE_SIX_ROUTES suite (including Slice4–9 rules), UI smoke suite, Amazon/Kyoto integration suite, full legacy suite, and tall-phone suite pass with zero failures; editor parse and native captures exit cleanly.

## Comparison history

1. ImageGen target established the portrait hierarchy and six-route board geometry.
2. First native READY capture exposed the shared Button disabled style painting opaque ivory cells over the board.
3. The view now overrides the disabled cell style with a transparent board-aligned style; the recaptured READY and PATH_INPUT states show the authored board unobstructed while legal cells retain gold focus rings.
4. Native 720×1280 and 360×640 captures confirm the same hierarchy and interaction layer across the target sizes.

final result: passed

---

# Design QA — Amazon and Kyoto Mobile Product UI

- Native evidence: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-ui-product-final.png`, `kyoto-ui-product.png`, `amazon-overview-product.png`, `amazon-menu-product.png`, and `kyoto-rolled-product-final.png`.
- Viewport: Windows OpenGL compatibility renderer at 720×1280.

The normal screens retain the Cairo cockpit hierarchy while keeping a slightly taller scenic map. HUD labels, LIFE/HP, mission progress, current position, route preview, and touch controls remain legible without shrinking the core controls. Colored semantic medals make route types readable over both the bright jungle and dark Kyoto backgrounds. The compact die does not obscure the seven-space route preview, and the enlarged three-roll values align with the artwork windows.

The full-map overlay contains the full course, colored route semantics, explorer marker, uninterrupted close CTA, and a skippable slow zoom/pan presentation. The pause menu contains BGM, SE, encyclopedia, continue, and stage-selection actions with large touch targets. Amazon/Kyoto stage-model tests, the Cairo 90-space session regression suite, and the full shared suite pass with zero failures. P0: none. P1: none. P2: none.

final result: passed

## Cairo-aligned Amazon/Kyoto normal-map pass (2026-08-12)

- Reference: `C:\Users\hiro\Desktop\cairo.jpg`.
- Verified native 720x1280 captures: `artifacts/amazon-kyoto/amazon-map-new2.png`, `kyoto-map-new.png`, `kyoto-overview.png`, and `kyoto-item-new.png`.
- The normal shell now keeps the Cairo order and touch-sized controls: HUD, stage band, MISSION, scenic map, local `現在地 +1〜+6` strip, message band, three slots, roll button, and item/coin/skill/menu dock.
- First entry opens the Amazon/Kyoto full-map overlay and the HUD map button reopens it. Stage palettes are rainforest teal for Amazon and indigo/vermillion for Kyoto.
- Kyoto item/event art is generated and wired into both preview and modal flows.
- Kyoto stage selection, normal map, and White Fox captures use the supplied BGM tracks through `BgmManager` (`古都、路地裏にて.mp3` / `雅なフィールド.mp3` / `お稲荷様.mp3`).

Verification:

- `Godot_v4.7-stable_win64_console.exe --headless --editor --path . --quit` — pass.
- `tests/run_amazon_kyoto_stage_tests.gd` — `AMAZON_KYOTO_TESTS passed=true`.
- `tests/run_v06_play_session_tests.gd` — `V06_PLAY_SESSION_TESTS failures=0`.
- `tests/run_tests.gd` — `DICE_SLOT_TRIP_TESTS failures=0`.
- Stage-selection QA — `QA_JOURNEY_STAGE_SELECT passed=true preview=true bgm_preview=true start=true bgm_map=true back=true`.

## Shared cockpit proportion pass (2026-08-13)

- Compared against `C:\Users\hiro\Desktop\cairo2.jpg` and `C:\Users\hiro\Desktop\dice7.jpg`.
- Normal map height was reduced from the scenic-first ~55–60% composition to ~44–47%; the combined message/tray/tool area now occupies ~27% and matches Cairo's interaction emphasis.
- Native 720×1280 evidence: `artifacts/amazon-kyoto/amazon-cockpit-final.png` and `artifacts/amazon-kyoto/kyoto-cockpit-v3.png`.
- The luxury three-slot frame and round roll control are readable at normal touch distance, all bottom tools remain at least 48px high, and the portrait stage art is preserved through current-position cropping plus the existing full-map overlay.

---

# Design QA — Amazon audio, cards, and Cairo-aligned journey shell

- Native normal map: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-map-cards-final.png`
- Native item card modal: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-item-modal.png`
- Native event card modal: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-event-modal.png`
- Native Aquafall boss: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/amazon-kyoto/amazon-boss-bgm.png`

Amazon's stage-select preview, map, and Aquafall transition use separate supplied BGM tracks with crossfade. The normal map keeps the Cairo hierarchy while protecting the waterfall playfield: shared stats at the top, transient status band, then the compact `3 ROLL SLOT` tray with item/event/dice actions. Generated item and event card art keeps the bronze-frame visual language, while labels remain Godot text for legibility and localization.

Verification: Amazon/Kyoto data + battle suite passed; stage-select QA passed with `bgm_preview=true` and `bgm_map=true`; full DICE SLOT TRIP suite passed with `failures=0`.

final result: passed

---

# Design QA — Amazon and Kyoto

- Viewport: 720×1280 portrait.
- Visual targets: supplied Amazon map and Kyoto White Fox screenshots.
- Evidence: `artifacts/amazon-kyoto/amazon-map.png`, `amazon-boss.png`, `kyoto-map.png`, `kyoto-boss.png`.

Amazon retains the dense vertical-jungle route hierarchy with all 120 markers, fixed HUD, and a dedicated bottom roll control. Aquafall has five high-contrast waterfall lanes, carried HP, height/lane/difficulty readout, the normalized Explorer Cat, and generated log obstacles. Kyoto presents its afternoon-to-dawn journey art, 90 main markers plus 38 detour markers, and goshuin progress. White Fox presents eight active targets around the guardian, a two-line unclipped current/next Foxfire forecast, and the working three-die/helper controls.

Map, branch, event, secret, boss, defeat, roulette, save, and stage-back paths are wired. The main CTA is 82px tall, secondary controls are 48–66px, Japanese labels use the bundled Noto Sans JP, and generated scenery contains no baked gameplay copy. Old Cairo play/save compatibility remains intact; the new stages use a separate versioned save.

Windows OpenGL native captures and the Amazon/Kyoto, V06 session, full legacy, and stage-select route suites pass. P0: none. P1: none. P2: none.

final result: passed

---

# Design QA — Source-art Title and Ordered Slot Pacing

- Selected visual target: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/backgrounds/title-hero.png`
- Generated backing matte: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/ui/title/title-backing-matte-v2.png`
- ImageGen prompt: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/_source/prompts/title-backing-matte-v2.prompt.txt`
- Standard capture: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/title-v2-qa/title-720x1280.png`
- Tall capture: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/title-v2-qa/title-720x1600.png`
- Combined comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/title-v2-qa/title-reference-comparison.png`
- Viewports/states: live Godot compatibility renderer at 720×1280 and an offscreen 720×1600 phone viewport, both on the title state.
- Runtime checks: V06 roll-set, play-screen, boss-screen, boss-battle, play-session, tall-phone, and full legacy suites completed with `failures=0`.

## Findings

No actionable P0/P1/P2 issues remain. The foreground is the complete source illustration with no replacement title, mask, or reconstructed button art. At 9:16 it matches the selected target edge to edge. At 9:20 it remains uncropped and centered, with equal top and bottom breathing room supplied by the generated low-detail travel-journal matte.

## Required fidelity and interaction surfaces

- The `DICE SLOT TRIP` wordmark, subtitle, Sphinx, traveler, painted controls, and autosave plaque remain source pixels rather than approximated UI.
- The four live buttons use source-image rectangles inside the same fitted art coordinate system, so appearance and touch geometry cannot drift independently.
- Invisible hit geometry expands each painted control to at least 96px at the 720-wide design size while preserving the original visual composition.
- Focus, hover, pressed, and disabled feedback are restrained translucent treatments over the painted controls; no extra lower-screen panel obscures the scene.
- `1・2・3` and `3・2・1` resolve STRAIGHT; shuffled consecutive faces such as `1・3・2` resolve MIX. Reach hints expose only the one ordered completion face.
- Boss die pace starts at 1.08× on lap one, rises by 0.035× per lap, and caps at 1.255× for readability.
- Victory roulette timing interpolates from 0.105 seconds per step for a close result to 0.215 seconds at a ten-space-or-larger lead.

## Comparison history

1. The first tall capture revealed that `STRETCH_KEEP_ASPECT` top-aligned the foreground while the shared art-rect calculation centered its shadow and hit targets.
2. The foreground switched to `STRETCH_KEEP_ASPECT_CENTERED`, matching the same centered rectangle used by the shadow and controls.
3. The final three-up comparison shows the selected source, 9:16 implementation, and 9:20 implementation retain identical foreground proportions and full wordmark visibility.

final result: passed

---

# Design QA — Functional Tools and Travel Postcards

- Item screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-tools-item-360x640.png`
- Skill screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-tools-skill-360x640.png`
- Encyclopedia screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-travel-encyclopedia-360x640.png`
- Viewport/state: Cairo travel READY state and travel encyclopedia, native 360×640 Movie Writer captures
- Interaction checks: item paging and consumption, six-face Pinpoint selection, modal input gating, victory postcard unlock, earned/locked postcard presentation
- Runtime checks: dedicated tools/postcard suite, V06 play-screen suite, V06 session/save/tile/boss suites, and full legacy suite passed

## Findings

No actionable P0/P1/P2 issues remain for this slice. Items now use a compact card with current quantity and bag capacity, while Pinpoint exposes all six valid choices only at READY. The encyclopedia leads with a scrollable two-card postcard gallery: earned memories retain full color and locked memories stay visibly dark without disappearing.

## Gameplay and collection contract

- ITEM spaces award one of three deterministic Cairo tools until the three-slot bag is full; overflow becomes coins rather than silently discarding a reward.
- Water restores one HP, the compass adds one step to the next normal move, and the scarab cancels the next risk effect. Each effect is stored in the stable save state.
- Pinpoint spends a full gauge to reserve one face from 1–6 and consumes that reservation exactly once when the next roll is stopped.
- Clearing the Cairo boss journey registers `cairo_journey_complete` once. The travel encyclopedia reads the persistent postcard registry and keeps both earned and undiscovered slots visible.

final result: passed

---

# Design QA — Victory, Sound, and Haptics Finish

- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-victory-finish-360x640.png`
- Viewport/state: restored Cairo boss victory at native 360×640.
- Result hierarchy: postcard, journey-complete kicker, victory title, score, mission completion, race detail, then one `次の旅へ` action.
- Playfield protection: the finished race board and gate label are hidden once the result settles; only the compact race counters remain as context.
- Feedback system: existing UI and dice assets are mixed through three bounded players; roll stop, reward, damage, mission completion, victory, and defeat use semantic events.
- Haptics: short event-specific patterns run only on Android/iOS, no-op safely on desktop/headless, and honor the persisted settings toggle.
- Runtime checks: feedback, boss screen, play screen, save, and mission suites passed; editor parse completed without script errors.

final result: passed

---

# Design QA — First-time Tile Help

- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-tile-help-360x640.png`
- Viewport/state: Cairo travel, first COIN landing help, native 360×640 Movie Writer capture
- Interaction checks: the full-screen overlay receives mouse/touch input; descendants ignore input; roll, map, tools, and back are gated until dismissal
- Runtime checks: card state, Japanese/English translation, seen-state save/restore, normal play, boss, mission, save, visual asset, and full legacy suites passed

## Findings

No actionable P0/P1/P2 issues remain. The centered parchment card preserves the existing Cairo art direction, the stronger dim separates it from the busy board, and the final teal prompt clearly communicates tap-anywhere dismissal without adding another button.

## Required fidelity surfaces

- Hierarchy: one title, one existing production discovery image, a short explanation, and a quiet dismissal prompt.
- Playfield protection: the card is transient and appears after the landing/camera sequence; it does not permanently consume board or tray space.
- State behavior: each of EVENT, ITEM, COIN, REST, RISK, and WARP appears once, becomes seen only after dismissal, and remains seen across save, retry, and later laps.
- Localization: all new card copy is keyed through Godot's TranslationServer with Japanese fallback and English resources.

final result: passed

---

# Design QA — Roll and Slot Alignment

- Source visual truth: `C:/Users/hiro/Desktop/ChatGPT Image 2026年8月1日 14_15_43.png`
- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-roll-slot-round-v4-idle-360x640.png`
- Full comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-roll-slot-round-v4-comparison-720x640.png`
- Focused comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-roll-slot-round-v4-focused-1440x360.png`
- Viewport/state: normal Cairo travel, READY, native 360×640 Movie Writer capture
- Density normalization: source 941×1672 downsampled and padded to 360×640; implementation captured natively at 360×640; both compared at 1:1 pixels
- Primary interaction checks: circular center accepts input, transparent corners reject input, `振る`/`止める`/disabled/movement copy remains state-driven, and the three slot values remain display-only
- Console/runtime check: Godot editor parse and dedicated runtime suites completed without script errors; browser console is not applicable to this Godot build

## Findings

No actionable P0/P1/P2 differences remain for the requested roll/slot alignment slice. The roll control is now a true circle with a matching circular hit region, and all three values sit inside the authored reel windows instead of drifting into transparent padding or dividers.

## Required fidelity surfaces

- Fonts and typography: the dynamic Japanese action copy is centered below the die icon with a readable outline; the three 54px design-space values remain centered in their windows.
- Spacing and layout rhythm: the 190×190 circular control and fixed reel-window overlays fit the existing 252px tray without reducing the 450px playfield contract.
- Colors and visual tokens: the new button uses the reference's antique gold, dark teal enamel, ivory highlight, and restrained compass-like details.
- Image quality and asset fidelity: the button is a real 1254×1254 RGBA raster generated from the selected visual and existing ornament style, not a code-drawn circle. The existing real three-window slot asset is preserved without stretching.
- Copy and content: `残りN`, slot faces, and state-specific `振る`/`止める`/`Nマス進む`/`移動中…` behavior remain data-driven.

## Comparison history

1. Pre-fix evidence `build/qa-roll-slot-controls-before.png` showed the first reel value in transparent padding, the second value near a divider, and a wide capsule roll ornament over a rectangular button surface.
2. The reel labels were moved from a generic HBox distribution to the three measured image-window centers.
3. A new circular brass/teal ornament was generated and chroma-keyed to RGBA, the button became square, and circular `_has_point` input rejected the invisible corners.
4. Post-fix evidence `build/qa-roll-slot-round-v4-focused-1440x360.png` confirms centered reel values plus the reference's circular die-over-copy action composition.

## Follow-up polish

- P3: the reference includes a taller mechanical slot cabinet with a lever and three lamp ornaments. The current slice intentionally retains the project's existing compact three-window tray so the board remains at least 450px tall.

final result: passed

---

# Design QA — Travel Menu and Stage Exit

- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-travel-menu-360x640.png`
- Viewport/state: Cairo travel, MENU open, native 360×640 Movie Writer capture
- Interaction checks: persistent bottom action opens MENU only; Continue resumes the same run; Return to Stage Select is the sole normal-travel exit action
- Runtime checks: clock pause/resume, input gating, signal isolation, Japanese/English copy, normal play, boss, tile help, mission, save, visual asset, and full legacy suites passed

## Findings

No actionable P0/P1/P2 issues remain. The menu uses the established dark-teal enamel, antique-gold edge, and ivory secondary action. It clearly prioritizes continuing the journey while keeping the destructive navigation action one disclosure level deeper.

## Playfield protection

- Normal play gains no new persistent panel; only the former direct-exit button changes to `メニュー`.
- The modal blocks board, roll, map, item, and skill input and pauses the run clock.
- Application resume cannot restart the clock underneath this or another pause surface.

final result: passed

---

# Design QA — Ring EXIT Emphasis and Third-lap Rescue

- Implementation screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/build/qa-loop-exit-360x640.png`
- Viewport/state: Oasis ring after two EXIT passes, native 360×640 Movie Writer capture
- Gameplay checks: exact-stop exit remains active for laps one and two; the third pass forces the active warp gate's canonical return; wrap progress saves and restores
- Runtime checks: course model, loop rescue, play session, play screen, tile effects, save, missions, boss, visual assets, and full legacy suites passed

## Findings

No actionable P0/P1/P2 issues remain. The EXIT tile now has a larger gold halo and a literal EXIT label, while the contextual center badge reports both exact distance and rescue progress. The treatment is only active inside a ring, so the main route still does not reveal detached-ring exit information.

## Playfield protection and motion

- The guidance uses the otherwise empty center of the eight-space ring rather than adding another persistent HUD row.
- Rescue triggers only after the third pass, preserving deliberate exact-stop play for the first two laps.
- Forced return reuses the existing portal-transfer and camera-return sequence instead of introducing a competing animation.

final result: passed

---

# Design QA — Heart Roulette (Historical, superseded)

> This section documents the former roulette contract (`+2`, `±0`, and `−1`). It is retained as project history and is superseded by the current 90-map/LIFE/recovery handoff below; it is not the current product contract.

- Source visual truth: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/ui/common/heart-roulette-wheel-v1.png`
- ImageGen prompt: `C:/Dev/Projects/dice-slot-trip-main-verify/assets/art/_source/prompts/heart-roulette-wheel-v1.prompt.txt`
- Pending screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/playtest/heart-roulette/heart-roulette-pending-540x960.png`
- Result screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/playtest/heart-roulette/heart-roulette-result-540x960.png`
- Combined comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/playtest/heart-roulette/heart-roulette-comparison-486x162.png`
- Viewport/state: live Godot window at 540×960, rendered from the 720×1280 design space at 0.75 scale; boss victory roulette both spinning and stopped.
- Density normalization: the 1254×1254 source wheel and both 162×162 implementation component crops are compared at equal display size.
- Interaction checks: the six visual positions map back to their authoritative session slots; STOP preserves the selected result; the following tap continues the journey.
- Runtime checks: main, V06 play-screen, V06 boss-screen, and V06 visual-asset suites completed with `failures=0`; `git diff --check` completed without whitespace errors.

## Findings

No actionable P0/P1/P2 issues remain. The three `+1` results occupy alternating points and read as a triangle, while `+2`, `±0`, and `−1` occupy the three gaps. The selected chip, center value, title, heart receipt, STOP action, and retained result create one clear cause-and-effect path.

## Required fidelity surfaces

- Typography: signed values stay large and tabular; `−1` uses a true minus and zero uses `±0` so every outcome scans at a glance.
- Spacing and hierarchy: the finish summary, 216px wheel stage, and 96px action remain separate at the 360×640-equivalent density.
- Palette and tokens: teal enamel, antique gold, warm ivory, and pink-red reward emphasis extend the existing Cairo boss treatment.
- Image fidelity: the ornate six-segment wheel is the generated production RGBA asset; code supplies only stateful labels, selection, and interaction.
- Copy: pending state says `STOP!`; result state names the heart change, retains the heart receipt, and changes the action to `次の旅へ`.

## Comparison history

1. The generated blank wheel established the six equal Cairo segments, gold rim, teal enamel, and central heart.
2. The first live pending capture exposed a stale full-width operation band covering the lower roulette segments.
3. Boss-finish entry now retires the transient reach/operation message and cancels its delayed refresh ownership.
4. The recaptured pending and result states show all six outcomes, including the bottom `±0`, unobstructed; the combined comparison confirms the runtime wheel retains the source asset's proportions and palette.

final result: passed

---

# Design QA — Current 90-map, LIFE, and HP Recovery Handoff

- ImageGen source: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/90-map-life-ui-qa/source-imagegen-original.png` (941×1672, SHA-256 `7DC7E986D7A858D397795C37F96294B101D7B9BE054C595EACFD33D6594D209A`)
- Native state matrix: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/90-map-life-ui-qa/`
- Recovery comparison montage: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/90-map-life-ui-qa/roulette-source-vs-implementation.png`
- Skill-selector correction montage: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/90-map-life-ui-qa/skill-selector-before-after.png`
- Detailed visual record: `C:/Dev/Projects/dice-slot-trip-main-verify/docs/goals/dice-slot-trip-90-map-life-rework/notes/T019-visual-qa.md`

## Native evidence matrix

- Normal map: 720×1280, 720×1600, and 360×640.
- Revival, LIFE gained, LIFE full, EVENT, skill discovery, and 3×2 skill selector: native 720×1280 each.
- Recovery pending, retained recovery result, and PERFECT: native 944×1664 each.
- The revival capture restores a valid stable HP3/LIFE2 snapshot and uses the production refresh/stamp path. Its HUD reads `復活 ×2` while the same frame reads `復活！　復活 ×2　HP FULL`.

## Current contract and findings

- The route is the approved 90-space Cairo course. The compact explorer-cat LIFE HUD communicates revival stock independently from three-heart HP without reducing the map playfield.
- LIFE starts/caps at three. Completed laps 10, 20, and so on add one LIFE only when below cap. At full LIFE the small `10 LAP達成 / 復活 FULL` stamp remains, with no additional reward.
- Wounded victory uses `HP RECOVERY` and exact clockwise outcomes `[+1, +2, +1, FULL, +1, +2]`; the three `+1` outcomes form the approved triangular placement. STOP preserves the chosen result. HP3 victory shows `PERFECT! / HP FULL` without a wheel.
- EVENT keeps both the coin-priced CTA and an enabled, focusable free `旅を続ける` exit. Skill READY uses six 96px-class choices in a 3×2 grid, explicit close, direct armed-face copy, and one-time discovery timing.
- Both comparison montages and all twelve native states were inspected for typography, hierarchy, playfield obstruction, overlap, CTA visibility, wheel order, result retention, and PERFECT state.

## Verification and severity

- Visual-asset, course-model, atlas-scenery, play-session, save, play-screen, boss-screen, feedback, tall-phone, loop-rescue, tile-effect, coin-economy, and full suites: pass, `failures=0`.
- Windows OpenGL native capture: pass at exact required dimensions.
- P0: none.
- P1: none.
- P2: none.

final result: passed

---

# Design QA — Title, Travel Encyclopedia, Game Over, and Boss Start

- Tall-title screenshot: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/01-title-tall.png`
- Encyclopedia list/detail: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/02-encyclopedia-list.png`, `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/03-encyclopedia-detail.png`
- Travel settings: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/04-travel-settings.png`
- Game over: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/05-game-over.png`
- Boss start: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/current-polish-qa/06-boss-intro.png`
- Viewports/states: live Godot compatibility renderer at 720×1600 for title/book and 720×1280 for travel, game-over, and boss-race surfaces.

## Findings

No actionable P0/P1/P2 issues remain for this slice. The complete `DICE SLOT TRIP` wordmark stays inside the tall-phone frame, while a fixed design-space parchment boundary hides obsolete painted buttons. The shared encyclopedia shows discovered and locked item, event, boss, and memory slots, with a full-art effect/detail view and a settings-menu route that keeps the run paused.

The game-over capture contains no stale slot values or operation copy over `もう一度旅する`. The first boss frame keeps both racers on the exact START camera, shows the Sphinx, and ends its explanation with one 96px `レースを始める` action.

## Interaction and persistence checks

- Item acquisition, event presentation, boss entry, and postcard victory register discoveries without clearing them on journey retry.
- `GameState` serialization restores the new travel-card IDs; legacy boss entries and postcard gallery node contracts remain readable.
- Closing the in-game encyclopedia returns to the still-paused settings menu; only `旅を続ける` resumes the clock.
- Targeted tools/postcards, travel-menu, play-screen, boss-screen, and tall-phone suites completed with `failures=0` after the visual pass.

final result: passed

---

# Design QA — Long-map Mobile UX Polish

- Detailed record: `C:/Dev/Projects/dice-slot-trip-main-verify/docs/goals/dice-slot-trip-long-map-ux-polish/notes/T007-visual-qa.md`
- Raw native matrix: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/long-map-ux-polish/`
- Normal/boss contact sheet: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/long-map-ux-polish/contact-normal-boss.png`
- Opposite map bounds sheet: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/long-map-ux-polish/contact-map-bounds.png`

Windows/OpenGL native captures at 360×640 and 720×1280 confirm the compact normal HUD shows mission progress `0/12` and `0/5`, with explorer-cat `復活 ×3` above the separate three-heart HP line. The HUD remains contained and preserves the central route playfield.

At both sizes, the corrected full-map modal reaches opposite padded route extents without blank overscroll, retains its title and separate `閉じる` action, and hides the backing operation band/white `サイコロを振ろう` copy. Direct message updates remain hidden while the map is open; closing restores the READY copy, clock ownership, MapButton focus, and die input. The purchased boss pre-roll state shows YOU `3 / 20` against SPHINX `0 / 20`, with both full racer footprints visible after the existing intro CTA and before the first roll.

The independent recorder validates exact PNG dimensions, non-uniform pixel content, and normal process exit. Mission, candidate-mission, save, play-screen, play-session, feedback, tall-phone, visual-asset, atlas-interaction, boss-screen, boss-battle, coin-economy, course-model, and full suites pass with no failures. P0: none. P1: none. P2: none.

final result: passed

---

# Design QA — Kyoto Normal Map / Cairo-style Current-to-+6 Horizon

## Evidence

- Source visual truth: `C:/Users/hiro/Desktop/cairo-kyoto.jpg` (757x798, Cairo reference on the left).
- Normalized Cairo reference crop: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/reference-cairo-360x800.png` (360x800).
- Implementation: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/kyoto-map-360x800.png` (Godot viewport 360x800, density 1).
- Responsive captures: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/kyoto-map-720x1280.png` and `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/kyoto-map-360x640.png`.
- Full-view comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/cairo-reference-vs-kyoto-implementation.png`.
- Focused map comparison: `C:/Dev/Projects/dice-slot-trip-main-verify/artifacts/kyoto-cairo-map/cairo-map-focus-vs-kyoto-map-focus.png`.
- State: fresh Kyoto normal map after the opening overview and one-time goshuin tutorial are dismissed.

## Findings

No actionable P0/P1/P2 findings remain. Cairo is now the layout source of truth for Kyoto's normal screen rather than a loose stylistic reference. At 360x800 the implemented bands measure approximately HUD 102px, MISSION 60px, playfield 352px, message 35px, SLOT 116px, and tool dock 58px, closely matching the reference hierarchy. The 99-node topology, two shortcuts, four goshuin checkpoints, and boss destination remain available in 全体マップ rather than competing with normal play.

- Fonts and typography: bundled Noto Sans JP remains consistent; +1 through +6 use 36-design-pixel labels, while 現在地 uses a responsive 24-pixel label so the three Japanese characters remain intact at 360px width.
- Spacing and layout: the seven cards target 260 design pixels in height (responsive minimum 220), the explorer is 136px and bottom-anchored, and the centered live die scales from 152 to 184px. On the 360x800 reference state the card horizon begins about 35% into the playfield, replacing the previous top-heavy composition and unused lower approach space. No overlap or clipping appears at 720x1280, 360x800, or 360x640.
- HUD: Kyoto now uses Cairo's two-row information hierarchy without four boxed value chips. The large `1/90` value, survival stack, coin value, and light 全体マップ action read as one cluster. This profile is Kyoto-only, preserving Amazon's existing battle geometry.
- Mission: 御朱印 0/4 moved into the stage band. The MISSION band now presents one saved, lap-local Cairo-style random objective with live DICE/SLOT/travel/coin progress and a single-claim COIN reward.
- Colors and tokens: Kyoto red, gold, cream, and ink replace Cairo teal appropriately. A restrained warm 18% overlay pushes the torii photograph behind the cards without blurring it.
- Image quality and assets: the existing Kyoto torii background, explorer strip, semantic tile icons, and real 3D ivory die are sharp and correctly cropped. No placeholder, handcrafted SVG, or code-drawn substitute is used.
- Copy and content: current through +6 is explicit, the status band remains contextual, and 全体マップ still names the complete-route action.
- Interaction and accessibility: ROLL/STOP, cat hop, camera follow, route refresh, reduced-motion path, branch choices, mission reward idempotency, JSON mission restore, and 360-wide scaling pass. The enlarged map die stays away from the finger-operated ROLL control. The four lower tools use Cairo's light panels, 36px icons, 16px labels, and approximately 58px physical height at 360x800.

## Comparison history

The first implementation capture exposed two P2 issues: one obsolete semantic route marker remained over the background, and the explorer obscured the 現在地 label. The second pass enlarged the cards, explorer, numbers, and die. The final source-of-truth pass removed Kyoto's boxed HUD, restored the full Cairo mission hierarchy, separated goshuin progress, moved the card horizon to the visual center, shortened the decorative playfield, softened the background, and adopted Cairo's light tool dock. Combined full and focused comparisons confirm the requested hierarchy is present.

## Verification

- Journey-stage UI regression: `failures=0`.
- Journey-stage motion for Amazon and Kyoto: `failures=0`.
- Amazon/Kyoto course, branch, goshuin, save, and boss integration: pass.
- Tall-phone layout: `failures=0`.
- 狐火追陣 core/UI regression: `failures=0`.
- Full foundational suite: `DICE_SLOT_TRIP_TESTS failures=0`.
- P0: none. P1: none. P2: none.

final result: passed
