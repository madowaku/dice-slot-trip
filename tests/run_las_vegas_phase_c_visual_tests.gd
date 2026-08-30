extends SceneTree

const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const SCREEN_SCRIPTS: Array[String] = [
	"res://scripts/app/casino_hub_screen.gd",
	"res://scripts/app/dice_race_screen.gd",
	"res://scripts/app/dice_tower_screen.gd",
	"res://scripts/app/dice_roulette_screen.gd",
	"res://scripts/app/treasure_21_screen.gd",
	"res://scripts/app/dice_poker_screen.gd",
	"res://scripts/app/vault_break_screen.gd",
]

var assertions: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	_test_button_binding()
	await _test_screen_bindings()
	await _test_result_reveal()
	var bgm: Node = root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	var ui_sfx: Node = root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	await process_frame
	print("Las Vegas Phase C visual tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _test_button_binding() -> void:
	var button := Button.new()
	root.add_child(button)
	VisualFeedback.bind_button(button)
	VisualFeedback.bind_button(button)
	button.button_down.emit()
	button.button_up.emit()
	_expect(button.has_meta("casino_feedback_bound"), "shared feedback marks a button as bound")
	_expect(button.offset_transform_enabled, "shared feedback enables transform-safe button motion")
	_expect(button.get_signal_connection_list(&"button_down").size() == 1, "binding is idempotent and does not duplicate press signals")
	button.queue_free()

func _test_screen_bindings() -> void:
	for script_path: String in SCREEN_SCRIPTS:
		var script: Script = load(script_path) as Script
		_expect(script != null, "screen script loads: %s" % script_path)
		if script == null:
			continue
		var screen: Object = script.new()
		var button: Button
		if script_path.ends_with("dice_roulette_screen.gd"):
			button = screen.call("_button", "TEST", 17) as Button
		elif script_path.ends_with("casino_hub_screen.gd"):
			button = screen.call("_button", "TEST") as Button
		else:
			button = screen.call("_button", "TEST", false) as Button
		_expect(button != null, "screen creates a CTA: %s" % script_path)
		if button == null:
			screen.free()
			continue
		root.add_child(button)
		await process_frame
		var bound := button.has_meta("casino_feedback_bound")
		var motion := button.get_signal_connection_list(&"button_down").size() > 0
		_expect(bound or motion, "screen exposes tactile CTA feedback: %s" % script_path)
		button.free()
		screen.free()

func _test_result_reveal() -> void:
	var result_card := Control.new()
	result_card.size = Vector2(240, 160)
	root.add_child(result_card)
	result_card.modulate.a = 1.0
	var tween: Tween = VisualFeedback.reveal(result_card, 0.12)
	_expect(tween != null, "result reveal returns a tween")
	_expect(result_card.has_meta("casino_result_reveal_tween"), "result reveal stores its replaceable tween")
	_expect(is_equal_approx(result_card.offset_transform_scale.x, 0.965), "result reveal starts with a restrained scale-in")
	await create_timer(0.20).timeout
	_expect(is_equal_approx(result_card.offset_transform_scale.x, 1.0), "result reveal settles at full scale")
	_expect(is_equal_approx(result_card.modulate.a, 1.0), "result reveal settles at full opacity")
	result_card.queue_free()
	await process_frame
