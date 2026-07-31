# Cairo atlas district scenery — image generation prompts

Built-in `imagegen` was used for the current `V06AtlasView` card-route screen,
with
`assets/art/landmarks/cairo/spice_market_lv3.png` as the strict visual
reference. Every source was generated on a flat magenta chroma-key background,
then converted to an alpha PNG with the Image Generation skill's
`remove_chroma_key.py` helper.

Shared direction:

- Production scenic diorama for the current portrait mobile atlas screen,
  moving behind the seven raised route cards.
- Match the current isometric miniature camera, crisp painterly 3D finish,
  honey sandstone, turquoise accents, warm light, and separated outer contour.
- Use a wide, low composition with three depth bands and clear side
  silhouettes for horizontal drift.
- Keep the lower middle readable for route tiles.
- No characters, UI, text, labels, logos, borders, or watermarks.
- Perfectly flat `#ff00ff` background; never use that color in the subject.

District subjects:

- `market.png`: historic spice souk, striped awnings, spice baskets, pottery,
  hanging lanterns, palms, domes, and a slim minaret.
- `pyramid.png`: Giza plateau with two large pyramids, one small pyramid,
  causeway, mastaba blocks, rocks, and a turquoise expedition canopy.
- `oasis.png`: turquoise pool and Nile channel, bridge, palms, reeds, garden
  pavilions, irrigation, pottery, flowers, and a small felucca.
- `ruins.png`: excavated temple courtyard, columns, obelisks, broken pylons,
  carved walls, fallen drums, sphinx fragment, and excavation lamps.
- `dunes.png`: layered wind-carved dunes, caravan trail, rocks, abandoned camp,
  pennants, rugs, jars, grasses, and distant camel silhouettes.

The final alpha PNGs are the project deliverables. The larger chroma-key
intermediates were intentionally omitted from the shipping project after matte
validation; this file preserves the reproducible prompt direction.
