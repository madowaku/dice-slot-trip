# Phase 5C: DICE ROULETTE FEEL POLISH

## Objective

Turn the existing DICE ROULETTE result flow into a paced two-stage reveal:
spin and stop, reveal WHERE, hold one beat, reveal BOOST, then show WIN or LOSE
and the CHIP result. The player should want to watch through BOOST rather than
treating the wheel stop as the end.

## Non-negotiable constraints

- Presentation, sound, haptics, display timing, and teardown safety only.
- Do not change WHERE or BOOST resolution, bets, wager amounts, payouts, RTP,
  dice RNG, win/loss, CasinoBank, persistence, BGM, routes, or CHANGE BET.
- Resolve the result with the existing timing/order; presentation follows the
  already-fixed result and may not reroll or settle twice.
- Preserve the terms WHERE and BOOST.
- Normal results should complete in roughly 1.8–2.3 seconds and stay below
  2.5 seconds; special/high-BOOST results may reach 2.5–2.7 seconds.
- Preserve the existing 360x800-first layout and verify 720x1280 too. Add no
  permanent UI that displaces WHERE, BOOST, BET, RETURN, NET, or result CTAs.
- Reuse CasinoFeelFX only for generic press/haptics/result/CHIP behavior; keep
  roulette acceleration, deceleration, slow ticks, WHERE, BOOST, special WHERE,
  and high BOOST local to DICE ROULETTE.
- Stop all tweens, timers, and spin audio safely when the scene exits.

## Acceptance

- SPIN reacts within 100ms and cannot update the round twice during animation.
- The wheel visibly accelerates, cruises, decelerates, lingers, and lands on the
  already-resolved result with a short dry stop cue and light haptic.
- The order is always stop -> quiet recognition beat -> WHERE -> beat -> BOOST
  -> WIN/LOSE -> BET/RETURN/NET -> CHIP change -> CTA unlock.
- Special WHERE and high BOOST are distinguishable without implying a win.
- WIN gives clear stake-inclusive return/net and CHIP reward feedback; LOSE is
  shorter, restrained, and equally clear.
- Result CTA and exit paths are guarded against duplicate handling.
- Queue-free is safe during acceleration, cruise, deceleration, WHERE, BOOST,
  and CHIP count; no roulette audio or Godot QA process remains afterward.
- Roulette model/UI plus Casino foundation, Casino, Casino UI, Casino expansion
  UI, DICE TOWER shared-feel, and VAULT BREAK regressions pass.
- Real-render QA at 360x800 and 720x1280 covers spin start, cruise, slowdown,
  normal/special WHERE, normal/high BOOST, WIN, LOSE, and CHIP result.
