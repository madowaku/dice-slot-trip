# T002 PM integration decision

## Adopted for this tranche

1. New laps use one selected mission. The selection pool is limited to mission kinds with authoritative Cairo hooks in this tranche: fixed-face dice, cumulative TRIP COIN, qualifying SLOT role, and no-damage boss victory. Selection uses a persisted per-run seed so a save/restore cannot change the displayed mission; old schema2 saves without the new optional fields remain in legacy mode until their next lap.
2. The selected mission exposes `active_id`, `selection_seed`, `progress`, `target`, `completed`, `reward_coins`, `reward_claimed`, and `legacy_mode` as optional additions to nested save schema2. Legacy three-mission fields remain in snapshots so old migrations and restores stay readable. Legacy saves do not receive retroactive rewards.
3. Mission rewards are TRIP COIN and are credited exactly once at completion. The reward is added directly to the wallet, without feeding back into mission progress. This tranche uses 12 for standard missions and 15 for the no-damage mission; the exact economy will be re-audited before broad balancing.
4. Normal-map SLOT roles display and award TRIP COIN: PAIR +1, STRAIGHT +3, TRIPLE +5. MIX has no normal SLOT reward. Full-HP REST charges SKILL +1; damaged REST continues to heal. This keeps the new SLOT reward copy truthful and preserves a path to SKILL without keeping the old SLOT charge rewards.
5. After two normal rolls, reach guidance prefers STRAIGHT, shows the best target and coin reward, and adds a second insurance line for PAIR when applicable. Non-adjacent pairs show both PAIR targets. If the target matches the selected mission (face or role), the primary line says `ダブルチャンス`. Boss reach copy remains on the existing Kyoto/Sphinx wording path.
6. The MISSION band becomes a single featured card at runtime. It reuses the existing scene assets, hides the two legacy cells, and shows short text, numeric progress, ten-dot progress, and `報酬: 🪙N`. The short completion feedback remains in the existing operation band and is limited to the current brief animation.

## Deferred

- Expanded MAP/TRIP mission catalog, exact economy rebalance, CASINO CHIP, two-tab coin shop, mission detail modal, and Kyoto boss redesign.
- A full new scene asset pass; the current card reuses the existing Cairo mission textures to keep the slice small and responsive at 360x640.

## Worker task

Implement the adopted model, optional save fields, single-card MISSION presentation, normal SLOT reach/reward copy, REST full-HP skill charge, and focused regression tests. Preserve the existing dirty coin UI changes. Do not touch unrelated stage systems.

## Allowed files

- `scripts/game/v06_play_session.gd`
- `scripts/game/v06_session_save_data.gd`
- `scripts/app/v06_play_screen.gd`
- `scenes/app/V06PlayScreen.tscn`
- `tests/run_v06_candidate_mission_tests.gd`
- `tests/run_v06_mission_tests.gd`
- `tests/run_v06_save_tests.gd`
- `tests/run_v06_play_session_tests.gd`
- `tests/run_v06_tile_effect_tests.gd`
- `tests/run_v06_play_screen_tests.gd`

## Verification / stop conditions

- `git diff --check` on all allowed source/test files.
- Godot headless editor parse.
- Focused mission, candidate mission, save, play-session, tile-effect, and play-screen suites.
- No new failure beyond the already known play-screen QA route-score baseline red.
- Stop if another stage model, save schema migration, or scene asset outside this list is required.

