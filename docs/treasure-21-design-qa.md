# TREASURE 21 Design QA

final result: passed

## Compared states

- SAFE reference: supplied TREASURE 21 mockup with TOTAL 12 and locked future preview.
- DANGER reference: supplied TOTAL 20 / ONE AWAY mockups with six deterministic outcomes.
- Implementation captures: `artifacts/qa/treasure21-product/final-360x800/` and `artifacts/qa/treasure21-product/final-720x1280/`.

## Blocking findings

- P0: none.
- P1: none.
- P2: none after responsive correction. The initial 720×1280 DANGER capture pushed the back action below the viewport; compact layout sizing now keeps all persistent actions on-screen.

## Verified

- TOTAL remains in one fixed visual location from SAFE through ONE AWAY.
- CASH OUT and ROLL retain their positions in every active state.
- SAFE keeps six fixed placeholders, avoiding layout movement when DANGER unlocks.
- TOTAL 17 reveals all six deterministic outcomes and clearly enables CASH OUT.
- TOTAL 20 emphasizes the single TREASURE face and de-emphasizes five BUST faces.
- Generated chest frames share one scale and bottom-center anchor and retain alpha transparency.
- All four authored chest textures load at 256×256 and map deterministically to BUST, CASH OUT, GOLDEN, and TREASURE result states.
- Result capture waits beyond the 0.26-second reveal; the settled card is fully opaque with readable RETURN / NET and all three transition actions on-screen.
- 81 bounds and capture assertions pass at both 360×800 and 720×1280.
- TREASURE 21 gameplay and visual-contract suite passes 90 assertions.
- Casino expansion UI passes 116 assertions; Las Vegas Phase C visual tests pass 29 assertions.

## P3 follow-up ideas

- Add authored sound cues specifically for entering DANGER and ONE AWAY.
- In Godot 4.7, tune the existing offset-transform button motion against device haptics.
