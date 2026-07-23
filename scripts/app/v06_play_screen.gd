class_name V06PlayScreen
extends Control

signal back_requested

const V06PlaySessionScript = preload("res://scripts/game/v06_play_session.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const UiThemeNamesScript = preload("res://scripts/ui/ui_theme_names.gd")
const ITEM_CARD: Texture2D = preload("res://assets/art/v08/cards/item-card.png")
const SKILL_CARD: Texture2D = preload("res://assets/art/v08/cards/skill-card.png")

const QA_SCENARIO_ATLAS_18 := "atlas_18"
const QA_SCENARIO_BOSS_READY := "boss_ready"
const SLOT_BREATH_PERIOD_SECONDS := 2.0
const SLOT_BREATH_ALPHA_AMPLITUDE := 0.025

@onready var lap_label: Label = %LapLabel
@onready var hp_label: Label = %HPLabel
@onready var pb_label: Label = %PBLabel
@onready var time_label: Label = %TimeLabel
@onready var progress_label: Label = %ProgressLabel
@onready var stage_label: Label = %StageLabel
@onready var route_label: Label = %RouteLabel
@onready var tile_kind_label: Label = %TileKindLabel
@onready var atlas_view: V06AtlasView = %AtlasView
@onready var message_label: Label = %MessageLabel
@onready var tray_status_label: Label = %TrayStatusLabel
@onready var slot_panels: Array[PanelContainer] = [%SlotPanel0, %SlotPanel1, %SlotPanel2]
@onready var slot_labels: Array[Label] = [%Slot0, %Slot1, %Slot2]
@onready var dice_presentation: DicePresentation3D = %DicePresentation
@onready var die_button: Button = %DieButton
@onready var tray_hint_label: Label = %TrayHintLabel
@onready var back_button: Button = %BackButton
@onready var item_tool_button: Button = %ItemToolButton
@onready var skill_tool_button: Button = %SkillToolButton
@onready var utility_overlay: Control = %UtilityOverlay
@onready var utility_title: Label = %UtilityTitle
@onready var utility_card_art: TextureRect = %UtilityCardArt
@onready var utility_detail: Label = %UtilityDetail
@onready var utility_close_button: Button = %UtilityCloseButton
@onready var map_button: Button = %MapButton
@onready var map_overlay: Control = %MapOverlay
@onready var overview_atlas_view: V06AtlasView = %OverviewAtlasView
@onready var map_close_button: Button = %MapCloseButton
@onready var choice_overlay: Control = %ChoiceOverlay
@onready var choice_main_button: Button = %ChoiceMainButton
@onready var choice_bypass_button: Button = %ChoiceBypassButton
@onready var resolution_overlay: Control = %ResolutionOverlay
@onready var resolution_title: Label = %ResolutionTitle
@onready var resolution_detail: Label = %ResolutionDetail
@onready var resolution_ack_button: Button = %ResolutionAckButton
@onready var boss_overlay: Control = %BossOverlay
@onready var boss_title: Label = %BossTitle
@onready var boss_hp_label: Label = %BossHPLabel
@onready var boss_action_label: Label = %BossActionLabel
@onready var boss_result_label: Label = %BossResultLabel
@onready var boss_round_ack_button: Button = %BossRoundAckButton
@onready var next_lap_button: Button = %NextLapButton
@onready var retry_button: Button = %RetryButton
@onready var boss_back_button: Button = %BossBackButton

var _session: RefCounted
var _rng := RandomNumberGenerator.new()
var _rolling := false
var _movement_active := false
var _shown_face := 0
var _lap_number := 1
var _hp_current := 3
var _hp_max := 3
var _pb_text := "--"
var _breath_elapsed := 0.0
var _clock_refresh_elapsed := 0.0
var _qa_hud_override := false
var _map_open := false
var _utility_open := false


func _ready() -> void:
	_rng.seed = 20260718
	_session = V06PlaySessionScript.new()
	_apply_surface_styles()
	_wire_controls()
	_wire_press_feedback()
	var qa_scenario := OS.get_environment("DICE_QA_V06_SCENARIO")
	if qa_scenario == QA_SCENARIO_ATLAS_18:
		apply_atlas_18_qa_scenario()
	else:
		atlas_view.set_route_position(_session.position(), true)
	overview_atlas_view.set_route_position(_session.position(), true)
	overview_atlas_view.set_overview_mode(false)
	_refresh_ui()
	if qa_scenario == QA_SCENARIO_BOSS_READY and _session.enter_boss(Time.get_ticks_msec()):
		_present_session_phase()
		_refresh_ui()


func _process(delta: float) -> void:
	_breath_elapsed = fmod(_breath_elapsed + delta, SLOT_BREATH_PERIOD_SECONDS)
	_clock_refresh_elapsed += delta
	if _clock_refresh_elapsed >= 0.1:
		_clock_refresh_elapsed = 0.0
		_refresh_clock()
	for panel: PanelContainer in slot_panels:
		panel.self_modulate = Color.WHITE
	if _session == null or _session.phase() != V06PlaySessionScript.PHASE_READY:
		return
	var next_slot: int = _session.faces().size()
	if next_slot < 0 or next_slot >= slot_panels.size():
		return
	var wave: float = sin((_breath_elapsed / SLOT_BREATH_PERIOD_SECONDS) * TAU)
	# The unconfirmed slot only breathes by 2.5% alpha over two seconds. It is
	# intentionally far below a reward flash so long sessions remain calm.
	slot_panels[next_slot].self_modulate = Color(1.0, 1.0, 1.0, 1.0 - SLOT_BREATH_ALPHA_AMPLITUDE * (0.5 + wave * 0.5))


func _notification(what: int) -> void:
	if _session == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_session.pause_clock(Time.get_ticks_msec())
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_session.resume_clock(Time.get_ticks_msec())
	_refresh_ui()


func session_snapshot() -> Dictionary:
	return _session.snapshot(Time.get_ticks_msec())


func session_for_test() -> RefCounted:
	return _session


func atlas_for_test() -> V06AtlasView:
	return atlas_view


func apply_atlas_18_qa_scenario() -> bool:
	# Build the requested state through real course and roll-set semantics:
	# [1,1,3] -> acknowledge at main 5, then 6 -> main 11, then the
	# second 6 pauses at main 12 and resumes on the main route to main 17.
	if not _session.restart():
		return false
	for face: int in [1, 1, 3]:
		if not _qa_resolve_roll(face):
			return false
	if not _session.acknowledge_resolution():
		return false
	if not _qa_resolve_roll(6):
		return false
	if not _qa_resolve_roll(6, V06CourseModelScript.ROUTE_MAIN):
		return false
	var valid_state: bool = _session.position() == {"route_id":"main","tile_index":17} and _session.faces() == [6, 6]
	if not valid_state:
		return false
	_lap_number = 4
	_hp_current = 2
	_hp_max = 3
	_pb_text = "-2.4s"
	_qa_hud_override = true
	_rolling = false
	_movement_active = false
	_shown_face = 0
	atlas_view.set_route_position(_session.position(), true)
	_refresh_ui()
	return true


func _wire_controls() -> void:
	die_button.pressed.connect(_on_die_pressed)
	back_button.pressed.connect(_request_back)
	item_tool_button.pressed.connect(_on_item_tool_pressed)
	skill_tool_button.pressed.connect(_on_skill_tool_pressed)
	utility_close_button.pressed.connect(_on_utility_closed)
	map_button.pressed.connect(_on_map_pressed)
	map_close_button.pressed.connect(_on_map_closed)
	choice_main_button.pressed.connect(_on_route_chosen.bind(V06CourseModelScript.ROUTE_MAIN))
	choice_bypass_button.pressed.connect(_on_route_chosen.bind(V06CourseModelScript.ROUTE_BYPASS))
	resolution_ack_button.pressed.connect(_on_resolution_acknowledged)
	boss_round_ack_button.pressed.connect(_on_boss_round_acknowledged)
	next_lap_button.pressed.connect(_on_next_lap_requested)
	retry_button.pressed.connect(_on_replay_requested)
	boss_back_button.pressed.connect(_request_back)


func _wire_press_feedback() -> void:
	for button: Button in [die_button, map_button, item_tool_button, skill_tool_button, back_button, utility_close_button]:
		button.button_down.connect(_set_button_pressed.bind(button, true))
		button.button_up.connect(_set_button_pressed.bind(button, false))
		button.mouse_exited.connect(_set_button_pressed.bind(button, false))


func _set_button_pressed(button: Button, pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.97, 0.97) if pressed else Vector2.ONE, 0.08)


