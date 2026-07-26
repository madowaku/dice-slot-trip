#!/usr/bin/env python3
"""Validate the normalized NORMAL tile-kind icon provenance contract."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROVENANCE_PATH = ROOT / "assets/art/v06/tile_kind_icons/normal-trail-stones.provenance.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def check(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"PASS {message}")
    else:
        failures.append(message)
        print(f"FAIL {message}")


def alpha_bbox(path: Path) -> tuple[int, int, int, int] | None:
    with Image.open(path) as image:
        return image.convert("RGBA").getchannel("A").getbbox()


def main() -> int:
    failures: list[str] = []
    check(PROVENANCE_PATH.is_file(), "NORMAL trail-stone provenance exists", failures)
    if failures:
        print("V07_TILE_ICON_VALIDATION failures=1")
        return 1

    data = json.loads(PROVENANCE_PATH.read_text(encoding="utf-8"))
    check(data.get("schema_version") == 1, "schema version is supported", failures)
    check(data.get("asset_id") == "normal-trail-stones", "asset id is canonical", failures)
    check(data.get("kind") == "NORMAL", "kind is NORMAL", failures)
    check(data.get("generation", {}).get("provider") == "OpenAI built-in ImageGen", "generation provider is explicit", failures)
    check(bool(data.get("generation", {}).get("prompt")), "verbatim generation prompt is preserved", failures)

    paths = {
        "source": ROOT / data.get("source_path", ""),
        "alpha": ROOT / data.get("alpha_path", ""),
        "runtime": ROOT / data.get("runtime_path", ""),
    }
    for role, path in paths.items():
        check(path.is_file(), f"{role} evidence exists", failures)
    if any(not path.is_file() for path in paths.values()):
        print(f"V07_TILE_ICON_VALIDATION failures={len(failures)}")
        return 1

    for role, path in paths.items():
        record = data["source" if role == "source" else "alpha_cleanup" if role == "alpha" else "runtime"]
        check(sha256(path) == record.get("sha256"), f"{role} SHA256 matches provenance", failures)
        check(path.stat().st_size == record.get("bytes"), f"{role} byte size matches provenance", failures)
        with Image.open(path) as image:
            check(list(image.size) == [record.get("width", image.width), record.get("height", image.height)], f"{role} dimensions match provenance", failures)
            check(image.mode == record.get("mode"), f"{role} mode matches provenance", failures)

    normalization = data.get("normalization", {})
    check(normalization.get("method") == "alpha-bounds-crop-uniform-scale-maxfilter-3-white-mask", "normalization method is explicit", failures)
    check(normalization.get("optical_envelope") == 104, "optical envelope is 104px", failures)
    check(normalization.get("canvas") == [128, 128], "runtime canvas is 128x128", failures)
    check(normalization.get("resized_uniformly") is True and normalization.get("cropped_to_alpha_bounds") is True, "uniform scale and alpha crop are recorded", failures)
    check(normalization.get("color_converted_to_white_mask") is True and normalization.get("runtime_text_or_topology_baked") is False, "mask conversion and no baked topology are recorded", failures)

    bbox = alpha_bbox(paths["runtime"])
    check(bbox == (18, 12, 110, 116), "runtime alpha bounds match optical normalization", failures)
    if bbox is not None:
        check(90 <= bbox[2] - bbox[0] <= 108 and 90 <= bbox[3] - bbox[1] <= 108, "runtime glyph stays within the optical envelope", failures)

    review = data.get("review", {})
    for key in ("neutral_walkable_semantics", "no_text", "no_logo", "no_watermark", "no_arrow", "no_warning_or_risk_symbol"):
        check(review.get(key) is True, f"semantic review flag {key} is true", failures)
    check(data.get("license", {}).get("type") == "project-owned AI-generated asset", "license ownership is explicit", failures)
    check("style reference only" in data.get("license", {}).get("kenney_reference", ""), "Kenney is not falsely claimed as source", failures)
    check(paths["runtime"].with_suffix(paths["runtime"].suffix + ".import").is_file(), "Godot import sidecar exists", failures)

    print(f"V07_TILE_ICON_VALIDATION failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
