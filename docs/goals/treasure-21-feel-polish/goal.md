# Phase 5D: TREASURE 21 FEEL POLISH

## Objective

Make the fixed TREASURE 21 flow feel like a rising approach to 21: TOTAL grows,
the chest advances one stage at a time, SAFE and ONE AWAY become legible
milestones, and TREASURE / CASH OUT / BUST resolve with a clear reward or loss
story. Complete the first safe, presentation-only implementation tranche and
audit it with deterministic 360x800 and 720x1280 evidence.

## Non-negotiable constraints

- Presentation, sound, haptics, display timing, input locking, and teardown only.
- Do not change dice RNG, TOTAL calculation, SAFE/ONE AWAY/TREASURE/BUST rules,
  cash-out conditions, BET, payout, RTP, RETURN/NET, CasinoBank, save data, BGM,
  HUB routes, restart semantics, or existing 17–21/chest-stage logic.
- Resolve gameplay first, then lock input, present the resolved result, and only
  unlock the next action after presentation; never settle twice.
- Preserve the existing six-outcome preview and update it only after the new
  TOTAL is confirmed; no permanent layout displacement at 360x800.
- Reuse CasinoFeelFX for generic press, dice, chip, haptic, result, and cancel
  behavior while keeping Treasure-specific TOTAL/chest/status/open/bust feel
  local to TREASURE 21.
- Keep normal ROLL near 1.2–1.5s, TREASURE near 2s, CASH OUT 0.5–0.9s, and BUST
  shorter and restrained; cap chest emphasis around scale 1.04–1.08.
- Every tween, timer, audio cue, and deferred callback must stop safely on exit.

## Acceptance

- The player can follow die result → TOTAL → current track → chest stage → status
  without rereading the help text.
- TOTAL is the visual protagonist; 17/18/19/20/21 advance with current-position
  emphasis only, while <17 stays restrained.
- First SAFE gets a small pop and chest step; 18/19 make the current RETURN and
  the neutral ROLL vs CASH OUT choice clear; ONE AWAY adds tension without
  promising the next roll; TREASURE opens lightly (パカッ → キラキラ → 金貨).
- CASH OUT reads as taking the treasure home, then shows RETURN/NET before CHIP
  balance/count; BUST shows TOTAL >21 before the restrained chest sink and
  RETURN 0 / NET result.
- ROLL, CASH OUT, PLAY AGAIN, CHANGE BET, and exit are idempotent during every
  presentation phase; CasinoBank settlement remains exactly once.
- Deterministic tests and stage-aware real renders cover normal, SAFE, 18/19,
  ONE AWAY, TREASURE, CASH OUT, BUST, preview refresh, repeated games, and
  mid-animation exit at 360x800 and 720x1280.
- Treasure/model/UI, Casino foundation/Casino/Casino UI/Expansion UI,
  CasinoFeelFX, DICE TOWER, VAULT BREAK, and DICE ROULETTE regressions pass;
  Godot parses cleanly, temporary QA processes/files are cleaned, and protected
  gameplay/economy/persistence/BGM/scene/route files show no diff.
