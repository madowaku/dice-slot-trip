# T003 Worker implementation receipt

## Implemented

- New Cairo laps select one mission from the bounded face, TRIP COIN, target-role, and no-damage pool.
- The selected mission persists through optional nested schema2 fields; old schema2 saves restore in legacy mode and receive no retroactive reward.
- The featured MISSION card shows its short target text, numeric progress, ten-dot progress, and TRIP COIN reward. Role missions expose the exact target role.
- MISSION completion awards TRIP COIN once and emits a short clear message. Damage failure remains latched for the no-damage mission.
- Normal SLOT roles award PAIR +1, STRAIGHT +3, and TRIPLE +5 TRIP COIN. MIX remains no-reward. Full-HP REST charges SKILL +1; wounded REST heals.
- Normal two-roll reach copy shows a compact target/reward cue, a best STRAIGHT target with one PAIR insurance line, and double-chance copy for both primary and insurance MISSION matches.
- Cairo onboarding/skill copy and the existing coin utility copy now describe the new TRIP COIN/SKILL behavior.

## Deferred by T002

- Expanded MAP/TRIP mission catalog and economy rebalance.
- CASINO CHIP cashout and Kyoto redesign.
- Mission detail modal, new scene art pass, and broad layout restructuring.

## Verification

- Godot 4.7 headless editor parse: pass.
- Candidate mission, mission/save migration, save, play-session, tile-effect, coin-economy, boss battle, and boss play-screen suites: failures=0.
- Play-screen suite: all new MISSION/SLOT/coin assertions pass; one pre-existing QA route-score baseline failure remains:
  `QA route scores exactly its seventeen travelled spaces while coin stays separate`.
- `git diff --check`: pass; only Git's LF/CRLF normalization warnings were emitted.
