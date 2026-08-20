# 狐火追陣 visual source record

## Selected UI target

- File: `ui/fox-fire-chase-target-v1.png`
- Canvas: 720×1280 portrait
- Direction selected from three ImageGen concepts:
  - option 2 top HUD and chase-distance readout
  - option 1 large board
  - pieces centered inside 6×6 square cells, never on lines or intersections
  - compact three-slot tray from options 1/2
  - large round ROLL/STOP control from options 1/3

The target is a visual composition reference. Runtime state, labels, board
positions, and touch behavior remain native Godot UI.

## Generated white-fox run asset

- Seed: `assets/art/bosses/kyoto/white-fox-guardian.png`
- Raw generation: `sprites/white-fox-chase-raw.png`
- Review sheet: `sprites/white-fox-chase-preview.png`
- Shipped frames: `assets/art/bosses/kyoto/fox_fire_chase/white_fox_run/01.png` … `04.png`
- Frame size: 192×192 RGBA, shared scale and bottom-center anchor

The four poses were generated in one pass from the approved guardian identity,
then normalized together with the Game Studio sprite pipeline. The prompt fixed
the white fur, red forehead mark, red-and-gold collar, left-facing direction,
four-frame count, transparent background, and small-token readability.