func _on_die_pressed() -> void:
	if _rolling:
		_stop_roll()
	elif not _movement_active and _session.can_roll():
		_start_roll()


func _start_roll() -> void:
	_rolling = true
	message_label.text = "回転中…もう一度タップで止める"
	_refresh_ui()


func _stop_roll() -> void:
	if not _rolling:
		return
	_rolling = false
	var face := _rng.randi_range(1, 6)
	_shown_face = face
	_run_face(face)


func _run_face(face: int) -> void:
	var pre_roll_phase: StringName = _session.phase()
	_movement_active = pre_roll_phase == V06PlaySessionScript.PHASE_READY
	var started: Dictionary = _session.start_roll(face, Time.get_ticks_msec())
	if not bool(started.get("ok", false)):
		_movement_active = false
		message_label.text = "今はダイスを振れません"
		_refresh_ui()
		return
	if pre_roll_phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		_shown_face = 0
		message_label.text = "ボスへの攻撃ダイス %d" % face
		_refresh_ui()
		_present_session_phase()
		return
	message_label.text = "%dマス進む" % face
	_refresh_ui()
	await _animate_pending_movement()


func _animate_pending_movement() -> void:
	while _session.has_pending_hops():
		var hop: Dictionary = _session.next_hop()
		await atlas_view.animate_hop_to(hop)
	var settled: Dictionary = _session.finish_movement()
	if not bool(settled.get("ok", false)):
		_movement_active = false
		message_label.text = "移動を完了できませんでした"
		_refresh_ui()
		return
	var stable_position: Dictionary = _session.position()
	if atlas_view.current_route_position() != stable_position:
		await atlas_view.animate_transfer_to(stable_position)
	else:
		atlas_view.set_route_position(stable_position)
	_movement_active = false
	_shown_face = 0
	_refresh_ui()
	_present_session_phase()


