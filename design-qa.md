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
