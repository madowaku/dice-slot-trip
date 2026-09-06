# Phase 5E: DICE POKER FEEL POLISH

## Objective

Make DICE POKER feel like a deliberate five-dice hand-building game: the
first roll lands clearly, HOLD decisions read immediately, rerolls preserve
held dice, and the final hand resolves in a staged result story. This tranche
is presentation-only and must be verified with deterministic 360x800 and
720x1280 evidence.

## Goal Kind

`specific`

## Current Tranche

Map the existing Poker flow, select one safe presentation slice, implement it,
verify the focused and casino regression suites, capture both target
resolutions, and complete a final protected-diff audit.

## Non-Negotiable Constraints

- Do not change dice RNG, five-dice rules, reroll count, hold conditions, hand
  determination, pay table, BET, payout, RTP, CasinoBank, save/persistence,
  BGM, HUB route, GAME START, or restart semantics.
- Resolve the model result first, then lock input, present the result, and only
  unlock the next action after presentation. No duplicate settlement or CTA
  handling.
- HOLD has priority over win language; held dice stay visually still during a
  reroll. Directly tapping the die card must toggle HOLD.
- Keep the first roll around 1.2–1.5s, normal reroll around 1.0–1.3s, final
  result around 1.0s (high hand up to about 1.7s), and keep no extra game
  flow over 10s.
- Stage the final order as dice stop → hand name → multiplier → WIN/LOSE →
  BET/RETURN/NET → CHIP delta/count → next CTA. NO HAND/LOSE stays restrained.
- Reuse CasinoFeelFX for generic press, dice, result, CHIP, and haptics; keep
  Poker-specific HOLD, reroll-target, hand-tier, and no-hand feel local.
- All tweens, timers, audio, haptics, and deferred callbacks must stop safely
  when the scene exits. Preserve 360x800 readability and verify 720x1280.

## Stop Rule

Stop when the final Judge accepts the scoped implementation and evidence, all
safe local verification passes, or continuing requires owner input, new
authority, files outside the bounded worker scope, or a gameplay/economy
decision the board cannot make.

## Canonical Board

Machine truth lives at:

`docs/goals/dice-poker-feel-polish/state.yaml`

## Run Command

```text
/goal Follow docs/goals/dice-poker-feel-polish/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## Acceptance

- A first-time Japanese player can understand GAME START, the next action,
  HOLD → REROLL intent, the hand reason, BET/RETURN/NET, PLAY AGAIN, and
  カジノへ戻る without reopening help.
- Five dice never overlap at 360x800; HOLD emphasis is limited to a readable
  4–6px lift/scale and does not displace the action CTAs.
- Deterministic fixtures cover HOLD, unhold/rehold, pair→three, final reroll,
  full house/high tier, NO HAND, and four-held/one-reroll cases.
- Focused Poker tests, editor parse, casino regressions, protected diff, real
  360x800/720x1280 renders, and process cleanup all pass.
