"""Normalize the v0.8 footprint glyph into the T029 white-mask contract."""

from pathlib import Path
import sys

from PIL import Image, ImageFilter


def normalize(source: Path, target: Path, envelope: int = 104) -> None:
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"source has no opaque pixels: {source}")
    alpha = alpha.crop(bounds)
    scale = envelope / max(alpha.size)
    size = tuple(max(1, round(axis * scale)) for axis in alpha.size)
    alpha = alpha.resize(size, Image.Resampling.LANCZOS).filter(ImageFilter.MaxFilter(3))
    canvas = Image.new("RGBA", (128, 128), (255, 255, 255, 0))
    x = (128 - size[0]) // 2
    y = (128 - size[1]) // 2
    white = Image.new("RGBA", size, (255, 255, 255, 255))
    white.putalpha(alpha)
    canvas.alpha_composite(white, (x, y))
    target.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(target, optimize=False, compress_level=9)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: normalize_v08_tile_icon.py <source-rgba.png> <target.png>")
    normalize(Path(sys.argv[1]), Path(sys.argv[2]))
    print(f"normalized {sys.argv[1]} -> {sys.argv[2]} envelope=104")
