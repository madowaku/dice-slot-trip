"""Strict, read-only validator for the v0.6 daylight-atlas / boss asset pack."""

from __future__ import annotations

import hashlib
import json
import math
import sys
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
RUNTIME_ROOT = ROOT / "assets" / "art" / "v06"
MANIFEST_PATH = RUNTIME_ROOT / "manifest.json"
PROVENANCE_PATH = ROOT / "art_source" / "v06" / "atlas_boss" / "provenance.json"
PIPELINE_PATH = ROOT / "art_source" / "v06" / "atlas_boss" / "pipeline.json"
VISUAL_REVIEW_PATH = ROOT / "art_source" / "v06" / "atlas_boss" / "visual-review.md"
SPHINX_SOURCE = ROOT / "assets" / "art" / "bosses" / "sleepy-sphinx.png"
SPHINX_PROMPT = ROOT / "assets" / "art" / "bosses" / "sleepy-sphinx.prompt.txt"
EXPECTED_SOURCE_SHA = "27759bf53575c42a8db3a700bcfb11dfb37e1e19885f32e1f271c052aaf70f0e"
EXPECTED_SOURCE_BYTES = 1_954_756
EXPECTED_SOURCE_SIZE = (1254, 1254)
MANDATED_MASK = "assets/art/v06/boss/night-vignette.png"

EXPECTED: dict[str, dict[str, Any]] = {
    "parchment_base": {
        "path": "assets/art/v06/atlas/parchment-base.png",
        "size": (1024, 1024),
        "mode": "RGB",
        "cells": (1, (1, 1), (1024, 1024), ("base",)),
        "anchor": None,
        "residency": "normal",
        "lighting": "daylight_neutral",
        "import": (2, False, False),
    },
    "cairo_cartography_ink": {
        "path": "assets/art/v06/atlas/cairo-cartography-ink.png",
        "size": (1024, 1024),
        "mode": "RGBA",
        "cells": (1, (1, 1), (1024, 1024), ("ink",)),
        "anchor": None,
        "residency": "normal",
        "lighting": "daylight_neutral",
        "import": (2, False, True),
    },
    "raised_route_tiles": {
        "path": "assets/art/v06/atlas/raised-route-tiles.png",
        "size": (512, 128),
        "mode": "RGBA",
        "cells": (4, (4, 1), (128, 128), ("main", "bypass", "loop", "current")),
        "anchor": (64, 118),
        "baseline": 118,
        "margin": 5,
        "residency": "normal",
        "lighting": "daylight_neutral",
        "import": (0, False, True),
    },
    "gold_boss_gate": {
        "path": "assets/art/v06/boss/gold-boss-gate.png",
        "size": (512, 256),
        "mode": "RGBA",
        "cells": (2, (2, 1), (256, 256), ("sleeping_unlit", "awakened_warm_gold")),
        "anchor": (128, 246),
        "baseline": 246,
        "margin": 8,
        "residency": "normal_and_boss",
        "lighting": "awakened_cell_boss_only",
        "import": (0, False, True),
    },
    "sleepy_sphinx": {
        "path": "assets/art/v06/boss/sleepy-sphinx.png",
        "size": (512, 512),
        "mode": "RGBA",
        "cells": (1, (1, 1), (512, 512), ("sleeping",)),
        "anchor": (256, 485),
        "residency": "boss_only",
        "lighting": "boss_only",
        "import": (0, False, True),
    },
    "night_vignette": {
        "path": MANDATED_MASK,
        "size": (720, 1280),
        "mode": "L",
        "cells": (1, (1, 1), (720, 1280), ("mask",)),
        "anchor": None,
        "residency": "boss_only",
        "lighting": "boss_only",
        "import": (0, False, False),
    },
    "lantern_glow": {
        "path": "assets/art/v06/effects/lantern-glow.png",
        "size": (512, 256),
        "mode": "RGBA",
        "cells": (4, (4, 1), (128, 256), ("quiet", "full", "triple_peak", "settle")),
        "anchor": (64, 244),
        "baseline": 244,
        "margin": 4,
        "residency": "boss_only",
        "lighting": "boss_triple_enhanced_only",
        "import": (0, False, True),
    },
}

