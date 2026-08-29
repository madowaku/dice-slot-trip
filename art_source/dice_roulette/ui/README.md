# DICE ROULETTE UI asset provenance

Generated on 2026-08-29 with the built-in ImageGen workflow and integrated as
editable Godot UI layers. The generated rasters contain no rules, labels,
results, balances, or controls.

## Visual reference

- `C:/Users/hiro/AppData/Local/Temp/codex-clipboard-700d9dd7-cb11-4787-a8cb-a2ac21aebac6.png`
- Role: premium casino art-direction and composition reference.

## Production assets

- `assets/casino/dice_roulette/ui/casino-table-bg-v1.png`
  - Portrait Las Vegas interior background.
  - Prompt intent: dark emerald center, warm brass edge lighting, restrained
    ruby/sapphire accents, no text, dice, wheel, buttons, or central focal
    object.
- `assets/casino/dice_roulette/ui/roulette-bezel-v1.png`
  - Transparent front-facing antique-gold and emerald wheel bezel.
  - Prompt intent: symmetric circular ornament, twelve divider studs, empty
    transparent center/exterior, no text, numbers, dice, pockets, or buttons.

## Sparkle normalization

The existing four-slot source
`assets/casino/las_vegas/las-vegas-selection-sparkle-strip.png` was normalized
with the Game Studio sprite pipeline into four 128×128 RGBA frames under
`assets/casino/dice_roulette/ui/sparkle_frames/`. One shared scale and a
bottom-center anchor were applied across the strip. The inspection sheet is
`art_source/dice_roulette/ui/roulette-sparkle-preview.png`.

## Runtime policy

Stateful UI remains code-driven. Background and ornament textures may be
replaced without changing CasinoBank, bets, RTP, settlement, save data, or the
roulette model.
