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