FAILURES: list[str] = []
PASSES: list[str] = []


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(condition: bool, label: str) -> None:
    if condition:
        PASSES.append(label)
    else:
        FAILURES.append(label)


def read_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        FAILURES.append(f"read JSON {path.relative_to(ROOT)}: {error}")
        return {}


def res_to_path(value: str) -> Path:
    if not value.startswith("res://"):
        raise ValueError(f"not a res:// path: {value}")
    return ROOT / value.removeprefix("res://")


def alpha_stats(image: Image.Image) -> dict[str, Any]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    histogram = alpha.histogram()
    transparent = histogram[0]
    opaque = histogram[255]
    partial = rgba.width * rgba.height - transparent - opaque
    partial_pixels = [pixel for pixel in rgba.get_flattened_data() if 0 < pixel[3] < 255]
    green_dominant = sum(1 for r, g, b, _a in partial_pixels if g > r + 28 and g > b + 28)
    key_like = [
        (r, g, b, a)
        for r, g, b, a in partial_pixels
        if a <= 16 and g >= 180 and g > r + 64 and g > b + 64 and r <= 80 and b <= 80
    ]
    return {
        "transparent_pixels": transparent,
        "partial_pixels": partial,
        "opaque_pixels": opaque,
        "coverage_ratio": round((opaque + partial) / (rgba.width * rgba.height), 8),
        "green_dominant_partial_pixels": green_dominant,
        "green_dominant_partial_ratio": round(green_dominant / max(1, partial), 8),
        "low_alpha_key_like_pixels": len(key_like),
        "low_alpha_key_like_alpha_sum": sum(pixel[3] for pixel in key_like),
        "corner_alpha": [
            alpha.getpixel((0, 0)),
            alpha.getpixel((rgba.width - 1, 0)),
            alpha.getpixel((0, rgba.height - 1)),
            alpha.getpixel((rgba.width - 1, rgba.height - 1)),
        ],
    }


def content_bbox(cell: Image.Image, threshold: int = 4) -> tuple[int, int, int, int] | None:
    alpha = cell.convert("RGBA").getchannel("A")
    return alpha.point(lambda value: 255 if value > threshold else 0).getbbox()


def validate_inventory(manifest: dict[str, Any]) -> None:
    records = manifest.get("assets", [])
    check(isinstance(records, list) and len(records) == 7, "manifest enumerates exactly seven runtime assets")
    paths = [record.get("path", "") for record in records if isinstance(record, dict)]
    check(len(paths) == len(set(paths)), "manifest asset paths are unique")
    expected_paths = {"res://" + spec["path"] for spec in EXPECTED.values()}
    check(set(paths) == expected_paths, "manifest paths exactly match the production pack")
    # The atlas/boss pack remains an exact seven-file contract. Character
    # animation strips and normalized tile-kind glyphs are separately validated
    # runtime packs under assets/art/v06 and must not be mistaken for
    # environment-pack extras.
    separate_pack_roots = {"characters", "tile_kind_icons"}
    actual_pngs = {
        path.relative_to(ROOT).as_posix()
        for path in RUNTIME_ROOT.rglob("*.png")
        if path.relative_to(RUNTIME_ROOT).parts[0] not in separate_pack_roots
    }
    check(actual_pngs == {spec["path"] for spec in EXPECTED.values()}, "runtime root contains no missing or extra PNGs")
    forbidden_parts = {"raw", "qc", "matte", "preview", "previews", "source", "contact"}
    leaks = [path for path in RUNTIME_ROOT.rglob("*") if path.is_file() and forbidden_parts.intersection(part.lower() for part in path.parts)]
    check(not leaks, "no raw, matte, QC, preview, source, or contact artifact leaks under assets")
    check((ROOT / "art_source" / ".gdignore").is_file(), "art_source raw/QC root remains protected by .gdignore")