func _present_session_phase() -> void:
	match _session.phase():
		V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			resolution_overlay.hide()
			boss_overlay.hide()
			choice_overlay.show()
			choice_main_button.grab_focus()
		V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
			choice_overlay.hide()
			boss_overlay.hide()
			_show_resolution()
		V06PlaySessionScript.PHASE_BOSS_GATE:
			choice_overlay.hide()
			resolution_overlay.hide()
			boss_overlay.show()
			_refresh_boss_panel()
			die_button.grab_focus()
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER:
			choice_overlay.hide()
			resolution_overlay.hide()
			boss_overlay.show()
			_refresh_boss_panel()


func _on_route_chosen(route_id: String) -> void:
	if _movement_active:
		return
	var resumed: Dictionary = _session.choose_route(route_id)
	if not bool(resumed.get("ok", false)):
		return
	choice_overlay.hide()
	_movement_active = true
	message_label.text = "本線を進む" if route_id == V06CourseModelScript.ROUTE_MAIN else "シロッコの近道を進む"
	_refresh_ui()
	await _animate_pending_movement()


func _show_resolution() -> void:
	var role := String(_session.resolution_role())
	resolution_title.text = role
	match role:
		"TRIPLE": resolution_detail.text = "3つの出目がそろった！\n次の区間へ気持ちよく進もう。"
		"PAIR": resolution_detail.text = "2つの出目がそろった。\n結果を確認して次の3投へ。"
		_: resolution_detail.text = "3投の移動が完了。\n結果を確認して次の3投へ。"
	resolution_overlay.show()
	resolution_ack_button.grab_focus()


func _on_resolution_acknowledged() -> void:
	if not _session.acknowledge_resolution():
		return
	resolution_overlay.hide()
	_refresh_ui()
	_present_session_phase()
	if _session.phase() == V06PlaySessionScript.PHASE_READY:
		message_label.text = "次の3投を始めよう"
		die_button.grab_focus()


