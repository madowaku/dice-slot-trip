# DICE SLOT TRIP Mobile UI Tokens

UI-P0A establishes one physical-size contract for the existing `720 × 1280`
design viewport. At the 360-wide baseline, two design units equal one logical
mobile pixel.

## Core scale

| Role | Design units | 360-wide result |
|---|---:|---:|
| Display text | 52 | 26 px |
| Page title | 40 | 20 px |
| Body text | 32 | 16 px |
| Caption text | 28 | 14 px |
| Primary button height | 104 | 52 px |
| Minimum touch target | 96 | 48 px |
| Screen edge | 32 | 16 px |
| Large / medium / small gap | 32 / 24 / 16 | 16 / 12 / 8 px |

The runtime source of truth is
`res://scripts/ui/ui_tokens.gd`. UI code should name the role it needs instead
of copying the numeric value into each screen.

## Usage rules

- Paragraphs and ordinary UI labels use `FONT_BODY`.
- Supporting copy uses `FONT_CAPTION`; `_body()` floors smaller legacy values
  to this token while screens are migrated.
- Map numbers and marks use the separate `FONT_MAP_*` scale because they are
  canvas annotations, not paragraphs or controls.
- Every visible release button must render at least `TOUCH_MIN` high. Primary
  actions use `BUTTON_HEIGHT`.
- Page and modal containers apply `content_margins()` so design edge spacing is
  added inside Android/iOS display cutouts and system-bar insets.
- Dense HUD information should be removed, shortened, or disclosed on demand;
  it must not be made readable by shrinking below the caption token.

## Acceptance baseline

- Title, destination, traveler, and first-roll screens fit at 360 × 640.
- Visible non-debug buttons pass the 48 px touch-target check.
- 393- and 412-wide layouts keep the same semantic sizes and use added height
  instead of stretching or shrinking copy.
- Android/iOS safe-area values are converted from physical display pixels to
  the expanded 720-design coordinate space before margins are applied.
