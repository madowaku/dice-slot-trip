"""Deterministically normalize the six approved Kenney tile-kind glyphs."""

from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "third_party" / "kenney-board-game-icons" / "selected-originals"
OUTPUT = ROOT / "assets" / "art" / "v06" / "tile_kind_icons"

# Shared optical envelope. Per-icon boxes are documented selection decisions;
# pixels are always scaled uniformly and never stretched.
SPECS = {
    "normal-arrow-right.png": ("arrow_right.png", 102, (0, 0)),
    "coin-tokens-stack.png": ("tokens_stack.png", 104, (0, 1)),
    "rest-campfire.png": ("campfire.png", 104, (0, 1)),
    "risk-skull.png": ("skull.png", 102, (0, 1)),
    "item-pouch.png": ("pouch.png", 104, (0, 1)),
    "event-book-open.png": ("book_open.png", 106, (0, 1)),
}


def normalize(source: Path, target: Path, envelope: int, offset: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"source has no opaque pixels: {source}")
    alpha = alpha.crop(bounds)
    scale = envelope / max(alpha.size)
    size = tuple(max(1, round(axis * scale)) for axis in alpha.size)
    alpha = alpha.resize(size, Image.Resampling.LANCZOS)
    alpha = alpha.filter(ImageFilter.MaxFilter(3))
    canvas = Image.new("RGBA", (128, 128), (255, 255, 255, 0))
    x = (128 - size[0]) // 2 + offset[0]
    y = (128 - size[1]) // 2 + offset[1]
    white = Image.new("RGBA", size, (255, 255, 255, 255))
    white.putalpha(alpha)
    canvas.alpha_composite(white, (x, y))
    canvas.save(target, optimize=False, compress_level=9)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for output_name, (source_name, envelope, offset) in SPECS.items():
        normalize(SOURCE / source_name, OUTPUT / output_name, envelope, offset)
        print(f"normalized {source_name} -> {output_name} envelope={envelope} offset={offset}")


if __name__ == "__main__":
    main()