func _on_replay_requested() -> void:
	if not _session.retry_run():
		return
	_qa_hud_override = false
	_shown_face = 0
	_rolling = false
	_movement_active = false
	boss_overlay.hide()
	choice_overlay.hide()
	resolution_overlay.hide()
	atlas_view.set_route_position(_session.position(), true)
	message_label.text = "カイロの旅を始めよう"
	_refresh_ui()


func _on_boss_round_acknowledged() -> void:
	if not _session.acknowledge_boss_round():
		return
	_refresh_ui()
	_present_session_phase()


func _on_next_lap_requested() -> void:
	if not _session.next_lap():
		return
	_shown_face = 0
	boss_overlay.hide()
	atlas_view.set_route_position(_session.position(), true)
	_refresh_ui()


func _request_back() -> void:
	if _utility_open:
		_on_utility_closed()
		return
	if _map_open:
		_on_map_closed()
		return
	if _movement_active:
		return
	back_requested.emit()


func _on_item_tool_pressed() -> void:
	_open_utility_card(
		"アイテム",
		ITEM_CARD,
		"所持数  0 / 3\n\n旅の途中で見つけた道具を、\nここから確認して使います。"
	)


func _on_skill_tool_pressed() -> void:
	_open_utility_card(
		"キャラクタースキル  ·  READY",
		SKILL_CARD,
		"選択中の旅人が持つ能力を、\nここから確認して発動します。\n\n発動できる時だけボタンが有効になります。"
	)


func _open_utility_card(title: String, texture: Texture2D, detail: String) -> void:
	if _utility_open or _map_open or _movement_active or _rolling or _session == null:
		return
	if _session.phase() != V06PlaySessionScript.PHASE_READY:
		return
	_utility_open = true
	_session.pause_clock(Time.get_ticks_msec())
	utility_title.text = title
	utility_card_art.texture = texture
	utility_detail.text = detail
	utility_overlay.show()
	utility_close_button.grab_focus()
	_refresh_ui()


func _on_utility_closed() -> void:
	if not _utility_open:
		return
	_utility_open = false
	utility_overlay.hide()
	_session.resume_clock(Time.get_ticks_msec())
	item_tool_button.grab_focus()
	_refresh_ui()


func _on_map_pressed() -> void:
	if _map_open or _movement_active or _rolling or _session == null:
		return
	if _session.phase() not in [V06PlaySessionScript.PHASE_READY]:
		return
	_session.pause_clock(Time.get_ticks_msec())
	_map_open = true
	overview_atlas_view.set_route_position(_session.position(), true)
	overview_atlas_view.set_overview_mode(true)
	map_overlay.show()
	map_close_button.grab_focus()


func _on_map_closed() -> void:
	if not _map_open:
		return
	_map_open = false
	map_overlay.hide()
	overview_atlas_view.set_overview_mode(false)
	_session.resume_clock(Time.get_ticks_msec())
	map_button.grab_focus()
	_refresh_ui()


