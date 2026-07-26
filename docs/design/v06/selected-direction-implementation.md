# Selected Atlas Living Map — Implementation Notes

`d-selected-atlas-living-map.png` is a direction-selection target, not a shipping bitmap UI.

## Asset separation

- Keep the parchment/map texture, faint Cairo cartography, distant boss-gate concept, and non-interactive decorative desk materials as separable art layers.
- Build route geometry from canonical game data. Main, bypass, and loop lines and nodes must not be baked into the background.
- Keep the cat, local raised-tile treatment, hop effects, boss-gate light, HUD, slot tray, slots, die, and all text as independent runtime assets/nodes.
- Use the distant gold gate accent as a separately controlled effect so normal daytime remains low stimulation.

## Rebuild in Godot

- Rebuild all HUD and tray typography with Godot `Control`/`Label` nodes and Noto Sans JP. The generated `LAP 4`, HP 2/3, `-2.4s`, `18/32`, `EXIT 4`, `[6][6][_]`, and `READY` marks are composition references only.
- Render the canonical 32-space route from data, but frame gameplay around the cat so only its vicinity and the next 8–12 spaces are prominent. Distant nodes should switch to symbols rather than persistent numbers.
- Implement a camera that gently tracks the cat and biases forward along the route. The cat must visibly hop one space at a time; movement cannot be represented only by a trail.
- Scale the cat to approximately 1.3–1.5× the B reference and keep it the focal point inside the eight-position loop.
- Raise only nearby route tiles with subtle parallax, shadows, or shallow 2.5D meshes. Keep the distant atlas flat to control scope and Android cost.
- Build the fixed bottom tray responsively: three adjacent slots `[6][6][_]` immediately beside exactly one READY die. Animate the unconfirmed slot with a very soft breathing glow.
- Keep the normal palette warm parchment/teal daytime. Enable restrained gold/lantern boss anticipation only on the distant gate and reserve broader C-style lighting for earned climax states.
- Validate route topology, state values, hit targets, safe areas, and legibility independently at 720×1280 and 360×640.

## Interpretation guardrails

The target intentionally crops the full route and emphasizes a local tracking view. Generated spatial details, repeated numbers, perspective, and text are not authoritative. The shipping scene must use canonical route/state data and accessible runtime UI.
