extends RefCounted

## Small, shared visual feedback for the Las Vegas casino controls.
##
## This helper owns presentation only. It never changes button state, wager
## state, or any of the CasinoBank transaction data.

const HOVER_SCALE: Vector2 = Vector2(1.02, 1.02)
const PRESS_SCALE: Vector2 = Vector2(0.975, 0.975)
const HOVER_SECONDS: float = 0.10
const RELEASE_SECONDS: float = 0.12
const PRESS_SECONDS: float = 0.06
const REVEAL_SCALE: Vector2 = Vector2(0.965, 0.965)
const REVEAL_SECONDS: float = 0.26
const REVEAL_FADE_SECONDS: float = 0.20

static func bind_button(button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.has_meta("casino_feedback_bound"):
		return
	button.set_meta("casino_feedback_bound", true)
	if _supports_offset_transform(button):
		button.set("offset_transform_enabled", true)
	else:
		button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_animate_button.bind(button, HOVER_SCALE, HOVER_SECONDS))
	button.mouse_exited.connect(_animate_button.bind(button, Vector2.ONE, RELEASE_SECONDS))
	button.focus_entered.connect(_animate_button.bind(button, HOVER_SCALE, HOVER_SECONDS))
	button.focus_exited.connect(_animate_button.bind(button, Vector2.ONE, RELEASE_SECONDS))
	button.button_down.connect(_animate_button.bind(button, PRESS_SCALE, PRESS_SECONDS))
	button.button_up.connect(_animate_button.bind(button, Vector2.ONE, RELEASE_SECONDS))

static func reveal(control: Control, duration: float = REVEAL_SECONDS) -> Tween:
	if control == null or not is_instance_valid(control):
		return null
	var previous: Variant = control.get_meta("casino_result_reveal_tween") if control.has_meta("casino_result_reveal_tween") else null
	if previous is Tween:
		(previous as Tween).kill()
	control.pivot_offset = control.size * 0.5
	var scale_property := "offset_transform_scale" if _supports_offset_transform(control) else "scale"
	if _supports_offset_transform(control):
		control.set("offset_transform_enabled", true)
	control.set(scale_property, REVEAL_SCALE)
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween()
	control.set_meta("casino_result_reveal_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(control, scale_property, Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, minf(REVEAL_FADE_SECONDS, duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween

static func _animate_button(button: Button, target: Vector2, duration: float) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	var previous: Variant = button.get_meta("casino_feedback_tween") if button.has_meta("casino_feedback_tween") else null
	if previous is Tween:
		(previous as Tween).kill()
	var tween: Tween = button.create_tween()
	button.set_meta("casino_feedback_tween", tween)
	var scale_property := "offset_transform_scale" if _supports_offset_transform(button) else "scale"
	tween.tween_property(button, scale_property, target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _supports_offset_transform(control: Control) -> bool:
	for property: Dictionary in control.get_property_list():
		if str(property.get("name", "")) == "offset_transform_enabled":
			return true
	return false
