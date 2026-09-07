extends SceneTree

const BankScript = preload("res://scripts/game/casino_bank.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const RaceScreen = preload("res://scripts/app/dice_race_screen.gd")
const RouletteScreen = preload("res://scripts/app/dice_roulette_screen.gd")
const PokerScreen = preload("res://scripts/app/dice_poker_screen.gd")
const TreasureScreen = preload("res://scripts/app/treasure_21_screen.gd")
const VaultScreen = preload("res://scripts/app/vault_break_screen.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const DEFAULT_VIEWPORT: Vector2i = Vector2i(360, 800)
const FACILITY_IDS: Array[String] = ["dice_race", "dice_tower", "dice_roulette", "treasure_21", "dice_poker", "vault_break"]

var assertions: int = 0
var failures: int = 0
var viewport_size: Vector2i = DEFAULT_VIEWPORT
var output_dir: String = ""
var fixture_path: String = ""
var production_path: String = ""
var production_hash_before: String = ""
var capture_viewport: SubViewport
var capture_root: Control
var stage_records: Array[Dictionary] = []
var require_capture: bool = false
var actual_rendering: bool = false
var audit_audio: bool = false

func _init() -> void:
	call_deferred("_record")

func _expect(value: bool, label: String) -> void:
	assertions += 1
	if value:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _record() -> void:
	_read_environment()
	DirAccess.make_dir_recursive_absolute(output_dir)
	production_path = ProjectSettings.globalize_path(BankScript.SAVE_PATH)
	production_hash_before = _fingerprint(production_path)
	fixture_path = ProjectSettings.globalize_path("res://.qa-casino-feel-recorder-%d.json" % OS.get_process_id())
	_remove_fixture()
	BankScript.set_test_save_path(fixture_path)
	var fixture: Dictionary = BankScript.default_data()
	fixture["chips"] = 300
	_expect(BankScript.save_data(fixture), "recorder starts from isolated 300 CHIP")
	_set_audio_suppressed(not audit_audio)
	_build_viewport()

	var hub: Node = HUB_SCENE.instantiate()
	capture_root.add_child(hub)
	await _settle_frames(8)
	await _capture("00-hub-start")
	var actual_ids: Array[String] = []
	for definition: Dictionary in hub.facility_definitions:
		actual_ids.append(str(definition.get("id", "")))
	_expect(actual_ids == FACILITY_IDS, "recorder follows displayed HUB order")
	stage_records.append(_record_state("hub_start", {"balance": BankScript.balance(), "facility_order": actual_ids}))

	for index: int in range(FACILITY_IDS.size()):
		var facility_id: String = FACILITY_IDS[index]
		var button: Button = hub.facility_buttons.get(facility_id) as Button
		var open_started: int = Time.get_ticks_msec()
		button.pressed.emit()
		await _settle_frames(8)
		var host: Control = hub.facility_hosts.get(facility_id) as Control
		var screen: Node = host.get_child(0) if host != null and host.get_child_count() == 1 else null
		_expect(screen != null and hub.active_facility_id == facility_id and not hub.hub_root.visible, "%s opens through its HUB CTA" % facility_id)
		if audit_audio:
			var bgm: Node = root.get_node_or_null("BgmManager")
			var sfx: Node = root.get_node_or_null("UiSfxManager")
			_expect(bgm != null and str(bgm.call("current_track")) == facility_id, "%s selects its dedicated BGM" % facility_id)
			var audio_receipt: Dictionary = sfx.call("receipt") as Dictionary if sfx != null else {}
			_expect(str(audio_receipt.get("stage_id", "")) == "las_vegas", "%s keeps UI SFX on the Las Vegas stage pack" % facility_id)
		var layout: Dictionary = _layout_receipt(screen)
		_expect(bool(layout.get("all_visible_buttons_inside", false)), "%s visible CTAs fit at %dx%d" % [facility_id, viewport_size.x, viewport_size.y])
		stage_records.append(_record_state("facility_open", {
			"facility": facility_id,
			"elapsed_ms": Time.get_ticks_msec() - open_started,
			"balance": BankScript.balance(),
			"layout": layout,
		}))
		await _capture("%02d-%s-setup" % [index + 1, facility_id])
		if screen != null and facility_id in ["dice_tower", "vault_break"]:
			await _exercise_responsive_scroll(screen, facility_id, index + 1)
		elif screen != null:
			await _exercise_tour_gameplay(screen, facility_id, index + 1)
		if screen != null:
			screen.emit_signal("back_requested")
		await _settle_frames(6)
		_expect(hub.hub_root.visible and hub.active_facility_id.is_empty() and host != null and host.get_child_count() == 0, "%s closes and releases its scene" % facility_id)
		if audit_audio:
			var bgm: Node = root.get_node_or_null("BgmManager")
			_expect(bgm != null and bgm.call("current_track") == &"lasvegas_main", "%s teardown restores HUB BGM" % facility_id)
		stage_records.append(_record_state("facility_close", {
			"facility": facility_id,
			"balance": BankScript.balance(),
			"hub_visible": hub.hub_root.visible,
			"host_children": host.get_child_count() if host != null else -1,
		}))
		await _capture("%02d-%s-hub-return" % [index + 1, facility_id])

	var trip_back: Button = hub.find_child("BackToTripButton", true, false) as Button
	_expect(trip_back != null and trip_back.text == "旅へ戻る", "tour ends at 旅へ戻る")
	stage_records.append(_record_state("tour_complete", {
		"balance": BankScript.balance(),
		"trip_cta": trip_back.text if trip_back != null else "",
		"objective_status": "PASS" if failures == 0 else "FAIL",
	}))
	hub.queue_free()
	await _settle_frames(3)
	await _cleanup()
	var production_hash_after: String = _fingerprint(production_path)
	_expect(production_hash_after == production_hash_before, "production CasinoBank save hash remains unchanged")
	_expect(not FileAccess.file_exists(fixture_path), "recorder fixture is removed")
	_write_stage_log(production_hash_after)
	print("CASINO_FEEL_FINAL_CAPTURE size=%s assertions=%d failures=%d actual_rendering=%s output=%s" % [viewport_size, assertions, failures, actual_rendering, output_dir])
	quit(1 if failures > 0 else 0)

func _read_environment() -> void:
	output_dir = OS.get_environment("CASINO_FEEL_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/qa/casino-feel-final/%dx%d" % [DEFAULT_VIEWPORT.x, DEFAULT_VIEWPORT.y])
	var value: String = OS.get_environment("CASINO_FEEL_QA_VIEWPORT").to_lower()
	if not value.is_empty():
		var parts: PackedStringArray = value.split("x")
		if parts.size() == 2:
			viewport_size = Vector2i(maxi(240, int(parts[0])), maxi(480, int(parts[1])))
	require_capture = OS.get_environment("CASINO_FEEL_QA_REQUIRE_CAPTURE").to_lower() in ["1", "true", "yes"]
	audit_audio = OS.get_environment("CASINO_FEEL_QA_AUDIO").to_lower() in ["1", "true", "yes"]

func _build_viewport() -> void:
	root.size = viewport_size
	var design_scale: float = float(viewport_size.x) / 720.0
	var design_size: Vector2i = Vector2i(720, ceili(float(viewport_size.y) / design_scale))
	capture_viewport = SubViewport.new()
	capture_viewport.name = "CasinoFeelFinalViewport"
	capture_viewport.size = viewport_size
	capture_viewport.size_2d_override = design_size
	capture_viewport.size_2d_override_stretch = false
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.transparent_bg = false
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.name = "CasinoFeelFinalRoot"
	capture_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	capture_root.size = Vector2(design_size)
	capture_root.scale = Vector2(design_scale, design_scale)
	capture_viewport.add_child(capture_root)

func _layout_receipt(screen: Node) -> Dictionary:
	var bounds: Rect2 = capture_root.get_global_rect().grow(1.0)
	var visible_buttons: int = 0
	var all_inside: bool = true
	var labels: Array[String] = []
	var outside: Array[Dictionary] = []
	var scrollable_outside: Array[Dictionary] = []
	for candidate: Node in screen.find_children("*", "Button", true, false):
		var button: Button = candidate as Button
		if button == null or not button.is_visible_in_tree():
			continue
		visible_buttons += 1
		var copy: String = button.text.replace("\n", " / ")
		labels.append(copy)
		var rect: Rect2 = button.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0 or not bounds.encloses(rect):
			var finding: Dictionary = {
				"name": button.name,
				"label": copy,
				"x": rect.position.x,
				"y": rect.position.y,
				"width": rect.size.x,
				"height": rect.size.y,
			}
			# ScrollContainer children may be laid out outside the current clip and
			# become reachable by scrolling. Only fixed/non-scroll CTA overflow is a
			# responsive failure; retain scrollable outliers as objective evidence.
			if _has_scroll_ancestor(button):
				scrollable_outside.append(finding)
			else:
				all_inside = false
				outside.append(finding)
	return {
		"visible_button_count": visible_buttons,
		"all_visible_buttons_inside": all_inside,
		"button_labels": labels,
		"outside_buttons": outside,
		"scrollable_outside_buttons": scrollable_outside,
	}

func _has_scroll_ancestor(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null and parent != capture_root:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false

func _exercise_responsive_scroll(screen: Node, facility_id: String, index: int) -> void:
	var scroll_name: String = "TowerContentScroll" if facility_id == "dice_tower" else "VaultBreakContentScroll"
	var scroll: ScrollContainer = screen.find_child(scroll_name, true, false) as ScrollContainer
	var start: Button = screen.find_child("StartButton", true, false) as Button
	_expect(scroll != null, "%s exposes one named vertical content scroller" % facility_id)
	_expect(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s keeps horizontal scrolling disabled" % facility_id)
	if scroll == null or start == null:
		_expect(false, "%s exposes its start CTA through the content scroller" % facility_id)
		return
	if facility_id == "dice_tower":
		var skip: Button = screen.find_child("TutorialSkipButton", true, false) as Button
		if skip != null and skip.is_visible_in_tree():
			skip.pressed.emit()
			await _settle_frames(2)
	var vertical_bar: VScrollBar = scroll.get_v_scroll_bar()
	var maximum_scroll: float = maxf(0.0, vertical_bar.max_value - vertical_bar.page)
	if viewport_size == Vector2i(720, 1280):
		_expect(maximum_scroll > 0.0, "%s has a vertical path to its below-fold CTA at 720x1280" % facility_id)
	scroll.ensure_control_visible(start)
	await _settle_frames(4)
	var start_reachable: bool = scroll.get_global_rect().grow(1.0).encloses(start.get_global_rect())
	_expect(start_reachable, "%s start CTA becomes fully reachable by scrolling" % facility_id)
	var back: Button = screen.find_child("CasinoBackButton", true, false) as Button
	if facility_id == "vault_break" and back != null:
		scroll.ensure_control_visible(back)
		await _settle_frames(4)
		_expect(scroll.get_global_rect().grow(1.0).encloses(back.get_global_rect()), "vault_break return CTA becomes fully reachable by scrolling")
		scroll.ensure_control_visible(start)
		await _settle_frames(3)
	await _capture("%02d-%s-cta-reachable" % [index, facility_id])
	_expect(not start.disabled, "%s reachable start CTA is enabled" % facility_id)
	start.pressed.emit()
	await _settle_frames(6)
	var active_view: Control = screen.find_child("TowerActiveView" if facility_id == "dice_tower" else "VaultBreakActiveView", true, false) as Control
	_expect(active_view != null and active_view.visible, "%s start CTA opens the active game view" % facility_id)
	_expect(scroll.scroll_vertical == 0, "%s active transition resets content scroll to the top" % facility_id)
	if facility_id == "dice_tower":
		screen.set("queued_roll_value", 1)
		(screen.get("roll_button") as Button).pressed.emit()
		await _wait_for_visible(screen.get("result_overlay") as Control, 180)
		await create_timer(0.70).timeout
		_expect((screen.get("result_overlay") as Control).visible, "dice_tower real roll reaches its BUST result")
	else:
		screen.set("animation_duration_scale", 0.0)
		for step: Array in [[1, 0], [4, 1], [6, 2]]:
			screen.set("queued_roll_value", int(step[0]))
			(screen.get("roll_button") as Button).pressed.emit()
			await _settle_frames(8)
			screen.call("_on_lock_pressed", int(step[1]))
			await _settle_frames(8)
		await _wait_for_visible(screen.get("result_view") as Control, 120)
		await create_timer(0.45).timeout
		_expect((screen.get("result_view") as Control).visible, "vault_break real lock choices reach SUCCESS result")
	await _capture("%02d-%s-result" % [index, facility_id])
	_expect(_visible_text(screen).contains("収支") or _visible_text(screen).contains("BET"), "%s result explains the wager outcome" % facility_id)
	scroll.scroll_vertical = int(maximum_scroll)
	if facility_id == "dice_tower":
		var retry: Button = screen.find_child("RetryButton", true, false) as Button
		if retry != null:
			retry.pressed.emit()
	else:
		var again: Button = screen.get("again_button") as Button
		if again != null:
			again.pressed.emit()
	await _settle_frames(4)
	_expect(scroll.scroll_vertical == 0, "%s next presentation state resets content scroll to the top" % facility_id)
	stage_records.append(_record_state("responsive_scroll", {
		"facility": facility_id,
		"horizontal_disabled": scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"maximum_scroll": maximum_scroll,
		"start_reachable": start_reachable,
		"transition_scroll_top": scroll.scroll_vertical,
	}))

func _exercise_tour_gameplay(screen: Node, facility_id: String, index: int) -> void:
	var balance_before: int = BankScript.balance()
	match facility_id:
		"dice_race":
			var start: Button = screen.get("start_button") as Button
			start.pressed.emit()
			await _settle_frames(4)
			var race: Dictionary = screen.get("race") as Dictionary
			var selected: String = str(screen.get("selected_racer"))
			var racers: Dictionary = race.get("racers", {}) as Dictionary
			for racer: Variant in racers.keys():
				var racer_state: Dictionary = racers.get(racer, {}) as Dictionary
				racer_state["position"] = 23 if str(racer) == selected else 0
				racer_state["foxfire_pending"] = false
				racer_state["log_pending"] = false
				racers[racer] = racer_state
			race["racers"] = racers
			screen.set("race", race)
			screen.set("queued_coast_steps", 0)
			var roll: Button = screen.get("roll_button") as Button
			roll.pressed.emit()
			await _settle_frames(2)
			roll.pressed.emit()
			await _wait_for_visible(screen.get("result_view") as Control, 300)
			await _wait_for_presentation_unlock(screen, 180)
			_expect((screen.get("result_view") as Control).visible, "dice_race real stop action reaches the finish result")
		"dice_roulette":
			screen.call("_select_amount", 10)
			screen.call("_place_main_bet", "HIGH")
			(screen.get("spin_button") as Button).pressed.emit()
			for _frame: int in range(300):
				if int(screen.get("phase")) == 7:
					break
				await create_timer(0.02).timeout
			_expect(int(screen.get("phase")) == 7, "dice_roulette real bet and spin reach ROUND_END")
		"treasure_21":
			screen.set("queued_golden_number", 19)
			screen.set("queued_roll_value", 6)
			(screen.get("start_button") as Button).pressed.emit()
			await _wait_for_unlocked(screen, 120)
			for face: int in [6, 6, 1]:
				if (screen.get("result_view") as Control).visible:
					break
				screen.set("queued_roll_value", face)
				(screen.get("roll_button") as Button).pressed.emit()
				await _wait_for_unlocked(screen, 120)
			await _wait_for_visible(screen.get("result_view") as Control, 180)
			_expect((screen.get("result_view") as Control).visible, "treasure_21 real rolls reach GOLDEN result")
		"dice_poker":
			screen.set("queued_roll_batch", [[2, 2, 3, 4, 6]])
			(screen.get("deal_button") as Button).pressed.emit()
			await _wait_for_unlocked(screen, 180)
			var keep_buttons: Dictionary = screen.get("keep_buttons") as Dictionary
			for die_index: int in range(5):
				(keep_buttons.get(die_index) as Button).pressed.emit()
			await _settle_frames(2)
			(screen.get("lock_button") as Button).pressed.emit()
			await _wait_for_visible(screen.get("result_view") as Control, 240)
			await _wait_for_unlocked(screen, 240)
			_expect((screen.get("result_view") as Control).visible, "dice_poker real HOLD and lock actions reach result")
	await _capture("%02d-%s-result" % [index, facility_id])
	var result_copy: String = _visible_text(screen)
	_expect(result_copy.contains("BET") and (result_copy.contains("収支") or result_copy.contains("受け取り") or result_copy.contains("RETURN") and result_copy.contains("NET")), "%s result shows BET and outcome accounting" % facility_id)
	stage_records.append(_record_state("tour_gameplay_result", {
		"facility": facility_id,
		"balance_before": balance_before,
		"balance_after": BankScript.balance(),
		"result_copy": result_copy,
	}))

func _wait_for_visible(control: Control, max_frames: int) -> void:
	for _frame: int in range(max_frames):
		if control != null and control.visible:
			return
		await create_timer(0.02).timeout

func _wait_for_unlocked(screen: Node, max_frames: int) -> void:
	for _frame: int in range(max_frames):
		if not bool(screen.get("presentation_locked")) and not bool(screen.get("rolling")):
			return
		await create_timer(0.02).timeout

func _wait_for_presentation_unlock(screen: Node, max_frames: int) -> void:
	for _frame: int in range(max_frames):
		if not bool(screen.get("presentation_locked")):
			return
		await create_timer(0.02).timeout

func _visible_text(screen: Node) -> String:
	var parts: Array[String] = []
	for candidate: Node in screen.find_children("*", "Label", true, false):
		var label: Label = candidate as Label
		if label != null and label.is_visible_in_tree() and not label.text.is_empty():
			parts.append(label.text.replace("\n", " / "))
	for candidate: Node in screen.find_children("*", "Button", true, false):
		var button: Button = candidate as Button
		if button != null and button.is_visible_in_tree() and not button.text.is_empty():
			parts.append(button.text.replace("\n", " / "))
	return " | ".join(parts)

func _capture(label: String) -> void:
	await _settle_frames(3)
	var image: Image = null
	if DisplayServer.get_name() != "headless" and is_instance_valid(capture_viewport):
		await RenderingServer.frame_post_draw
		var texture: ViewportTexture = capture_viewport.get_texture()
		if texture != null:
			image = texture.get_image()
	if image == null or image.is_empty():
		stage_records.append(_record_state("capture_unavailable", {"label": label, "display_server": DisplayServer.get_name()}))
		if require_capture:
			_expect(false, "%s capture is available" % label)
		return
	actual_rendering = true
	var path: String = output_dir.path_join("%s-%dx%d.png" % [label, viewport_size.x, viewport_size.y])
	var result: Error = image.save_png(path)
	_expect(result == OK and image.get_size() == viewport_size, "%s screenshot is saved at physical size" % label)
	stage_records.append(_record_state("capture", {"label": label, "path": path, "bytes": FileAccess.get_file_as_bytes(path).size()}))

func _record_state(event: String, extra: Dictionary = {}) -> Dictionary:
	var value: Dictionary = {"event": event, "time_ms": Time.get_ticks_msec()}
	for key: Variant in extra.keys():
		value[str(key)] = extra[key]
	return value

func _write_stage_log(production_hash_after: String) -> void:
	var payload: Dictionary = {
		"status": "CASINO_FEEL_FINAL_OBJECTIVE_PASS" if failures == 0 else "FAIL",
		"viewport": {"width": viewport_size.x, "height": viewport_size.y},
		"assertions": assertions,
		"failures": failures,
		"actual_rendering": actual_rendering,
		"production_save_hash_before": production_hash_before,
		"production_save_hash_after": production_hash_after,
		"fixture_removed": not FileAccess.file_exists(fixture_path),
		"records": stage_records,
	}
	var file: FileAccess = FileAccess.open(output_dir.path_join("stage-log.json"), FileAccess.WRITE)
	if file == null:
		push_error("FAIL: cannot write Casino Feel stage log")
		return
	file.store_string(JSON.stringify(payload, "  "))

func _settle_frames(count: int) -> void:
	for _index: int in count:
		await process_frame

func _set_audio_suppressed(value: bool) -> void:
	HubScript.suppress_audio_for_tests = value
	RaceScreen.suppress_audio_for_tests = value
	RouletteScreen.suppress_audio_for_tests = value
	PokerScreen.suppress_audio_for_tests = value
	TreasureScreen.suppress_audio_for_tests = value
	VaultScreen.suppress_audio_for_tests = value

func _cleanup() -> void:
	var ui_sfx: Node = root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	var bgm: Node = root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	await process_frame
	_remove_fixture()
	BankScript.clear_test_save_path()
	_set_audio_suppressed(false)

func _remove_fixture() -> void:
	if not fixture_path.is_empty() and FileAccess.file_exists(fixture_path):
		DirAccess.remove_absolute(fixture_path)

func _fingerprint(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<missing>"
	return FileAccess.get_sha256(path)
