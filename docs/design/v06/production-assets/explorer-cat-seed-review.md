# Explorer Cat Seed — Owner Review Gate

Status: **one candidate prepared; not approved and not wired into runtime**

## Candidate identity

- Candidate (relative): `art_source/v06/explorer_cat_seed/explorer-cat-seed-192.png`
- Candidate (absolute): `C:\Dev\Projects\dice-slot-trip\art_source\v06\explorer_cat_seed\explorer-cat-seed-192.png`
- SHA-256: `eccf84a8ca380f2c1ad662868abdce664ad866e6072a0d67b5e00173e63cb1cd`
- Format: PNG, RGBA, exactly `192×192`
- Feet anchor: exactly `(96,179)`; both nonzero-alpha boot groups reach `y=179`
- Alpha bbox: `(26,8)–(143,180)` with transparent corners and safety padding

This hash is the only candidate eligible for the T022 owner decision. It must not be used as a strip source until the owner explicitly approves this exact path and hash.

## In-context evidence

| Artifact | Relative path | Absolute path | SHA-256 |
|---|---|---|---|
| Native preview | `art_source/v06/explorer_cat_seed/explorer-cat-preview-720.png` | `C:\Dev\Projects\dice-slot-trip\art_source\v06\explorer_cat_seed\explorer-cat-preview-720.png` | `4f7fb0e00a22e4d135c4510a0487a455e3c090eb2ed6eeb29082a46fd54e450b` |
| 1/2 derivative | `art_source/v06/explorer_cat_seed/explorer-cat-preview-360.png` | `C:\Dev\Projects\dice-slot-trip\art_source\v06\explorer_cat_seed\explorer-cat-preview-360.png` | `492e7a63c6e46df985ac036a74b6e8998743560361c51fbea015a6dc333afa0d` |

- The 720 preview displays the visible cat at `94 px` high against a `63 px` current route tile: `1.492×`.
- The 360 preview is a direct Lanczos derivative, exactly `360×640`.
- Native RGB differences from the source capture are confined to map coordinates `(94,484)–(192,597)`. HUD, route topology, EXIT marker, slot/die tray and baked text are unchanged.
- The cat remains readable at 360px: orange/cream face, teal eyes/scarf, brass safari hat, tan backpack and two boots remain distinguishable.

## Generation and pipeline

- Mode: OpenAI built-in `image_gen`, one `generate` call, exactly one candidate.
- No CLI model, native-transparency fallback, second generation, variant, animation frame or strip was used.
- The selected atlas was inspected as a style/silhouette/palette reference. It was not used as an edit target and no image was passed to the generator.
- Exact prompt: `art_source/v06/explorer_cat_seed/prompt-used.txt`
- Immutable copied generator output SHA-256: `d6a4d5f6501eba41318c9e9e9c6e81fdc76861f05ac08b51bf2cd1386daf40d4`
- Chroma removal: installed `remove_chroma_key.py`, `--auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill`.
- The tool-generated raster was visually flat green but varied slightly around the requested key; border auto-sampling selected `#02F807`. Final alpha cleanup preserved the fur silhouette. No edge-contract retry was needed.
- Alpha/fringe evidence: `1,070,289` transparent, `33,732` partial and `468,495` opaque source-matte pixels; zero neon-green partial pixels, zero pixels with green excess above 80, maximum green excess `0`.
- Normalization and preview are deterministic in `art_source/v06/explorer_cat_seed/build-seed-qc.py`; complete measurements are in `pipeline-meta.json` and hashes/reference roles in `provenance.json`.

## Visual checklist

- [x] Unmistakably an animal cat: feline muzzle, ears, whiskers, tail and paws; no human skin, hair, hands or fingers.
- [x] Orange/cream fur and large green/teal eyes read at both seed and 360px review scale.
- [x] Brass/tan safari hat, teal scarf, small tan leather backpack and short boots are present.
- [x] Compact rounded, friendly-determined explorer silhouette matches the selected B+A atlas direction.
- [x] Full-body, centered, three-quarter/front travel-facing idle; both boot groups share the normalized alpha baseline.
- [x] No weapon, scenery, floor, shadow, reflection, text, logo, watermark, map, route, tile or die in the candidate.
- [x] Hand-painted storybook/travel-journal finish, crisp enough for mobile-scale identification.
- [x] Transparent corners, safe alpha bbox, no visible green fringe.
- [x] HUD, route styles, EXIT, fixed tray and die remain legible in both in-context previews.
- [x] No animation strip and no file under `assets/art/v06/**` were created.

## Owner decision required

Approve or reject exactly:

`art_source/v06/explorer_cat_seed/explorer-cat-seed-192.png`<br>
`SHA-256 eccf84a8ca380f2c1ad662868abdce664ad866e6072a0d67b5e00173e63cb1cd`

Approval authorizes only the later whole-strip cat animation task. Rejection must create a replacement-candidate task; it must not silently add a second candidate to T015.