def validate_asset_records(manifest: dict[str, Any]) -> tuple[list[dict[str, Any]], dict[str, Image.Image]]:
    records = {record.get("id"): record for record in manifest.get("assets", []) if isinstance(record, dict)}
    images: dict[str, Image.Image] = {}
    ordered: list[dict[str, Any]] = []
    forbidden_tokens = {"exit", "ready", "hud", "label", "number", "dice", "die", "lap", "roll"}
    for asset_id, expected in EXPECTED.items():
        record = records.get(asset_id)
        check(record is not None, f"manifest includes {asset_id}")
        if record is None:
            continue
        ordered.append(record)
        path = ROOT / expected["path"]
        check(path.is_file(), f"{asset_id} file exists")
        if not path.is_file():
            continue
        image = Image.open(path)
        images[asset_id] = image.copy()
        check(image.size == expected["size"], f"{asset_id} dimensions are exact")
        check(image.mode == expected["mode"], f"{asset_id} mode is {expected['mode']}")
        check(tuple(record.get("dimensions", [])) == expected["size"], f"{asset_id} manifest dimensions agree")
        check(record.get("mode") == expected["mode"], f"{asset_id} manifest mode agrees")
        check(record.get("sha256") == sha256(path), f"{asset_id} SHA-256 matches")
        check(record.get("source_bytes") == path.stat().st_size, f"{asset_id} source-byte count matches")
        channels = {"L": 1, "RGB": 3, "RGBA": 4}[image.mode]
        check(record.get("decoded_byte_estimate") == image.width * image.height * channels, f"{asset_id} decoded-byte estimate matches")
        cells = record.get("cells", {})
        count, layout, size, ids = expected["cells"]
        check(cells.get("count") == count, f"{asset_id} cell count")
        check(tuple(cells.get("layout", [])) == layout, f"{asset_id} cell layout")
        check(tuple(cells.get("size", [])) == size, f"{asset_id} cell size")
        check(tuple(cells.get("ids", [])) == ids, f"{asset_id} cell order and language")
        check(record.get("residency") == expected["residency"], f"{asset_id} residency classification")
        check(record.get("lighting_scope") == expected["lighting"], f"{asset_id} lighting scope")
        import_intent = record.get("import_intent", {})
        import_mode, import_mipmaps, import_fix_alpha = expected["import"]
        expected_compression = "vram_compressed_etc2_astc" if import_mode == 2 else ("lossless_l8" if asset_id == "night_vignette" else "lossless")
        check(import_intent.get("compression") == expected_compression, f"{asset_id} manifest import compression intent")
        check(import_intent.get("godot_compress_mode") == import_mode, f"{asset_id} manifest Godot compression mode")
        check(import_intent.get("mipmaps") == import_mipmaps, f"{asset_id} manifest mipmap intent")
        check(import_intent.get("fix_alpha_border") == import_fix_alpha, f"{asset_id} manifest alpha-border intent")
        check(import_intent.get("filter") is True, f"{asset_id} manifest linear-filter intent")
        anchor = record.get("anchor")
        if expected["anchor"] is None:
            check(anchor is None, f"{asset_id} has no sprite anchor")
        else:
            check(tuple(anchor.get("point", [])) == expected["anchor"], f"{asset_id} anchor is exact")
            check(cells.get("common_baseline_y") == expected.get("baseline"), f"{asset_id} common baseline metadata")
        review = record.get("content_review", {})
        check(review.get("no_baked_text") is True, f"{asset_id} no-baked-text review")
        check(review.get("no_baked_numbers") is True, f"{asset_id} no-baked-numbers review")
        check(review.get("no_baked_exit_or_ui") is True, f"{asset_id} no-baked-EXIT/UI review")
        name_tokens = set(asset_id.lower().replace("-", "_").split("_")) | set(path.stem.lower().replace("-", "_").split("_"))
        check(not forbidden_tokens.intersection(name_tokens), f"{asset_id} filename/id has no route-text or UI identifier")
        if image.mode == "RGBA":
            stats = alpha_stats(image)
            check(stats["transparent_pixels"] > 0, f"{asset_id} has transparent background")
            check(stats["corner_alpha"] == [0, 0, 0, 0], f"{asset_id} has four transparent corners")
            check(stats["low_alpha_key_like_pixels"] == 0, f"{asset_id} has no low-alpha chroma-key fringe")
            check(record.get("alpha") == stats, f"{asset_id} alpha statistics match manifest")
        elif asset_id == "parchment_base":
            check("A" not in image.getbands(), "parchment is opaque without alpha channel")
        elif asset_id == "night_vignette":
            check(image.getbands() == ("L",), "night vignette is single-channel L8")
    return ordered, images


