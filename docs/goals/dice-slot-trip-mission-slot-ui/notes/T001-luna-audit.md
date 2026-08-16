# T001 Luna audit — MISSION and SLOT UI

## Lane A: MISSION / SAVE

- `scripts/game/v06_play_session.gd` currently uses nested mission schema2, three active IDs (`cairo_coin15`, `cairo_triple2`, `cairo_no_damage`), per-lap progress, event serial, and stable snapshot/restore.
- `next_lap()` calls `_reset_course_and_clock(false)`, which resets all current mission progress.
- Completion emits a mission event but does not grant a dedicated TRIP COIN reward.
- Existing schema1 migration and schema2 tests preserve `active_ids`, ranks, targets, event state, and old saves.
- A new one-mission selection needs an optional state extension. Old schema2 saves with three IDs should be recognized as legacy mode and continue their historical tracking until the next lap; the next lap can select the new one-mission mode. This avoids rewriting a save while a mission is in progress.
- Required checks: one selected ID per new lap, progress/completion/reward exactly once, no recursive mission progress from the reward, round-trip/restore, and no duplicate reward after UI refresh or next lap.

## Lane B: SLOT reach / result UI

- `_normal_slot_reach()` and `_show_slot_reach_cue()` already run after two normal rolls and use the shared message band above the tray.
- Current normal copy is `SKILL READY` for TRIPLE and `SKILL +2` for STRAIGHT; it has no TRIP COIN reward or mission overlap signal.
- `_play_inline_slot_result()` owns the short three-roll result animation using `RoleLabel` and `RoleRewardLabel`; reach copy should remain in `MessageBand` so the two surfaces do not compete.
- Session reward authority is `_award_role_score()`. A reach preview must remain presentation-only; the third roll is the only point that awards the role.
- Required checks: target/role/reward copy, mission-overlap copy, existing short result visibility/order, and 360x640 non-overlap.

## Integration risks / decisions required

1. The one-mission rule must be real state for new laps, not merely hiding two cells while three missions continue silently.
2. The wireframe examples establish normal role rewards as PAIR +1, STRAIGHT +3, TRIPLE +5 TRIP COIN. This conflicts with the current skill-charge rewards and requires either a coherent REST/SKILL follow-up or an explicitly presentation-only slice.
3. Mission reward trigger is not specified. For this tranche, grant the selected mission's configured TRIP COIN reward at completion, exactly once, and persist `reward_claimed`; old legacy saves receive no retroactive reward.
4. The exact random pool is not fully specified. Use only mission kinds with implemented progress handlers in the bounded slice; keep broader MAP/TRIP candidates deferred until their authoritative hooks exist.

## Recommended bounded file set

- `scripts/game/v06_play_session.gd`
- `scripts/game/v06_session_save_data.gd`
- `scripts/app/v06_play_screen.gd`
- `scenes/app/V06PlayScreen.tscn`
- `tests/run_v06_candidate_mission_tests.gd`
- `tests/run_v06_mission_tests.gd`
- `tests/run_v06_save_tests.gd`
- `tests/run_v06_play_screen_tests.gd`

Existing dirty coin UI files must remain in the same diff and must not be reverted.

