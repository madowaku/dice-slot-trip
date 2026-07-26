# Selected Atlas Living Map — Generation Prompt

Mode: built-in `image_gen` with three local reference images. Use case: `ui-mockup`.

## Reference roles

- `b-explorers-atlas.png` — primary structure: Explorer's Atlas hierarchy, warm folding-paper map, slim top HUD, dominant central travel map, fixed bottom field-kit tray, and clear route-line language.
- `a-sunlit-cairo-diorama.png` — only the localized 2.5D movement feel around the cat: nearby tiles subtly rise into a miniature world while distant paper stays flat.
- `c-lantern-night-bazaar.png` — only restrained distant climax lighting at the boss gate: a small warm gold/lantern promise, never a night scene or global glow.

## Exact prompt

```text
Use case: ui-mockup
Asset type: final selected portrait gameplay visual target for a one-handed mobile Godot game, 9:16.
Input images: Image 1 is the PRIMARY structural reference: preserve its Explorer's Atlas hierarchy, warm folding-paper map, slim top HUD, dominant central travel map, fixed bottom field-kit tray, and clear route line language. Image 2 supplies ONLY the localized 2.5D movement feel around the cat: nearby tiles subtly rise into a miniature world while distant paper stays flat. Image 3 supplies ONLY the restrained distant climax lighting at the boss gate: a small warm gold/lantern promise far ahead, never a night scene and never global glow.
Primary request: create one refined selected direction based on B, centered closely on the travelling cat and its current vicinity. Do not show all 32 spaces. Make only the current vicinity and next 8–12 spaces prominent, with the route continuing beyond the crop so gentle forward camera tracking is implied. The cat is the clear focal point and 1.3–1.5x larger than in Image 1. Show real one-space hopping through pose, a tiny lifted paw/body arc, and subtle short directional motion cues, not merely a growing trail.
Scene/backdrop: warm parchment Cairo atlas in daytime, indigo/teal ink, understated sandstone miniature details only near the cat. Distant map remains flat paper with sparse cartographic symbols.
Composition/framing: simple compact top HUD; very large central map; fixed bottom tray. Main route, bypass branch, and an eight-position loop must be immediately readable despite the close camera. The cat is inside the 8-loop at main progress 18/32 and loop EXIT 4. Show numbers only around the current location; distant spaces use symbols, dots, stamps, and line styles. The distant boss gate sits near the upper distance with one restrained gold lantern accent.
HUD state: visually communicate LAP 4, HP 2/3, PB -2.4s, progress 18/32, but treat lettering as illustrative concept UI.
Bottom tray: exactly three immediately adjacent slots showing [6][6][_], directly beside exactly ONE READY die. The empty unconfirmed slot has only a very soft breathing glow, nearly matte. No other dice anywhere.
Lighting/mood: low-stimulation, warm parchment and muted teal daytime for long play sessions; calm, tactile, legible. Only the distant boss gate receives restrained C-style gold/lantern anticipation.
Materials/textures: aged ivory paper, hand ink, linen, worn leather, subtle brass, tiny locally raised sandstone tile edges.
Constraints: readable main route, bypass, and eight-position loop; cat-centered tracking composition; next 8–12 spaces prominent; fixed tray; exact single die; no shipping-quality reliance on generated text.
Avoid: generic dashboard, full-map fixed overview, showing all 32 spaces, dense route numbering, excessive cards, excessive glow, night palette, global lantern lighting, multiple dice, huge scenery, modal overlays, watermark, logo, photoreal phone frame.
```

The native 941×1672 output was normalized with Lanczos scaling to 720×1280. Generated lettering and route numbering are illustrative only.