def validate_cell_geometry(images: dict[str, Image.Image]) -> None:
    for asset_id in ["raised_route_tiles", "gold_boss_gate", "lantern_glow"]:
        image = images.get(asset_id)
        if image is None:
            continue
        expected = EXPECTED[asset_id]
        count, _layout, cell_size, _ids = expected["cells"]
        baseline = expected["baseline"]
        margin = expected["margin"]
        bboxes: list[tuple[int, int, int, int]] = []
        for index in range(count):
            cell = image.crop((index * cell_size[0], 0, (index + 1) * cell_size[0], cell_size[1]))
            bbox = content_bbox(cell)
            check(bbox is not None, f"{asset_id} cell {index} has alpha content")
            if bbox is None:
                continue
            bboxes.append(bbox)
            check(bbox[3] == baseline, f"{asset_id} cell {index} lands on common baseline")
            check(bbox[0] >= margin and cell_size[0] - bbox[2] >= margin, f"{asset_id} cell {index} horizontal safety margin")
            check(bbox[1] >= margin and cell_size[1] - bbox[3] >= margin, f"{asset_id} cell {index} vertical safety margin")
            center = (bbox[0] + bbox[2]) / 2.0
            check(abs(center - cell_size[0] / 2.0) <= 1.5, f"{asset_id} cell {index} bottom-center alignment")
        if asset_id == "gold_boss_gate" and len(bboxes) == 2:
            sizes = [(box[2] - box[0], box[3] - box[1]) for box in bboxes]
            check(sizes[0] == sizes[1], "gate states have identical normalized silhouette bounds")


def validate_background_and_mask(images: dict[str, Image.Image]) -> None:
    parchment = images.get("parchment_base")
    if parchment is not None:
        check(parchment.crop((0, 0, 1, 1024)).tobytes() == parchment.crop((1023, 0, 1024, 1024)).tobytes(), "parchment left/right edges match exactly")
        check(parchment.crop((0, 0, 1024, 1)).tobytes() == parchment.crop((0, 1023, 1024, 1024)).tobytes(), "parchment top/bottom edges match exactly")
        gray = parchment.convert("L")
        histogram = gray.histogram()
        total = parchment.width * parchment.height
        mean = sum(index * count for index, count in enumerate(histogram)) / total
        variance = sum(((index - mean) ** 2) * count for index, count in enumerate(histogram)) / total
        check(175 <= mean <= 235 and math.sqrt(variance) <= 28, "parchment luminance is warm and low-stimulation")
    mask = images.get("night_vignette")
    if mask is not None:
        check(mask.getextrema()[0] >= 0 and mask.getextrema()[1] <= 255, "night mask is valid L8 range")
        edge_mean = sum(mask.getpixel(point) for point in [(0, 0), (719, 0), (0, 1279), (719, 1279)]) / 4
        center = mask.getpixel((360, 540))
        hud = mask.getpixel((360, 72))
        tray = mask.getpixel((360, 1040))
        check(edge_mean - center >= 100, "night mask preserves center readability")
        check(edge_mean - hud >= 60, "night mask preserves HUD readability")
        check(edge_mean - tray >= 100, "night mask preserves tray readability")


