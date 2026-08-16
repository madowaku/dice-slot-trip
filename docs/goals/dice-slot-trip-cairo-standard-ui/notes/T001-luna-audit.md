# T001 Luna audit receipt

## Integrated finding

The existing Cairo runtime has a safe foundation for the requested flow, but it is still a partial implementation: one selected mission per lap exists, normal SLOT coin rewards exist, and the operation message is runtime-reparented between the landing board and the SLOT/ROLL tray. The requested 12-row difficulty catalog, weighted lap selection, pure MAP landing candidates, and neutral MISSION/SLOT/MAP conflict presentation are not yet implemented.

## A — MISSION / SAVE

Evidence: `scripts/game/v06_play_session.gd:56-63`, `540-642`, `1500-1609`; `scripts/game/v06_session_save_data.gd:245-314`; mission/save tests.

- Current selectable pool is four entries (`cairo_face`, `cairo_coin15`, `cairo_role`, `cairo_no_damage`), selected by seed modulo pool size.
- Current rewards are effectively 12 for normal missions and 15 for the no-damage mission; there is no explicit EASY/NORMAL/HARD catalog or 8/12/18 resolver.
- Nested and outer save schemas are both 2. Older schema-2 payloads without the optional active-selection fields already restore in legacy mode; they must not be rerolled or retroactively rewarded.
- The exact requested first 12 stable rows, hook mappings, and boundary tests are absent. The implementation must preserve existing IDs and make the new selection fields optional for old saves.

Recommended compatible shape: retain schema 2, add stable catalog metadata and persisted `active_id`, selection seed, target, difficulty/reward, progress, completion, claim state, and legacy mode; select difficulty from the lap bucket first, then select a row within that difficulty bucket.

## B — SLOT / MISSION conflict

Evidence: current `_normal_slot_reach` and `_show_slot_reach_cue` in `scripts/game/v06_play_screen.gd`, plus existing play-screen tests.

- Current reach logic combines candidate discovery, precedence, copy, and rendering. Adjacent faces promote STRAIGHT and embed a PAIR fallback; overlap is then annotated.
- The final spec needs a pure candidate contract with at most two rows: triple match first; MISSION+SLOT match; MISSION+MAP match; SLOT+MAP; neutral competing candidates; SLOT-only; MISSION-only; otherwise silent.
- Competition must show neutral alternatives and must never emit an “おすすめ” recommendation. A value-bearing candidate such as `🎰 6 → STRAIGHT 🪙3` may coexist with `🎯 5 → MISSION + PAIR 🪙1`.
- No-value/MIX states should leave the guidance band quiet instead of showing a filler explanation.

## C — MAP / landing preview

Evidence: `scripts/game/v06_course_model.gd:62`; `scripts/game/v06_play_session.gd:1145`, `1312`, `1338`; `scripts/game/v06_atlas_view.gd:668`, `1350`; course and route tests.

- `V06CourseModel.advance()` is the authoritative pure walker. The Atlas preview is visual-only and is incorrect around branches, warps, loops, boss termination, and effects.
- A later session-level `preview_forward_landings(6)` should enumerate exact distances using `_course_context()`, preserve `CHOICE_REQUIRED` and remaining steps, and expose position, tile kind, effect, path, transitions, warp/loop/boss flags, and route options without mutating session state.
- Preview must distinguish exact warp landing from passing a gate, loop exit conditions, boss surplus-step discard, consumed-node display, ITEM capacity, REST/RISK state, and deferred EVENT interaction.
- Authoritative integrated Cairo data is `data/stages/v06_cairo_course.json` (90 main tiles, boss at main 89). `cairo_stage.yaml` and the v0.8 document still describe an older 58-tile model; do not silently use them for runtime behavior.

## D — ordinary screen / 360x640

Evidence: `scenes/app/V06PlayScreen.tscn:72-88`, `89-376`, `505-887`, `1239-1268`; `scripts/app/v06_play_screen.gd:469-518`, `2161-2224`, `4145-4158`; layout/save/boss/item/game-over tests.

- Existing runtime order is already HUD → stage/mission → Atlas landing board → operation message → SLOT/ROLL tray → item/coin/skill/menu dock. Preserve this order and do not shrink established touch targets as a first move.
- The scene authors `MessageBand` as a root-level overlay, while runtime reparents it between `AtlasFrame` and `TrayPanel`; a regression in `_prepare_operation_message_band` would overlap the tray. Keep runtime placement authoritative unless a later bounded geometry patch proves safer.
- The 720x1280 logical design scales to the 360x640 physical baseline with approximately 106px vertical slack. Add a direct 360x640 assertion/capture for the complete stack before changing coordinates.
- Keep score semantics distinct: score is travelled distance; `lap_score` and persistent best are separate; route denominators such as 18/90 are not score.
- Modal onboarding/landing cards stay modal and outside the three-layer normal flow. Extend item-use and GAME OVER/retry geometry checks at the same baseline when layout changes.

## T001 decision inputs for PM

1. First worker should make the mission catalog/weighted selection and pure next-one-roll candidate contract explicit, with save compatibility tests, before a broad coordinate rewrite.
2. Treat the 90-tile JSON course as authoritative; document the 58-tile files as legacy/spec conflicts.
3. Keep the existing MessageBand reparenting and current layout in the first slice; add candidate/360 assertions before visual rearrangement.
4. Defer CASINO CHIP, Kyoto, economy rebalance, and full MAP candidate implementation until the pure candidate contract is approved and covered.
