# V0.6 Atlas / Boss Environment Pack — Visual Review

Artifact role: **QC evidence only; no runtime wiring is represented or implied.**

## Accepted production sources

- Exactly five built-in ImageGen calls were accepted: parchment, Cairo ink, route-tile sheet, boss-gate sheet, and lantern-glow sheet.
- No retry, competing variant, native-transparency request, CLI fallback, or concept/document crop was used.
- `docs/design/v06/d-selected-atlas-living-map.png` was used only for storybook palette, brushwork, and material character. Its composition, UI, topology, route, nodes, numbers, `EXIT`, labels, cat, die, and gate were excluded.
- The existing sphinx is a deterministic Lanczos derivative of `assets/art/bosses/sleepy-sphinx.png`; the 1254×1254 source remains unchanged at SHA-256 `27759bf53575c42a8db3a700bcfb11dfb37e1e19885f32e1f271c052aaf70f0e` and 1,954,756 bytes.
- The sphinx source is an existing project-generated asset with `sleepy-sphinx.prompt.txt`; no sphinx record exists under `third_party/` and it is not claimed as third-party art.

## Content and lighting gates

- PASS — parchment is opaque, low-stimulation warm paper with exact mirrored edge continuity and no focal objects.
- PASS — Cairo ink contains only Nile, pyramids, mosque, market canopies, and palms. It contains no gameplay route, nodes, circles-as-spaces, numbers, letters, labels, `EXIT`, UI, die, explorer cat, or compass.
- PASS — four route cells read distinctly as main teal, bypass rust/dashed, loop brass/teal, and raised current teal/gold. All faces are blank and share a common normalized baseline.
- PASS — boss gate cells retain the same normalized 220×232 silhouette, scale, and bottom-center baseline. Only the awakened cell emits contained warm gold.
- PASS — lantern variants form one restrained warm-gold effect family with a shared bottom-center baseline. The brighter three-lobe cell reads as a TRIPLE emphasis without a numeral, icon, or word.
- PASS — no C-style night, vignette, lantern, or broad gold lighting appears in daylight runtime layers or the daylight preview.
- PASS — night vignette, awakened-gate light, and lantern effects are confined to boss-only metadata and the boss-lit QC preview.

## Alpha and small-screen review

- Built-in transparent requests used a flat requested `#00FF00` background and the installed `remove_chroma_key.py` helper with border auto-key, soft matte, thresholds 12/220, and despill.
- All final RGBA runtime assets have four transparent corners and zero near-pure low-alpha chroma-key residual pixels after premultiplied-alpha Lanczos normalization.
- Alpha fringe contact checks were reviewed on split light/dark backgrounds. Fine Cairo wash edges, tile rims, gate masonry, sphinx outline, and lantern halos remain intact.
- PASS at 720×1280 and Lanczos 360×640. Fine landmark pen lines soften at 360 px as intended; route-tile, gate, sphinx, and lantern silhouettes remain readable.
- Visual caveat: the lantern sheet intentionally retains a feathered gray-gold outer halo at low alpha. This is part of the controlled painterly light effect, not green chroma spill.

## Size exception and preview boundary

- The exact 720×1280 single-channel `assets/art/v06/boss/night-vignette.png` is the sole mandated screen-mask exception to the general 1152 px runtime edge cap. The exception is path- and dimension-fixed and does not apply to any other asset.
- Every other runtime asset has a maximum edge of 1024 px; the immutable 1254×1254 sphinx source remains outside this normalized runtime pack.
- Daylight and boss-lit previews include a procedural sample route solely to show raised assets in context. That sample topology is QC-only and is not present in parchment or Cairo ink runtime layers.