def validate_provenance(manifest: dict[str, Any]) -> None:
    provenance = read_json(PROVENANCE_PATH)
    pipeline = read_json(PIPELINE_PATH)
    check(manifest.get("provenance_path") == "res://art_source/v06/atlas_boss/provenance.json", "manifest provenance path is exact")
    check(manifest.get("provenance_sha256") == sha256(PROVENANCE_PATH), "manifest provenance SHA-256 matches")
    check(provenance.get("generation_call_count") == 5 and len(provenance.get("generation_calls", [])) == 5, "provenance records exactly five ImageGen calls")
    check(provenance.get("model_mode") == "built_in_image_gen_default", "provenance records built-in ImageGen mode")
    for call in provenance.get("generation_calls", []):
        prompt_path = ROOT / call.get("prompt_path", "")
        raw_path = ROOT / call.get("raw_workspace_copy", "")
        check(call.get("accepted") is True and call.get("retry_or_competing_variant") is False, f"call {call.get('call')} is the sole accepted source")
        check(prompt_path.is_file() and call.get("prompt_sha256") == sha256(prompt_path), f"call {call.get('call')} exact prompt hash")
        if prompt_path.is_file():
            check(call.get("prompt_exact") == prompt_path.read_text(encoding="utf-8").rstrip("\n"), f"call {call.get('call')} exact prompt text")
        check(raw_path.is_file() and call.get("raw_sha256") == sha256(raw_path), f"call {call.get('call')} raw-source hash")
    references = provenance.get("reference_inputs", [])
    selected = [item for item in references if item.get("path") == "docs/design/v06/d-selected-atlas-living-map.png"]
    check(len(selected) == 1 and selected[0].get("generator_input") is True and "style_and_palette_reference_only" in selected[0].get("role", ""), "selected target role is style/palette only")
    review = provenance.get("content_review", {})
    for key in [
        "reviewed_all_raw_mattes_runtime_contact_and_previews",
        "no_text_numbers_exit_ui_labels_die_or_explorer_cat_in_generated_runtime_layers",
        "no_route_or_node_topology_in_parchment_or_cairo_ink",
        "c_lighting_absent_from_daylight_assets_and_daylight_preview",
        "c_lighting_confined_to_awakened_gate_lantern_vignette_and_boss_preview",
        "chroma_cleanup_preserves_silhouettes",
    ]:
        check(review.get(key) is True, f"provenance review flag {key}")
    check(review.get("native_transparency_fallback_used") is False and review.get("concept_or_document_crop_used") is False, "no native/CLI fallback or concept crop")
    chroma = pipeline.get("chroma_helper", {})
    check(chroma.get("requested_key") == "#00FF00", "pipeline records requested #00FF00 key")
    check(chroma.get("native_transparency_or_cli_fallback_used") is False, "pipeline records no native/CLI transparency fallback")
    check(chroma.get("edge_contract_retry_used") is False, "pipeline records no edge-contract retry")
    check(set(chroma.get("detected_keys", {})) == {"ink", "tiles", "gate", "lantern"}, "pipeline records all detected chroma keys")
    for name, fact in pipeline.get("matte_sources", {}).items():
        stats = fact.get("alpha", {})
        check(stats.get("corner_alpha") == [0, 0, 0, 0], f"{name} matte corners are transparent")
        check(stats.get("green_dominant_partial_pixels") == 0, f"{name} matte has no green fringe")
    check(VISUAL_REVIEW_PATH.is_file() and "QC evidence only" in VISUAL_REVIEW_PATH.read_text(encoding="utf-8"), "visual-review markdown exists and declares QC-only role")


