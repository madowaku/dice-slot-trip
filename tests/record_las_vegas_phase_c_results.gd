extends SceneTree

## Phase C result captures wait for the shared reveal tween to settle before
## saving the image. The Phase B recorder intentionally remains unchanged.

const TREASURE_SCENE: PackedScene = preload("res://scenes/casino/Treasure21.tscn")
const VAULT_SCENE: PackedScene = preload("res://scenes/casino/VaultBreak.tscn")
const Treasure = preload("res://scripts/app/treasure_21_screen.gd")
const Vault = preload("res://scripts/app/vault_break_screen.gd")

const DESIGN_SIZE := Vector2i(720, 1600)
const OUTPUT_SIZE := Vector2i(360, 800)
const REVEAL_SETTLE_FRAMES := 24

var failures: int = 0
var output_dir: String = ""
var capture_viewport: SubViewport
var capture_root: Control

func _init() -> void:
	call_deferred("_record")

func _record() -> void:
	output_dir = OS.get_environment("LAS_VEGAS_PHASE_C_RESULTS_OUTPUT_DIR")
	if output_dir.is_empty():
		push_error("LAS_VEGAS_PHASE_C_RESULTS_OUTPUT_DIR is required")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	Treasure.suppress_audio_for_tests = true
	Vault.suppress_audio_for_tests = true
	capture_viewport = SubViewport.new()
	capture_viewport.size = DESIGN_SIZE
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.transparent_bg = false
	root.add_child(capture_viewport)
	capture_root = Control.new()
	capture_root.size = Vector2(DESIGN_SIZE)
	capture_viewport.add_child(capture_root)

	var treasure := TREASURE_SCENE.instantiate()
	capture_root.add_child(treasure)
	await _settle(8)
	treasure.game = {
		"bet": 20,
		"payout": 28,
		"result": "golden",
		"total": 19,
		"golden_number": 19,
	}
	treasure.call("_show_result")
	await _settle(REVEAL_SETTLE_FRAMES)
	_capture("treasure-result-360x800.png")
	treasure.queue_free()
	await _settle(3)

	var vault := VAULT_SCENE.instantiate()
	capture_root.add_child(vault)
	await _settle(10)
	vault.result_data = {
		"won": true,
		"result": "success",
		"reward": 34,
		"bet": 20,
		"tier": "bronze",
		"template_id": "B01",
		"rolls_used": 4,
		"max_rolls": 5,
	}
	vault.call("_set_state", vault.State.RESULT)
	vault.call("_show_result")
	await _settle(REVEAL_SETTLE_FRAMES)
	_capture("vault-result-360x800.png")
	vault.queue_free()
	await _settle(3)

	Treasure.suppress_audio_for_tests = false
	Vault.suppress_audio_for_tests = false
	print("LAS_VEGAS_PHASE_C_RESULTS size=%s failures=%d output=%s actual_rendering=%s" % [OUTPUT_SIZE, failures, output_dir, true])
	quit(1 if failures > 0 else 0)

func _capture(file_name: String) -> void:
	RenderingServer.force_draw(false, 0.0)
	RenderingServer.force_sync()
	var image: Image = capture_viewport.get_texture().get_image()
	if image == null or image.is_empty():
		failures += 1
		push_error("empty capture: %s" % file_name)
		return
	image.resize(OUTPUT_SIZE.x, OUTPUT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK or image.get_size() != OUTPUT_SIZE:
		failures += 1
		push_error("capture failed: %s" % file_name)
	else:
		print("CAPTURE %s" % output_dir.path_join(file_name))

func _settle(frames: int) -> void:
	for _frame: int in range(frames):
		await process_frame
