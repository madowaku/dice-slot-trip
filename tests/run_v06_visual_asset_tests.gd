extends SceneTree

const AtlasScript = preload("res://scripts/game/v06_atlas_view.gd")
const CourseScript = preload("res://scripts/game/v06_course_model.gd")
const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")
const CAT_IDLE := preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-idle-strip.png")
const CAT_JUMP := preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-jump-strip.png")
const CAT_LAND := preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-land-strip.png")
const PARCHMENT_BASE := preload("res://assets/art/v06/atlas/parchment-base.png")
const CAIRO_CARTOGRAPHY_INK := preload("res://assets/art/v06/atlas/cairo-cartography-ink.png")
const RAISED_ROUTE_TILES := preload("res://assets/art/v06/atlas/raised-route-tiles.png")
const GOLD_BOSS_GATE := preload("res://assets/art/v06/boss/gold-boss-gate.png")
const LEATHER_TEXTURE := preload("res://assets/art/v07/ui/dark-walnut-leather.png")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(Vector2i(CAT_IDLE.get_width(), CAT_IDLE.get_height()) == Vector2i(768, 192), "idle strip imports as 4x192")
	_expect(Vector2i(CAT_JUMP.get_width(), CAT_JUMP.get_height()) == Vector2i(1152, 192), "jump strip imports as 6x192")
	_expect(Vector2i(CAT_LAND.get_width(), CAT_LAND.get_height()) == Vector2i(768, 192), "land strip imports as 4x192")
	_expect(is_equal_approx(AtlasScript.HOP_SECONDS, 0.30), "one-step carousel hop uses the approved low-stimulation timing")
	_expect(AtlasScript.CAT_FEET_ANCHOR == Vector2(96.0, 179.0), "runtime uses production feet anchor")
	var atlas: Control = AtlasScript.new()
	atlas.size = Vector2(660.0, 760.0)
	root.add_child(atlas)
	await process_frame
	_expect(atlas.uses_production_cat_strips(), "atlas binds all three production cat strips")
	_expect(atlas.uses_production_environment_pack(), "atlas binds the four daylight and gate production textures")
	_expect(atlas.uses_production_tile_kind_icons(), "atlas binds all six normalized Kenney tile-kind textures")
	_expect(atlas.uses_semicircle_carousel(), "normal main travel uses the open-left semicircle carousel")
	_expect(atlas.carousel_slot_normalized_positions() == [Vector2(0.484375, 0.710744), Vector2(0.671875, 0.677686), Vector2(0.820313, 0.561983), Vector2(0.851563, 0.396694), Vector2(0.742188, 0.272727), Vector2(0.570313, 0.223140), Vector2(0.390625, 0.256198)], "carousel exposes the seven canonical normalized slot centers")
	_expect(atlas.carousel_moves_clockwise(), "carousel order moves clockwise from upper arm through right edge to lower arm")
	var edge_segments: Array[Dictionary] = atlas.carousel_main_edge_segments()
	_expect(edge_segments.size() == 2 and edge_segments[0].to == atlas.carousel_slot_position(0) and edge_segments[1].to == atlas.carousel_slot_position(6), "main carousel exposes two continuous open-left edge segments")
	_expect(atlas.set_route_position({"route_id":CourseScript.ROUTE_MAIN,"tile_index":18}, true), "visual tests restore the owner QA position before checking context tiles")
	var context_positions: Array[Dictionary] = atlas.carousel_context_positions()
	_expect(context_positions.size() == 4 and context_positions[0].tile_index == 16 and context_positions[1].tile_index == 17 and context_positions[2].tile_index == 25 and context_positions[3].tile_index == 26, "main carousel adds two subdued context tiles on each open-left endpoint without changing forward successors")
	_expect(atlas.carousel_context_slot_position(context_positions[0]).x < atlas.carousel_slot_position(0).x and atlas.carousel_context_slot_position(context_positions[2]).x < atlas.carousel_slot_position(6).x, "context tiles stay on the same horizontal continuation lines")
	_test_bypass_successors(atlas)
	_expect(atlas.carousel_cat_feet_anchor() == atlas.carousel_slot_position(0), "cat feet stay fixed at slot zero")
	_expect(is_equal_approx(atlas.carousel_tile_radius(), 30.0) and is_equal_approx(atlas.carousel_tile_radius(true), 34.0), "carousel future and current radii are 30 and 34")
	_expect(Vector2i(PARCHMENT_BASE.get_width(), PARCHMENT_BASE.get_height()) == Vector2i(1024, 1024), "production parchment imports")
	_expect(Vector2i(CAIRO_CARTOGRAPHY_INK.get_width(), CAIRO_CARTOGRAPHY_INK.get_height()) == Vector2i(1024, 1024), "production Cairo ink imports")
	_expect(Vector2i(RAISED_ROUTE_TILES.get_width(), RAISED_ROUTE_TILES.get_height()) == Vector2i(512, 128), "production raised tile strip imports")
	_expect(Vector2i(GOLD_BOSS_GATE.get_width(), GOLD_BOSS_GATE.get_height()) == Vector2i(512, 256), "production boss gate strip imports")
	_expect(LEATHER_TEXTURE.get_width() >= 1024 and LEATHER_TEXTURE.get_height() >= 1024, "approved tactile UI leather texture imports at production resolution")
	var leather_provenance_path := "res://assets/art/v07/ui/dark-walnut-leather.provenance.json"
	var leather_source_path := "res://docs/design/v07/art-source/dark-walnut-leather-imagegen-source.png"
	_expect(FileAccess.file_exists(leather_provenance_path), "leather ImageGen provenance is packaged for audit")
	_expect(FileAccess.file_exists(leather_source_path), "leather ImageGen source evidence is retained")
	var leather_provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(leather_provenance_path))
	_expect(String(leather_provenance.get("asset_id", "")) == "dark-walnut-leather" and String(leather_provenance.get("generation", {}).get("provider", "")) == "OpenAI built-in ImageGen", "leather provenance identifies asset and generator")
	_expect(FileAccess.get_sha256("res://assets/art/v07/ui/dark-walnut-leather.png") == String(leather_provenance.get("runtime", {}).get("sha256", "")) and FileAccess.get_sha256(leather_source_path) == String(leather_provenance.get("source", {}).get("sha256", "")), "leather runtime and source hashes match provenance")
	_expect(atlas.route_tile_cell_for(CourseScript.ROUTE_MAIN, false) == 0 and atlas.route_tile_cell_for(CourseScript.ROUTE_BYPASS, false) == 1 and atlas.route_tile_cell_for(CourseScript.ROUTE_LOOP, false) == 2 and atlas.route_tile_cell_for(CourseScript.ROUTE_MAIN, true) == 3, "route kinds select the canonical raised tile cells")
	_expect(atlas.boss_gate_cell() == 0, "boss gate remains unlit during normal daylight travel")
	_expect(is_equal_approx(atlas.tile_draw_diameter_for_radius(25.0), 76.25), "local raised tile is approximately 76px wide")
	_expect(is_equal_approx(atlas.kind_badge_radius_for_tile(25.0) * 2.0, 50.0), "local kind plate is approximately 50px wide")
	var core_kinds := ["NORMAL", "COIN", "REST", "RISK", "ITEM", "EVENT"]
	var expected_icon_ids := [&"imagegen_footprints", &"kenney_tokens_stack", &"kenney_campfire", &"kenney_skull", &"kenney_pouch", &"kenney_book_open"]
	var expected_files := ["normal-footprints.png", "coin-tokens-stack.png", "rest-campfire.png", "risk-skull.png", "item-pouch.png", "event-book-open.png"]
	var shape_ids := {}
	var icon_ids := {}
	for kind: String in core_kinds:
		var spec: Dictionary = atlas.tile_visual_spec(kind)
		shape_ids[String(spec.shape_id)] = true
		icon_ids[String(spec.icon_id)] = true
	_expect(shape_ids.size() == core_kinds.size(), "six core kinds have six color-independent silhouettes")
	_expect(icon_ids.size() == core_kinds.size(), "six core kinds have six distinct center icons")
	for index: int in range(core_kinds.size()):
		var icon_id: StringName = atlas.tile_visual_spec(core_kinds[index]).icon_id
		var mapping_label := "approved walking-footprints mapping" if core_kinds[index] == "NORMAL" else "exact approved Kenney mapping"
		_expect(icon_id == expected_icon_ids[index] and atlas.tile_kind_icon_texture(icon_id) != null, "%s uses its %s" % [core_kinds[index], mapping_label])
		_expect(FileAccess.file_exists("res://assets/art/v06/tile_kind_icons/%s" % expected_files[index]), "%s normalized PNG is packaged" % core_kinds[index])
		var opaque_bound: float = atlas.tile_kind_glyph_opaque_bound_at_360(core_kinds[index])
		_expect(opaque_bound >= 16.0 and opaque_bound <= 22.0, "%s opaque glyph stays readable and clear of its plate at 360" % core_kinds[index])
	var normal_used_rect: Rect2i = atlas.tile_kind_icon_texture(&"imagegen_footprints").get_image().get_used_rect()
	_expect(normal_used_rect.size.y > normal_used_rect.size.x * 1.4, "NORMAL reads as a tall alternating-footprints silhouette rather than the COIN stack")
	_expect(FileAccess.file_exists("res://assets/art/v06/tile_kind_icons/normal-footprints.provenance.json"), "NORMAL footprint provenance is packaged")
	_expect(atlas.CURRENT_RING_WIDTH >= 3.0 and atlas.CURRENT_RING_WIDTH <= 4.0, "current tile ring is a stronger but restrained focus cue")
	for provenance_path: String in [
		"res://third_party/kenney-board-game-icons/LICENSE.txt", "res://third_party/kenney-board-game-icons/source_url.txt",
		"res://third_party/kenney-board-game-info/LICENSE.txt", "res://third_party/kenney-board-game-info/source_url.txt",
		"res://third_party/kenney-boardgame-pack/LICENSE.txt", "res://third_party/kenney-boardgame-pack/source_url.txt",
	]:
		_expect(FileAccess.file_exists(provenance_path), "Kenney provenance file exists: %s" % provenance_path)
	_expect(int(atlas.tile_visual_spec("RISK").priority) < int(atlas.tile_visual_spec("REST").priority), "RISK remains the first visual priority ahead of REST")
	_expect(atlas.tile_kind_for(CourseScript.ROUTE_MAIN, 2) == "COIN" and atlas.tile_kind_for(CourseScript.ROUTE_MAIN, 7) == "REST" and atlas.tile_kind_for(CourseScript.ROUTE_MAIN, 21) == "RISK", "tile kinds come from canonical course data")
	atlas.set_kind_preview_override(PackedStringArray(["NORMAL", "COIN", "REST", "RISK", "ITEM", "EVENT"]))
	var preview_positions: Array[Dictionary] = atlas.prominent_positions()
	_expect(atlas.displayed_tile_kind_for(str(preview_positions[0].route_id), int(preview_positions[0].tile_index)) == "NORMAL" and atlas.tile_kind_for(str(preview_positions[0].route_id), int(preview_positions[0].tile_index)) == "NORMAL", "QA kind strip does not mutate canonical course data")
	_expect(String(atlas.tile_visual_spec("LOOP_PORTAL").icon_id) == "swirl" and String(atlas.tile_visual_spec("BYPASS_FORK").icon_id) == "fork" and String(atlas.tile_visual_spec("BOSS_GATE").icon_id) == "crown", "structural spaces keep unique non-text symbols")
	_expect(atlas.cat_animation_state() == &"idle", "atlas starts in idle")
	_expect(atlas.idle_animation_frame_for_elapsed(0.0) == 0, "idle rests on approved seed")
	_expect(atlas.idle_animation_frame_for_elapsed(3.3) == 1, "idle breath is a bounded hold")
	_expect(atlas.idle_animation_frame_for_elapsed(4.45) == 2, "idle blink is short and intentional")
	_expect(atlas.idle_animation_frame_for_elapsed(5.0) == 0, "idle returns to approved seed")
	var sequence := [
		atlas.animation_cell_for_hop_progress(0.00),
		atlas.animation_cell_for_hop_progress(0.12),
		atlas.animation_cell_for_hop_progress(0.30),
		atlas.animation_cell_for_hop_progress(0.50),
		atlas.animation_cell_for_hop_progress(0.68),
		atlas.animation_cell_for_hop_progress(0.80),
		atlas.animation_cell_for_hop_progress(0.92),
		atlas.animation_cell_for_hop_progress(0.99),
	]
	_expect(sequence == [
		{"strip": &"jump", "frame": 0},
		{"strip": &"jump", "frame": 1},
		{"strip": &"jump", "frame": 2},
		{"strip": &"jump", "frame": 3},
		{"strip": &"jump", "frame": 5},
		{"strip": &"land", "frame": 0},
		{"strip": &"land", "frame": 1},
		{"strip": &"land", "frame": 2},
	], "hop uses restrained crouch, takeoff, apex, contact, and compression keys")
	var capture_path := OS.get_environment("DICE_QA_CAT_CAPTURE_PATH")
	if not capture_path.is_empty():
		await _capture_runtime_screen(capture_path)
	atlas.queue_free()
	await process_frame
	print("V06_VISUAL_ASSET_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_bypass_successors(atlas: Control) -> void:
	var expected := [
		[{"route_id":CourseScript.ROUTE_BYPASS,"tile_index":1}, {"route_id":CourseScript.ROUTE_BYPASS,"tile_index":2}, {"route_id":CourseScript.ROUTE_BYPASS,"tile_index":3}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":20}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":21}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":22}],
		[{"route_id":CourseScript.ROUTE_BYPASS,"tile_index":2}, {"route_id":CourseScript.ROUTE_BYPASS,"tile_index":3}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":20}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":21}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":22}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":23}],
		[{"route_id":CourseScript.ROUTE_BYPASS,"tile_index":3}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":20}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":21}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":22}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":23}, {"route_id":CourseScript.ROUTE_MAIN,"tile_index":24}],
		[{"route_id":"main","tile_index":20}, {"route_id":"main","tile_index":21}, {"route_id":"main","tile_index":22}, {"route_id":"main","tile_index":23}, {"route_id":"main","tile_index":24}, {"route_id":"main","tile_index":25}],
	]
	for bypass_index: int in range(4):
		_expect(atlas.set_route_position({"route_id":CourseScript.ROUTE_BYPASS,"tile_index":bypass_index}, true), "bypass %d is a known canonical position" % bypass_index)
		_expect(atlas.prominent_positions() == expected[bypass_index], "bypass %d exposes exact traversable successor order" % bypass_index)
		_expect(atlas.future_successor_count() == 6 and atlas.prominent_space_count() == 6, "bypass %d fills all six future carousel slots" % bypass_index)
	var styles: PackedStringArray = atlas.carousel_segment_style_ids()
	_expect(styles == PackedStringArray([String(AtlasScript.ROUTE_STYLE_BYPASS), String(AtlasScript.ROUTE_STYLE_MAIN), String(AtlasScript.ROUTE_STYLE_MAIN), String(AtlasScript.ROUTE_STYLE_MAIN), String(AtlasScript.ROUTE_STYLE_MAIN), String(AtlasScript.ROUTE_STYLE_MAIN)]), "bypass terminal segment transitions from rust dashed to teal solid after rejoin")
	_expect(atlas.set_route_position({"route_id":CourseScript.ROUTE_MAIN,"tile_index":0}, true), "visual tests restore the canonical start")


func _capture_runtime_screen(path: String) -> void:
	OS.set_environment("DICE_QA_V06_SCENARIO", "atlas_18")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var host := Control.new()
	host.size = Vector2(720.0, 1280.0)
	viewport.add_child(host)
	var screen: Control = ScreenScene.instantiate()
	host.add_child(screen)
	for ignored: int in range(6):
		await process_frame
	var texture := viewport.get_texture()
	if texture == null:
		print("V06_CAT_CAPTURE_UNAVAILABLE renderer returned no viewport texture")
		OS.set_environment("DICE_QA_V06_SCENARIO", "")
		viewport.queue_free()
		await process_frame
		return
	var image := texture.get_image()
	if image == null:
		print("V06_CAT_CAPTURE_UNAVAILABLE renderer returned no viewport image")
		OS.set_environment("DICE_QA_V06_SCENARIO", "")
		viewport.queue_free()
		await process_frame
		return
	var result := image.save_png(path)
	_expect(image.get_size() == Vector2i(720, 1280) and result == OK, "runtime cat capture saves at 720x1280")
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	viewport.queue_free()
	await process_frame


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
