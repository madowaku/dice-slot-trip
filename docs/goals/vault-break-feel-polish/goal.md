# VAULT BREAK FEEL POLISH

## Current tranche

Polish VAULT BREAK so each roll, discard, lock advance, final-roll decision,
success, and access-denied result feels like operating a precise luxury vault.
Reuse the bounded shared CasinoFeelFX foundation from DICE TOWER while keeping
vault-specific lock and door cues local to VAULT BREAK.

## Non-negotiable constraints

- Presentation, sound, haptics, and display timing only.
- Do not change BET, payouts, success/failure conditions, five-roll rules,
  discard behavior, tier unlocks, templates, CasinoBank, saves, BGM, routes,
  RTP, or probability.
- Commit model state immediately; presentation may follow without delaying or
  duplicating settlement.
- Preserve pending-roll/resume and screen-destruction safety.
- Prefer existing door art, dice WAVs, and semantic UI SFX. External audio is
  optional and must not be copied without license-aware admission.
- Preserve Japanese-first readability and touch targets at 360x800 and
  720x1280. Do not add persistent UI that crowds the layout.
- Keep normal roll interaction bounded near 1.1-1.3 seconds and avoid flashes,
  large shakes, repeated haptics, or long failure sequences.

## Acceptance

- ROLL responds immediately, plays shared roll/land audio, and locks duplicate
  input without changing canonical state timing.
- DISCARD selection and confirmation feel mechanical and remain unambiguous.
- Newly satisfied locks advance sequentially with restrained click feedback.
- Remaining rolls become more noticeable at two and clearly communicate the
  final roll at one, without changing BGM.
- SUCCESS visibly opens the existing vault door, emphasizes the reward, and
  counts CHIP/balance with a medium result haptic.
- ACCESS DENIED shows a short resisted-door motion, heavy rejection cue, and
  clear BET / RETURN / NET information without overstaying.
- Tier presentation differs subtly while game contents remain identical.
- VAULT model/UI, Casino foundation, CasinoFeelFX/DICE TOWER regressions pass.
- Real rendered QA covers active, last-roll, success, and denied states at
  360x800 and 720x1280.
- Final qualitative outcome: the player wants to hear one more lock click and
  see the vault open.
