# T014 — Boss / Lap / Production Asset Contract

## Decision

- 新規 pure `V06BossBattle` が boss 用 `V06RollSet` を1個だけ所有する。
- `V06PlaySession` が travel → boss → lap result → next lap / run over と、player HP、clock、in-memory PB を統括する。
- 旧 `BossSystem` は交流ゲージ方式なのでHP戦闘ロジックへ流用しない。
- 通常時はBのdaylight atlas、局所移動はA、広いC lightingはboss到達後だけ有効にする。
- 最初に explorer-cat seed 候補を1枚だけ生成する。ownerがpathとSHA-256を承認するまでstrip生成は禁止する。待機中もpure boss modelと非cat環境packは進められる。

## Minimal Boss / Lap Rules

### State

- Player HP: `3/3` at run start.
- Boss HP: `3/3` each lap.
- Lap: `1` at run start.
- One boss round: exactly one die, three rolls, fresh blank boss slots.
- Gate arrival on travel slot 1/2/3 always finishes the T012 travel-result contract first, then boss starts from `[_][_][_]`; travel faces never shorten a boss round.

### Resolution

- Attack is the sum of the three boss-round faces.
- Base deterministic boss actions / defense:
  1. `SAND_GAZE`, DEF 9
  2. `STONE_WARD`, DEF 11
  3. `SOLAR_SEAL`, DEF 13
  4. repeat the three-action cycle
- Next defense is visible before all three rolls.
- `attack >= DEF`: boss takes 1 damage. Tie succeeds.
- `attack < DEF`: player takes 1 damage.
- No simultaneous base damage.
- `PAIR`: if the comparison fails, GUARD reduces player damage to 0 for that round; a successful comparison still deals the normal 1 boss damage.
- `TRIPLE`: ignores defense and deals 2 boss damage. Clamp at HP 0 and report applied damage separately.
- No STRAIGHT, coins, items, character abilities, bonus dice, or carried shield in this tranche.
- Every third roll shows a round result once; acknowledgment is required before the next round/victory/loss state. Duplicate acknowledgment and a fourth roll are rejected.

### Outcome / Next Lap

- Boss HP 0: victory and lap result.
- Player HP 0: run over.
- Victory acknowledgment increments lap, resets course/boss/round/travel slots/boss slots, and preserves player HP plus in-memory PB.
- Player HP is not healed automatically between laps; the run ends only at HP 0.
- Enhanced boss occurs when `lap % 10 == 0` (10, 20, ...). Boss HP remains 3; all defense values gain +2 → `[11, 13, 15]`.

### Time / PB

- Caller injects monotonic `now_ms`; pure battle never reads system time.
- Timer starts on the first accepted travel roll. Boss-direct QA may start at `enter_boss(now_ms)`.
- Route choice, movement, and boss combat count. Pause/resume duration is excluded. Reversed time is rejected.
- Timer stops when victory or defeat damage is committed.
- PB updates only on victory and only when unset or strictly faster; ties do not update. No save write yet.
- HUD shows readable `TIME mm:ss.d` and `PB -- / ±x.xs` separately; refresh at no more than 10 Hz.

## Deterministic Acceptance Cases

- `[2,3,4]`: sum 9 vs DEF 9 → boss 3→2.
- `[2,2,6]`: sum 10 vs DEF 11 with PAIR → no damage to either side.
- `[1,1,1]`: TRIPLE → boss 2→0, victory.
- `[1,2,3]` for three rounds: player 3→2→1→0, run over.
- Lap 9 DEF 9; lap 10 DEF 11; lap 20 DEF 11; lap 11 DEF 9.
- Victory → ack → next lap: main:0, blank travel/boss slots, boss 3, player HP carried, timer armed.
- Cover first PB, slower, faster, tie, pause subtraction, double ack, fourth-roll rejection.

## Runtime Boundary

- `V06BossBattle`: boss slots, action/DEF, round resolution, HP changes, victory/defeat. No UI/course/save/clock calls.
- `V06PlaySession`: composes battle and owns travel/boss/lap/run phases. Add `BOSS_ROLL_READY`, `BOSS_ROUND_RESULT`, `LAP_RESULT`, `RUN_OVER`.
- `V06PlayScreen`: same single DieButton and fixed three slots route input to travel or boss, never both. Boss center shows sphinx, player/boss HP, next DEF, comparison/result. Result acknowledgment precedes victory/loss.
- Boss state darkens the atlas and activates gate/night/lantern layers. Daylight travel never inherits broad C lighting.
- `main.gd`, `GameState`, `SaveManager`, save version, legacy BossSystem and BoardModel remain untouched.

## First Production Asset Pack

Raw/QC lives below `.gdignore`; only normalized runtime assets live under `assets/art/v06/**`. Every generated asset records prompt, provenance, pipeline metadata, normalization metadata, preview, and SHA-256.

| Asset | Runtime spec | Notes |
|---|---:|---|
| Explorer cat seed | 192×192 RGBA | feet anchor `(96,179)`; orange/cream cat, brass safari hat, teal scarf, tan backpack |
| Cat idle | 768×192, 4 frames | whole strip, frame-1 lock |
| Cat hop | 1152×192, 6 frames | whole strip, 0.18s, frame-1 lock |
| Cat land | 768×192, 4 frames | whole strip, 0.06s |
| Parchment | 1024×1024 opaque | seamless daylight base |
| Cairo ink | 1024×1024 RGBA | Nile/landmarks only; no route, number, EXIT, or text |
| Raised route tiles | 512×128 RGBA | four 128px cells: main/bypass/loop/current; no text |
| Boss gate | 512×256 RGBA | two 256px states: sleeping/awakened; bottom-center |
| Sleepy sphinx | 512×512 RGBA derivative | retain existing 1254² source; never overwrite it |
| Night vignette | 720×1280 L8 | boss-only mask |
| Lantern glow | 512×256 RGBA | four variants; boss/TRIPLE/enhanced only |

Sprite invariants: approved seed first, action strip generated as one edit, transparent canvas, identical identity/direction/palette/proportions, shared scale, shared bottom-center anchor, optional frame-1 lock, preview and in-engine approval. Never generate frames independently.

Import/budget:

- Painterly alpha/UI sprites: lossless, no mipmaps, alpha-border fix, linear filtering.
- Opaque parchment/ink: 2D-appropriate compression, no mipmaps; validate artifacts at 360×640.
- Normal resident increment ≤14 MiB decoded.
- Boss peak increment ≤16 MiB decoded.
- Runtime PCK delta ≤8 MiB.
- Raw/QC/docs must not enter PCK. Current `export_filter=all_resources` requires a later explicit export inventory/exclusion task.

## Ordered Tasks

1. `T015` Worker — exactly one explorer-cat seed candidate plus in-context previews; no strip/runtime wiring.
2. `T022` PM — owner approves candidate path + SHA-256; rejection creates a replacement candidate task.
3. `T016` Worker — pure boss model and dedicated tests; independent of seed approval.
4. `T017` Worker — boss/lap/time/PB runtime integration; no new raster.
5. `T018` Worker — atlas/boss environment pack; independent of cat approval.
6. `T019` Worker — cat strips; blocked until T022 approval hash.
7. `T020` Worker — production assets wired into runtime.
8. `T021` Judge — repeatable lap, visuals, budgets, and export evidence audit.

## Deferred

Save v11, all tile effects, multiple bosses, character abilities, boss relationship migration, dedicated boss audio/haptics, and Google Play release packaging remain out of this tranche.
