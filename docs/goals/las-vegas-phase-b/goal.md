# Las Vegas Phase B — Economy And Six-Game UX

## Objective

Raise the six Las Vegas casino games from economically safe to clearly differentiated, easy-to-read experiences, beginning with removal of the remaining DICE TOWER positive-EV bet.

## Goal Kind

`audit`

## Current Tranche

Reproduce and fix DICE TOWER's 10 CHIP RTP issue, audit all six facilities with current-run visual evidence, implement P1 and small P2 improvements only, re-simulate the 300 CHIP experience, run the Phase A regression set plus new coverage, and publish a Phase B re-audit.

## Non-Negotiable Constraints

- Preserve Phase A transaction, save/load, pending-result, and exactly-once settlement guarantees.
- Do not touch or commit unrelated user-owned APK, import, audio, export, or other-city changes.
- Do not add games, meta-progression, or forced rotation rewards.
- Prefer payout and timing/copy/layout changes over rule changes or large redesigns.
- Capture and inspect current-run 360×800 evidence before making UX audit claims.
- Implement P1 and small P2 only; leave large work as recommendations.
- Do not reduce the Phase A baseline of 1,247 assertions / 0 failures.

## Stop Rule

Stop when the tranche audit passes, all safe local work is blocked, or continuing would require owner input, credentials, destructive operations, or strategy the board cannot decide.

Do not stop after planning, discovery, or task selection while a safe implementation task remains.

## Canonical Board

Machine truth lives at:

`docs/goals/las-vegas-phase-b/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins.

## Run Command

```text
/goal Follow docs/goals/las-vegas-phase-b/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

1. Read this charter and `state.yaml`.
2. Work only on the active task.
3. Record a compact receipt before selecting the next task.
4. Keep at most one write-capable task active.
5. Finish only with a Judge/PM audit receipt mapped to the requested Phase B outcomes.
