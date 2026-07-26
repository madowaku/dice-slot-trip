#!/usr/bin/env python3
"""Validate the explorer-cat source, provenance, strips, anchors, and budgets."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = ROOT / "art_source" / "v06" / "explorer_cat_animations"
RUNTIME_ROOT = ROOT / "assets" / "art" / "v06" / "characters" / "explorer_cat"
SEED = ROOT / "art_source" / "v06" / "explorer_cat_seed" / "explorer-cat-seed-192.png"
SEED_SHA = "eccf84a8ca380f2c1ad662868abdce664ad866e6072a0d67b5e00173e63cb1cd"
EXPECTED = {"idle": 4, "jump": 6, "land": 4}
EXPECTED_RAW_SHA = {
    "idle": "66116639cc29f0b09b5b4f51c10f876694a53b0a2d46b42abcf6b9aed836113b",
    "jump": "68157195d85c96ecdc043e61d1049a9a7b8517c55b853506412f21cc23563a96",
    "land": "8d578d075481688a82789d6a917ecdb720b89d927fcb779cfc340bd35164dab9",
}

passes = 0
failures = 0


def check(condition: bool, label: str) -> None:
    global passes, failures
    if condition:
        passes += 1
        print(f"PASS {label}")
    else:
        failures += 1
        print(f"FAIL {label}")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()


def strong_key_fringe_count(image: Image.Image) -> int:
    return sum(
        1
        for red, green, blue, alpha in image.get_flattened_data()
        if 0 < alpha < 255 and green > 180 and red < 80 and blue < 100
    )


def feet_center_x(image: Image.Image, bbox: tuple[int, int, int, int]) -> float:
    band_top = bbox[1] + int((bbox[3] - bbox[1]) * 0.85)
    alpha = image.getchannel("A")
    xs = [
        x
        for y in range(band_top, bbox[3])
        for x in range(bbox[0], bbox[2])
        if alpha.getpixel((x, y)) > 8
    ]
    return (min(xs) + max(xs)) * 0.5


def main() -> None:
    metadata = json.loads((RUNTIME_ROOT / "animation-metadata.json").read_text(encoding="utf-8"))
    provenance = json.loads((SOURCE_ROOT / "provenance.json").read_text(encoding="utf-8"))
    seed = Image.open(SEED).convert("RGBA")
    check(sha256(SEED) == SEED_SHA, "approved seed hash is exact")
    check(seed.size == (192, 192), "approved seed is 192px")
    check(metadata.get("approved_seed_sha256") == SEED_SHA, "metadata binds approved seed")
    check(metadata.get("frame_size") == [192, 192], "metadata frame size")
    check(metadata.get("anchor") == [96, 179], "metadata shared feet anchor")
    canonical_feet_center_x = float(metadata.get("canonical_visual_feet_center_x", -1))
    check(abs(canonical_feet_center_x - feet_center_x(seed, alpha_bbox(seed))) <= 0.01, "metadata preserves seed visual feet center")
    check(metadata.get("generation_call_count") == 3, "three whole-strip ImageGen calls")
    check(len(provenance.get("calls", [])) == 3, "provenance records three calls")
    check((SOURCE_ROOT / "prompts.md").is_file(), "prompt set is stored")

    for name, expected_hash in EXPECTED_RAW_SHA.items():
        raw = SOURCE_ROOT / "raw" / f"{name}-raw.png"
        check(raw.is_file() and sha256(raw) == expected_hash, f"{name} raw source hash")
        matte = Image.open(SOURCE_ROOT / "matte" / f"{name}-matte.png").convert("RGBA")
        check(all(matte.getpixel(point)[3] == 0 for point in [(0, 0), (matte.width - 1, 0), (0, matte.height - 1), (matte.width - 1, matte.height - 1)]), f"{name} matte transparent corners")

    runtime_pngs = sorted(RUNTIME_ROOT.glob("*.png"))
    check([path.name for path in runtime_pngs] == [
        "explorer-cat-idle-strip.png",
        "explorer-cat-jump-strip.png",
        "explorer-cat-land-strip.png",
    ], "runtime pack contains exactly three strips")

    locked = {("idle", 0), ("jump", 0), ("land", 3)}
    for name, frame_count in EXPECTED.items():
        strip = Image.open(RUNTIME_ROOT / f"explorer-cat-{name}-strip.png").convert("RGBA")
        check(strip.size == (192 * frame_count, 192), f"{name} strip dimensions")
        record = metadata["strips"][name]
        check(record["frame_count"] == frame_count, f"{name} metadata frame count")
        for index in range(frame_count):
            frame = strip.crop((index * 192, 0, (index + 1) * 192, 192))
            bbox = alpha_bbox(frame)
            check(bbox is not None, f"{name} frame {index + 1:02d} has content")
            if bbox is None:
                continue
            check(bbox[0] >= 4 and bbox[1] >= 4 and bbox[2] <= 188 and bbox[3] == 180, f"{name} frame {index + 1:02d} safety and feet anchor")
            check(abs(feet_center_x(frame, bbox) - canonical_feet_center_x) <= 1, f"{name} frame {index + 1:02d} visual feet alignment")
            check(strong_key_fringe_count(frame) <= 6, f"{name} frame {index + 1:02d} chroma fringe bound")
            if (name, index) in locked:
                check(frame.tobytes() == seed.tobytes(), f"{name} frame {index + 1:02d} pixel-locks approved seed")

    budgets = metadata["budgets"]
    source_bytes = sum(path.stat().st_size for path in runtime_pngs)
    decoded_bytes = sum(Image.open(path).width * Image.open(path).height * 4 for path in runtime_pngs)
    check(source_bytes == budgets["runtime_png_source_bytes"] <= budgets["runtime_png_source_limit_bytes"], "runtime source budget <=1 MiB")
    check(decoded_bytes == budgets["runtime_decoded_bytes"] <= budgets["runtime_decoded_limit_bytes"], "runtime decoded budget <=3 MiB")
    review = metadata["content_review"]
    check(all(review.values()), "identity, face, accessories, low-motion, and no-UI review recorded")

    print(f"V06_CAT_ASSET_VALIDATION passes={passes} failures={failures}")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
