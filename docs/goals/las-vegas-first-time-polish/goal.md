# Las Vegas First-Time Polish

## Outcome

Make the six active Las Vegas casino facilities understandable to a first-time Japanese player without relying on English action labels or repeated help lookup.

## Ordered phases

1. Phase 1.5: remove PRIZE COUNTER from the Hub surface while retaining its data and purchase code for a future separate screen; keep the complete Hub usable without scrolling at 360x800.
2. Phase 2: localize primary and result CTAs by describing what happens when pressed, while retaining established game-specific terms such as WHERE and BOOST where useful.
3. Phase 3: introduce one shared `CasinoHowTo3Steps` UI structure and give all six facilities concise per-game step data.
4. Phase 4: run new-player-equivalent QA near 300 CHIP and judge whether each game can be played after reading help once without reopening it.

## Non-negotiable constraints

- Preserve game rules, RTP, CasinoBank transaction semantics, save compatibility, routes, and the active six-facility order.
- Keep HIGH LOW retired from the Hub.
- Keep prize-card data and mechanics dormant; do not delete them.
- Use large Japanese text, touch-safe controls, visible focus states, and real-render verification at 360x800 and 720x1280.
- Preserve unrelated dirty-worktree changes.

## Completion

The tranche is complete only after all four ordered phases have implementation receipts, focused regression coverage, real-render evidence, and a final Judge audit mapped to first-time comprehension.
