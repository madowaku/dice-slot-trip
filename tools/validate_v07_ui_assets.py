#!/usr/bin/env python3
"""Validate provenance and normalization contracts for v0.7 UI raster assets."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[1]
PROVENANCE_PATH = ROOT / "assets/art/v07/ui/dark-walnut-leather.provenance.json"
EXPECTED_PROMPT = """Use case: ui-mockup
Asset type: seamless material texture for a premium mobile game UI
Primary request: Create a square, perfectly tileable dark warm brown explorer satchel leather texture for Dice Slot Trip. Fine natural grain, softly worn but clean, subtle tonal variation, premium handcrafted field-instrument feeling.
Composition: uniform edge-to-edge material, no objects, no frame, no border, no seams, no stitching, no corners, no directional lighting hotspot.
Color palette: very dark warm walnut and oxblood brown, low saturation, compatible with parchment, teal enamel and restrained antique brass.
Lighting/mood: diffuse even studio illumination baked into the material, low contrast so UI text remains readable over panels.
Target: 1024 x 1024 square texture, visually seamless on all four edges.
Constraints: texture only, no text, no symbols, no logo, no watermark, no buttons, no metal, no parchment, no cast shadows."""


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


def main() -> int:
    failures: list[str] = []
    check(PROVENANCE_PATH.is_file(), "provenance file exists", failures)
    if failures:
        return 1

    data = json.loads(PROVENANCE_PATH.read_text(encoding="utf-8"))
    runtime_path = ROOT / data["runtime_path"]
    source_path = ROOT / data["source_path"]
    check(data.get("schema_version") == 1, "schema version is supported", failures)
    check(data.get("asset_id") == "dark-walnut-leather", "asset id is canonical", failures)
    check(data["generation"].get("provider") == "OpenAI built-in ImageGen", "generation provider is explicit", failures)
    check(data["generation"].get("generated_on") == "2026-07-19", "generation date is explicit", failures)
    check(data["generation"].get("prompt") == EXPECTED_PROMPT, "verbatim generation prompt is preserved", failures)
    check(runtime_path.is_file(), "runtime texture exists", failures)
    check(source_path.is_file(), "workspace source evidence exists", failures)
    if not runtime_path.is_file() or not source_path.is_file():
        return 1

    runtime_hash = sha256(runtime_path)
    source_hash = sha256(source_path)
    check(runtime_hash == data["runtime"]["sha256"], "runtime SHA256 matches provenance", failures)
    check(source_hash == data["source"]["sha256"], "source SHA256 matches provenance", failures)
    check(runtime_hash == source_hash, "runtime is an exact source copy", failures)
    check(runtime_path.stat().st_size == data["runtime"]["bytes"], "runtime byte size matches provenance", failures)
    check(source_path.stat().st_size == data["source"]["bytes"], "source byte size matches provenance", failures)

    with Image.open(runtime_path) as image:
        check(list(image.size) == [data["runtime"]["width"], data["runtime"]["height"]], "runtime dimensions match provenance", failures)
        check(image.mode == data["runtime"]["mode"] == "RGB", "runtime mode is RGB", failures)
        rgb = image.convert("RGB")
        width, height = rgb.size
        left_right = ImageStat.Stat(ImageChops.difference(rgb.crop((0, 0, 1, height)), rgb.crop((width - 1, 0, width, height)))).mean
        top_bottom = ImageStat.Stat(ImageChops.difference(rgb.crop((0, 0, width, 1)), rgb.crop((0, height - 1, width, height)))).mean
        threshold = float(data["edge_evidence"]["max_allowed_channel_mean"])
        check(max(left_right + top_bottom) <= threshold, "opposite-edge low-seam evidence stays within threshold", failures)

    normalization = data["normalization"]
    check(normalization == {
        "method": "exact-byte-copy",
        "resized": False,
        "cropped": False,
        "recompressed": False,
        "color_converted": False,
    }, "normalization contract records an unmodified byte copy", failures)
    semantic_review = data["usage"]["semantic_review"]
    check(all(semantic_review.get(key) is True for key in ("no_text", "no_logo", "no_symbols", "no_watermark")), "manual semantic review flags are complete", failures)
    check((runtime_path.with_suffix(runtime_path.suffix + ".import")).is_file(), "Godot import sidecar exists", failures)

    print(f"V07_UI_ASSET_VALIDATION failures={len(failures)}")
    if failures:
        for failure in failures:
            print(f"  - {failure}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
