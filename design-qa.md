# Design QA — Cairo normal journey slice

## Evidence

- Source visual truth: `C:\Users\hiro\Desktop\dice3.png`
- Combined comparison: `C:\Dev\Projects\dice-slot-trip-recovery\build\design-qa-comparison.png`
- RESULT_LOCK implementation: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-result-lock-score-hud-720x1280.png`
- Inline MIX implementation: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-inline-mix-720x1280.png`
- Inline PAIR implementation: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-inline-pair-720x1280.png`
- Stage-select implementation: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-stage-select-latest-720x1280.png`
- Detached-ring overview: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-detached-rings-map-720x1280.png`
- Two-shortcut overview: `C:\Dev\Projects\dice-slot-trip-recovery\build\qa-two-shortcuts-map-720x1280.png`
- Source pixels: 843 × 907
- RESULT_LOCK and inline-result pixels: 720 × 1280
- Stage-select pixels: 360 × 640
- Godot logical viewport: 360 × 640; gameplay evidence was captured at 2× density.
- Density normalization: the source was scaled to 1280 px high; stage select was scaled from 360 × 640 to 720 × 1280; the modal capture remained 720 × 1280. These were placed in one 2630 × 1280 comparison image.
- States: normal-journey RESULT_LOCK, three-roll inline role result, and Cairo stage selection.

## Full-view comparison evidence

The normal HUD gives SCORE the leading position and removes TIME, PB, LAP, and ROLLS. The Cairo card and map composition remain unchanged, while the route summary reads 58 spaces and names the Sphinx lap boss. The duplicate trial action is gone and one primary `この旅へ` action remains. The latest full-screen evidence shows the three-roll result embedded in the slot tray without covering the map.

## Focused-region comparison evidence

Focused captures were needed because the two source callouts are small:

- Inline result: the completed `[4][1][6]` slots, `MIX`, `+50`, and `コイン+1` remain in the tray; no dim layer, modal card, or confirmation button covers the map.
- PAIR result: the two matching `[6]` slots are joined by a short light line, while the third slot remains outside that connection.
- Stage actions: the single primary `この旅へ` action launches the latest V06 route, with 58-space and Sphinx information immediately above it.
- RESULT_LOCK: only the card corresponding to the fixed face receives a restrained outline/ring. ROLLING has no target highlight. The score count-up follows the authoritative v0.1 score table.

## Required fidelity surfaces

- Fonts and typography: the existing Japanese game font and hierarchy are preserved. SCORE is legible and dominant; coin, hearts, progress, and MAP remain secondary. No clipping or truncation is visible at 360 × 640.
- Spacing and layout rhythm: the normal HUD fits on one row, the duplicate stage button was removed, and the taller slot tray fits role and reward copy without clipping the map or bottom tools. The two-line stage summary is an intentional narrow-screen wrap.
- Colors and visual tokens: the existing parchment, teal, gold, and dark HUD tokens are reused. RESULT_LOCK uses a calm teal/gold emphasis rather than an active rolling glow.
- Image quality and asset fidelity: existing Cairo, Sphinx, coin, cat, map, and die assets are retained. No visible image was replaced by emoji, placeholder geometry, or a newly approximated asset.
- Copy and content: normal journey copy uses SCORE and 58-space progress; Cairo names the sleepy Sphinx as lap boss; the duplicate V06 trial copy is removed; `この旅へ` is the canonical launch action.

## Comparison history

### Iteration 1

- [P1] The map die rendered above the resolution modal and overlapped its action.
- [P1] Stage selection exposed two competing launch actions, with the older `この旅へ` path and a separate latest V06 trial path.
- [P2] Cairo still presented 90 spaces in the supplied source state.
- [P2] Normal travel foregrounded TIME/PB/LAP instead of score growth.
- [P2] The first RESULT_LOCK capture caught the score mid-count-up and exposed an extra HUD separator.

Fixes made:

- Raised resolution and choice overlays above the map die.
- Routed the Cairo postcard and single `この旅へ` button to the latest V06 journey and removed the duplicate trial button.
- Replaced 90 with 58 and named the Sphinx lap boss.
- Replaced normal TIME/PB/LAP/ROLLS fields with SCORE, coin, HP hearts, progress, and MAP.
- Delayed the deterministic capture until the score tween settled and removed the redundant separator.

### Iteration 2

Post-fix evidence in `build/design-qa-comparison.png`, `build/qa-result-lock-score-hud-720x1280.png`, and `build/qa-resolution-modal-layer-720x1280.png` shows no remaining actionable P0/P1/P2 mismatch in this slice.

### Iteration 3

- [P1] MIX / PAIR / STRAIGHT / TRIPLE still interrupted travel with a full-screen confirmation modal.
- [P2] Role rewards were awarded only after movement, so the slot could not answer immediately when the third face stopped.

Fixes made:

- Moved travel-role results into the slot tray and removed the confirmation step from the travel flow.
- Awarded role score, coin, and skill gauge at result lock, before cat movement.
- Added equal-duration role treatments: MIX soft flash, PAIR linked matches, STRAIGHT left-to-right flow, and TRIPLE strong simultaneous flash.
- Automatically resets the three slots only after movement, landing, and camera follow complete.

Post-fix evidence in `build/qa-inline-mix-720x1280.png` and `build/qa-inline-pair-720x1280.png` shows no remaining actionable P0/P1/P2 mismatch in the inline-result slice.

### Iteration 4

- [P1] The former ring was attached to the main route as a permanent side loop, so entering it read as ordinary route traversal.
- [P1] A single portal could not communicate safe, dangerous, and special destinations before the player committed.
- [P2] Ring rewards and movement score could be collected repeatedly.

Fixes made:

- Split the side route into independent `オアシス環` and `墓廊の輪` spaces and removed permanent minimap connector lines.
- Added five exact-stop gates across the 58-space main route: two aqua oasis gates, two purple tomb gates, and one gold special gate.
- Fixed each EXIT return to the tile immediately after the next gate, without retriggering that gate.
- Made each source gate single-use per lap and normalized consumed gates and ring rewards to NORMAL.
- Applied first-visit-only movement score and route-specific first-time EXIT scores from `スコア仕様 v0.1.md`.

The production OpenGL capture in `build/qa-detached-rings-map-720x1280.png` confirms that both rings read as floating islands, the five destination gates remain visible on the main route, and no permanent line connects either ring to the route.

### Iteration 5

- [P1] The former single shortcut occupied the central crossing and competed with the main route and player marker.
- [P1] Cairo needed two geographically distinct shortcuts rather than one fixed branch contract.
- [P2] Shortcut entry, merge, distance saving, and selection state were not explicit enough on the overview.

Fixes made:

- Added `バザール裏路地` from 11 to 19 on the right, with a four-space saving.
- Added `砂嵐の抜け道` from 34 to 46 on the left, with a six-space saving.
- Kept both shortcuts connected to the main route, visually distinct from the detached ring spaces.
- Added thicker rust-red dashed paths, split and merge markers, compact saving labels, and existing RISK / ITEM node icons.
- Unselected paths use restrained opacity; the currently selected shortcut brightens without changing topology.
- Generalized movement, route choice, completion score, six-space forward preview, and UI copy from one hard-coded bypass to two data-driven shortcuts.

The production OpenGL capture in `build/qa-two-shortcuts-map-720x1280.png` confirms that the two branches occupy opposite outside edges and no longer form a central knot with the player, main route, or either ring.

## Findings

No actionable P0, P1, or P2 findings remain.

## Open questions

- The stage route summary wraps onto two lines at 360 px width. This is acceptable for the current information set; it can be revisited only if future HUD copy becomes longer.

## Implementation checklist

- [x] RESULT_LOCK-only quiet target emphasis
- [x] Modal layering above the map die
- [x] Single latest Cairo launch path
- [x] 58-space Cairo route and Sphinx lap boss
- [x] Score-led normal HUD
- [x] MIX / PAIR / STRAIGHT / TRIPLE additive role scoring
- [x] Nonmodal inline role results with no confirmation button
- [x] MIX coin reward and PAIR / STRAIGHT / TRIPLE skill-gauge rewards
- [x] Five exact-stop warp gates with distinct oasis, tomb, and gold treatments
- [x] Two detached minimap rings with no permanent connector lines
- [x] Fixed post-next-gate return and no immediate re-warp
- [x] Per-lap gate consumption and one-time ring rewards
- [x] First-visit-only movement scoring and v0.1 score categories
- [x] Bazaar alley 11→19 / four-space saving
- [x] Sirocco shortcut 34→46 / six-space saving
- [x] Opposite-side shortcut placement with split and merge markers
- [x] Faint unselected path and bright selected path
- [x] 360 × 640 and 720 × 1280 visual verification

## Follow-up polish

- [P3] A later presentation milestone may give large score awards bespoke sound, particles, and material response. This is intentionally outside the current stability/information slice.

final result: passed
