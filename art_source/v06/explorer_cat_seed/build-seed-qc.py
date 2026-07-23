from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


FRAME_SIZE = (192, 192)
FRAME_ANCHOR = (96, 179)
TOP_SAFETY = 8
PREVIEW_SIZE = (720, 1280)
PREVIEW_DISPLAY_SIZE = 100
PREVIEW_ANCHOR = (143, 594)
PREVIEW_ROUTE_TILE_DIAMETER = 63


def alpha_stats(image: Image.Image) -> dict[str, object]:
    alpha = np.asarray(image.getchannel("A"), dtype=np.uint8)
    ys, xs = np.nonzero(alpha)
    if len(xs) == 0:
        raise RuntimeError("Alpha matte contains no visible subject pixels.")
    return {
        "bbox": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
        "transparent": int(np.count_nonzero(alpha == 0)),
        "partial": int(np.count_nonzero((alpha > 0) & (alpha < 255))),
        "opaque": int(np.count_nonzero(alpha == 255)),
        "visible": int(np.count_nonzero(alpha > 0)),
    }


def normalize_seed(matte: Image.Image) -> tuple[Image.Image, dict[str, object]]:
    matte = matte.convert("RGBA")
    source_stats = alpha_stats(matte)
    left, top, right, bottom = source_stats["bbox"]
    crop = matte.crop((left, top, right, bottom))
    crop_alpha = np.asarray(crop.getchannel("A"), dtype=np.float64)

    # The lowest 16% contains the two boots but excludes the raised tail. Its
    # alpha-weighted centroid is the stable between-feet horizontal anchor.
    foot_band_start = max(0, crop.height - int(round(crop.height * 0.16)))
    foot_band = crop_alpha[foot_band_start:, :]
    x_weights = foot_band.sum(axis=0)
    if float(x_weights.sum()) <= 0.0:
        raise RuntimeError("Could not derive a feet anchor from the source matte.")
    source_anchor_x_in_crop = float(
        np.dot(np.arange(crop.width, dtype=np.float64), x_weights) / x_weights.sum()
    )

    available_height = FRAME_ANCHOR[1] - TOP_SAFETY + 1
    scale = available_height / float(crop.height)
    resized_width = max(1, int(round(crop.width * scale)))
    resized_height = available_height
    resized = crop.resize((resized_width, resized_height), Image.Resampling.LANCZOS)

    mapped_anchor_x = source_anchor_x_in_crop * (resized_width - 1) / max(1, crop.width - 1)
    paste_x = int(round(FRAME_ANCHOR[0] - mapped_anchor_x))
    paste_y = FRAME_ANCHOR[1] - (resized_height - 1)

    seed = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    seed.alpha_composite(resized, (paste_x, paste_y))
    final_stats = alpha_stats(seed)
    f_left, f_top, f_right, f_bottom = final_stats["bbox"]
    if f_top < TOP_SAFETY or f_bottom - 1 != FRAME_ANCHOR[1]:
        raise RuntimeError(f"Normalized vertical safety/anchor failed: {final_stats['bbox']}")
    if f_left < 8 or f_right > FRAME_SIZE[0] - 8:
        raise RuntimeError(f"Normalized horizontal safety failed: {final_stats['bbox']}")

    return seed, {
        "source": source_stats,
        "source_anchor_x_in_crop": source_anchor_x_in_crop,
        "source_foot_band_start_y": top + foot_band_start,
        "scale": scale,
        "resized_subject": [resized_width, resized_height],
        "paste_origin": [paste_x, paste_y],
        "final": final_stats,
    }


def build_preview(seed: Image.Image, capture: Image.Image) -> tuple[Image.Image, dict[str, object]]:
    capture = capture.convert("RGBA")
    if capture.size != PREVIEW_SIZE:
        raise RuntimeError(f"Expected 720x1280 native capture, got {capture.size}.")

    # Remove only the flat procedural head above the current tile by cloning a
    # nearby clean atlas patch from the same Nile/map column. Runtime HUD,
    # routes, tile label, and tray pixels remain untouched.
    clean_source_box = (69, 284, 167, 394)
    clean_patch = capture.crop(clean_source_box)
    clean_destination = (94, 484)
    destination_box = (
        clean_destination[0],
        clean_destination[1],
        clean_destination[0] + clean_patch.width,
        clean_destination[1] + clean_patch.height,
    )
    original_region = capture.crop(destination_box)
    feather = Image.new("L", clean_patch.size, 0)
    feather.paste(255, (3, 3, clean_patch.width - 3, clean_patch.height - 3))
    feather = feather.filter(ImageFilter.GaussianBlur(radius=2.0))
    capture.paste(Image.composite(clean_patch, original_region, feather), clean_destination)

    display = seed.resize(
        (PREVIEW_DISPLAY_SIZE, PREVIEW_DISPLAY_SIZE), Image.Resampling.LANCZOS
    )
    anchor_x = int(round(FRAME_ANCHOR[0] * PREVIEW_DISPLAY_SIZE / FRAME_SIZE[0]))
    anchor_y = int(round(FRAME_ANCHOR[1] * PREVIEW_DISPLAY_SIZE / FRAME_SIZE[1]))
    paste = (PREVIEW_ANCHOR[0] - anchor_x, PREVIEW_ANCHOR[1] - anchor_y)
    capture.alpha_composite(display, paste)

    display_stats = alpha_stats(display)
    subject_height = display_stats["bbox"][3] - display_stats["bbox"][1]
    ratio = subject_height / float(PREVIEW_ROUTE_TILE_DIAMETER)
    if not 1.3 <= ratio <= 1.5:
        raise RuntimeError(f"Preview cat/tile ratio {ratio:.4f} is outside 1.3-1.5.")

    return capture, {
        "native_dimensions": list(PREVIEW_SIZE),
        "seed_display_canvas": [PREVIEW_DISPLAY_SIZE, PREVIEW_DISPLAY_SIZE],
        "seed_display_alpha_bbox": display_stats["bbox"],
        "seed_display_subject_height_px": subject_height,
        "route_tile_visual_diameter_px": PREVIEW_ROUTE_TILE_DIAMETER,
        "cat_to_route_tile_ratio": ratio,
        "preview_anchor": list(PREVIEW_ANCHOR),
        "preview_paste_origin": list(paste),
        "procedural_cat_cleanup_source_box": list(clean_source_box),
        "procedural_cat_cleanup_destination_box": list(destination_box),
    }


def save_png(image: Image.Image, path: Path) -> None:
    image.save(path, format="PNG", compress_level=9, optimize=False)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", type=Path, required=True)
    args = parser.parse_args()

    root = Path(__file__).resolve().parent
    matte_path = root / "explorer-cat-matte.png"
    seed_path = root / "explorer-cat-seed-192.png"
    preview_path = root / "explorer-cat-preview-720.png"
    preview_small_path = root / "explorer-cat-preview-360.png"

    seed, normalization = normalize_seed(Image.open(matte_path))
    save_png(seed, seed_path)

    preview, preview_meta = build_preview(seed, Image.open(args.capture))
    save_png(preview, preview_path)
    small = preview.resize((360, 640), Image.Resampling.LANCZOS)
    save_png(small, preview_small_path)

    print("normalization", normalization)
    print("preview", preview_meta)
    print("outputs", seed_path, preview_path, preview_small_path)


if __name__ == "__main__":
    main()