func _refresh_ui() -> void:
	if not is_instance_valid(lap_label) or _session == null:
		return
	if not _qa_hud_override:
		_lap_number = _session.lap()
		_hp_current = _session.player_hp()
		_pb_text = _format_pb_delta(_session.pb_delta_ms(Time.get_ticks_msec()))
		if _session.phase() == V06PlaySessionScript.PHASE_LAP_RESULT and _session.snapshot().pb_updated and _session.pb_delta_ms() == null:
			_pb_text = "NEW"
	lap_label.text = "LAP %d" % _lap_number
	hp_label.text = "HP %d/%d" % [_hp_current, _hp_max]
	pb_label.text = "PB %s" % _pb_text
	_refresh_clock()
	var route_position: Dictionary = _session.position()
	var route_id := str(route_position.get("route_id", "main"))
	var tile_index := int(route_position.get("tile_index", 0))
	var stage_info: Dictionary = _session.stage_summary()
	var main_total := int(stage_info.get("main_tile_count", 0))
	if main_total <= 0:
		main_total = 32
	match route_id:
		V06CourseModelScript.ROUTE_MAIN:
			progress_label.text = "%d/%d" % [tile_index + 1, main_total]
			route_label.text = "本線"
		V06CourseModelScript.ROUTE_BYPASS:
			progress_label.text = "BYPASS %d/%d" % [tile_index + 1, 4]
			route_label.text = "近道"
		_:
			progress_label.text = "LOOP %d/%d" % [tile_index + 1, 8]
			route_label.text = "スーク円環"
	stage_label.text = str(stage_info.get("name_ja", "砂時計のカイロ"))
	tile_kind_label.text = _tile_kind_display(_session.current_tile_kind())
	var values: Array[int] = _session.faces()
	for index: int in range(slot_labels.size()):
		slot_labels[index].text = str(values[index]) if index < values.size() else "—"
	var phase: StringName = _session.phase()
	match phase:
		V06PlaySessionScript.PHASE_READY:
			tray_status_label.text = "3 ROLL SLOT　　%d / 3" % values.size()
			tray_hint_label.text = "ダイスをタップ。もう一度で停止。"
			if not _rolling and not _movement_active:
				message_label.text = "ダイス1個で、1マスずつ進む"
		V06PlaySessionScript.PHASE_MOVING:
			tray_status_label.text = "MOVING"
		V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			tray_status_label.text = "ROUTE CHOICE"
			tray_hint_label.text = "残り%dマス・出目%dを保持中" % [_session.pending_remaining_steps(), _session.pending_face()]
			message_label.text = "進むルートを選ぶ"
		V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
			tray_status_label.text = String(_session.resolution_role())
			tray_hint_label.text = "結果を確認すると次の3投へ進めます"
		V06PlaySessionScript.PHASE_BOSS_GATE:
			tray_status_label.text = "BOSS ROUND"
			tray_hint_label.text = "3投で攻撃。次の行動とDEFを確認"
			message_label.text = "眠れるスフィンクスに挑む"
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
			tray_status_label.text = "ROUND RESULT"
			tray_hint_label.text = "結果確認が必要です"
		V06PlaySessionScript.PHASE_LAP_RESULT:
			tray_status_label.text = "LAP CLEAR"
		V06PlaySessionScript.PHASE_RUN_OVER:
			tray_status_label.text = "RUN OVER"
	_refresh_boss_panel()
	if _rolling:
		die_button.text = "TAP\nSTOP"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		die_button.text = "BOSS\nROLL"
	elif _shown_face > 0:
		die_button.text = "%d\nMOVE" % _shown_face
	else:
		die_button.text = "READY\nROLL"
	_refresh_die_presentation()
	die_button.disabled = _utility_open or _movement_active or (not _rolling and not _session.can_roll())
	var utility_disabled := _utility_open or _map_open or _movement_active or _rolling or phase != V06PlaySessionScript.PHASE_READY
	item_tool_button.disabled = utility_disabled
	skill_tool_button.disabled = utility_disabled
	back_button.disabled = _movement_active


func _refresh_die_presentation() -> void:
	if not is_instance_valid(dice_presentation):
		return
	var display_face := _shown_face if _shown_face > 0 else 6
	dice_presentation.present([display_face], _rolling, 0 if _rolling else 1)


func _qa_resolve_roll(face: int, route_choice := "") -> bool:
	var started: Dictionary = _session.start_roll(face)
	if not bool(started.get("ok", false)):
		return false
	while _session.has_pending_hops():
		_session.next_hop()
	var settled: Dictionary = _session.finish_movement()
	if not bool(settled.get("ok", false)):
		return false
	if _session.phase() != V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
		return true
	if route_choice.is_empty():
		return false
	var resumed: Dictionary = _session.choose_route(route_choice)
	if not bool(resumed.get("ok", false)):
		return false
	while _session.has_pending_hops():
		_session.next_hop()
	return bool(_session.finish_movement().get("ok", false))


func _tile_kind_display(kind: String) -> String:
	match kind:
		"START": return "START"
		"COIN": return "COIN"
		"ITEM": return "ITEM"
		"EVENT": return "EVENT"
		"REST": return "REST"
		"RISK": return "RISK"
		"BYPASS_FORK": return "ROUTE FORK"
		"LOOP_ENTRY": return "LOOP ENTRY"
		"EXIT_GATE": return "EXIT GATE"
		"BOSS_GATE": return "BOSS GATE"
		_: return "TRAVEL"


