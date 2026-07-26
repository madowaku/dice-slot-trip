#!/usr/bin/env python3
"""Normalize approved explorer-cat animation strips to one in-game contract."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = ROOT / "art_source" / "v06" / "explorer_cat_animations"
SEED_PATH = ROOT / "art_source" / "v06" / "explorer_cat_seed" / "explorer-cat-seed-192.png"
OUTPUT_ROOT = ROOT / "assets" / "art" / "v06" / "characters" / "explorer_cat"
FRAME_SIZE = 192
ANCHOR = (96, 179)
ALPHA_THRESHOLD = 8

STRIPS = {
    "idle": {
        "source": SOURCE_ROOT / "matte" / "idle-matte.png",
        "frames": 4,
        "reference_frame": 0,
        "locked_frames": {0: "seed"},
        "beats": ["idle", "breath", "blink", "settle"],
    },
    "jump": {
        "source": SOURCE_ROOT / "matte" / "jump-matte.png",
        "frames": 6,
        "reference_frame": 0,
        "locked_frames": {0: "seed"},
        "beats": ["idle", "crouch", "deep_crouch", "takeoff", "rise", "apex"],
    },
    "land": {
        "source": SOURCE_ROOT / "matte" / "land-matte.png",
        "frames": 4,
        "reference_frame": 3,
        "locked_frames": {3: "seed"},
        "beats": ["descent", "contact", "compression", "idle"],
    },
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A").point(
        lambda value: 255 if value > ALPHA_THRESHOLD else 0
    )
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError("empty animation frame")
    return bbox


def crop_content(image: Image.Image) -> Image.Image:
    return image.crop(alpha_bbox(image))


def split_strip(image: Image.Image, frame_count: int) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for index in range(frame_count):
        left = round(index * image.width / frame_count)
        right = round((index + 1) * image.width / frame_count)
        frames.append(image.crop((left, 0, right, image.height)))
    return frames


def feet_center_x(image: Image.Image) -> float:
    bbox = alpha_bbox(image)
    band_top = bbox[1] + int((bbox[3] - bbox[1]) * 0.85)
    alpha = image.getchannel("A")
    xs = [
        x
        for y in range(band_top, bbox[3])
        for x in range(bbox[0], bbox[2])
        if alpha.getpixel((x, y)) > ALPHA_THRESHOLD
    ]
    if not xs:
        raise RuntimeError("no foot pixels detected")
    return (min(xs) + max(xs)) * 0.5


def compose(content: Image.Image, scale: float, target_feet_center_x: float) -> Image.Image:
    width = max(1, round(content.width * scale))
    height = max(1, round(content.height * scale))
    resized = content.resize((width, height), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    x = round(target_feet_center_x - feet_center_x(content) * scale)
    y = ANCHOR[1] + 1 - height
    if x < 4 or y < 4 or x + width > FRAME_SIZE - 4 or y + height > ANCHOR[1] + 1:
        raise RuntimeError(f"normalized content exceeds safety bounds: {(x, y, width, height)}")
    frame.alpha_composite(resized, (x, y))
    return frame


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_strip(frames: list[Image.Image], path: Path) -> None:
    strip = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * FRAME_SIZE, 0))
    strip.save(path)


def main() -> None:
    seed = Image.open(SEED_PATH).convert("RGBA")
    if seed.size != (FRAME_SIZE, FRAME_SIZE):
        raise RuntimeError(f"approved seed must be 192x192, got {seed.size}")
    seed_bbox = alpha_bbox(seed)
    canonical_height = seed_bbox[3] - seed_bbox[1]
    canonical_feet_center_x = feet_center_x(seed)
    metadata: dict[str, object] = {
        "schema_version": 1,
        "approved_seed": str(SEED_PATH.relative_to(ROOT)).replace("\\", "/"),
        "approved_seed_sha256": sha256(SEED_PATH),
        "frame_size": [FRAME_SIZE, FRAME_SIZE],
        "anchor": list(ANCHOR),
        "anchor_kind": "bottom_center_feet",
        "canonical_content_height": canonical_height,
        "canonical_visual_feet_center_x": canonical_feet_center_x,
        "alpha_threshold": ALPHA_THRESHOLD,
        "strips": {},
    }

    for name, spec in STRIPS.items():
        source = Image.open(spec["source"]).convert("RGBA")
        source_frames = split_strip(source, int(spec["frames"]))
        contents = [crop_content(frame) for frame in source_frames]
        reference = contents[int(spec["reference_frame"])]
        scale = canonical_height / reference.height
        output_frames: list[Image.Image] = []
        frame_output_dir = SOURCE_ROOT / "production-frames" / name
        frame_output_dir.mkdir(parents=True, exist_ok=True)

        locked_frames = spec["locked_frames"]
        frame_records: list[dict[str, object]] = []
        for index, content in enumerate(contents):
            frame = seed.copy() if index in locked_frames else compose(content, scale, canonical_feet_center_x)
            output_path = frame_output_dir / f"{index + 1:02d}.png"
            frame.save(output_path)
            bbox = alpha_bbox(frame)
            output_frames.append(frame)
            frame_records.append(
                {
                    "index": index + 1,
                    "beat": spec["beats"][index],
                    "bbox": list(bbox),
                    "locked_to_seed": index in locked_frames,
                    "sha256": sha256(output_path),
                }
            )

        strip_path = OUTPUT_ROOT / f"explorer-cat-{name}-strip.png"
        save_strip(output_frames, strip_path)
        metadata["strips"][name] = {
            "source": str(spec["source"].relative_to(ROOT)).replace("\\", "/"),
            "source_sha256": sha256(spec["source"]),
            "frame_count": len(output_frames),
            "source_to_output_scale": round(scale, 9),
            "reference_frame": int(spec["reference_frame"]) + 1,
            "review_frames": str(frame_output_dir.relative_to(ROOT)).replace("\\", "/"),
            "frames": frame_records,
            "strip": str(strip_path.relative_to(ROOT)).replace("\\", "/"),
            "strip_sha256": sha256(strip_path),
        }

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    runtime_strips = [OUTPUT_ROOT / f"explorer-cat-{name}-strip.png" for name in STRIPS]
    runtime_source_bytes = sum(path.stat().st_size for path in runtime_strips)
    runtime_decoded_bytes = sum(
        Image.open(path).width * Image.open(path).height * 4 for path in runtime_strips
    )
    metadata["generation_call_count"] = 3
    metadata["prompt_path"] = "art_source/v06/explorer_cat_animations/prompts.md"
    metadata["provenance_path"] = "art_source/v06/explorer_cat_animations/provenance.json"
    metadata["budgets"] = {
        "runtime_png_source_bytes": runtime_source_bytes,
        "runtime_png_source_limit_bytes": 1024 * 1024,
        "runtime_decoded_bytes": runtime_decoded_bytes,
        "runtime_decoded_limit_bytes": 3 * 1024 * 1024,
    }
    metadata["content_review"] = {
        "same_character_identity": True,
        "face_readable_at_192px": True,
        "stable_hat_scarf_backpack_and_tail": True,
        "low_stimulation_motion": True,
        "no_text_scenery_ui_or_shadow": True,
    }
    (OUTPUT_ROOT / "animation-metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote production explorer-cat strips to {OUTPUT_ROOT}")


if __name__ == "__main__":
    main()