def validate_source_guard(manifest: dict[str, Any]) -> None:
    check(SPHINX_SOURCE.is_file(), "immutable sphinx source exists")
    if not SPHINX_SOURCE.is_file():
        return
    image = Image.open(SPHINX_SOURCE)
    check(sha256(SPHINX_SOURCE) == EXPECTED_SOURCE_SHA, "immutable sphinx source SHA unchanged")
    check(SPHINX_SOURCE.stat().st_size == EXPECTED_SOURCE_BYTES, "immutable sphinx source byte size unchanged")
    check(image.size == EXPECTED_SOURCE_SIZE and image.mode == "RGBA", "immutable sphinx source dimensions/mode unchanged")
    guard = manifest.get("immutable_source_guard", {})
    check(guard.get("path") == "res://assets/art/bosses/sleepy-sphinx.png", "source guard path exact")
    check(guard.get("sha256") == EXPECTED_SOURCE_SHA and guard.get("source_bytes") == EXPECTED_SOURCE_BYTES, "manifest source guard hash/bytes exact")
    check(tuple(guard.get("dimensions", [])) == EXPECTED_SOURCE_SIZE, "manifest source guard dimensions exact")
    check(guard.get("source_prompt_path") == "res://assets/art/bosses/sleepy-sphinx.prompt.txt", "source prompt provenance path exact")
    check(SPHINX_PROMPT.is_file() and guard.get("source_prompt_sha256") == sha256(SPHINX_PROMPT), "source prompt provenance hash exact")
    check(guard.get("is_third_party") is False, "sphinx derivative is not falsely claimed as third-party")


def validate_budgets(manifest: dict[str, Any], records: list[dict[str, Any]]) -> None:
    budgets = manifest.get("budgets", {})
    normal = sum(record.get("decoded_byte_estimate", 0) for record in records if record.get("residency") in {"normal", "normal_and_boss"})
    boss = sum(record.get("decoded_byte_estimate", 0) for record in records)
    source = sum(record.get("source_bytes", 0) for record in records)
    check(normal == budgets.get("normal_resident_decoded_bytes") and normal <= 14 * 1024 * 1024, "normal decoded residency <=14 MiB and exact")
    check(boss == budgets.get("boss_peak_decoded_bytes") and boss <= 16 * 1024 * 1024, "boss peak decoded residency <=16 MiB and exact")
    check(source == budgets.get("runtime_png_source_bytes") and source <= 8 * 1024 * 1024, "runtime PNG/source bytes <=8 MiB and exact")
    exception = budgets.get("mandated_screen_mask_exception", {})
    check(exception == {"path": "res://" + MANDATED_MASK, "dimensions": [720, 1280], "reason": "exact viewport-sized single-channel contract", "applies_to_any_other_asset": False}, "mandated screen-mask exception is fixed to one path and exact dimensions")
    general_edges = [max(record["dimensions"]) for record in records if record.get("path") != "res://" + MANDATED_MASK]
    check(max(general_edges) <= 1152 and budgets.get("maximum_general_runtime_edge_px") == max(general_edges), "all general runtime assets obey 1152px edge cap")
    mask_records = [record for record in records if record.get("path") == "res://" + MANDATED_MASK]
    check(len(mask_records) == 1 and mask_records[0].get("dimensions") == [720, 1280] and mask_records[0].get("mode") == "L", "only exact L8 night mask uses edge exception")


def parse_param(text: str, key: str) -> str | None:
    prefix = key + "="
    for line in text.splitlines():
        if line.startswith(prefix):
            return line[len(prefix):].strip().strip('"')
    return None


def validate_imports() -> None:
    for asset_id, expected in EXPECTED.items():
        png = ROOT / expected["path"]
        sidecar = Path(str(png) + ".import")
        check(sidecar.is_file(), f"{asset_id} Godot import sidecar exists")
        if not sidecar.is_file():
            continue
        text = sidecar.read_text(encoding="utf-8")
        mode, mipmaps, fix_alpha = expected["import"]
        check(parse_param(text, "compress/mode") == str(mode), f"{asset_id} import compression mode")
        check(parse_param(text, "mipmaps/generate") == str(mipmaps).lower(), f"{asset_id} import mipmaps disabled")
        check(parse_param(text, "process/fix_alpha_border") == str(fix_alpha).lower(), f"{asset_id} import alpha-border intent")
        check(parse_param(text, "source_file") == "res://" + expected["path"], f"{asset_id} import source path")
        if mode == 2:
            check('"vram_texture": true' in text, f"{asset_id} import is marked VRAM-compressed")
            check("path.etc2=" in text, f"{asset_id} import includes ETC2 platform payload")
        else:
            check('"vram_texture": false' in text, f"{asset_id} import is marked lossless/non-VRAM")
    project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
    check("textures/vram_compression/import_etc2_astc=true" in project_text, "project enables ETC2/ASTC VRAM import")


