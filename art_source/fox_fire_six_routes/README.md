# Fox Fire Six Routes — generated art provenance

All raster assets in this folder and the corresponding production files were
created with the built-in Image Generation tool on 2026-08-13. The established
Kyoto boss art, white fox, and current product capture were used only as visual
references. UI copy, gameplay markers, path edges, and interaction states remain
native Godot elements.

## Selected visual target

- Output: `docs/design/fox-fire-six-routes-target-v1.png`
- Use case: `ui-mockup`
- Prompt: redesign the existing 720x1280 Kyoto boss screen as a portrait
  `狐火六路陣` surface with a dominant 6x6 board, white fox behind the board,
  torii A `(2,5)`, B `(3,0)`, C `(0,1)`, D `(5,3)`, an explorer cat at A,
  vermilion and gold edge trails, white-fire blocking and preview states, compact
  HUD, exact-N reachability highlights, 3ROLL SLOT, remaining steps, undo, and
  path confirmation. Preserve the leather, indigo, vermilion, antique-gold, and
  warm storybook-board art direction; avoid generic dashboard styling.

## Arena background

- Output: `assets/art/backgrounds/fox-fire-six-routes-board.png` (720x1280)
- Use case: `stylized-concept`
- Prompt: warm painterly 3D Kyoto shrine garden at autumn sunrise with a large
  lacquered wooden board showing exactly six columns and six rows, near-front
  perspective, clear character ledge, antique brass fittings, and no pieces,
  text, fire, markers, UI, or covered cells.

## Board markers

- Output: `assets/art/bosses/kyoto/fox-fire-torii.png` (192x192 RGBA)
- Use case: `stylized-concept`
- Prompt: one front-facing vermilion Shinto torii with restrained antique-gold
  fittings, strong silhouette at game scale, isolated with generous padding and
  no scenery, text, shadow, or watermark.
- Output: `assets/art/bosses/kyoto/white-foxfire.png` (128x128 RGBA)
- Use case: `stylized-concept`
- Prompt: one compact opaque pearl-white kitsune flame with cool-blue inner
  accents and a restrained gold outline, readable at game scale, isolated with
  no scenery, shadow, text, or watermark.

## Slice 6 special-tile markers

- Output: `assets/art/bosses/kyoto/fox-fire-special-tiles.png` (256x128 RGBA, two 128px tiles)
- Use case: `stylized-concept`
- Prompt: production-ready transparent PNG sprite sheet for a portrait mobile
  Kyoto board game, with a delicate pink-and-gold sakura blossom and a jade
  bamboo cluster on one strip, readable at small size, no text or background.
- Integration: the controller keeps SAKURA/BAMBOO rules authoritative; the
  view uses the generated strip only for the visual marker, with native rings
  and touch feedback layered above it.

## Explorer-cat movement strip

- Seed: `cat_move/seed-01.png`, extracted from the approved shipped idle strip.
- Edit canvas: `cat_move/move-edit-canvas.png`.
- Raw chroma source: `cat_move/move-raw-chroma.png`.
- Cleaned strip: `cat_move/move-raw-alpha.png`.
- Production output: `assets/art/bosses/kyoto/explorer-cat-move-strip.png`
  (four 192x192 RGBA frames).
- Preview: `artifacts/fox-fire-six-routes/cat-move-preview.png`.
- Use case: `identity-preserve`.
- Prompt: preserve frame 1 and the same explorer cat, outfit, front-facing
  silhouette, palette, proportions, and storybook rendering while creating one
  four-frame forward step cycle in a single strip. Keep one shared scale and
  bottom-center foot anchor; no scenery, labels, shadows, or per-frame drift.
- Processing: the game-studio sprite pipeline created the edit canvas, removed
  the flat chroma key, normalized all frames with one scale, locked frame 1 back
  to the shipped seed, aligned every frame bottom-center, and rendered the
  preview sheet before integration.
