# T008 real-play receipt

## Complete Casino Tours from 300 CHIP

The final recorder now opens every facility from the real HUB, performs its real
screen actions through Buttons, waits for the authored result presentation, checks
BET/RETURN/NET or equivalent accounting, carries the resulting balance forward,
returns to HUB, and releases the facility scene.

- 360x800 GPU tour: 71 assertions, 0 failures.
- 720x1280 GPU tour: 73 assertions, 0 failures.
- 360x800 GPU tour with audio enabled: 89 assertions, 0 failures.
- Final 360x800 audio-enabled visual rerun: 89 assertions, 0 failures.
- Headless deterministic tour: 50 assertions, 0 failures.

The audio-enabled run also verifies every facility selects its dedicated BGM,
keeps UI SFX on the Las Vegas stage pack, and restores `lasvegas_main` after each
teardown. All runs start from an isolated 300-CHIP fixture. The production save
SHA-256 remains `1682990277a6b6c98042dbbfb8eb6766cab48ac36f5e2624193f9d750f9d7e86`.

## Real screen actions per facility

| Facility | Tour actions | Result evidence |
|---|---|---|
| DICE RACE | GAME START, spin, stop | WIN, rank, BET/RETURN/NET, retry/change/return |
| DICE TOWER | GAME START, roll forced to deterministic 1 | BUST, RETURN 0, negative net, retry |
| DICE ROULETTE | amount, HIGH area, SPIN | WHERE, BOOST, BET/return/net, three next actions |
| TREASURE 21 | GAME START, deterministic real rolls to GOLDEN 19 | return/net and three next actions |
| DICE POKER | GAME START, five HOLD actions, lock hand | hand name, WIN, BET/return/net, retry |
| VAULT BREAK | GAME START, three real rolls and three lock choices | unlock result, BET/return/net, next vault |

Three separate real-GPU tours each execute one complete round per facility, so
every facility has at least three full screen-operated rounds. The rich Phase 5A-F
recorders were also rerun at 360x800 and add the representative edge moments:
Race overtake/drop/PHOTO FINISH; Tower floor 5/BUST/10F; Roulette normal/special
WHERE/high BOOST/win/loss; Treasure safe 17/ONE AWAY/21/cash-out/bust; Poker
HOLD/unhold/reroll/full-house/no-hand; Vault placement/discard/remaining-one/
ACCESS DENIED/bronze success/black success.

## Timing and motion evidence

- Roulette stage logs measure final CTA unlock at roughly 2.2-2.6 seconds, with
  separate land, WHERE, BOOST, outcome, CHIP, and CTA beats.
- Race runtime traces cover input lock, movement completion, PHOTO FINISH, result
  lock/unlock, and queue-free during presentation.
- Poker traces cover initial lock, HOLD/unhold, reroll suspense, ordered result
  stages, and teardown during intermediate/result CHIP animation.
- Treasure traces cover total readability, ONE AWAY emphasis, result readability,
  CHIP count, CTA unlock, and teardown.
- Authored emphasis scales observed in scoped sources range from restrained
  1.02-1.14 UI pulses to 1.22 markers and 1.25 transient Race effect sprites;
  screenshots show no clipped fixed CTA at either target resolution.

## Human-first interpretation

Automation proves that the next action is exposed, result accounting is present,
retry/change/return paths work, and English legacy operation CTAs do not block the
flow. Whether a new Japanese player personally prefers one facility, feels fatigue
on the third round, or can recall every rule without reopening help remains a
subjective Android-device smoke-test item and is not fabricated here.
