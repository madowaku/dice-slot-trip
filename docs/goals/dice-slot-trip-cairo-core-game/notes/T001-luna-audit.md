# T001 Luna A-D Audit

## Runtime source of truth

- Cairo currently runs `V06PlayScreen` backed by `V06PlaySession`, `v06_cairo_course.json`, and the v06 save manager.
- The active course is 90 main-route spaces plus two optional 8-space loops, ending at `main:89`; the Sphinx race is 20 spaces.
- `cairo_stage.yaml` and old 58-space references are not the active runtime contract and must not drive PHASE 1 economy decisions.
- `JourneyStageScreen` is active for the newer Amazon/Kyoto journey path. Its coin tool is only an informational modal; this is a later shared-screen follow-up, not the Cairo implementation target.

## A. Current code

- Missions: three simultaneous lap missions (`coin target 12`, `PAIR/STRAIGHT/TRIPLE total 5`, `no damage`), reset each lap and persisted with mission schema 2.
- Slot: three rolls; normal-map rewards are `MIX = COIN +1`, `PAIR = SKILL +1`, `STRAIGHT = SKILL +2`, `TRIPLE = SKILL READY`.
- Skill: gauge max 3; when ready, the player chooses one next die face. It resets with the lap.
- REST: heals 1; purchased REST boost makes the next heal 2; full-HP REST currently awards COIN +1.
- Coin shop: five one-shot flags at prices 2/2/3/4/5. Travel items are RISK guard and REST boost; boss items are shield, head start, and boss stop.
- Boss prep may be bought during normal READY or before the first boss roll. Boss entry clears the travel slot and starts a fresh boss slot.
- `next_lap()` resets position, lap score, coins, items, skill, missions, and route state while preserving cumulative distance/BEST and milestone LIFE behavior.
- Save schema 2 validates stable phases and has primary/backup recovery. Legacy mission schema 1 (6/2 targets) migrates to schema 2 (12/5).

## B. UI/UX

- Cairo's V06 shop is functional but uses one-card paging and abbreviated descriptions (`RISK ×0`, `BOSS ÷2`, `START +3`, `BOSS STOP ×1`), with no category tabs and weak owned/timing language.
- The mission band exposes three small simultaneous objectives. Family players can see values without understanding why they matter or what the reward is.
- Two-roll reach logic exists and uses the shared message band, but the message is transient and assumes players already understand PAIR/STRAIGHT/TRIPLE.
- Mission-plus-slot double progress is not stated when a mission wants the same role.
- Existing 360x640 tests enforce layout/touch contracts but do not prove first-time comprehension.

## C. Economy

- Expected lap length is about 24-27 rolls (practical range 20-30), or 7-10 slot sets.
- Main-route COIN spaces total 13 at +2 each; optional loops add +2 and +3. Full REST, MIX, and full-item conversion add more.
- Estimated gross income is roughly 29-48 TRIP COIN, base case 35-40 before spending.
- Existing shop costs total 16; event choices commonly add 6-10 possible spend, so typical spend is 5-9 and maximum useful spend is about 16-26.
- Random 3d6 role rates: PAIR 41.67%, STRAIGHT 3.70%, TRIPLE 2.78%. Learned stopping can raise role completion substantially.
- If `+1/+3/+5` is added on top of current rewards, skilled play inflates. If it replaces both MIX coin and role skill charge, the random-play increase is small, but skilled-play output can still rise sharply.
- Conservative initial replacement reward is `PAIR +1 / STRAIGHT +2 / TRIPLE +3`, `MIX +0`, with no hidden cap. Revisit after measured family runs.

## D. Regression and tests

- P0: preserve old save loading; keep TRIP COIN and future CASINO CHIP separate; prevent double conversion/reward at boss/lap result.
- P0: preserve boss-result, heart-roulette, lap-result, and game-over phase idempotence.
- P1: separate distance SCORE, slot reward, mission progress, REST result, and shop purchase accounting.
- P1: test insufficient coins, duplicate purchase, invalid phase, boss-first-roll cutoff, and save/restore of active purchases.
- CASINO CHIP must be a new optional persistent field defaulting to 0. Never infer CHIP from coins in an old save.
- The obsolete coin emergency revive remains removed unless separately re-approved; stale documents disagree with runtime/tests.

## Baseline verification

- Godot 4.7 headless editor parse: pass.
- `tests/run_v06_play_session_tests.gd`: failures=0.
- `tests/run_v06_play_screen_tests.gd`: one pre-existing failure at its QA route-score fixture; all coin/slot/UI contracts passed. Treat this known red separately from new regressions.
