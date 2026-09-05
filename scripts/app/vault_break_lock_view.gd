class_name VaultBreakLockView
extends Button

## Reusable presentation-only lock target. The owning screen decides whether a
## face is legal and passes a visual state here; this class never evaluates a
## VAULT BREAK rule.

signal lock_selected(lock_index: int)

enum State {
	EMPTY,
	VALID_TARGET,
	INVALID_TARGET,
	FILLED,
	SUCCESS,
	FAILED,
}

const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")

const PARCHMENT := Color("#f4dfb0")
const PARCHMENT_DARK := Color("#d7b875")
const INK := Color("#2f2117")
const NAVY := Color("#171932")
const PLUM := Color("#36213e")
const BRASS := Color("#c9963d")
const BRASS_LIGHT := Color("#f2d27b")
const OXBLOOD := Color("#7e2929")
const GREEN := Color("#3f7d58")
const MUTED := Color("#77717b")

var lock_index := -1
var lock_data: Dictionary = {}
var accepted_faces: Array[int] = []
var placed_face := 0
var state: int = State.EMPTY
var view_state: int = State.EMPTY

var rule_label: Label
var faces_label: Label
var state_label: Label
var face_label: Label
var feedback_tween: Tween

func _ready() -> void:
	_ensure_ui()
	_apply_state()

func configure(index: int, authored_lock: Dictionary, display_faces: Array) -> void:
	lock_index = index
	lock_data = authored_lock.duplicate(true)
	accepted_faces.clear()
	for value: Variant in display_faces:
		var face := int(value)
		if face in range(1, 7) and face not in accepted_faces:
			accepted_faces.append(face)
	accepted_faces.sort()
	placed_face = 0
	_ensure_ui()
	_refresh_rule_copy()
	set_lock_state(State.EMPTY)

func setup(index: int, authored_lock: Dictionary, display_faces: Array) -> void:
	configure(index, authored_lock, display_faces)

func set_lock_state(new_state: int, face: int = 0) -> void:
	state = clampi(new_state, State.EMPTY, State.FAILED)
	view_state = state
	if face in range(1, 7):
		placed_face = face
	elif state in [State.EMPTY, State.VALID_TARGET, State.INVALID_TARGET, State.FAILED]:
		placed_face = 0
	_ensure_ui()
	_apply_state()

func set_visual_state(new_state: int, face: int = 0) -> void:
	set_lock_state(new_state, face)

func get_lock_state() -> int:
	return state

func is_valid_target() -> bool:
	return state == State.VALID_TARGET and not disabled and placed_face == 0

func play_lock_feedback() -> void:
	offset_transform_enabled = true
	if feedback_tween != null:
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_property(self, "offset_transform_position", Vector2(0.0, -5.0), 0.06)
	feedback_tween.parallel().tween_property(self, "offset_transform_scale", Vector2(1.10, 1.10), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(self, "offset_transform_position", Vector2.ZERO, 0.10)
	feedback_tween.parallel().tween_property(self, "offset_transform_scale", Vector2.ONE, 0.10)

func accepted_faces_text() -> String:
	var parts: PackedStringArray = []
	for face: int in accepted_faces:
		parts.append(str(face))
	return "  ".join(parts)

func _ensure_ui() -> void:
	if rule_label != null:
		return
	name = "VaultLock_%d" % maxi(0, lock_index)
	custom_minimum_size = Vector2(132, 146)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	text = ""
	tooltip_text = "VAULT BREAK LOCK"
	add_theme_font_override("font", FONT)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	var box := VBoxContainer.new()
	box.name = "LockCopy"
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	rule_label = _label("LOCK", 20, PARCHMENT)
	rule_label.name = "RuleLabel"
	rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rule_label)

	faces_label = _label("1  2  3", 17, BRASS_LIGHT)
	faces_label.name = "AcceptedFacesLabel"
	faces_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(faces_label)

	face_label = _label("—", 27, PARCHMENT)
	face_label.name = "LockedFaceLabel"
	face_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(face_label)

	state_label = _label("EMPTY", 13, Color("#d5ccdc"))
	state_label.name = "LockStateLabel"
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(state_label)
	_refresh_rule_copy()

func _refresh_rule_copy() -> void:
	if rule_label == null:
		return
	var rule := str(lock_data.get("rule", "lock")).to_upper()
	if rule == "EXACT":
		rule = "EXACT %d" % int(lock_data.get("value", 0))
	rule_label.text = rule
	faces_label.text = accepted_faces_text()
	tooltip_text = "%s: accepts %s" % [rule, accepted_faces_text()]

func _apply_state() -> void:
	if rule_label == null:
		return
	disabled = state != State.VALID_TARGET
	var fill := PLUM
	var border := Color("#725f83")
	var text_color := PARCHMENT
	var status := "EMPTY · WAITING"
	var face_copy := "—"
	match state:
		State.VALID_TARGET:
			fill = Color("#3f3824")
			border = BRASS_LIGHT
			text_color = Color("#fff2bf")
			status = "SELECT · VALID"
			face_copy = "FIT"
		State.INVALID_TARGET:
			fill = Color("#292532")
			border = MUTED
			text_color = Color("#bdb7c3")
			status = "NO FIT"
			face_copy = "×"
		State.FILLED:
			fill = Color("#24384a")
			border = BRASS
			status = "LOCKED · IMMUTABLE"
			face_copy = str(placed_face)
		State.SUCCESS:
			fill = Color("#254638")
			border = BRASS_LIGHT
			text_color = Color("#fff2bf")
			status = "OPEN · SECURED"
			face_copy = str(placed_face)
		State.FAILED:
			fill = Color("#442530")
			border = OXBLOOD
			text_color = Color("#efb9af")
			status = "UNFILLED · FAILED"
			face_copy = "—"
		_:
			pass
	rule_label.add_theme_color_override("font_color", text_color)
	faces_label.add_theme_color_override("font_color", BRASS_LIGHT if state != State.INVALID_TARGET else Color("#aaa2ad"))
	face_label.add_theme_color_override("font_color", text_color)
	face_label.text = face_copy
	state_label.add_theme_color_override("font_color", text_color)
	state_label.text = status
	add_theme_stylebox_override("normal", _panel(fill, border, 14, 3 if state == State.VALID_TARGET else 2))
	add_theme_stylebox_override("hover", _panel(fill.lightened(0.08), BRASS_LIGHT, 14, 3))
	add_theme_stylebox_override("pressed", _panel(fill.darkened(0.08), BRASS_LIGHT, 14, 4))
	add_theme_stylebox_override("focus", _panel(Color.TRANSPARENT, BRASS_LIGHT, 14, 3))
	# Disabled states retain their own semantic styling instead of collapsing to
	# one generic grey button.
	add_theme_stylebox_override("disabled", _panel(fill, border, 14, 2))

func _on_pressed() -> void:
	if is_valid_target():
		lock_selected.emit(lock_index)

func _label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
