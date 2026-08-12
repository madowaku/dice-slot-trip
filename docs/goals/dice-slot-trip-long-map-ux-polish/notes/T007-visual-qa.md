# T007 Native Mobile Visual QA

## Capture method

- Independent recorder: `res://tests/record_v06_long_map_ux.gd`.
- Runtime: Godot 4.7 stable, Windows display driver, OpenGL 3 compatibility renderer, Dummy audio.
- Raw images are direct viewport readbacks and were never resized. Every invocation exited normally after checking the exact image size and non-uniform pixel content.
- Comparison sheets resize copies only; they do not replace the raw evidence.

## Native evidence

| State | 360×640 | 720×1280 |
| --- | --- | --- |
| Normal HUD / mission | `artifacts/long-map-ux-polish/normal-360x640.png` | `artifacts/long-map-ux-polish/normal-720x1280.png` |
| Full map, minimum pan bound | `artifacts/long-map-ux-polish/map_min-360x640.png` | `artifacts/long-map-ux-polish/map_min-720x1280.png` |
| Full map, maximum pan bound | `artifacts/long-map-ux-polish/map_max-360x640.png` | `artifacts/long-map-ux-polish/map_max-720x1280.png` |
| Boss pre-roll, purchased START+3 | `artifacts/long-map-ux-polish/boss_start3-360x640.png` | `artifacts/long-map-ux-polish/boss_start3-720x1280.png` |

Comparison sheets:

- `artifacts/long-map-ux-polish/contact-normal-boss.png`
- `artifacts/long-map-ux-polish/contact-map-bounds.png`

## Inspection

- Typography and copy: both native sizes retain readable mission values `獲得0/12` and `0/5`. LIFE is a compact first/top row (`復活 ×3`) and the three-heart HP line sits immediately below it. No text collision or truncation was found.
- HUD containment and playfield: the fixed survival cluster and horizontal mission strip remain inside their authored bands. The central route, current cat, six successors, dice, tray, and tool dock remain visible; the normal HUD does not intrude into the map playfield.
- Full map: opposite huge drags visibly reach opposite padded route extents at both sizes. The parchment remains filled without blank overscroll. The modal title and separate `閉じる` CTA remain visible and readable. The backing operation band and its white `サイコロを振ろう` copy are absent throughout the modal. No QA-only gesture label was overlaid; production input ownership, tap/drag separation, and bound reachability are evidenced by the atlas/play-screen suites.
- Boss entry: after the production intro CTA and before any roll, the purchased state reads YOU `3 / 20` and SPHINX `0 / 20`. Both complete racer sprites, their footprint rings, the truthful SPHINX START label, lane frames, die, and ROLL control are visible at both sizes.
- Palette and assets: parchment/gold/teal travel surfaces, explorer-cat LIFE art, map route symbols, boss lane art, and Sphinx art remain consistent. No placeholder or QA-only imagery appears in raw captures.
- Interaction hierarchy: map remains modal with one close action; boss pre-roll keeps one primary ROLL action. Normal play retains one main roll control and low-density secondary tools.

## Iteration history

1. The first recorder pass incorrectly assigned the physical 360×640 size as the logical design size, producing a cropped QA image. This was a recorder-only issue; no production or behavior-test file changed.
2. The recorder retained the project 720×1280 logical design space while requesting native 360×640 output. All eight raw states were recaptured with exact headers and passed pixel sanity.
3. The initial boss capture stopped on the explanation card, which visually covered the racers. The recorder now invokes the existing production intro CTA and captures the still-unrolled boss-ready state; both token footprints are fully visible.
4. Judge review found the backing operation copy bleeding onto the full-map parchment. Map open/direct-message refresh now preserves message state while hiding both backing nodes; all four native map bounds and their contact sheet were replaced. The corrected images contain no white operation copy.

## Verification

- Mission, candidate-mission, save, play-screen, play-session, feedback, tall-phone, visual-asset, atlas-interaction, boss-screen, boss-battle, coin-economy, course-model, and full suites: pass, exit 0 / `failures=0`.
- Native capture matrix: pass, exact 360×640 and 720×1280 headers, pixel sanity true, normal process exit.
- Severity: P0 none; P1 none; P2 none.

final result: passed
