extends SceneTree

const VAULT_SCENE: PackedScene = preload("res://scenes/casino/VaultBreak.tscn")
const BankScript = preload("res://scripts/game/casino_bank.gd")
const ScreenScript = preload("res://scripts/app/vault_break_screen.gd")
const ProgressScript = preload("res://scripts/game/vault_break/vault_break_progress.gd")

const PHONE_SIZE := Vector2i(360, 800)
const DESIGN_360 := Vector2i(720, 1600)
const DESIGN_720 := Vector2i(720, 1280)

var capture_viewport: SubViewport
var capture_root: Control
var screen: VaultBreakScreen
var failures: int = 0
var save_path: String = ""
var output_dir: String = ""
var output_size: Vector2i = PHONE_SIZE

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	output_dir = OS.get_environment("VAULT_BREAK_QA_OUTPUT_DIR")
	if output_dir.is_empty():
		output_dir = ProjectSettings.globalize_path("res://artifacts/playtest/vault-break-feel")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var requested: String = OS.get_environment("VAULT_BREAK_QA_VIEWPORT")
	var design_size: Vector2i = DESIGN_360
	if requested == "720x1280":
		output_size = DESIGN_720
		design_size = DESIGN_720

	save_path = "user://vault_break_feel_recorder_%d.json" % OS.get_process_id()
	BankScript.set_test_save_path(save_path)
	ScreenScript.suppress_audio_for_tests = true
	_reset_bank()
	capture_viewport = SubViewport.new()
	capture_viewport.size = design_size
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(design_size)
	capture_viewport.add_child(capture_root)

	await _spawn_screen()
	screen.call("_select_bet", 20)
	screen.call("_start_game")
	await _roll_to_wait(6)
	await _capture("placement-choice")
	screen.call("_on_lock_pressed", 2)
	await _settle(5)
	await _capture("lock-progress")
	await _roll_to_wait(6)
	await _capture("discard-choice")
	screen.call("_on_discard_pressed")
	await _settle(5)
	for ignored: int in 2:
		await _roll_to_wait(6)
		screen.call("_on_discard_pressed")
		await _settle(5)
	await _capture("remaining-1")
	await _roll_to_wait(6)
	screen.call("_on_discard_pressed")
	await _settle(12)
	await _capture("access-denied")

	await _replace_screen()
	screen.call("_select_bet", 20)
	screen.call("_start_game")
	await _roll_and_place(1, 0)
	await _roll_and_place(4, 1)
	await _roll_and_place(6, 2)
	await _settle(12)
	await _capture("bronze-success")

	await _replace_screen_with_black()
	screen.call("_start_game")
	await _roll_and_place(1, 0)
	await _roll_and_place(2, 1)
	await _roll_and_place(3, 2)
	await _settle(12)
	await _capture("black-success")

	print("VAULT_BREAK_FEEL_CAPTURE failures=%d output=%s" % [failures, output_dir])
	await _cleanup()
	quit(1 if failures > 0 else 0)

func _spawn_screen() -> void:
	screen = VAULT_SCENE.instantiate() as VaultBreakScreen
	if screen == null:
		failures += 1
		push_error("VAULT_BREAK_FEEL_CAPTURE: scene did not instantiate")
		return
	screen.animation_duration_scale = 0.0
	capture_root.add_child(screen)
	await _settle(8)

func _replace_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	await _settle(3)
	_reset_bank()
	await _spawn_screen()

func _replace_screen_with_black() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	await _settle(3)
	var raw_progress: Dictionary = ProgressScript.default_progress()
	var tiers: Dictionary = raw_progress.get("tiers", {}) as Dictionary
	var gold: Dictionary = tiers.get("gold", {}) as Dictionary
	gold["plays"] = 1
	gold["wins"] = 1
	gold["first_play_done"] = true
	tiers["gold"] = gold
	raw_progress["tiers"] = tiers
	var spawn: Dictionary = raw_progress.get("black_spawn", {}) as Dictionary
	spawn["active_template_id"] = "K01"
	raw_progress["black_spawn"] = spawn
	_reset_bank({"schema_version": 1, "progress": raw_progress, "last_bet": 20, "last_tier": "black"})
	await _spawn_screen()

func _roll_to_wait(face: int) -> void:
	screen.queued_roll_value = face
	screen.call("_on_roll_pressed")
	await _settle(6)

func _roll_and_place(face: int, lock_index: int) -> void:
	await _roll_to_wait(face)
	screen.call("_on_lock_pressed", lock_index)
	await _settle(6)

func _capture(label: String) -> void:
	await _settle(3)
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image: Image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures += 1
		push_error("VAULT_BREAK_FEEL_CAPTURE: empty image for %s" % label)
		return
	image.resize(output_size.x, output_size.y, Image.INTERPOLATE_LANCZOS)
	var path: String = output_dir.path_join("%s-%dx%d.png" % [label, output_size.x, output_size.y])
	var error: Error = image.save_png(path)
	if error != OK:
		failures += 1
		push_error("VAULT_BREAK_FEEL_CAPTURE: save failed for %s" % path)
	else:
		print("CAPTURE %s" % path)

func _reset_bank(vault_meta: Dictionary = {}) -> void:
	var data: Dictionary = BankScript.default_data()
	data["chips"] = 500
	if not vault_meta.is_empty():
		data["vault_break"] = vault_meta.duplicate(true)
	BankScript.save_data(data)

func _cleanup() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	if is_instance_valid(capture_viewport):
		capture_viewport.queue_free()
	await _settle(3)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	BankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false

func _settle(frames: int) -> void:
	for ignored: int in frames:
		await process_frame