def validate_qc() -> None:
    qc = ROOT / "art_source" / "v06" / "atlas_boss" / "qc"
    expected = {
        "daylight-pack-preview-720x1280.png": (720, 1280),
        "daylight-pack-preview-360x640.png": (360, 640),
        "boss-lit-pack-preview-720x1280.png": (720, 1280),
        "boss-lit-pack-preview-360x640.png": (360, 640),
        "tiles-cell-contact.png": (1024, 256),
        "gate-cell-contact.png": (1024, 512),
        "lantern-cell-contact.png": (1024, 512),
        "alpha-fringe-checks.png": (1024, 768),
        "runtime-pack-contact-sheet.png": (1024, 1024),
    }
    actual = {path.name for path in qc.glob("*.png")}
    check(actual == set(expected), "QC folder has exact preview/contact/fringe inventory")
    for name, size in expected.items():
        path = qc / name
        check(path.is_file(), f"QC artifact {name} exists")
        if not path.is_file():
            continue
        image = Image.open(path)
        check(image.size == size, f"QC artifact {name} dimensions")
        check(image.info.get("artifact_role") == "QC_PREVIEW_NOT_RUNTIME" and image.info.get("runtime_wiring") == "false", f"QC artifact {name} metadata label")
    for prefix in ["daylight-pack-preview", "boss-lit-pack-preview"]:
        large = Image.open(qc / f"{prefix}-720x1280.png").convert("RGB")
        small = Image.open(qc / f"{prefix}-360x640.png").convert("RGB")
        expected_small = large.resize((360, 640), Image.Resampling.LANCZOS)
        check(ImageChops.difference(small, expected_small).getbbox() is None, f"{prefix} 360x640 is exact Lanczos derivative")


def validate_pack_policy(manifest: dict[str, Any]) -> None:
    check(manifest.get("schema_version") == 1 and manifest.get("pack_id") == "v06_daylight_atlas_boss_climax_01", "manifest schema and pack id")
    check(manifest.get("runtime_root") == "res://assets/art/v06" and manifest.get("runtime_wiring") is True, "manifest declares normalized pack with runtime wiring")
    check(manifest.get("generation_call_count") == 5, "manifest records five generation calls")
    policy = manifest.get("pack_policy", {})
    check(policy == {"runtime_png_count": 7, "raw_or_qc_under_runtime_root": False, "background_contains_runtime_topology": False, "daylight_contains_boss_lighting": False, "baked_text_numbers_exit_or_ui": False}, "manifest pack policy prohibits leaks, topology, daylight C lighting, and baked text")


def main() -> int:
    manifest = read_json(MANIFEST_PATH)
    if not manifest:
        print("V06_ASSET_PACK_VALIDATION failures=1")
        return 1
    validate_pack_policy(manifest)
    validate_inventory(manifest)
    records, images = validate_asset_records(manifest)
    validate_cell_geometry(images)
    validate_background_and_mask(images)
    validate_provenance(manifest)
    validate_source_guard(manifest)
    validate_budgets(manifest, records)
    validate_imports()
    validate_qc()
    for label in PASSES:
        print(f"PASS {label}")
    for label in FAILURES:
        print(f"FAIL {label}", file=sys.stderr)
    print(f"V06_ASSET_PACK_VALIDATION passes={len(PASSES)} failures={len(FAILURES)}")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    raise SystemExit(main())
