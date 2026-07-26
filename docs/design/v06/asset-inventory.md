# v0.6 Visual Target Asset Inventory

## Generated deliverables

| File | Source | Processing | Intended use |
|---|---|---|---|
| `a-sunlit-cairo-diorama.png` | Original built-in ImageGen generation | Native 941×1672 PNG resized to 720×1280 with ffmpeg Lanczos | Visual direction target only |
| `b-explorers-atlas.png` | Original built-in ImageGen generation | Native 941×1672 PNG resized to 720×1280 with ffmpeg Lanczos | Visual direction target only |
| `c-lantern-night-bazaar.png` | Original built-in ImageGen generation | Native 941×1672 PNG resized to 720×1280 with ffmpeg Lanczos | Visual direction target only |

No third-party raster asset is embedded or copied into these deliverables. The generated cat, Cairo scenery, map marks, dice, materials and icons are original ImageGen output.

## Reference-only inputs

- `docs/reference/android-ui-game-tourism.png`: existing runtime hierarchy and fixed-tray reference; not embedded.
- `docs/reference/runtime-premium-ui-one.png`: existing premium material treatment and single-die reference; not embedded.
- `docs/reference/game_concept.png`: prior Cairo travel-game ambition; not embedded. Its legacy 90-space/multi-die implications were explicitly excluded.
- `ステージ画面イメージ3.png`: prior dense bazaar/world staging reference; not embedded.
- `docs/改善統合仕様書 v0.6.md`: canonical gameplay and UI requirements.

## Shipping caveat

Do not ship generated text or route numbering as UI. Rebuild readable labels, numerals, route topology and state in Godot Controls using Noto Sans JP and the canonical game model. Treat the PNGs solely as visual targets for spatial hierarchy, palette, lighting and material language.
