"""Deterministically normalize the accepted v0.6 atlas/boss production sources.

Raw ImageGen outputs and chroma-key mattes stay below art_source/.gdignore.
Only the seven normalized PNG files and their manifest are written below
assets/art/v06. This script does not modify scenes, runtime code, or imports.
"""

from __future__ import annotations

import hashlib
import json
import math
import platform
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont, ImageOps, PngImagePlugin, __version__ as PILLOW_VERSION


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RAW = HERE / "raw"
MATTE = HERE / "matte"
PROMPTS = HERE / "prompts"
QC = HERE / "qc"
ATLAS = ROOT / "assets" / "art" / "v06" / "atlas"
BOSS = ROOT / "assets" / "art" / "v06" / "boss"
EFFECTS = ROOT / "assets" / "art" / "v06" / "effects"
MANIFEST = ROOT / "assets" / "art" / "v06" / "manifest.json"
REFERENCE = ROOT / "docs" / "design" / "v06" / "d-selected-atlas-living-map.png"
SPHINX_SOURCE = ROOT / "assets" / "art" / "bosses" / "sleepy-sphinx.png"
SPHINX_SOURCE_PROMPT = ROOT / "assets" / "art" / "bosses" / "sleepy-sphinx.prompt.txt"
BOSS_READY_REFERENCE = Path("C:/tmp/v06-boss-ready-720.png")
ENHANCED_REFERENCE = Path("C:/tmp/v06-lap10-enhanced-720.png")
LANCZOS = Image.Resampling.LANCZOS

