extends SceneTree

const MANIFEST_PATH := "res://assets/art/v06/manifest.json"
const SOURCE_SPHINX_PATH := "res://assets/art/bosses/sleepy-sphinx.png"
const SOURCE_SPHINX_SHA := "27759bf53575c42a8db3a700bcfb11dfb37e1e19885f32e1f271c052aaf70f0e"

const EXPECTED := {
	"parchment_base": {"path":"res://assets/art/v06/atlas/parchment-base.png", "size":Vector2i(1024, 1024), "mode":"RGB", "cells":1, "cell_size":Vector2i(1024, 1024)},
	"cairo_cartography_ink": {"path":"res://assets/art/v06/atlas/cairo-cartography-ink.png", "size":Vector2i(1024, 1024), "mode":"RGBA", "cells":1, "cell_size":Vector2i(1024, 1024)},
	"raised_route_tiles": {"path":"res://assets/art/v06/atlas/raised-route-tiles.png", "size":Vector2i(512, 128), "mode":"RGBA", "cells":4, "cell_size":Vector2i(128, 128), "anchor":Vector2i(64, 118)},
	"gold_boss_gate": {"path":"res://assets/art/v06/boss/gold-boss-gate.png", "size":Vector2i(512, 256), "mode":"RGBA", "cells":2, "cell_size":Vector2i(256, 256), "anchor":Vector2i(128, 246)},
	"sleepy_sphinx": {"path":"res://assets/art/v06/boss/sleepy-sphinx.png", "size":Vector2i(512, 512), "mode":"RGBA", "cells":1, "cell_size":Vector2i(512, 512), "anchor":Vector2i(256, 485)},
	"night_vignette": {"path":"res://assets/art/v06/boss/night-vignette.png", "size":Vector2i(720, 1280), "mode":"L", "cells":1, "cell_size":Vector2i(720, 1280)},
	"lantern_glow": {"path":"res://assets/art/v06/effects/lantern-glow.png", "size":Vector2i(512, 256), "mode":"RGBA", "cells":4, "cell_size":Vector2i(128, 256), "anchor":Vector2i(64, 244)},
}

const EXPECTED_CELL_IDS := {
	"parchment_base": ["base"],
	"cairo_cartography_ink": ["ink"],
	"raised_route_tiles": ["main", "bypass", "loop", "current"],
	"gold_boss_gate": ["sleeping_unlit", "awakened_warm_gold"],
	"sleepy_sphinx": ["sleeping"],
	"night_vignette": ["mask"],
	"lantern_glow": ["quiet", "full", "triple_peak", "settle"],
}

var failures: int = 0


func _init() -> void:
	var manifest := _load_json(MANIFEST_PATH)
	_expect(not manifest.is_empty(), "manifest parses")
	if manifest.is_empty():
		_finish()
		return
	_expect(manifest.get("schema_version") == 1, "manifest schema")
	_expect(manifest.get("pack_id") == "v06_daylight_atlas_boss_climax_01", "manifest pack id")
	_expect(manifest.get("runtime_root") == "res://assets/art/v06", "runtime root")
	_expect(manifest.get("runtime_wiring") == true, "pack is wired into v0.7 runtime")
	_expect(manifest.get("generation_call_count") == 5, "five accepted ImageGen calls")
	var assets: Array = manifest.get("assets", [])
	_expect(assets.size() == EXPECTED.size(), "exact seven-asset manifest")
	var seen: Dictionary = {}
	for record_value: Variant in assets:
		var record: Dictionary = record_value
		var asset_id := str(record.get("id", ""))
		_expect(EXPECTED.has(asset_id), "known asset id %s" % asset_id)
		if not EXPECTED.has(asset_id):
			continue
		_expect(not seen.has(asset_id), "unique asset id %s" % asset_id)
		seen[asset_id] = true
		_validate_asset(asset_id, record, EXPECTED[asset_id])
	_expect(seen.size() == EXPECTED.size(), "all expected asset ids loaded")
	_validate_pack_policy(manifest)
	_validate_budgets(manifest)
	_validate_source_guard(manifest)
	_finish()


func _validate_asset(asset_id: String, record: Dictionary, expected: Dictionary) -> void:
	var path := str(record.get("path", ""))
	_expect(path == expected.path, "%s exact path" % asset_id)
	_expect(not _contains_forbidden_route_text_identifier(asset_id, path), "%s has no route-text/UI filename identifier" % asset_id)
	_expect(not path.contains("/raw/") and not path.contains("/qc/") and not path.contains("preview") and not path.contains("contact"), "%s is normalized runtime art" % asset_id)
	var dimensions := _vec2i(record.get("dimensions", []))
	_expect(dimensions == expected.size, "%s manifest dimensions" % asset_id)
	_expect(record.get("mode") == expected.mode, "%s manifest mode" % asset_id)
	var cells: Dictionary = record.get("cells", {})
	_expect(int(cells.get("count", 0)) == expected.cells, "%s cell count" % asset_id)
	_expect(_vec2i(cells.get("size", [])) == expected.cell_size, "%s cell size" % asset_id)
	_expect(cells.get("ids", []) == EXPECTED_CELL_IDS[asset_id], "%s cell order" % asset_id)
	if expected.has("anchor"):
		_expect(_vec2i(record.get("anchor", {}).get("point", [])) == expected.anchor, "%s anchor" % asset_id)
	var review: Dictionary = record.get("content_review", {})
	_expect(review.get("no_baked_text") == true and review.get("no_baked_numbers") == true and review.get("no_baked_exit_or_ui") == true, "%s no baked route text/UI metadata" % asset_id)
	_expect(ResourceLoader.exists(path), "%s imported texture exists" % asset_id)
	var texture := load(path) as Texture2D
	_expect(texture != null, "%s texture loads" % asset_id)
	if texture != null:
		_expect(Vector2i(texture.get_width(), texture.get_height()) == expected.size, "%s imported texture dimensions" % asset_id)
	var image := Image.new()
	var decode_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	_expect(decode_error == OK and not image.is_empty(), "%s PNG decodes" % asset_id)
	if image.is_empty():
		return
	_expect(image.get_size() == expected.size, "%s decoded image dimensions" % asset_id)
	if expected.mode == "RGBA":
		_expect(image.get_format() == Image.FORMAT_RGBA8, "%s decoded RGBA8" % asset_id)
		_expect(_transparent_corners(image), "%s transparent corners" % asset_id)
	elif expected.mode == "RGB":
		_expect(image.get_format() == Image.FORMAT_RGB8, "%s decoded RGB8" % asset_id)
	else:
		_expect(image.get_format() == Image.FORMAT_L8, "%s decoded L8" % asset_id)


