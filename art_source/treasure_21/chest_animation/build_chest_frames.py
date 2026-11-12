from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "raw" / "treasure-chest-strip-bgextract.png"
CUTOUT = ROOT / "raw" / "treasure-chest-strip-cutout.png"


def is_background(pixel: tuple[int, int, int]) -> bool:
    low = min(pixel)
    high = max(pixel)
    return low >= 220 and high - low <= 14


def main() -> None:
    source = Image.open(SOURCE).convert("RGB")
    width, height = source.size
    pixels = source.load()
    background = Image.new("L", source.size, 0)
    mask = background.load()
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if mask[x, y] != 0 or not is_background(pixels[x, y]):
            continue
        mask[x, y] = 255
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    alpha = background.point(lambda value: 0 if value else 255)
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.55))
    output = source.convert("RGBA")
    output.putalpha(alpha)
    output.save(CUTOUT)
    print(f"wrote {CUTOUT} ({width}x{height}, RGBA)")


if __name__ == "__main__":
    main()
