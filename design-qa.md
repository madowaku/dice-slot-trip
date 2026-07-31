# Cairo Sphinx Boss Race v3.2 — Motion Comfort QA

## Evidence

- Full 360×640 race: `docs/reference/v13-boss-race-full.mp4`
- Timeline contact sheet: `docs/reference/v13-boss-race-full-contact-sheet.png`
- Offscreen opponent marker and readable sand penalty:
  `docs/reference/v13-boss-race-offscreen-360x640.png`
- Fixed-scale late-race frame:
  `docs/reference/v13-boss-race-fixed-camera-360x640.png`
- Retuned camera timing race:
  `docs/reference/v14-boss-race-camera-timing.mp4`
- Retuned camera timeline:
  `docs/reference/v14-boss-race-camera-contact-sheet.png`
- Dice, offscreen rival, and FINISHED polish:
  `docs/reference/v15-boss-race-polish.mp4`
- Offscreen Sphinx portrait:
  `docs/reference/v15-boss-race-offscreen-sphinx.png`
- Revised finish hierarchy:
  `docs/reference/v15-boss-race-finish.png`
- Player-anchor regression race:
  `docs/reference/v16-boss-race-player-anchor.mp4`
- Player-anchor timeline:
  `docs/reference/v16-boss-race-player-anchor-contact-sheet.png`
- Stable-intro regression race:
  `docs/reference/v17-boss-race-stable-intro.mp4`
- Stable-intro opening frames:
  `docs/reference/v17-boss-race-stable-intro-contact-sheet.png`

## Motion-comfort audit

1. The former range camera and its dynamic zoom/cell compression are removed.
   Board cells stay on a fixed 78px logical pitch; both lanes keep the same
   width and horizontal coordinates for the entire race.
2. Racer updates and landing previews never move the camera. Dice motion,
   one-cell hops, and wing/quicksand landing effects complete against a still
   board.
3. After a turn has fully resolved, the board holds for 120ms, makes one
   0.42-second `ease_in_out` vertical translation of exactly two spaces, then
   holds for another 120ms before ROLL can return. It does not pan horizontally
   or change the camera magnification.
4. Characters, foot markers, target pictograms, and special-space art keep
   `Vector2.ONE` scale during live race play.
5. A racer beyond the visible board is hidden and replaced at the appropriate
   lane edge by a distance chip such as `SPHINX ↑ 8マス先`.
6. Gate approach uses four precomposed static background phases. A phase
   transition crossfades two stationary plates; no continuous background scale
   or position animation runs during play. The crossfade begins only after the
   board-scroll sequence has fully completed.
7. Quicksand now separates `流砂` from a large white `−2` inside a dark,
   orange-bordered penalty badge. The forecast also uses the full
   `流砂 −2` wording.
8. FINISHED remains a dedicated result state. Camera scale is unchanged until
   it starts, normal race input disappears, and only `次の旅へ` remains
   actionable.
9. Existing concrete coordinates, 20-space course, opposite-face result,
   `翼 +3`, `流砂 −2`, and player-favored exact tie remain unchanged.
10. The live boss die is approximately 18% larger, sits closer to the action
    frame, uses larger near-black pips, and moves upward only for the STOP
    reveal/flip.
11. An offscreen Sphinx distance marker includes a static portrait so the rival
    remains present without adding continuous animation.
12. FINISHED now reads in order: one gate-light pulse, one winner jump, a 46px
    winner callout, then race statistics after a 0.5-second hold.
13. The explorer cat never disappears. During a long hop it is pinned to the
    visible edge of its lane, then the camera repeats fixed two-space segments
    until the cat is restored to the lower player anchor. Only an offscreen
    Sphinx is replaced by a distance marker.
14. Boss entry now uses a fixed-scale reference frame. The panel and board
    fade in without a scale bounce, and the initial racer positions are seeded
    before the first deferred refresh so the intro cannot begin with a phantom
    movement tween.

## 20-space baseline measurement

`tests/run_v06_boss_race_metrics.gd` runs 10,000 deterministic-seed races
against the production course and resolution code. Uniformly selected visible
faces are used as an unbiased baseline; each selected non-six is counted as an
intentional alternative to the maximum-distance face.

- Average turns: 5.074
- Races ending within five turns: 72.7%
- Races lasting seven or eight turns: 1.6%
- Average wing landings: 0.881
- Average quicksand landings: 0.900
- Average non-six selections: 4.237
- Average gap before the final roll: 5.252 spaces

The mean sits just above the proposed five-turn threshold, but the 72.7%
short-race rate supports evaluating a separate 24-space candidate. The
production course remains at 20 spaces in this revision.

## Automated verification

- `tests/run_v06_boss_play_screen_tests.gd`: passed; fixed 78px spacing,
  immutable camera during racer/preview updates, two-space scroll request,
  0.42-second eased motion with 120ms holds, ROLL gating, vertical-only
  translation, upward and downward edge markers, non-overlapping backdrop
  crossfade, intro gating, FINISHED/stale-await guards, and 720×1280 design
  geometry with 360×640 half-scale readability.
- `tests/run_v06_boss_race_metrics.gd`: completed 10,000 production-logic
  samples with a fixed seed and emitted the baseline values above.
- `tests/run_v06_boss_battle_tests.gd`: passed; mirror pairs, two immediate
  effects, effect counters, 20-space goal, tie priority, save restore, and no
  boss SLOT.
- `tests/run_v06_play_session_tests.gd`: passed.
- `tests/run_v06_save_tests.gd`: passed.
- `tests/run_v06_tile_effect_tests.gd`: passed.
- `tests/run_v06_play_screen_tests.gd`: passed.
- `tests/run_tests.gd`: passed, `failures=0`.

## Video route

The deterministic race uses faces `1, 1, 6, 6, 6`. It first sends SPHINX far
ahead, proves the edge marker at YOU 2 / SPHINX 10, shows the enlarged
quicksand penalty, then lets YOU recover and finish. Across the full recording,
cell, racer, and pictogram scale remain fixed; board translation occurs only
after resolved movement.

final result: passed
