# T019 Visual QA — 90-map / LIFE UI

## Evidence

- ImageGen source: `artifacts/90-map-life-ui-qa/source-imagegen-original.png`
  - Native size: 941x1672
  - SHA-256: `7DC7E986D7A858D397795C37F96294B101D7B9BE054C595EACFD33D6594D209A`
- Recovery implementation: `artifacts/90-map-life-ui-qa/roulette_pending-944x1664.png`
  - Native size: 944x1664
- Full/focused comparison: `artifacts/90-map-life-ui-qa/roulette-source-vs-implementation.png`
- Selector correction comparison: `artifacts/90-map-life-ui-qa/skill-selector-before-after.png`
- Corrected selector native capture: `artifacts/90-map-life-ui-qa/skill_selector-720x1280.png`

Montages resize copies only for alignment. Every matrix image below was inspected at its native PNG dimensions.

## Native state matrix

| State | Native evidence | Result |
| --- | --- | --- |
| Normal compact | `smoke-normal-720x1280.png` (720x1280) | Clear map/HUD/control hierarchy; no overlap |
| Normal tall | `normal-720x1600.png` (720x1600) | Added height benefits the map; controls remain anchored |
| Normal narrow | `normal-360x640.png` (360x640) | Copy and controls remain readable at half scale |
| Revival | `revival-720x1280.png` (720x1280) | Stable HP3/LIFE2 snapshot drives matching HUD `復活 ×2` and production stamp `復活！ / 復活 ×2 / HP FULL` |
| LIFE gained | `lap_gain-720x1280.png` (720x1280) | `10 LAP BONUS / 復活 +1` is distinct and compact |
| LIFE full | `lap_full-720x1280.png` (720x1280) | `10 LAP達成 / 復活 FULL`; no extra reward affordance |
| EVENT | `event-720x1280.png` (720x1280) | Paid coin CTA and free journey CTA are both clear |
| Skill discovery | `skill_discovery-720x1280.png` (720x1280) | Focused first-READY explanation and one obvious CTA |
| Skill selector | `skill_selector-720x1280.png` (720x1280) | 3x2 faces and unobstructed close CTA; no operation-copy bleed |
| Recovery pending | `roulette_pending-944x1664.png` (944x1664) | Wheel, helper, selected marker, and STOP hierarchy readable |
| Recovery result | `roulette_result-944x1664.png` (944x1664) | Chosen result remains visible with Next Journey available |
| PERFECT | `perfect-944x1664.png` (944x1664) | `PERFECT! / HP FULL`; no recovery wheel |

## Design QA findings

- Typography and hierarchy: primary state headings, numeric LIFE/HP values, CTA copy, and secondary helpers have distinct tiers. Japanese labels remain readable in compact and narrow captures.
- Layout and playfield: the fixed HUD and stamps do not take additional map height. Overlays stay within the viewport, preserve safe margins, and keep their primary CTA visible.
- Colors: Egyptian gold, teal, parchment, and dark backdrops consistently separate interactive, informational, and disabled states with adequate visual contrast.
- Assets: the explorer-cat LIFE icon, coin stack, skill pinpoint, wheel, and sparkle treatments reuse the approved existing assets. No new raster asset was introduced.
- Copy: LIFE reads as `復活 ×N`, separate from heart HP. Milestone, EVENT, skill, recovery, and PERFECT copy matches the frozen product contract. Obsolete coin revival and `HEART CHANCE!` copy are absent from implementation.
- Overlap/readability: all twelve states are free of production-level overlap or clipping. The corrected skill selector reserves the modal surface for its own content; both operation-message nodes remain hidden until close.
- Selector interaction: six 96px-class face targets form a clear 3x2 grid. The explicit close button is inside the panel, focusable, and unobstructed; closing restores the READY operation message and gameplay input.
- Roulette: clockwise outcomes are exactly `[+1, +2, +1, FULL, +1, +2]`, including triangular +1 placement. STOP is the dominant action and remains separated from the wheel and summary.
- Result retention: the selected recovery result remains highlighted after STOP while the onward CTA remains available.
- PERFECT/defeat: HP3 victory shows `PERFECT! / HP FULL` without a wheel. Defeat does not show recovery or PERFECT UI.
- Source comparison: the implementation preserves the reference's gold/teal circular recovery focus and large STOP hierarchy while replacing the source's stale `HEART CHANCE!` layer with the compact approved `HP RECOVERY` presentation.

## Iteration history

1. T018's headless same-state capture timed out, so no trustworthy visual comparison was available.
2. T022 produced exact native Windows/OpenGL captures and exposed operation-message text overlapping the skill selector close CTA.
3. T024 suppressed only MessageBand/MessageLabel while UtilityOverlay is open, added regression coverage, and recaptured the selector at native 720x1280. The before/after montage confirms the overlap is removed and the close CTA is clear.

## Verification

- `run_v06_play_screen_tests.gd`: pass, failures=0
- `run_v06_play_session_tests.gd`: pass, failures=0
- `run_v06_save_tests.gd`: pass, failures=0
- `run_v06_boss_play_screen_tests.gd`: pass, failures=0
- `run_v06_feedback_tests.gd`: pass, failures=0
- `run_tall_phone_layout_tests.gd`: pass, failures=0
- `run_tests.gd`: pass, failures=0
- Windows/OpenGL selector recapture: pass, native 720x1280
- Windows/OpenGL coherent revival recapture: pass, native 720x1280; HUD and stamp both derive from restored LIFE2
- All twelve native visual states and both comparison montages: inspected, pass

final result: passed
