# T004 Worker receipt

## Finding addressed

The first Judge review correctly identified that the shared `_award_role_score()` path was also called by boss resolution. Without a phase/intent guard, boss PAIR/STRAIGHT/TRIPLE roles could award normal-map TRIP COIN and advance a selected normal mission.

## Change

- Boss resolution calls `_award_role_score(boss_role, false)`.
- `_award_role_score()` always records role statistics, but only the normal-slot path advances the selected role mission and applies PAIR +1, STRAIGHT +3, or TRIPLE +5 TRIP COIN.
- A deterministic boss regression test proves a high-roll boss victory records TRIPLE statistics while wallet and selected coin-mission progress remain unchanged.
- The coin-economy cashout fixture again asserts no hidden boss cashout and no boss normal-role coin.

## Verification

- Godot 4.7 headless editor parse: pass.
- `run_v06_play_session_tests.gd`: failures=0.
- `run_v06_mission_tests.gd`: failures=0.
- `run_v06_coin_economy_tests.gd`: failures=0.
