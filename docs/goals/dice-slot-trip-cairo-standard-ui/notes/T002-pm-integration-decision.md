# T002 PM integration decision

## Adopted first 12 mission rows

The first Cairo set is fixed to the 12 rows explicitly prioritized in the user specification. Stable IDs are new and must not replace the existing legacy IDs `cairo_face`, `cairo_coin15`, `cairo_role`, `cairo_no_damage`, or `cairo_triple2`.

| difficulty | id | kind | target contract | reward |
| --- | --- | --- | --- | ---: |
| EASY | `cairo_face6` | DICE | one seeded face, 6 hits | 8 |
| EASY | `cairo_pair4` | SLOT | PAIR, 4 times | 8 |
| EASY | `cairo_coin3` | MAP | COIN tile, 3 landings | 8 |
| EASY | `cairo_item2` | TRIP | obtain ITEM, 2 times | 8 |
| NORMAL | `cairo_face10` | DICE | one seeded face, 10 hits | 12 |
| NORMAL | `cairo_straight4` | SLOT | STRAIGHT, 4 times | 12 |
| NORMAL | `cairo_risk4` | MAP | RISK tile, 4 landings | 12 |
| NORMAL | `cairo_coin5` | MAP | COIN tile, 5 landings | 12 |
| NORMAL | `cairo_hp_full_boss` | TRIP | arrive at boss gate with full HP | 12 |
| NORMAL | `cairo_small_faces` | DICE | faces 1, 2, and 3 each 4 times (12 weighted hits) | 12 |
| HARD | `cairo_triple3` | SLOT | TRIPLE, 3 times | 18 |
| HARD | `cairo_risk6_survive` | MAP | RISK tile, 6 landings, then survive the lap | 18 |

The face-bearing rows persist `target_face`; the three-face row persists per-face counters; the survival row has an explicit failed/active state. Progress is capped and completion/reward remains exactly once.

## Selection and compatibility

Use the requested difficulty weights by lap bucket:

- laps 1–2: EASY 70 / NORMAL 30 / HARD 0
- laps 3–5: EASY 35 / NORMAL 55 / HARD 10
- laps 6+: EASY 20 / NORMAL 60 / HARD 20

Select a difficulty from a deterministic 0–99 draw derived from the persisted selection seed and lap, then select a row inside that difficulty bucket from a second deterministic draw. Persist the selected row and all parameters; loading must never reroll. Keep outer save schema 2 and nested mission schema 2. A legacy schema-2 save without `active_id` remains legacy for its current lap and only enters the new one-mission selection on `next_lap()`; it receives no retroactive reward or event replay.

The 90-main-tile course in `data/stages/v06_cairo_course.json` is authoritative for the integrated runtime. The older 58-tile `cairo_stage.yaml` and v0.8 document are not runtime sources and should be treated as legacy documentation conflicts.

## Candidate presentation contract

The first candidate resolver is pure and returns structured candidate rows before rendering. It accepts the two committed SLOT faces, active mission metadata, and (when available) a MAP landing candidate. It never mutates session state and never recommends one option during a conflict.

Precedence:

1. MISSION + SLOT + MAP all match: one special `ALL MATCH`/`TRIPLE CHANCE` row.
2. MISSION + SLOT match: one double-chance row.
3. MISSION + MAP match: one double-chance row.
4. SLOT + MAP match: one combined row.
5. Otherwise show up to two neutral value-bearing candidates; preserve both sides of a real trade-off.
6. SLOT-only, then MISSION-only, only when there is no competing value-bearing row.
7. No meaningful candidate: return no rows and leave the guidance band quiet.

Rendering is capped at two lines. Examples are contracts, not hard-coded recommendation text:

```text
🎰 6 → STRAIGHT 🪙3
🎯 5 → MISSION + PAIR 🪙1
```

Do not emit `おすすめ`, `best`, or an equivalent. A matching mission face may use the stronger double-chance treatment; a competition remains neutral.

## First Worker slice

The first Worker should implement only the data/logic slice and its regression tests:

- canonical 12-row catalog, difficulty/reward metadata, seeded parameters, and lap-bucket selection;
- compatible schema-2 save/restore for the selected row and legacy fallback;
- generalized event hooks for the selected row where the existing session already has authoritative events (face, normal SLOT role, COIN/RISK landing, ITEM acquisition, and terminal full-HP boss check);
- a pure structured SLOT/MISSION candidate resolver with the two-line/no-recommendation contract, keeping the existing screen geometry and MessageBand reparenting unchanged;
- focused tests for catalog counts/rewards, weighted boundary determinism, save round-trip/no-reroll, candidate precedence, and known play-screen baseline.

Defer the full six-distance MAP preview and coordinate redesign to a later Worker. The MAP preview must use `V06CourseModel.advance()` rather than Atlas visual successors, and must be separately tested for branches, warps, loops, and boss termination before it drives the live guidance band.

## Proposed Worker ownership / verification

Proposed code ownership for Judge approval:

- `scripts/game/v06_play_session.gd`
- `scripts/game/v06_session_save_data.gd`
- `scripts/app/v06_play_screen.gd`
- `tests/run_v06_mission_tests.gd`
- `tests/run_v06_candidate_mission_tests.gd`
- `tests/run_v06_save_tests.gd`
- `tests/run_v06_play_screen_tests.gd`

Verification should include the focused V06 mission/candidate/save/play-screen tests, the existing boss/tile/economy tests, headless parse, and `git diff --check`. The one documented play-screen baseline failure remains a known exception unless its output changes.