RUNTIME_SPECS: dict[str, dict[str, Any]] = {
    "parchment": {
        "path": ATLAS / "parchment-base.png",
        "id": "parchment_base",
        "mode": "RGB",
        "dimensions": [1024, 1024],
        "residency": "normal",
        "use": "Opaque edge-safe daylight atlas base; never contains gameplay topology.",
        "lighting_scope": "daylight_neutral",
        "cells": {"count": 1, "layout": [1, 1], "size": [1024, 1024], "ids": ["base"]},
        "anchor": None,
        "import_intent": {
            "compression": "vram_compressed_etc2_astc",
            "godot_compress_mode": 2,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": False,
        },
    },
    "ink": {
        "path": ATLAS / "cairo-cartography-ink.png",
        "id": "cairo_cartography_ink",
        "mode": "RGBA",
        "dimensions": [1024, 1024],
        "residency": "normal",
        "use": "Transparent Nile and sparse Cairo landmark ink; no route, nodes, labels, or UI.",
        "lighting_scope": "daylight_neutral",
        "cells": {"count": 1, "layout": [1, 1], "size": [1024, 1024], "ids": ["ink"]},
        "anchor": None,
        "import_intent": {
            "compression": "vram_compressed_etc2_astc",
            "godot_compress_mode": 2,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": True,
        },
    },
    "tiles": {
        "path": ATLAS / "raised-route-tiles.png",
        "id": "raised_route_tiles",
        "mode": "RGBA",
        "dimensions": [512, 128],
        "residency": "normal",
        "use": "Blank raised tile treatments applied locally by canonical runtime route data.",
        "lighting_scope": "daylight_neutral",
        "cells": {
            "count": 4,
            "layout": [4, 1],
            "size": [128, 128],
            "ids": ["main", "bypass", "loop", "current"],
            "common_baseline_y": 118,
            "safety_margin_px": 5,
        },
        "anchor": {"kind": "bottom_center_per_cell", "point": [64, 118]},
        "import_intent": {
            "compression": "lossless",
            "godot_compress_mode": 0,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": True,
        },
    },
    "gate": {
        "path": BOSS / "gold-boss-gate.png",
        "id": "gold_boss_gate",
        "mode": "RGBA",
        "dimensions": [512, 256],
        "residency": "normal_and_boss",
        "use": "Sleeping daylight gate and awakened internally lit boss state; identical bottom anchor.",
        "lighting_scope": "awakened_cell_boss_only",
        "cells": {
            "count": 2,
            "layout": [2, 1],
            "size": [256, 256],
            "ids": ["sleeping_unlit", "awakened_warm_gold"],
            "common_baseline_y": 246,
            "safety_margin_px": 8,
        },
        "anchor": {"kind": "bottom_center_per_cell", "point": [128, 246]},
        "import_intent": {
            "compression": "lossless",
            "godot_compress_mode": 0,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": True,
        },
    },
    "sphinx": {
        "path": BOSS / "sleepy-sphinx.png",
        "id": "sleepy_sphinx",
        "mode": "RGBA",
        "dimensions": [512, 512],
        "residency": "boss_only",
        "use": "Deterministic Lanczos derivative of the immutable existing sphinx source.",
        "lighting_scope": "boss_only",
        "cells": {"count": 1, "layout": [1, 1], "size": [512, 512], "ids": ["sleeping"]},
        "anchor": {"kind": "bottom_center", "point": [256, 488]},
        "import_intent": {
            "compression": "lossless",
            "godot_compress_mode": 0,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": True,
        },
    },
    "vignette": {
        "path": BOSS / "night-vignette.png",
        "id": "night_vignette",
        "mode": "L",
        "dimensions": [720, 1280],
        "residency": "boss_only",
        "use": "Single-channel boss-only edge darkening mask with HUD, center, and tray readability windows.",
        "lighting_scope": "boss_only",
        "cells": {"count": 1, "layout": [1, 1], "size": [720, 1280], "ids": ["mask"]},
        "anchor": None,
        "import_intent": {
            "compression": "lossless_l8",
            "godot_compress_mode": 0,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": False,
        },
    },
    "lantern": {
        "path": EFFECTS / "lantern-glow.png",
        "id": "lantern_glow",
        "mode": "RGBA",
        "dimensions": [512, 256],
        "residency": "boss_only",
        "use": "Four warm lantern/gold variants reserved for boss, TRIPLE, and enhanced states.",
        "lighting_scope": "boss_triple_enhanced_only",
        "cells": {
            "count": 4,
            "layout": [4, 1],
            "size": [128, 256],
            "ids": ["quiet", "full", "triple_peak", "settle"],
            "common_baseline_y": 244,
            "safety_margin_px": 4,
        },
        "anchor": {"kind": "bottom_center_per_cell", "point": [64, 244]},
        "import_intent": {
            "compression": "lossless",
            "godot_compress_mode": 0,
            "mipmaps": False,
            "filter": True,
            "fix_alpha_border": True,
        },
    },
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rel(path: Path) -> str:
    return path.resolve().relative_to(ROOT.resolve()).as_posix()


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")


def save_png(image: Image.Image, path: Path, pnginfo: PngImagePlugin.PngInfo | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True, compress_level=9, pnginfo=pnginfo)


def resize_rgba(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Lanczos-resize in premultiplied-alpha space to prevent hidden-key bleed."""
    return image.convert("RGBa").resize(size, LANCZOS).convert("RGBA")


def clear_low_alpha_key_residual(image: Image.Image) -> Image.Image:
    """Clear only imperceptible chroma-key remnants created by alpha unpremultiply.

    The accepted soft matte is preserved. This targets near-pure green pixels at
    <= 6.3% alpha and cannot contract any readable silhouette.
    """
    rgba = image.convert("RGBA")
    cleaned: list[tuple[int, int, int, int]] = []
    for r, g, b, a in rgba.get_flattened_data():
        if 0 < a <= 16 and g >= 180 and g > r + 64 and g > b + 64 and r <= 80 and b <= 80:
            cleaned.append((0, 0, 0, 0))
        else:
            cleaned.append((r, g, b, a))
    rgba.putdata(cleaned)
    return rgba


def alpha_stats(image: Image.Image) -> dict[str, Any]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    histogram = alpha.histogram()
    transparent = histogram[0]
    opaque = histogram[255]
    partial = rgba.width * rgba.height - transparent - opaque
    partial_pixels = [pixel for pixel in rgba.get_flattened_data() if 0 < pixel[3] < 255]
    green_fringe = sum(1 for r, g, b, _a in partial_pixels if g > r + 28 and g > b + 28)
    key_like = [
        (r, g, b, a)
        for r, g, b, a in partial_pixels
        if a <= 16 and g >= 180 and g > r + 64 and g > b + 64 and r <= 80 and b <= 80
    ]
    corners = [
        alpha.getpixel((0, 0)),
        alpha.getpixel((rgba.width - 1, 0)),
        alpha.getpixel((0, rgba.height - 1)),
        alpha.getpixel((rgba.width - 1, rgba.height - 1)),
    ]
    return {
        "transparent_pixels": transparent,
        "partial_pixels": partial,
        "opaque_pixels": opaque,
        "coverage_ratio": round((opaque + partial) / (rgba.width * rgba.height), 8),
        "green_dominant_partial_pixels": green_fringe,
        "green_dominant_partial_ratio": round(green_fringe / max(1, partial), 8),
        "low_alpha_key_like_pixels": len(key_like),
        "low_alpha_key_like_alpha_sum": sum(pixel[3] for pixel in key_like),
        "corner_alpha": corners,
    }


def content_bbox(image: Image.Image, threshold: int = 4) -> tuple[int, int, int, int]:
    alpha = image.convert("RGBA").getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("source cell contains no alpha content")
    return bbox


def normalize_cells(
    source: Image.Image,
    source_boxes: list[tuple[int, int, int, int]],
    target_cell: tuple[int, int],
    max_content: tuple[int, int],
    baseline_y: int,
) -> tuple[Image.Image, dict[str, Any]]:
    cells: list[Image.Image] = []
    bboxes: list[tuple[int, int, int, int]] = []
    for box in source_boxes:
        cell = source.crop(box).convert("RGBA")
        bbox = content_bbox(cell)
        cells.append(cell.crop(bbox))
        bboxes.append(bbox)
    max_width = max(cell.width for cell in cells)
    max_height = max(cell.height for cell in cells)
    scale = min(max_content[0] / max_width, max_content[1] / max_height)
    out = Image.new("RGBA", (target_cell[0] * len(cells), target_cell[1]), (0, 0, 0, 0))
    normalized: list[dict[str, Any]] = []
    for index, cell in enumerate(cells):
        size = (max(1, round(cell.width * scale)), max(1, round(cell.height * scale)))
        resized = clear_low_alpha_key_residual(resize_rgba(cell, size))
        local_x = (target_cell[0] - resized.width) // 2
        y = baseline_y - resized.height
        normalized_cell = Image.new("RGBA", target_cell, (0, 0, 0, 0))
        normalized_cell.alpha_composite(resized, (local_x, y))
        readable_bbox = content_bbox(normalized_cell)
        baseline_shift = baseline_y - readable_bbox[3]
        if baseline_shift:
            shifted = Image.new("RGBA", target_cell, (0, 0, 0, 0))
            shifted.alpha_composite(normalized_cell, (0, baseline_shift))
            normalized_cell = shifted
            y += baseline_shift
        x = index * target_cell[0] + local_x
        out.alpha_composite(normalized_cell, (index * target_cell[0], 0))
        normalized.append(
            {
                "source_cell": list(source_boxes[index]),
                "source_alpha_bbox_local": list(bboxes[index]),
                "normalized_size": list(size),
                "paste_xy": [x, y],
                "post_cleanup_baseline_shift": baseline_shift,
                "anchor": [index * target_cell[0] + target_cell[0] // 2, baseline_y],
            }
        )
    out = clear_low_alpha_key_residual(out)
    return out, {
        "shared_scale": round(scale, 10),
        "target_cell": list(target_cell),
        "max_content": list(max_content),
        "baseline_y": baseline_y,
        "cells": normalized,
    }


def build_parchment() -> dict[str, Any]:
    raw = Image.open(RAW / "parchment-raw.png").convert("RGB")
    seed = raw.resize((512, 512), LANCZOS)
    out = Image.new("RGB", (1024, 1024))
    out.paste(seed, (0, 0))
    out.paste(ImageOps.mirror(seed), (512, 0))
    out.paste(ImageOps.flip(seed), (0, 512))
    out.paste(ImageOps.mirror(ImageOps.flip(seed)), (512, 512))
    save_png(out, RUNTIME_SPECS["parchment"]["path"])
    return {
        "method": "1254 square source Lanczos-resized to 512 then mirrored 2x2 for exact edge continuity",
        "resample": "Pillow.Image.Resampling.LANCZOS",
        "edge_sha": {
            "left": hashlib.sha256(out.crop((0, 0, 1, 1024)).tobytes()).hexdigest(),
            "right": hashlib.sha256(out.crop((1023, 0, 1024, 1024)).tobytes()).hexdigest(),
            "top": hashlib.sha256(out.crop((0, 0, 1024, 1)).tobytes()).hexdigest(),
            "bottom": hashlib.sha256(out.crop((0, 1023, 1024, 1024)).tobytes()).hexdigest(),
        },
    }


def build_ink() -> dict[str, Any]:
    raw = Image.open(MATTE / "cairo-ink-matte.png").convert("RGBA")
    resized = resize_rgba(raw, (980, 980))
    out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    out.alpha_composite(resized, (22, 22))
    out = clear_low_alpha_key_residual(out)
    save_png(out, RUNTIME_SPECS["ink"]["path"])
    return {"method": "full-sheet Lanczos normalization with 22px transparent outer safety pad", "paste_xy": [22, 22]}


def build_tiles() -> dict[str, Any]:
    source = Image.open(MATTE / "route-tiles-matte.png").convert("RGBA")
    half_w, half_h = source.width // 2, source.height // 2
    boxes = [
        (0, 0, half_w, half_h),
        (half_w, 0, source.width, half_h),
        (0, half_h, half_w, source.height),
        (half_w, half_h, source.width, source.height),
    ]
    out, metadata = normalize_cells(source, boxes, (128, 128), (116, 108), 118)
    save_png(out, RUNTIME_SPECS["tiles"]["path"])
    return metadata


def build_gate() -> dict[str, Any]:
    source = Image.open(MATTE / "boss-gate-matte.png").convert("RGBA")
    half_w = source.width // 2
    boxes = [(0, 0, half_w, source.height), (half_w, 0, source.width, source.height)]
    out, metadata = normalize_cells(source, boxes, (256, 256), (238, 232), 246)
    save_png(out, RUNTIME_SPECS["gate"]["path"])
    return metadata


def build_sphinx() -> dict[str, Any]:
    source = Image.open(SPHINX_SOURCE).convert("RGBA")
    out = clear_low_alpha_key_residual(resize_rgba(source, (512, 512)))
    save_png(out, RUNTIME_SPECS["sphinx"]["path"])
    bbox = content_bbox(out)
    RUNTIME_SPECS["sphinx"]["anchor"]["point"] = [256, min(511, bbox[3] - 1)]
    return {
        "method": "immutable source resized directly from 1254x1254 to 512x512",
        "resample": "Pillow.Image.Resampling.LANCZOS",
        "source_path": rel(SPHINX_SOURCE),
        "source_sha256": sha256(SPHINX_SOURCE),
        "source_dimensions": list(source.size),
        "normalized_alpha_bbox": list(bbox),
    }


def smoothstep(low: float, high: float, value: float) -> float:
    t = max(0.0, min(1.0, (value - low) / (high - low)))
    return t * t * (3.0 - 2.0 * t)


def readability_window(nx: float, ny: float, cx: float, cy: float, rx: float, ry: float) -> float:
    distance = math.sqrt(((nx - cx) / rx) ** 2 + ((ny - cy) / ry) ** 2)
    return 1.0 - smoothstep(0.55, 1.0, distance)


def build_vignette() -> dict[str, Any]:
    width, height = 720, 1280
    pixels: list[int] = []
    for y in range(height):
        ny = ((y + 0.5) / height) * 2.0 - 1.0
        for x in range(width):
            nx = ((x + 0.5) / width) * 2.0 - 1.0
            radius = math.sqrt((nx / 1.08) ** 2 + (ny / 1.12) ** 2)
            value = 34.0 + 154.0 * smoothstep(0.32, 1.02, radius)
            hud = readability_window(nx, ny, 0.0, -0.87, 0.93, 0.17)
            center = readability_window(nx, ny, 0.0, -0.18, 0.70, 0.44)
            tray = readability_window(nx, ny, 0.0, 0.64, 0.82, 0.27)
            value -= 43.0 * hud + 66.0 * center + 58.0 * tray
            pixels.append(max(12, min(198, round(value))))
    out = Image.new("L", (width, height))
    out.putdata(pixels)
    save_png(out, RUNTIME_SPECS["vignette"]["path"])
    sample_points = {
        "top_left": out.getpixel((0, 0)),
        "top_center_hud": out.getpixel((360, 72)),
        "center": out.getpixel((360, 540)),
        "tray_center": out.getpixel((360, 1040)),
        "bottom_right": out.getpixel((719, 1279)),
    }
    return {
        "method": "deterministic analytic elliptical smoothstep mask with three readability windows",
        "value_range": list(out.getextrema()),
        "samples": sample_points,
    }


def build_lantern() -> dict[str, Any]:
    source = Image.open(MATTE / "lantern-glow-matte.png").convert("RGBA")
    half_w, half_h = source.width // 2, source.height // 2
    boxes = [
        (0, 0, half_w, half_h),
        (half_w, 0, source.width, half_h),
        (0, half_h, half_w, source.height),
        (half_w, half_h, source.width, source.height),
    ]
    out, metadata = normalize_cells(source, boxes, (128, 256), (118, 232), 244)
    save_png(out, RUNTIME_SPECS["lantern"]["path"])
    return metadata


def checkerboard(size: tuple[int, int], cell: int = 16) -> Image.Image:
    out = Image.new("RGBA", size, (232, 226, 210, 255))
    draw = ImageDraw.Draw(out)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle((x, y, min(size[0], x + cell) - 1, min(size[1], y + cell) - 1), fill=(172, 180, 178, 255))
    return out


def fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    copy = image.convert("RGBA")
    ratio = min(size[0] / copy.width, size[1] / copy.height, 1.0)
    return resize_rgba(copy, (max(1, round(copy.width * ratio)), max(1, round(copy.height * ratio))))


def paste_center(canvas: Image.Image, sprite: Image.Image, center: tuple[int, int]) -> None:
    canvas.alpha_composite(sprite, (center[0] - sprite.width // 2, center[1] - sprite.height // 2))


def qc_pnginfo(kind: str, size: str) -> PngImagePlugin.PngInfo:
    info = PngImagePlugin.PngInfo()
    info.add_text("artifact_role", "QC_PREVIEW_NOT_RUNTIME")
    info.add_text("lighting_state", kind)
    info.add_text("runtime_wiring", "false")
    info.add_text("canvas", size)
    info.add_text("composition_note", "Purpose-built pack layers composited for visual QC; sample route is procedural preview-only.")
    return info


def base_context() -> Image.Image:
    parchment = Image.open(RUNTIME_SPECS["parchment"]["path"]).convert("RGBA").resize((720, 1280), LANCZOS)
    ink = Image.open(RUNTIME_SPECS["ink"]["path"]).convert("RGBA").resize((720, 720), LANCZOS)
    parchment.alpha_composite(ink, (0, 150))
    return parchment


def build_previews() -> list[dict[str, Any]]:
    QC.mkdir(parents=True, exist_ok=True)
    tiles = Image.open(RUNTIME_SPECS["tiles"]["path"]).convert("RGBA")
    gate = Image.open(RUNTIME_SPECS["gate"]["path"]).convert("RGBA")
    sphinx = Image.open(RUNTIME_SPECS["sphinx"]["path"]).convert("RGBA")
    lantern = Image.open(RUNTIME_SPECS["lantern"]["path"]).convert("RGBA")

    daylight = base_context()
    route_layer = Image.new("RGBA", daylight.size, (0, 0, 0, 0))
    route_draw = ImageDraw.Draw(route_layer)
    points = [(120, 1110), (170, 990), (290, 910), (430, 910), (530, 810), (550, 650)]
    route_draw.line(points, fill=(26, 124, 126, 210), width=10, joint="curve")
    for start, end in [((290, 910), (250, 790)), ((250, 790), (330, 710)), ((330, 710), (430, 720))]:
        route_draw.line((start, end), fill=(159, 82, 58, 190), width=8)
    daylight.alpha_composite(route_layer)
    tile_centers = [(120, 1110), (290, 910), (430, 720), (550, 650)]
    for index, center in enumerate(tile_centers):
        cell = tiles.crop((index * 128, 0, (index + 1) * 128, 128))
        paste_center(daylight, fit(cell, (104, 104)), center)
    sleeping_gate = fit(gate.crop((0, 0, 256, 256)), (230, 230))
    paste_center(daylight, sleeping_gate, (510, 285))
    daylight_path = QC / "daylight-pack-preview-720x1280.png"
    save_png(daylight.convert("RGB"), daylight_path, qc_pnginfo("daylight", "720x1280"))
    daylight_small = daylight.resize((360, 640), LANCZOS).convert("RGB")
    daylight_small_path = QC / "daylight-pack-preview-360x640.png"
    save_png(daylight_small, daylight_small_path, qc_pnginfo("daylight", "360x640 Lanczos from 720x1280"))

    boss = base_context()
    mask = Image.open(RUNTIME_SPECS["vignette"]["path"]).convert("L")
    dark = Image.new("RGBA", boss.size, (16, 25, 30, 0))
    dark.putalpha(mask)
    boss.alpha_composite(dark)
    bright_effect = resize_rgba(lantern.crop((2 * 128, 0, 3 * 128, 256)), (300, 600))
    paste_center(boss, bright_effect, (360, 440))
    awakened_gate = fit(gate.crop((256, 0, 512, 256)), (270, 270))
    paste_center(boss, awakened_gate, (360, 260))
    paste_center(boss, fit(sphinx, (470, 470)), (360, 690))
    current = fit(tiles.crop((3 * 128, 0, 4 * 128, 128)), (122, 122))
    paste_center(boss, current, (360, 1050))
    boss_path = QC / "boss-lit-pack-preview-720x1280.png"
    save_png(boss.convert("RGB"), boss_path, qc_pnginfo("boss_lit", "720x1280"))
    boss_small = boss.resize((360, 640), LANCZOS).convert("RGB")
    boss_small_path = QC / "boss-lit-pack-preview-360x640.png"
    save_png(boss_small, boss_small_path, qc_pnginfo("boss_lit", "360x640 Lanczos from 720x1280"))

    return [
        {"path": rel(daylight_path), "role": "QC_PREVIEW_NOT_RUNTIME", "lighting": "daylight", "dimensions": [720, 1280]},
        {"path": rel(daylight_small_path), "role": "QC_PREVIEW_NOT_RUNTIME", "lighting": "daylight", "dimensions": [360, 640], "derived_from": rel(daylight_path)},
        {"path": rel(boss_path), "role": "QC_PREVIEW_NOT_RUNTIME", "lighting": "boss_lit", "dimensions": [720, 1280]},
        {"path": rel(boss_small_path), "role": "QC_PREVIEW_NOT_RUNTIME", "lighting": "boss_lit", "dimensions": [360, 640], "derived_from": rel(boss_path)},
    ]


def build_cell_previews() -> list[dict[str, Any]]:
    outputs: list[dict[str, Any]] = []
    for key, scale in [("tiles", 2), ("gate", 2), ("lantern", 2)]:
        image = Image.open(RUNTIME_SPECS[key]["path"]).convert("RGBA")
        canvas = checkerboard((image.width * scale, image.height * scale), 16)
        canvas.alpha_composite(resize_rgba(image, canvas.size))
        draw = ImageDraw.Draw(canvas)
        cells = RUNTIME_SPECS[key]["cells"]
        cell_w = cells["size"][0] * scale
        for index in range(1, cells["count"]):
            x = index * cell_w
            draw.line((x, 0, x, canvas.height), fill=(255, 0, 255, 255), width=1)
        path = QC / f"{key}-cell-contact.png"
        save_png(canvas.convert("RGB"), path, qc_pnginfo("cell_contact", f"{canvas.width}x{canvas.height}"))
        outputs.append({"path": rel(path), "role": "QC_CELL_CONTACT_NOT_RUNTIME", "dimensions": list(canvas.size)})
    return outputs


def build_fringe_preview() -> dict[str, Any]:
    canvas = Image.new("RGBA", (1024, 768), (18, 24, 30, 255))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    panels = [
        ("ink", (0, 0, 512, 384)),
        ("tiles", (512, 0, 1024, 384)),
        ("gate", (0, 384, 512, 768)),
        ("lantern", (512, 384, 1024, 768)),
    ]
    for key, panel in panels:
        x0, y0, x1, y1 = panel
        draw.rectangle((x0, y0, (x0 + x1) // 2, y1), fill=(244, 241, 228, 255))
        draw.rectangle(((x0 + x1) // 2, y0, x1, y1), fill=(15, 25, 32, 255))
        image = Image.open(RUNTIME_SPECS[key]["path"]).convert("RGBA")
        thumb = fit(image, (472, 330))
        paste_center(canvas, thumb, ((x0 + x1) // 2, (y0 + y1) // 2 + 10))
        stats = alpha_stats(image)
        draw.text((x0 + 8, y0 + 8), f"{key}  partial={stats['partial_pixels']}  key-like-residual={stats['low_alpha_key_like_pixels']}", fill=(235, 72, 205, 255), font=font)
    path = QC / "alpha-fringe-checks.png"
    save_png(canvas.convert("RGB"), path, qc_pnginfo("alpha_fringe", "1024x768"))
    return {"path": rel(path), "role": "QC_ALPHA_FRINGE_NOT_RUNTIME", "dimensions": [1024, 768]}


def build_pack_contact() -> dict[str, Any]:
    canvas = checkerboard((1024, 1024), 24)
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default()
    placements = [
        ("parchment", (16, 30), (300, 300)),
        ("ink", (350, 30), (300, 300)),
        ("vignette", (760, 30), (180, 320)),
        ("tiles", (16, 390), (512, 128)),
        ("gate", (16, 600), (512, 256)),
        ("sphinx", (630, 400), (330, 330)),
        ("lantern", (500, 760), (500, 250)),
    ]
    for key, xy, max_size in placements:
        image = Image.open(RUNTIME_SPECS[key]["path"]).convert("RGBA")
        thumb = fit(image, max_size)
        canvas.alpha_composite(thumb, xy)
        draw.text((xy[0], max(0, xy[1] - 14)), key, fill=(12, 62, 65, 255), font=font)
    path = QC / "runtime-pack-contact-sheet.png"
    save_png(canvas.convert("RGB"), path, qc_pnginfo("pack_contact", "1024x1024"))
    return {"path": rel(path), "role": "QC_PACK_CONTACT_NOT_RUNTIME", "dimensions": [1024, 1024]}


def runtime_asset_record(key: str, provenance_sha: str) -> dict[str, Any]:
    spec = RUNTIME_SPECS[key]
    path: Path = spec["path"]
    image = Image.open(path)
    channels = {"L": 1, "RGB": 3, "RGBA": 4}[image.mode]
    record = {
        "id": spec["id"],
        "path": "res://" + rel(path),
        "dimensions": list(image.size),
        "mode": image.mode,
        "sha256": sha256(path),
        "source_bytes": path.stat().st_size,
        "decoded_byte_estimate": image.width * image.height * channels,
        "cells": spec["cells"],
        "anchor": spec["anchor"],
        "use": spec["use"],
        "lighting_scope": spec["lighting_scope"],
        "residency": spec["residency"],
        "import_intent": spec["import_intent"],
        "provenance_sha256": provenance_sha,
        "content_review": {
            "no_baked_text": True,
            "no_baked_numbers": True,
            "no_baked_exit_or_ui": True,
            "no_baked_die_or_explorer_cat": key not in {"sphinx"},
            "contains_boss_sphinx_character": key == "sphinx",
            "no_runtime_topology_in_background": key in {"parchment", "ink"},
        },
    }
    if image.mode == "RGBA":
        record["alpha"] = alpha_stats(image)
    return record


def file_fact(path: Path) -> dict[str, Any]:
    image = Image.open(path)
    fact: dict[str, Any] = {
        "path": rel(path) if path.resolve().is_relative_to(ROOT.resolve()) else path.as_posix(),
        "sha256": sha256(path),
        "source_bytes": path.stat().st_size,
        "dimensions": list(image.size),
        "mode": image.mode,
    }
    if image.mode == "RGBA":
        fact["alpha"] = alpha_stats(image)
    return fact


def build_metadata(normalization: dict[str, Any], previews: list[dict[str, Any]]) -> None:
    raw_map = {
        "parchment": RAW / "parchment-raw.png",
        "ink": RAW / "cairo-ink-chroma-raw.png",
        "tiles": RAW / "route-tiles-chroma-raw.png",
        "gate": RAW / "boss-gate-chroma-raw.png",
        "lantern": RAW / "lantern-glow-chroma-raw.png",
    }
    matte_map = {
        "ink": MATTE / "cairo-ink-matte.png",
        "tiles": MATTE / "route-tiles-matte.png",
        "gate": MATTE / "boss-gate-matte.png",
        "lantern": MATTE / "lantern-glow-matte.png",
    }
    prompt_map = {
        "parchment": PROMPTS / "parchment.txt",
        "ink": PROMPTS / "cairo-ink.txt",
        "tiles": PROMPTS / "route-tiles.txt",
        "gate": PROMPTS / "boss-gate.txt",
        "lantern": PROMPTS / "lantern-glow.txt",
    }
    detected_keys = {"ink": "#34ef37", "tiles": "#02f906", "gate": "#06f911", "lantern": "#03f90a"}
    pipeline = {
        "schema_version": 1,
        "pipeline_version": "v06-atlas-boss-normalize-1",
        "python": platform.python_version(),
        "pillow": PILLOW_VERSION,
        "resampling": "Pillow.Image.Resampling.LANCZOS",
        "chroma_helper": {
            "path": "C:/Users/hiro/.codex/skills/.system/imagegen/scripts/remove_chroma_key.py",
            "arguments": ["--auto-key", "border", "--soft-matte", "--transparent-threshold", "12", "--opaque-threshold", "220", "--despill"],
            "requested_key": "#00FF00",
            "detected_keys": detected_keys,
            "edge_contract_retry_used": False,
            "native_transparency_or_cli_fallback_used": False,
            "post_resize_cleanup": "clear only near-pure key green at alpha<=16; no silhouette contraction",
        },
        "normalization": normalization,
        "raw_sources": {name: file_fact(path) for name, path in raw_map.items()},
        "matte_sources": {name: file_fact(path) for name, path in matte_map.items()},
        "runtime_outputs": {name: file_fact(spec["path"]) for name, spec in RUNTIME_SPECS.items()},
        "previews": previews,
    }
    write_json(HERE / "pipeline.json", pipeline)

    reference_inputs: list[dict[str, Any]] = [
        {
            "path": rel(REFERENCE),
            "sha256": sha256(REFERENCE),
            "role": "ImageGen style_and_palette_reference_only",
            "generator_input": True,
            "excluded_from_shipping": "composition, topology, route, nodes, numbers, EXIT, UI text, cat, die, gate and labels",
        },
        {
            "path": rel(SPHINX_SOURCE),
            "sha256": sha256(SPHINX_SOURCE),
            "source_bytes": SPHINX_SOURCE.stat().st_size,
            "dimensions": list(Image.open(SPHINX_SOURCE).size),
            "mode": Image.open(SPHINX_SOURCE).mode,
            "role": "immutable derivative source for 512x512 sleepy sphinx",
            "generator_input": False,
        },
    ]
    for path, role in [
        (BOSS_READY_REFERENCE, "read-only boss-screen context reference; not sent to ImageGen"),
        (ENHANCED_REFERENCE, "read-only enhanced-lap context reference; not sent to ImageGen"),
    ]:
        if path.exists():
            reference_inputs.append({"path": path.as_posix(), "sha256": sha256(path), "source_bytes": path.stat().st_size, "role": role, "generator_input": False})
    generation_calls: list[dict[str, Any]] = []
    raw_origins = {
        "parchment": "C:/Users/hiro/.codex/generated_images/019f7511-16b9-79f0-819d-fc748f323519/exec-61d8aafb-1944-416a-9998-466dd8a7eeaf.png",
        "ink": "C:/Users/hiro/.codex/generated_images/019f7511-16b9-79f0-819d-fc748f323519/exec-242266b4-afe8-4c0a-8d04-9f0a7fdfad26.png",
        "tiles": "C:/Users/hiro/.codex/generated_images/019f7511-16b9-79f0-819d-fc748f323519/exec-6e2a0636-3f96-4351-ba66-4bd850d311d4.png",
        "gate": "C:/Users/hiro/.codex/generated_images/019f7511-16b9-79f0-819d-fc748f323519/exec-d794be6d-c27a-4833-a8a7-2e8e24c4eb00.png",
        "lantern": "C:/Users/hiro/.codex/generated_images/019f7511-16b9-79f0-819d-fc748f323519/exec-120f2fb6-1615-46d0-bf6a-d5a13ec17f76.png",
    }
    for index, name in enumerate(["parchment", "ink", "tiles", "gate", "lantern"], start=1):
        generation_calls.append(
            {
                "call": index,
                "asset": name,
                "mode": "built_in_image_gen_default",
                "use_case": "stylized-concept",
                "raw_workspace_copy": rel(raw_map[name]),
                "raw_sha256": sha256(raw_map[name]),
                "generator_output_origin": raw_origins[name],
                "prompt_path": rel(prompt_map[name]),
                "prompt_sha256": sha256(prompt_map[name]),
                "prompt_exact": prompt_map[name].read_text(encoding="utf-8").rstrip("\n"),
                "reference_role": "selected atlas target used only for style and palette",
                "accepted": True,
                "retry_or_competing_variant": False,
            }
        )
    provenance = {
        "schema_version": 1,
        "pack_id": "v06_daylight_atlas_boss_climax_01",
        "generation_date": "2026-07-18",
        "generator": "OpenAI built-in image_gen tool",
        "model_mode": "built_in_image_gen_default",
        "generation_call_count": 5,
        "generation_calls": generation_calls,
        "reference_inputs": reference_inputs,
        "normalization_pipeline": rel(Path(__file__)),
        "pipeline_metadata": rel(HERE / "pipeline.json"),
        "source_overwrite": False,
        "immutable_sphinx_source": {
            "path": rel(SPHINX_SOURCE),
            "sha256": sha256(SPHINX_SOURCE),
            "source_bytes": SPHINX_SOURCE.stat().st_size,
            "dimensions": list(Image.open(SPHINX_SOURCE).size),
            "mode": Image.open(SPHINX_SOURCE).mode,
            "source_prompt_path": rel(SPHINX_SOURCE_PROMPT),
            "source_prompt_sha256": sha256(SPHINX_SOURCE_PROMPT),
            "third_party_provenance": {
                "is_third_party": False,
                "third_party_record_found": False,
                "basis": "existing project-generated source has a repository prompt record and no third_party sphinx record",
            },
        },
        "content_review": {
            "reviewed_all_raw_mattes_runtime_contact_and_previews": True,
            "no_text_numbers_exit_ui_labels_die_or_explorer_cat_in_generated_runtime_layers": True,
            "no_route_or_node_topology_in_parchment_or_cairo_ink": True,
            "c_lighting_absent_from_daylight_assets_and_daylight_preview": True,
            "c_lighting_confined_to_awakened_gate_lantern_vignette_and_boss_preview": True,
            "chroma_cleanup_preserves_silhouettes": True,
            "native_transparency_fallback_used": False,
            "concept_or_document_crop_used": False,
            "baked_text_risk": "visual review PASS; all five exact prompts explicitly prohibited text, letters, numbers, labels and UI",
        },
        "runtime_outputs": {name: file_fact(spec["path"]) for name, spec in RUNTIME_SPECS.items()},
        "qc_artifacts": previews,
    }
    write_json(HERE / "provenance.json", provenance)
    provenance_sha = sha256(HERE / "provenance.json")

    assets = [runtime_asset_record(key, provenance_sha) for key in ["parchment", "ink", "tiles", "gate", "sphinx", "vignette", "lantern"]]
    normal_bytes = sum(asset["decoded_byte_estimate"] for asset in assets if asset["residency"] in {"normal", "normal_and_boss"})
    boss_peak_bytes = sum(asset["decoded_byte_estimate"] for asset in assets)
    source_bytes = sum(asset["source_bytes"] for asset in assets)
    manifest = {
        "schema_version": 1,
        "pack_id": "v06_daylight_atlas_boss_climax_01",
        "runtime_root": "res://assets/art/v06",
        "runtime_wiring": False,
        "generation_call_count": 5,
        "provenance_path": "res://" + rel(HERE / "provenance.json"),
        "provenance_sha256": provenance_sha,
        "immutable_source_guard": {
            "path": "res://" + rel(SPHINX_SOURCE),
            "sha256": sha256(SPHINX_SOURCE),
            "source_bytes": SPHINX_SOURCE.stat().st_size,
            "dimensions": list(Image.open(SPHINX_SOURCE).size),
            "source_prompt_path": "res://" + rel(SPHINX_SOURCE_PROMPT),
            "source_prompt_sha256": sha256(SPHINX_SOURCE_PROMPT),
            "is_third_party": False,
        },
        "budgets": {
            "normal_resident_decoded_bytes": normal_bytes,
            "normal_resident_decoded_mib": round(normal_bytes / (1024 * 1024), 4),
            "normal_resident_limit_bytes": 14 * 1024 * 1024,
            "boss_peak_decoded_bytes": boss_peak_bytes,
            "boss_peak_decoded_mib": round(boss_peak_bytes / (1024 * 1024), 4),
            "boss_peak_limit_bytes": 16 * 1024 * 1024,
            "runtime_png_source_bytes": source_bytes,
            "runtime_png_source_mib": round(source_bytes / (1024 * 1024), 4),
            "runtime_png_source_limit_bytes": 8 * 1024 * 1024,
            "maximum_runtime_edge_px_including_mandated_mask": max(max(asset["dimensions"]) for asset in assets),
            "maximum_general_runtime_edge_px": max(max(asset["dimensions"]) for asset in assets if asset["id"] != "night_vignette"),
            "maximum_general_runtime_edge_limit_px": 1152,
            "mandated_screen_mask_exception": {
                "path": "res://assets/art/v06/boss/night-vignette.png",
                "dimensions": [720, 1280],
                "reason": "exact viewport-sized single-channel contract",
                "applies_to_any_other_asset": False,
            },
        },
        "pack_policy": {
            "runtime_png_count": 7,
            "raw_or_qc_under_runtime_root": False,
            "background_contains_runtime_topology": False,
            "daylight_contains_boss_lighting": False,
            "baked_text_numbers_exit_or_ui": False,
        },
        "assets": assets,
    }
    write_json(MANIFEST, manifest)


def main() -> None:
    for directory in [QC, ATLAS, BOSS, EFFECTS]:
        directory.mkdir(parents=True, exist_ok=True)
    normalization = {
        "parchment": build_parchment(),
        "ink": build_ink(),
        "tiles": build_tiles(),
        "gate": build_gate(),
        "sphinx": build_sphinx(),
        "vignette": build_vignette(),
        "lantern": build_lantern(),
    }
    previews = build_previews()
    previews.extend(build_cell_previews())
    previews.append(build_fringe_preview())
    previews.append(build_pack_contact())
    build_metadata(normalization, previews)
    print("Built v0.6 atlas/boss pack: 7 runtime PNGs, 5 ImageGen calls, runtime wiring=false")


if __name__ == "__main__":
    main()
