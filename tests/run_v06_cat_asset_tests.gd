extends SceneTree

const ROOT := "res://assets/art/v06/characters/explorer_cat"
const META_PATH := ROOT + "/animation-metadata.json"
const SEED_PATH := "res://art_source/v06/explorer_cat_seed/explorer-cat-seed-192.png"
const SEED_SHA := "eccf84a8ca380f2c1ad662868abdce664ad866e6072a0d67b5e00173e63cb1cd"
const FRAME_SIZE := Vector2i(192, 192)
const ANCHOR := Vector2i(96, 179)
const EXPECTED := {"idle": 4, "jump": 6, "land": 4}

var failures := 0


func _init() -> void:
	var metadata := _load_json(META_PATH)
	_expect(not metadata.is_empty(), "animation metadata parses")
	if metadata.is_empty():
		_finish()
		return
	_expect(FileAccess.get_sha256(SEED_PATH) == SEED_SHA, "approved seed SHA is unchanged")
	_expect(_vec2i(metadata.get("frame_size", [])) == FRAME_SIZE, "metadata uses 192px frames")
	_expect(_vec2i(metadata.get("anchor", [])) == ANCHOR, "metadata uses shared feet anchor 96,179")
	_expect(metadata.get("anchor_kind") == "bottom_center_feet", "metadata declares bottom-center feet anchor")
	var canonical_feet_center_x := float(metadata.get("canonical_visual_feet_center_x", -1.0))
	var metadata_strips: Dictionary = metadata.get("strips", {})
	var seed := _load_png(SEED_PATH)
	_expect(not seed.is_empty(), "approved seed decodes")
	for strip_name: String in EXPECTED:
		var frame_count: int = EXPECTED[strip_name]
		_expect(metadata_strips.has(strip_name), "%s metadata exists" % strip_name)
		if metadata_strips.has(strip_name):
			_expect(int(metadata_strips[strip_name].get("frame_count", 0)) == frame_count, "%s frame count metadata" % strip_name)
		_validate_strip(strip_name, frame_count, seed, canonical_feet_center_x)
	_finish()


func _validate_strip(strip_name: String, frame_count: int, seed: Image, canonical_feet_center_x: float) -> void:
	var strip_path := "%s/explorer-cat-%s-strip.png" % [ROOT, strip_name]
	var strip_image := _load_png(strip_path)
	_expect(not strip_image.is_empty(), "%s production strip decodes" % strip_name)
	if not strip_image.is_empty():
		_expect(strip_image.get_size() == Vector2i(FRAME_SIZE.x * frame_count, FRAME_SIZE.y), "%s strip dimensions" % strip_name)
	if strip_image.is_empty():
		return
	for index: int in range(1, frame_count + 1):
		var image := strip_image.get_region(Rect2i((index - 1) * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y))
		_expect(image.get_size() == FRAME_SIZE, "%s frame %02d is 192px" % [strip_name, index])
		_expect(image.get_format() == Image.FORMAT_RGBA8, "%s frame %02d is RGBA8" % [strip_name, index])
		_expect(_transparent_corners(image), "%s frame %02d has transparent corners" % [strip_name, index])
		var bbox := _alpha_bbox(image)
		_expect(bbox.size.x > 0 and bbox.size.y > 0, "%s frame %02d has sprite content" % [strip_name, index])
		if bbox.size.x <= 0 or bbox.size.y <= 0:
			continue
		_expect(bbox.position.x >= 4 and bbox.position.y >= 4 and bbox.position.x + bbox.size.x <= FRAME_SIZE.x - 4, "%s frame %02d keeps safety margin" % [strip_name, index])
		_expect(bbox.position.y + bbox.size.y == ANCHOR.y + 1, "%s frame %02d shares feet anchor" % [strip_name, index])
		_expect(absf(_feet_center_x(image, bbox) - canonical_feet_center_x) <= 1.0, "%s frame %02d shares visual feet alignment" % [strip_name, index])
		_expect(_strong_key_fringe_count(image) <= 6, "%s frame %02d has no added chroma fringe" % [strip_name, index])
		var should_lock := (strip_name == "idle" and index == 1) \
			or (strip_name == "jump" and index == 1) \
			or (strip_name == "land" and index == 4)
		if should_lock:
			_expect(image.get_data() == seed.get_data(), "%s frame %02d locks to approved seed" % [strip_name, index])


func _alpha_bbox(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			if image.get_pixel(x, y).a * 255.0 > 8.0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _strong_key_fringe_count(image: Image) -> int:
	var count := 0
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.a < 1.0 and pixel.g > 0.70 and pixel.r < 0.32 and pixel.b < 0.40:
				count += 1
	return count


func _feet_center_x(image: Image, bbox: Rect2i) -> float:
	var band_top := bbox.position.y + int(float(bbox.size.y) * 0.85)
	var min_x := image.get_width()
	var max_x := -1
	for y: int in range(band_top, bbox.position.y + bbox.size.y):
		for x: int in range(bbox.position.x, bbox.position.x + bbox.size.x):
			if image.get_pixel(x, y).a * 255.0 > 8.0:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	return (float(min_x) + float(max_x)) * 0.5


func _transparent_corners(image: Image) -> bool:
	var width := image.get_width()
	var height := image.get_height()
	return image.get_pixel(0, 0).a == 0.0 \
		and image.get_pixel(width - 1, 0).a == 0.0 \
		and image.get_pixel(0, height - 1).a == 0.0 \
		and image.get_pixel(width - 1, height - 1).a == 0.0


func _load_png(path: String) -> Image:
	var image := Image.new()
	var result := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image if result == OK else Image.new()


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _vec2i(value: Variant) -> Vector2i:
	if value is Array and value.size() == 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)


func _finish() -> void:
	print("V06_CAT_ASSET_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)
