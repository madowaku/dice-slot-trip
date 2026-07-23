#!/usr/bin/env python3
"""Validate v0.8 ImageGen item and skill card provenance."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PROVENANCE = ROOT / "assets/art/v08/cards/cards.provenance.json"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    failures: list[str] = []

    def check(value: bool, label: str) -> None:
        print(f"{'PASS' if value else 'FAIL'} {label}")
        if not value:
            failures.append(label)

    check(PROVENANCE.is_file(), "card provenance exists")
    if failures:
        return 1
    data = json.loads(PROVENANCE.read_text(encoding="utf-8"))
    check(data.get("provider") == "OpenAI built-in ImageGen", "generator is explicit")
    check(data.get("license") == "project-owned AI-generated assets", "license is explicit")
    assets = data.get("assets", [])
    check([entry.get("asset_id") for entry in assets] == ["item-card", "skill-card"], "exact item and skill card set")
    for entry in assets:
        asset_id = entry.get("asset_id", "unknown")
        source = ROOT / entry.get("source_path", "")
        runtime = ROOT / entry.get("runtime_path", "")
        check(source.is_file(), f"{asset_id} source exists")
        check(runtime.is_file(), f"{asset_id} runtime exists")
        if not source.is_file() or not runtime.is_file():
            continue
        check(digest(source) == entry.get("source_sha256"), f"{asset_id} source hash matches")
        check(digest(runtime) == entry.get("runtime_sha256"), f"{asset_id} runtime hash matches")
        check(bool(entry.get("prompt")) and "no text" in entry.get("prompt", ""), f"{asset_id} verbatim prompt and no-text rule retained")
        with Image.open(source) as image:
            check(image.size == (1254, 1254) and image.mode == "RGB", f"{asset_id} source dimensions and mode")
        with Image.open(runtime) as image:
            check(image.size == (512, 512) and image.mode == "RGB", f"{asset_id} runtime dimensions and mode")
        check(runtime.with_suffix(runtime.suffix + ".import").is_file(), f"{asset_id} Godot import exists")
    check(data.get("normalization", {}).get("method") == "Lanczos resize only", "normalization method is explicit")
    check(data.get("normalization", {}).get("baked_text") is False, "runtime contains no generated UI text")
    print(f"V08_CARD_VALIDATION failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
