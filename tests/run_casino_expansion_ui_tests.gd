extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const RouletteScript = preload("res://scripts/app/dice_roulette_screen.gd")
const TreasureScript = preload("res://scripts/app/treasure_21_screen.gd")
const PokerScript = preload("res://scripts/app/dice_poker_screen.gd")
const VaultScript = preload("res://scripts/app/vault_break_screen.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")

var failures := 0
var assertions := 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _assert_buttons_inside_map(hub: CasinoHubScreen, map: Control, label: String) -> void:
	var safety := 11.0
	for id: String in ["dice_race", "dice_tower", "dice_roulette", "treasure_21", "dice_poker", "vault_break"]:
		var button := hub.facility_nodes.get(id) as Button
		var rect := Rect2(button.position, button.size)
		_expect(rect.position.x >= safety and rect.position.y >= safety, "%s %s CTA starts inside map" % [label, id])
		_expect(rect.end.x <= map.size.x - safety and rect.end.y <= map.size.y - safety, "%s %s CTA ends inside map" % [label, id])

func _assert_sparkle_above_center(map: Control, label: String) -> void:
	var sparkle := map.get_node_or_null("RingSelectionSparkle") as AnimatedSprite2D
	var center_panel := map.get_node_or_null("RingCenter") as PanelContainer
	if sparkle == null or center_panel == null:
		_expect(false, "%s sparkle and center panel are present" % label)
		return
	var sparkle_half := Vector2(128.0, 128.0) * sparkle.scale
	var sparkle_rect := Rect2(sparkle.position - sparkle_half, sparkle_half * 2.0)
	var center_rect := Rect2(center_panel.position, center_panel.size)
	_expect(not sparkle_rect.intersects(center_rect), "%s selection sparkle stays above center copy" % label)

func _assert_cta_colors(button: Button, id: String) -> void:
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		_expect(button.has_theme_color_override(color_name), "%s CTA explicitly overrides %s" % [id, color_name])
		var color := button.get_theme_color(color_name)
		_expect(color.get_luminance() >= 0.55, "%s CTA %s text remains light against dark fill" % [id, color_name])

func _assert_how_to(screen: Node, id: String, actions: Array[String]) -> void:
	var panel := screen.find_child("CasinoHowTo3Steps", true, false) as PanelContainer
	_expect(panel != null, "%s exposes the shared CasinoHowTo3Steps panel" % id)
	if panel == null:
		return
	_expect(str(panel.get_meta("facility_id", "")) == id, "%s shared how-to metadata identifies the facility" % id)
	var headings: Array[String] = [
		"① 最初に何をする？",
		"② プレイ中に何をする？",
		"③ どうなれば勝ち？",
	]
	for index: int in range(3):
		var heading := panel.find_child("Step%dHeading" % (index + 1), true, false) as Label
		var detail := panel.find_child("Step%dDetail" % (index + 1), true, false) as Label
		_expect(heading != null and heading.text == headings[index], "%s keeps shared step heading %d" % [id, index + 1])
		_expect(detail != null and index < actions.size() and actions[index] in detail.text and detail.text.length() <= 48, "%s keeps concise step copy %d" % [id, index + 1])