func _apply_surface_styles() -> void:
	%HudPanel.add_theme_stylebox_override("panel", _panel_style(Color("#172625"), Color("#b88a46"), 22, 4))
	%StageBand.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#8d683b"), 8, 2))
	%AtlasFrame.add_theme_stylebox_override("panel", _panel_style(Color("#e8d7b5"), Color("#9c7742"), 12, 4))
	%TrayPanel.add_theme_stylebox_override("panel", _panel_style(Color("#3a2118"), Color("#b88a46"), 24, 5))
	%ToolDock.add_theme_stylebox_override("panel", _panel_style(Color("#241813"), Color("#8d683b"), 18, 3))
	%DieWell.add_theme_stylebox_override("panel", _panel_style(Color("#22150f"), Color("#8d683b"), 14, 4))
	for slot_panel: PanelContainer in [%SlotPanel0, %SlotPanel1, %SlotPanel2]:
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color("#efe0bf"), Color("#9c7742"), 14, 3))
	for modal_panel: PanelContainer in [%ChoicePanel, %ResolutionPanel, %BossPanel, %UtilityPanel]:
		modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f1e2c2"), Color("#9b743d"), 22, 4))
	die_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	for button: Button in [item_tool_button, skill_tool_button, back_button, utility_close_button, choice_main_button, choice_bypass_button, resolution_ack_button, boss_round_ack_button, next_lap_button, retry_button, boss_back_button]:
		button.custom_minimum_size.y = UiTokensScript.TOUCH_MIN
	back_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	item_tool_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	skill_tool_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	utility_close_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	choice_main_button.theme_type_variation = UiThemeNamesScript.SELECTED_BUTTON
	choice_bypass_button.theme_type_variation = UiThemeNamesScript.DANGER_BUTTON
	resolution_ack_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	boss_round_ack_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	next_lap_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	retry_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	boss_back_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON


func _refresh_clock() -> void:
	if not is_instance_valid(time_label) or _session == null:
		return
	time_label.text = _format_time(_session.elapsed_ms(Time.get_ticks_msec()))


func _format_time(value_ms: int) -> String:
	var tenths := value_ms / 100
	return "%02d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


func _format_pb_delta(value: Variant) -> String:
	if value == null:
		return "--"
	var delta := int(value)
	if delta == 0:
		return "±0.0s"
	return "%s%.1fs" % ["+" if delta > 0 else "-", abs(delta) / 1000.0]


func _refresh_boss_panel() -> void:
	if not is_instance_valid(boss_overlay) or _session == null:
		return
	var boss: Dictionary = _session.boss_snapshot()
	var phase: StringName = _session.phase()
	if boss.is_empty():
		return
	boss_hp_label.text = "PLAYER HP %d/3    BOSS HP %d/3" % [int(boss.player_hp), int(boss.boss_hp)]
	boss_action_label.text = "%s  ·  DEF %d" % [String(boss.action).replace("_", " "), int(boss.defense)]
	boss_round_ack_button.visible = phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT
	next_lap_button.visible = phase == V06PlaySessionScript.PHASE_LAP_RESULT
	retry_button.visible = phase == V06PlaySessionScript.PHASE_RUN_OVER
	if phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
		var result: Dictionary = _session.boss_result()
		boss_result_label.text = "%d vs DEF %d · %s\nPLAYER -%d / BOSS -%d" % [int(result.sum), int(result.defense), String(result.role), int(result.applied_player_damage), int(result.applied_boss_damage)]
	elif phase == V06PlaySessionScript.PHASE_LAP_RESULT:
		boss_title.text = "LAP CLEAR"
		boss_result_label.text = "スフィンクスを突破！\n%s" % pb_label.text
	elif phase == V06PlaySessionScript.PHASE_RUN_OVER:
		boss_title.text = "RUN OVER"
		boss_result_label.text = "旅はここまで。PBを残して再挑戦できます。"
	else:
		boss_title.text = "SLEEPY SPHINX"
		boss_result_label.text = "3回振って攻撃しよう"


func _panel_style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.14, 0.09, 0.05, 0.20)
	style.shadow_size = 7
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
