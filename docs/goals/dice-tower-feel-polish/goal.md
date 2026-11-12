# DICE TOWER FEEL POLISH

## Current tranche

Polish the DICE TOWER presentation until one roll feels immediately responsive,
readable, and rewarding on a Japanese-first mobile screen. This tranche covers
presentation, sound, tactility, and timing only. The resulting feel grammar can
later be ported to VAULT BREAK and DICE ROULETTE, but those facilities are out
of scope here.

## Non-negotiable constraints

- Do not change tower rules, probability, BET amounts, payouts, BUST condition,
  CasinoBank transactions, economy, save data, or route behavior.
- Keep the existing deterministic pending-roll/resume flow intact.
- Keep the existing Japanese CTA labels and shared three-step setup guidance.
- Preserve readable touch targets and the 360x800 / 720x1280 layouts.
- Keep feedback bounded: a normal roll should resolve in about 1.3 seconds,
  with no skip requirement and no intrusive BGM tempo changes.
- Do not edit VAULT BREAK or DICE ROULETTE in this tranche.

## Feel acceptance

- ROLL gives an immediate press response, weak haptic on mobile, and a clear
  dice-roll sound before the die animation.
- The visual land and sound land together; success makes the floor increase,
  payout increase, and next-roll/cash-out choice legible.
- Higher floors feel subtly tenser without changing odds or BGM tempo.
- CASH OUT reads as a deliberate decision and visibly counts the awarded CHIP.
- BUST is understandable at once: short stillness, BUST emphasis, tower/UI
  drop, payout candidate cleared, and NET shown.
- FLOOR 10 is happier than an ordinary cash-out with a dedicated completion
  fanfare and tower-top emphasis.
- No economy/state regression; deterministic tests still prove the same model
  outcomes and persistence.
- Real rendered QA passes at 360x800 and 720x1280.
- Final human-feel question: even when unnecessary, would a player want to
  press ROLL once more?

## Verification commands

- `& 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --debug --ignore-error-breaks --path . --editor --quit`
- `& 'C:\Dev\Tools\Godot-4.7-stable\Godot_v4.7-stable_win64_console.exe' --headless --path . --script tests/record_dice_tower.gd`
- Existing DICE TOWER model/UI suites and a two-resolution rendered recorder.
- `git diff --check`