func _run() -> void:
	var save_path := "user://dice_slot_trip_casino_expansion_ui_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CasinoBankScript.add_chips(250)
	HubScript.suppress_audio_for_tests = true
	RouletteScript.suppress_audio_for_tests = true
	TreasureScript.suppress_audio_for_tests = true
	PokerScript.suppress_audio_for_tests = true
	VaultScript.suppress_audio_for_tests = true

	var hub := HUB_SCENE.instantiate() as CasinoHubScreen
	root.add_child(hub)
	await process_frame
	_expect(hub != null, "Casino Hub scene instantiates")
	_expect(hub.facility_definitions.size() == 6, "hub keeps the six-facility order")
	_expect(hub.card_data.size() == 6, "dormant prize-card data remains loaded")
	_expect(hub.prize_list == null and hub.find_children("*", "ScrollContainer", true, false).is_empty(), "Hub has no Prize Counter or scrolling container")
	_expect(hub.find_children("*", "Button", true, false).all(func(candidate: Button) -> bool: return "OWNED" not in candidate.text and not candidate.text.ends_with(" CHIP")), "Hub has no visible prize rows")
	var expected_ids := ["dice_race", "dice_tower", "dice_roulette", "treasure_21", "dice_poker", "vault_break"]
	for index: int in range(expected_ids.size()):
		var definition: Dictionary = hub.facility_definitions[index]
		var id := str(definition.get("id", ""))
		var button := hub.facility_nodes.get(id) as Button
		var button_label := str(definition.get("button_label", ""))
		var subtitle := str(definition.get("subtitle", ""))
		_expect(id == expected_ids[index], "facility %d remains %s" % [index + 1, expected_ids[index]])
		_expect(bool(hub.facility_availability.get(id, false)), "%s route is available" % id)
		_expect(button != null and button_label in button.text and "遊ぶ" in button.text and subtitle in button.tooltip_text, "%s exposes Japanese identity, action, and guidance" % id)
	_expect(not hub.facility_definitions.any(func(definition: Dictionary) -> bool: return str(definition.get("id", "")) == "high_low"), "HIGH / LOW is absent from the active hub")

	var map_art := hub.find_child("RingMapBackground", true, false) as TextureRect
	_expect(map_art != null and map_art.texture != null and map_art.texture.resource_path == "res://assets/casino/las_vegas/las-vegas-ring-map-v1.png", "hub uses the authored Las Vegas ring map texture")
	_expect(map_art != null and map_art.visible, "ring map texture is visible")
	var sparkle := hub.find_child("RingSelectionSparkle", true, false) as AnimatedSprite2D
	_expect(sparkle != null and sparkle.visible and sparkle.sprite_frames != null, "hub loads the authored selection sparkle animation")
	_expect(sparkle != null and sparkle.sprite_frames.get_frame_count("ambient") == 4, "selection sparkle keeps four atlas frames")
	_expect(hub.facility_nodes.size() == 6, "ring map creates six facility nodes")
	for id: String in expected_ids:
		var button := hub.facility_nodes.get(id) as Button
		_expect(button != null and button.size.x >= UiTokensScript.TOUCH_MIN and button.size.y >= UiTokensScript.BUTTON_HEIGHT, "%s CTA keeps the shared large touch target" % id)
		_expect(button != null and button.get_theme_font_size("font_size") >= UiTokensScript.FONT_CAPTION, "%s CTA keeps the shared readable type size" % id)
		if button != null:
			_assert_cta_colors(button, id)
	_assert_buttons_inside_map(hub, map_art.get_parent() as Control, "720 design bounds")
	_assert_sparkle_above_center(map_art.get_parent() as Control, "720 design bounds")
	var map_canvas := map_art.get_parent() as Control
	map_canvas.size = Vector2(316, 616)
	hub.call("_layout_ring_map", map_canvas)
	_assert_buttons_inside_map(hub, map_canvas, "360x800 portrait fit")
	_assert_sparkle_above_center(map_canvas, "360x800 portrait fit")
	var hub_back := hub.find_child("BackToTripButton", true, false) as Button
	_expect(hub_back != null and hub_back.text == "旅へ戻る" and hub_back.get_global_rect().end.y <= hub.hub_root.get_global_rect().end.y, "complete non-scrolling Hub keeps its return action on-screen")

	for id: String in ["dice_roulette", "treasure_21", "dice_poker", "vault_break"]:
		_expect(bool(hub.call("_open_facility", id)), "%s opens from the Las Vegas ring" % id)
		await process_frame
		var host := hub.facility_hosts.get(id) as Control
		_expect(host != null and host.visible and host.get_child_count() == 1, "%s host is visible" % id)
		var screen := host.get_child(0)
		_expect(screen.has_signal("back_requested"), "%s exposes the return signal" % id)
		var casino_back := screen.find_child("CasinoBackButton", true, false) as Button
		_expect(casino_back != null and casino_back.text == "カジノへ戻る" and casino_back.custom_minimum_size.y >= UiTokensScript.TOUCH_MIN and casino_back.get_theme_font_size("font_size") >= UiTokensScript.FONT_CAPTION and casino_back.has_theme_stylebox_override("focus"), "%s uses the large shared Japanese casino-return action" % id)
		var how_to_actions: Array[String] = []
		match id:
			"dice_roulette":
				how_to_actions = ["ベットを決める", "回す", "的中を確認する"]
			"treasure_21":
				how_to_actions = ["ベットを決める", "サイコロを振る", "ここで受け取る"]
			"dice_poker":
				how_to_actions = ["ベットを決める", "キープして振り直す", "役を作る"]
			"vault_break":
				how_to_actions = ["ベットと金庫を選ぶ", "サイコロを振って置く", "6つのロックを埋める"]
		_assert_how_to(screen, id, how_to_actions)
		screen.emit_signal("back_requested")
		await process_frame
		_expect(hub.hub_root.visible and not host.visible, "back from %s restores the Casino Hub" % id)

	hub.queue_free()
	await process_frame
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	var sfx := root.get_node_or_null("UiSfxManager")
	if sfx != null:
		sfx.call("stop_all")
	await process_frame
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	CasinoBankScript.clear_test_save_path()
	HubScript.suppress_audio_for_tests = false
	RouletteScript.suppress_audio_for_tests = false
	TreasureScript.suppress_audio_for_tests = false
	PokerScript.suppress_audio_for_tests = false
	VaultScript.suppress_audio_for_tests = false
	print("Casino expansion UI tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
