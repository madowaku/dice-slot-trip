# T007 baseline receipt

- Actual-rendered Godot capture: 360x800, 53 assertions, 0 failures, `actual_rendering=true`.
- Hub: facility cards show only name + `PLAY`; emotional differentiation exists only lower in the prize-counter list and is not available at the decision point.
- DICE RACE win: status says `80 CHIP獲得` but the screen does not distinguish stake-inclusive return from net change.
- DICE TOWER active: floor, cash-out amount, and one-roll loss are already legible. BUST overlay clearly shows `65 CHIP → 0 CHIP` and `BET結果 -20 CHIP`; success needs equivalent treatment using the same overlay.
- TREASURE 21 setup: payout copy is stale (`x0.6/x1.0/x1.2/x2.0`, golden `x1.5/x1.7/x2.0`) relative to Phase A.
- VAULT active: valid multiple destinations can occur, but the current central prompt only says to place the die; a short choice hint is appropriate. Result needs stake-inclusive return and net change.
- DICE POKER first-roll-only RTP 37.60% is a deliberately non-participating behavior, not a representative beginner policy: the visible flow presents KEEP and two REROLL opportunities. Use a simple visible-rule heuristic (keep any pair/triple/quad; otherwise pursue the longest straight; always consume rerolls) for the beginner cross-facility report, while retaining first-roll-only as a documented lower bound.

Accepted bounded UX set: Hub emotional subtitle; RACE return/net; TOWER success overlay; current TREASURE payout copy; VAULT choice hint and return/net; replay vs setup-return wording. No Roulette/Poker source changes.
