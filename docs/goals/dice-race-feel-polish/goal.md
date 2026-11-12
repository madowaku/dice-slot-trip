# Phase 5F: DICE RACE FEEL POLISH

## Objective

Make DICE RACE feel like a readable, exciting race: the bet racer stays
visible, ROLL naturally hands off to dice → movement → ranking, overtakes and
the final stretch read at a glance, PHOTO FINISH feels like an announcement,
and the result explains rank before WIN/LOSS, BET/RETURN/NET, CHIP, and the
next CTA. This tranche is presentation-only and must be verified with
deterministic 360x800 and 720x1280 evidence.

## Goal Kind

`specific`

## Current Tranche

Map the existing Dice Race flow, select one safe presentation slice, implement
it, verify focused and casino regressions, capture both target resolutions, and
complete a final protected-diff audit.

## Non-Negotiable Constraints

- Do not change BET, RNG, payout, racer dice processing, movement amount, roll
  count, goal, ranking, photo-finish rules, tie handling, WIN/LOSS semantics,
  RETURN/NET, CasinoBank, save/persistence, BGM, HUB, routes, racer order, or
  start condition.
- Resolve model state first, then lock input, present the result, and unlock
  only after the presentation. Reject duplicate start, roll, result CTA, and
  back actions.
- Keep the selected/bet racer identifiable without relying on color alone.
- Keep normal ROLL compact (about 1.2–1.5s), final roll slightly more suspenseful,
  PHOTO FINISH compact (about 0.6s), and results short enough for repeat play.
- Stage results as rank → WIN/LOSS → BET/RETURN/NET → CHIP count/delta → CTA.
- Reuse existing generic CasinoFeelFX hooks where applicable; do not change its
  shared API. Race-specific start, movement, overtake, leader, final stretch,
  goal, and PHOTO FINISH feel stays local to Race.
- All tweens, timers, audio, haptics, awaits, and deferred callbacks must stop
  safely when the scene exits. Preserve 360x800 readability and verify 720x1280.

## Stop Rule

Stop when the final Judge accepts the scoped implementation and evidence, all
safe local verification passes, or continuing requires owner input, new
authority, files outside the bounded worker scope, or a gameplay/economy
decision the board cannot make.

## Canonical Board

Machine truth lives at:

`docs/goals/dice-race-feel-polish/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-race-feel-polish/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## Acceptance

- A first-time Japanese player can identify the bet racer, understand the
  ROLL → movement handoff, see why a racer gained/lost position, understand
  PHOTO FINISH, and read rank, WIN/LOSS, BET/RETURN/NET, CHIP, and the three
  result CTAs without reopening help.
- Start and every roll are visibly staged without duplicate input; the final
  stretch and goal have a little more tension while normal turns stay quick.
- PHOTO FINISH is a compact visible overlay rather than a blank wait state.
- Deterministic fixtures cover normal progress, 3rd→2nd overtake, 2nd→1st
  leader change, 1st→2nd drop, goal, PHOTO FINISH, LOSS, extra ROLL, and exit
  during presentation.
- Focused Race tests, editor parse, casino regressions, protected diff, real
  360x800/720x1280 renders, teardown probes, and process cleanup pass.