func _validate_pack_policy(manifest: Dictionary) -> void:
	var policy: Dictionary = manifest.get("pack_policy", {})
	_expect(policy.get("runtime_png_count") == 7, "policy exact runtime PNG count")
	_expect(policy.get("raw_or_qc_under_runtime_root") == false, "policy no raw/QC leak")
	_expect(policy.get("background_contains_runtime_topology") == false, "policy no route topology in background")
	_expect(policy.get("daylight_contains_boss_lighting") == false, "policy no C lighting in daylight")
	_expect(policy.get("baked_text_numbers_exit_or_ui") == false, "policy no route text identifiers")
	var by_id: Dictionary = {}
	for value: Variant in manifest.get("assets", []):
		by_id[value.id] = value
	_expect(by_id.parchment_base.content_review.no_runtime_topology_in_background == true, "parchment background topology review")
	_expect(by_id.cairo_cartography_ink.content_review.no_runtime_topology_in_background == true, "Cairo ink topology review")
	_expect(by_id.parchment_base.lighting_scope == "daylight_neutral" and by_id.cairo_cartography_ink.lighting_scope == "daylight_neutral" and by_id.raised_route_tiles.lighting_scope == "daylight_neutral", "daylight layers remain neutral")
	_expect(by_id.night_vignette.lighting_scope == "boss_only" and by_id.lantern_glow.lighting_scope == "boss_triple_enhanced_only", "C lighting is boss-only")


func _validate_budgets(manifest: Dictionary) -> void:
	var budgets: Dictionary = manifest.get("budgets", {})
	_expect(int(budgets.get("normal_resident_decoded_bytes", 0)) <= 14 * 1024 * 1024, "normal decoded budget <=14 MiB")
	_expect(int(budgets.get("boss_peak_decoded_bytes", 0)) <= 16 * 1024 * 1024, "boss peak decoded budget <=16 MiB")
	_expect(int(budgets.get("runtime_png_source_bytes", 0)) <= 8 * 1024 * 1024, "runtime PNG/source budget <=8 MiB")
	_expect(int(budgets.get("maximum_general_runtime_edge_px", 0)) <= 1152, "general runtime edge <=1152")
	var exception: Dictionary = budgets.get("mandated_screen_mask_exception", {})
	_expect(exception.get("path") == "res://assets/art/v06/boss/night-vignette.png", "edge exception fixed to night vignette path")
	_expect(_vec2i(exception.get("dimensions", [])) == Vector2i(720, 1280), "edge exception fixed to exact viewport mask")
	_expect(exception.get("applies_to_any_other_asset") == false, "edge exception cannot apply to another asset")


func _validate_source_guard(manifest: Dictionary) -> void:
	var guard: Dictionary = manifest.get("immutable_source_guard", {})
	_expect(guard.get("path") == SOURCE_SPHINX_PATH, "source guard path")
	_expect(guard.get("sha256") == SOURCE_SPHINX_SHA, "source guard SHA")
	_expect(int(guard.get("source_bytes", 0)) == 1954756, "source guard byte size")
	_expect(FileAccess.get_sha256(SOURCE_SPHINX_PATH) == SOURCE_SPHINX_SHA, "existing 1254 sphinx SHA unchanged")
	_expect(guard.get("is_third_party") == false, "source is not falsely labeled third-party")


func _contains_forbidden_route_text_identifier(asset_id: String, path: String) -> bool:
	var normalized := (asset_id + "_" + path.get_file().get_basename()).to_lower().replace("-", "_")
	var tokens := normalized.split("_", false)
	for forbidden: String in ["exit", "ready", "hud", "label", "number", "dice", "die", "lap", "roll"]:
		if forbidden in tokens:
			return true
	return false


func _transparent_corners(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	return image.get_pixel(0, 0).a == 0.0 \
		and image.get_pixel(width - 1, 0).a == 0.0 \
		and image.get_pixel(0, height - 1).a == 0.0 \
		and image.get_pixel(width - 1, height - 1).a == 0.0


func _vec2i(value: Variant) -> Vector2i:
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)


func _finish() -> void:
	print("V06_ASSET_PACK_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)
