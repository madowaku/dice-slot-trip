class_name V06PlayScreen
extends Control

signal back_requested
signal resume_failed

const V06PlaySessionScript = preload("res://scripts/game/v06_play_session.gd")
const V06SessionSaveManagerScript = preload("res://scripts/game/v06_session_save_manager.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const UiThemeNamesScript = preload("res://scripts/ui/ui_theme_names.gd")
const ITEM_CARD: Texture2D = preload("res://assets/art/v08/cards/item-card.png")
const SKILL_CARD: Texture2D = preload("res://assets/art/v08/cards/skill-card.png")

const QA_SCENARIO_ATLAS_18 := "atlas_18"
const QA_SCENARIO_BOSS_READY := "boss_ready"
const SLOT_BREATH_PERIOD_SECONDS := 2.0
const SLOT_BREATH_ALPHA_AMPLITUDE := 0.025
const TARGET_PREVIEW_SECONDS := 0.20
const SLOT_STOP_DELAY_SECONDS := 0.12
const ROLLING_SLOT_STEP_SECONDS := 0.06
const INLINE_SLOT_RESULT_SECONDS := 0.46
const DICE_ANCHOR_NORMAL := Vector2(0.45, 0.82)
const DICE_ANCHOR_LOOP := Vector2(0.88, 0.82)
const SLOT_RESULT_GLOW := Color(1.45, 1.42, 1.30, 1.0)
const SLOT_RESULT_STRONG_GLOW := Color(1.75, 1.68, 1.42, 1.0)

@onready var lap_label: Label = %LapLabel
@onready var roll_count_label: Label = %RollCountLabel
@onready var hp_label: Label = %HPLabel
@onready var pb_label: Label = %PBLabel
@onready var time_label: Label = %TimeLabel
@onready var score_label: Label = %ScoreLabel
@onready var score_delta_label: Label = %ScoreDeltaLabel
@onready var coin_label: Label = %CoinLabel
@onready var progress_label: Label = %ProgressLabel
@onready var stage_label: Label = %StageLabel
@onready var route_label: Label = %RouteLabel
@onready var tile_kind_label: Label = %TileKindLabel
@onready var atlas_view: V06AtlasView = %AtlasView
@onready var message_label: Label = %MessageLabel
@onready var tray_status_label: Label = %TrayStatusLabel
@onready var role_label: Label = %RoleLabel
@onready var role_reward_label: Label = %RoleRewardLabel
@onready var next_need_label: Label = %NextNeedLabel
@onready var action_hint_label: Label = %ActionHintLabel
@onready var slot_column: VBoxContainer = %SlotColumn
@onready var slot_panels: Array[PanelContainer] = [%SlotPanel0, %SlotPanel1, %SlotPanel2]
@onready var slot_labels: Array[Label] = [%Slot0, %Slot1, %Slot2]
@onready var pair_link: Line2D = %PairLink
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
@onready var choice_detail_label: Label = $ChoiceOverlay/Center/ChoicePanel/Content/Detail
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
var _slot_settling := false
var _rolling_slot_elapsed := 0.0
var _rolling_slot_face := 1
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
var _motion_generation := 0
var _score_display_value := 0.0
var _score_target := 0
var _score_tween: Tween
var _score_delta_tween: Tween
var _inline_slot_result_active := false
var _start_stage_id: StringName = V06PlaySessionScript.DEFAULT_STAGE_ID
var _start_character_id: StringName = V06PlaySessionScript.DEFAULT_CHARACTER_ID
var _save_manager: RefCounted
var _save_enabled := false
var _resume_data: Dictionary = {}


func configure_start_context(stage_id: StringName, character_id: StringName) -> void:
	_start_stage_id = stage_id if not String(stage_id).is_empty() else V06PlaySessionScript.DEFAULT_STAGE_ID
	_start_character_id = character_id if not String(character_id).is_empty() else V06PlaySessionScript.DEFAULT_CHARACTER_ID


func configure_save_manager(manager: RefCounted) -> void:
	_save_manager = manager
	_save_enabled = manager != null and manager.has_method("save_session")


func configure_resume_data(data: Dictionary) -> void:
	_resume_data = data.duplicate(true)


func _ready() -> void:
	_rng.randomize()
	add_to_group("v06_session_screen")
	_session = V06PlaySessionScript.new(_start_stage_id, _start_character_id)
	var resume_requested := not _resume_data.is_empty()
	var restored := false
	if not _resume_data.is_empty():
		var state: Variant = _resume_data.get("session_state", {})
		if state is Dictionary:
			restored = _session.restore_stable_snapshot(state as Dictionary, Time.get_ticks_msec())
		if not restored:
			call_deferred("_emit_resume_failed")
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
	if restored:
		_present_session_phase()
	elif not resume_requested:
		_save_stable_checkpoint()


func _emit_resume_failed() -> void:
	resume_failed.emit()


func _save_stable_checkpoint() -> void:
	if not _save_enabled or _save_manager == null or _session == null:
		return
	var result: Dictionary = _save_manager.save_session(_session)
	if not bool(result.get("ok", false)) and str(result.get("status", "")) != "NOT_STABLE":
		push_warning("V06 stable checkpoint was not saved: %s" % str(result.get("error", result.get("status", "unknown"))))


func _process(delta: float) -> void:
	_breath_elapsed = fmod(_breath_elapsed + delta, SLOT_BREATH_PERIOD_SECONDS)
	if _rolling:
		_rolling_slot_elapsed += delta
		_refresh_rolling_slot_preview()
	_clock_refresh_elapsed += delta
	if _clock_refresh_elapsed >= 0.1:
		_clock_refresh_elapsed = 0.0
		_refresh_clock()
	if not _inline_slot_result_active:
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
		_save_stable_checkpoint()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_session.resume_clock(Time.get_ticks_msec())
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_stable_checkpoint()
	_refresh_ui()


func _exit_tree() -> void:
	_motion_generation += 1
	if is_instance_valid(atlas_view):
		atlas_view.cancel_visual_motion()


func _cancel_motion(route_position := {}) -> void:
	_motion_generation += 1
	_rolling = false
	_slot_settling = false
	_movement_active = false
	_reset_inline_slot_result()
	if is_instance_valid(atlas_view):
		atlas_view.cancel_visual_motion(route_position)
		atlas_view.clear_roll_preview()


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
	atlas_view.clear_roll_preview()
	_rolling = true
	_slot_settling = false
	_rolling_slot_elapsed = 0.0
	_rolling_slot_face = 1
	message_label.text = "回転中…もう一度タップで止める"
	message_label.show()
	_refresh_ui()
	_refresh_rolling_slot_preview()


func _stop_roll() -> void:
	if not _rolling:
		return
	_rolling = false
	_slot_settling = true
	_movement_active = _session.can_roll()
	var face := _rng.randi_range(1, 6)
	_shown_face = face
	_refresh_ui()
	_run_face(face)


func _run_face(face: int) -> void:
	var pre_roll_phase: StringName = _session.phase()
	var pre_roll_position: Dictionary = _session.position()
	var motion_generation := _motion_generation
	_movement_active = pre_roll_phase == V06PlaySessionScript.PHASE_READY
	if _slot_settling:
		await get_tree().create_timer(SLOT_STOP_DELAY_SECONDS).timeout
		if motion_generation != _motion_generation:
			return
		_slot_settling = false
	var started: Dictionary = _session.start_roll(face, Time.get_ticks_msec())
	if not bool(started.get("ok", false)):
		_movement_active = false
		_slot_settling = false
		message_label.text = "今はダイスを振れません"
		_refresh_ui()
		return
	if pre_roll_phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		_shown_face = 0
		message_label.text = "ボスへの攻撃ダイス %d" % face
		_refresh_ui()
		_present_session_phase()
		if _session.is_stable_for_save():
			_save_stable_checkpoint()
		return
	message_label.text = "%dマス進む" % face
	message_label.show()
	atlas_view.set_roll_preview(face)
	_refresh_ui()
	var pending_role := String(_session.pending_resolution_role())
	if pending_role != "":
		await _play_inline_slot_result(pending_role, face, motion_generation)
		if not _movement_active or motion_generation != _motion_generation:
			return
	elif atlas_view.can_use_straight_travel(pre_roll_position, _session.pending_hop_count()):
		await get_tree().create_timer(TARGET_PREVIEW_SECONDS).timeout
		if not _movement_active or motion_generation != _motion_generation:
			return
	atlas_view.release_roll_preview()
	await _animate_pending_movement(motion_generation)


func _animate_pending_movement(motion_generation := -1) -> bool:
	if motion_generation >= 0 and motion_generation != _motion_generation:
		return false
	var start_position: Dictionary = _session.position()
	var visual_path: Array[Dictionary] = _session.pending_hop_positions()
	var start_route := str(start_position.get("route_id", ""))
	var loop_mode := start_route in [V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB]
	var step_travel_mode := false
	if not visual_path.is_empty() and not loop_mode:
		step_travel_mode = atlas_view.begin_step_travel(start_position, visual_path)
	if not visual_path.is_empty() and not loop_mode and not step_travel_mode:
		atlas_view.cancel_visual_motion(start_position)
		_movement_active = false
		message_label.text = "移動アニメーションを開始できませんでした"
		_refresh_ui()
		return false
	var step := 0
	var previous_route := start_route
	while _session.has_pending_hops():
		var hop: Dictionary = _session.next_hop()
		var hop_route := str(hop.get("route_id", ""))
		var entered_bypass := previous_route == V06CourseModelScript.ROUTE_MAIN and hop_route in V06CourseModelScript.ROUTE_BYPASSES
		step += 1
		if loop_mode:
			await atlas_view.animate_hop_to(hop)
		else:
			await atlas_view.animate_straight_step(step)
		if motion_generation >= 0 and motion_generation != _motion_generation:
			return false
		if entered_bypass:
			await atlas_view.play_bypass_entry_effect(hop_route)
			if motion_generation >= 0 and motion_generation != _motion_generation:
				return false
		previous_route = hop_route
	var settled: Dictionary = _session.finish_movement()
	if not bool(settled.get("ok", false)):
		atlas_view.clear_roll_preview()
		atlas_view.cancel_visual_motion(start_position)
		_movement_active = false
		message_label.text = "移動を完了できませんでした"
		_refresh_ui()
		return false
	var stable_position: Dictionary = _session.position()
	if visual_path.is_empty():
		atlas_view.clear_roll_preview()
	elif loop_mode:
		if atlas_view.current_route_position() != stable_position:
			await atlas_view.animate_portal_transfer_to(stable_position)
		else:
			atlas_view.set_route_position(stable_position)
		if _session.phase() != V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			await atlas_view.play_landing_effect(stable_position)
		if motion_generation >= 0 and motion_generation != _motion_generation:
			return false
	else:
		if _session.phase() != V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			await atlas_view.play_landing_effect(stable_position)
			if motion_generation >= 0 and motion_generation != _motion_generation:
				return false
		atlas_view.clear_roll_preview()
		await atlas_view.animate_straight_camera_follow()
		if motion_generation >= 0 and motion_generation != _motion_generation:
			return false
		if not atlas_view.finish_straight_travel(stable_position):
			atlas_view.cancel_visual_motion(stable_position)
	atlas_view.clear_roll_preview()
	_movement_active = false
	_shown_face = 0
	_refresh_ui()
	_present_session_phase()
	_save_stable_checkpoint()
	return true


func _present_session_phase() -> void:
	match _session.phase():
		V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			resolution_overlay.hide()
			boss_overlay.hide()
			_configure_route_choice()
			choice_overlay.show()
			choice_main_button.grab_focus()
		V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
			choice_overlay.hide()
			boss_overlay.hide()
			resolution_overlay.hide()
			_complete_nonmodal_resolution()
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
	var bypass: Dictionary = _session.pending_bypass()
	var resumed: Dictionary = _session.choose_route(route_id)
	if not bool(resumed.get("ok", false)):
		return
	choice_overlay.hide()
	_movement_active = true
	message_label.text = "本線を進む" if route_id == V06CourseModelScript.ROUTE_MAIN else "%sを進む" % str(bypass.get("name_ja", "近道"))
	_refresh_ui()
	await _animate_pending_movement()


func _complete_nonmodal_resolution() -> void:
	if not _session.acknowledge_resolution():
		return
	resolution_overlay.hide()
	role_reward_label.hide()
	pair_link.hide()
	_refresh_ui()
	_present_session_phase()
	_save_stable_checkpoint()
	if _session.phase() == V06PlaySessionScript.PHASE_READY:
		message_label.text = "次の3投を始めよう"


func _on_replay_requested() -> void:
	if not _session.retry_run():
		return
	_qa_hud_override = false
	_shown_face = 0
	_cancel_motion(_session.position())
	boss_overlay.hide()
	choice_overlay.hide()
	resolution_overlay.hide()
	atlas_view.set_route_position(_session.position(), true)
	message_label.text = "カイロの旅を始めよう"
	_refresh_ui()
	_save_stable_checkpoint()


func _on_boss_round_acknowledged() -> void:
	if not _session.acknowledge_boss_round():
		return
	_refresh_ui()
	_present_session_phase()
	_save_stable_checkpoint()


func _on_next_lap_requested() -> void:
	if not _session.next_lap():
		return
	_shown_face = 0
	_cancel_motion(_session.position())
	boss_overlay.hide()
	atlas_view.set_route_position(_session.position(), true)
	_refresh_ui()
	_save_stable_checkpoint()


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
		"キャラクタースキル  ·  ピンポイント",
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
	_save_stable_checkpoint()
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
	_save_stable_checkpoint()
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
	roll_count_label.text = "ROLLS %d" % _session.roll_count()
	hp_label.text = _heart_text(_hp_current, _hp_max)
	pb_label.text = "PB %s" % _pb_text
	if is_instance_valid(atlas_view):
		atlas_view.set_consumed_route_state(_session.consumed_warp_gate_ids(), _session.consumed_reward_node_keys())
	if is_instance_valid(overview_atlas_view):
		overview_atlas_view.set_consumed_route_state(_session.consumed_warp_gate_ids(), _session.consumed_reward_node_keys())
	_refresh_score_hud()
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
		V06CourseModelScript.ROUTE_BYPASS_BAZAAR:
			progress_label.text = "ALLEY %d/3" % [tile_index + 1]
			route_label.text = "バザール裏路地"
		V06CourseModelScript.ROUTE_BYPASS_SIROCCO:
			progress_label.text = "BYPASS %d/5" % [tile_index + 1]
			route_label.text = "砂嵐の抜け道"
		V06CourseModelScript.ROUTE_LOOP_OASIS:
			progress_label.text = "OASIS %d/%d" % [tile_index + 1, 8]
			route_label.text = "オアシス環"
		_:
			progress_label.text = "LOOP %d/%d" % [tile_index + 1, 8]
			route_label.text = "墓廊の輪"
	stage_label.text = str(stage_info.get("name_ja", "砂時計のカイロ"))
	tile_kind_label.text = _tile_kind_display(_session.current_tile_kind())
	var values: Array[int] = _session.faces()
	for index: int in range(slot_labels.size()):
		slot_labels[index].text = str(values[index]) if index < values.size() else "—"
	_refresh_slot_display(values)
	var phase: StringName = _session.phase()
	_refresh_slot_guidance(values, phase)
	if phase != V06PlaySessionScript.PHASE_READY:
		message_label.show()
	match phase:
		V06PlaySessionScript.PHASE_READY:
			tray_status_label.text = "3 ROLL SLOT　　%d / 3" % values.size()
			tray_hint_label.text = "左で役を考え、右で振る。もう一度で停止。"
			if not _rolling and not _movement_active:
				if _session.roll_count() < 3:
					message_label.text = "ダイス1個で、1マスずつ進む"
					message_label.show()
				else:
					message_label.hide()
		V06PlaySessionScript.PHASE_MOVING:
			if _session.pending_resolution_role() != &"":
				tray_status_label.text = "3 ROLL SLOT　　3 / 3"
				tray_hint_label.text = "役を確認中"
			else:
				tray_status_label.text = "MOVING"
				tray_hint_label.text = "着地点へ移動中…"
		V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			tray_status_label.text = "ROUTE CHOICE"
			tray_hint_label.text = "残り%dマス・出目%dを保持中" % [_session.pending_remaining_steps(), _session.pending_face()]
			message_label.text = "進むルートを選ぶ"
		V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
			tray_status_label.text = String(_session.resolution_role())
			tray_hint_label.text = "次の3投を準備中"
		V06PlaySessionScript.PHASE_BOSS_GATE:
			tray_status_label.text = "BOSS ROUND"
			tray_hint_label.text = "3投で攻撃。次の行動とDEFを確認"
			message_label.text = "この周回のボスステージ"
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
			tray_status_label.text = "ROUND RESULT"
			tray_hint_label.text = "結果確認が必要です"
		V06PlaySessionScript.PHASE_LAP_RESULT:
			tray_status_label.text = "LAP CLEAR"
		V06PlaySessionScript.PHASE_RUN_OVER:
			tray_status_label.text = "RUN OVER"
	_refresh_boss_panel()
	skill_tool_button.text = "スキル\nピンポイント READY" if _session.skill_gauge() >= V06PlaySessionScript.SKILL_GAUGE_MAX else "スキル\nピンポイント %d/%d" % [_session.skill_gauge(), V06PlaySessionScript.SKILL_GAUGE_MAX]
	if _rolling:
		die_button.text = "止める"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		die_button.text = "ボスに挑む"
	elif _shown_face > 0:
		die_button.text = "%dマス進む" % _shown_face
	else:
		die_button.text = "サイコロを振る"
	_refresh_die_layout(route_id)
	_refresh_die_presentation()
	die_button.disabled = _utility_open or _movement_active or (not _rolling and not _session.can_roll())
	var utility_disabled := _utility_open or _map_open or _movement_active or _rolling or phase != V06PlaySessionScript.PHASE_READY
	item_tool_button.disabled = utility_disabled
	skill_tool_button.disabled = utility_disabled
	back_button.disabled = _movement_active


func _refresh_slot_guidance(values: Array[int], phase: StringName) -> void:
	if _inline_slot_result_active:
		return
	role_label.add_theme_color_override("font_color", Color(0.73, 0.59, 0.37, 1))
	if phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		role_label.text = "ボス攻撃を準備"
		next_need_label.text = ""
		action_hint_label.text = ""
		return
	if phase in [V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER]:
		role_label.text = "結果を確認"
		next_need_label.text = ""
		action_hint_label.text = ""
		return
	match values.size():
		0:
			role_label.text = "役をつくろう"
		1:
			role_label.text = "同じ数字を狙う"
		2:
			if values[0] == values[1]:
				role_label.text = "%dでTRIPLE" % values[0]
			else:
				role_label.text = "どちらかでPAIR"
		_:
			role_label.text = _display_role(String(_session.resolution_role()))
	next_need_label.text = ""
	action_hint_label.text = ""


func _refresh_slot_display(values: Array[int]) -> void:
	var next_slot: int = values.size()
	if next_slot < 0 or next_slot >= slot_labels.size():
		return
	if _session != null and _session.phase() in [V06PlaySessionScript.PHASE_MOVING, V06PlaySessionScript.PHASE_CHOICE_REQUIRED] and _session.pending_face() > 0:
		# The session owns the stopped face. Showing pending_face here transfers
		# the same value into the next slot before the first hop begins and keeps
		# it visible while a fork choice preserves the unspent movement.
		slot_labels[next_slot].text = str(_session.pending_face())
	elif _rolling or _slot_settling:
		slot_labels[next_slot].text = str(_rolling_slot_face)


func _refresh_rolling_slot_preview() -> void:
	if not _rolling or _session == null:
		return
	var next_slot: int = _session.faces().size()
	if next_slot < 0 or next_slot >= slot_labels.size():
		return
	_rolling_slot_face = 1 + (int(_rolling_slot_elapsed / ROLLING_SLOT_STEP_SECONDS) % 6)
	slot_labels[next_slot].text = str(_rolling_slot_face)


func _play_inline_slot_result(role: String, face: int, motion_generation: int) -> void:
	_inline_slot_result_active = true
	var values: Array[int] = _session.faces()
	values.append(face)
	var spec := inline_slot_result_spec(role, values)
	role_label.text = _display_role(role)
	role_label.add_theme_color_override("font_color", Color("#167f82"))
	role_reward_label.text = str(spec.reward)
	role_reward_label.show()
	tray_status_label.text = "3 ROLL SLOT　　3 / 3"
	pair_link.hide()
	for panel: PanelContainer in slot_panels:
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2.ONE
		panel.self_modulate = Color.WHITE
	match str(spec.effect):
		"pair_link":
			var pair_indices: Array = spec.indices
			if pair_indices.size() == 2:
				_position_pair_link(pair_indices[0], pair_indices[1])
				pair_link.show()
				pair_link.modulate.a = 0.0
				var link_tween := create_tween()
				link_tween.tween_property(pair_link, "modulate:a", 0.92, 0.12)
				link_tween.tween_interval(0.16)
				link_tween.tween_property(pair_link, "modulate:a", 0.0, 0.14)
				_flash_slot_panels(pair_indices, SLOT_RESULT_GLOW, 1.035)
		"left_to_right":
			for index: int in range(slot_panels.size()):
				var flow_tween := create_tween()
				flow_tween.tween_interval(index * 0.07)
				flow_tween.tween_property(slot_panels[index], "self_modulate", SLOT_RESULT_GLOW, 0.10)
				flow_tween.parallel().tween_property(slot_panels[index], "scale", Vector2.ONE * 1.025, 0.10)
				flow_tween.tween_property(slot_panels[index], "self_modulate", Color.WHITE, 0.16)
				flow_tween.parallel().tween_property(slot_panels[index], "scale", Vector2.ONE, 0.16)
		"strong_flash":
			_flash_slot_panels([0, 1, 2], SLOT_RESULT_STRONG_GLOW, 1.055)
		_:
			_flash_slot_panels([0, 1, 2], SLOT_RESULT_GLOW, 1.02)
	await get_tree().create_timer(INLINE_SLOT_RESULT_SECONDS).timeout
	if motion_generation != _motion_generation:
		return
	_reset_inline_slot_result()


func _flash_slot_panels(indices: Array, glow: Color, peak_scale: float) -> void:
	for value: Variant in indices:
		var index := int(value)
		if index < 0 or index >= slot_panels.size():
			continue
		var tween := create_tween()
		tween.tween_property(slot_panels[index], "self_modulate", glow, 0.12)
		tween.parallel().tween_property(slot_panels[index], "scale", Vector2.ONE * peak_scale, 0.12)
		tween.tween_interval(0.08)
		tween.tween_property(slot_panels[index], "self_modulate", Color.WHITE, 0.18)
		tween.parallel().tween_property(slot_panels[index], "scale", Vector2.ONE, 0.18)


func _matching_pair_indices(values: Array[int]) -> Array[int]:
	for first: int in range(values.size()):
		for second: int in range(first + 1, values.size()):
			if values[first] == values[second]:
				return [first, second]
	return []


func _position_pair_link(first: int, second: int) -> void:
	var first_rect := slot_panels[first].get_global_rect()
	var second_rect := slot_panels[second].get_global_rect()
	var origin := slot_column.global_position
	var y := minf(first_rect.end.y, second_rect.end.y) - origin.y - 12.0
	pair_link.points = PackedVector2Array([
		Vector2(first_rect.get_center().x - origin.x, y),
		Vector2(second_rect.get_center().x - origin.x, y),
	])


func _inline_role_reward(role: String) -> String:
	match role:
		"PAIR":
			return "+150　ゲージ+1"
		"STRAIGHT":
			return "+350　ゲージ+2"
		"TRIPLE":
			return "+800　READY"
		_:
			return "+50　コイン+1"


func inline_slot_result_spec(role: String, values: Array[int]) -> Dictionary:
	match role:
		"PAIR":
			return {"effect":"pair_link", "indices":_matching_pair_indices(values), "reward":_inline_role_reward(role), "duration":INLINE_SLOT_RESULT_SECONDS}
		"STRAIGHT":
			return {"effect":"left_to_right", "indices":[0, 1, 2], "reward":_inline_role_reward(role), "duration":INLINE_SLOT_RESULT_SECONDS}
		"TRIPLE":
			return {"effect":"strong_flash", "indices":[0, 1, 2], "reward":_inline_role_reward(role), "duration":INLINE_SLOT_RESULT_SECONDS}
		_:
			return {"effect":"soft_flash", "indices":[0, 1, 2], "reward":_inline_role_reward(role), "duration":INLINE_SLOT_RESULT_SECONDS}


func _reset_inline_slot_result() -> void:
	_inline_slot_result_active = false
	if is_instance_valid(role_reward_label):
		role_reward_label.hide()
	if is_instance_valid(pair_link):
		pair_link.hide()
	for panel: PanelContainer in slot_panels:
		panel.scale = Vector2.ONE
		panel.self_modulate = Color.WHITE


func _refresh_die_presentation() -> void:
	if not is_instance_valid(dice_presentation):
		return
	var display_face := _shown_face if _shown_face > 0 else 6
	dice_presentation.present([display_face], _rolling, 0 if _rolling else 1)
	dice_presentation.pivot_offset = dice_presentation.size * 0.5
	var target_scale := 1.08 if _rolling else (1.05 if _shown_face > 0 and _movement_active else 1.0)
	dice_presentation.scale = Vector2.ONE * target_scale


func die_anchor_for_route(route_id: String) -> Vector2:
	return DICE_ANCHOR_LOOP if route_id in [V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB] else DICE_ANCHOR_NORMAL


func _refresh_die_layout(route_id: String) -> void:
	if not is_instance_valid(dice_presentation):
		return
	var anchor := die_anchor_for_route(route_id)
	dice_presentation.anchor_left = anchor.x
	dice_presentation.anchor_right = anchor.x
	dice_presentation.anchor_top = anchor.y
	dice_presentation.anchor_bottom = anchor.y


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
		"WARP_OASIS": return "OASIS WARP"
		"WARP_TOMB": return "TOMB WARP"
		"WARP_GOLD": return "GOLD WARP"
		"LOOP_ENTRY", "LOOP_ENTRY_GOLD": return "LOOP ENTRY"
		"EXIT_GATE": return "EXIT GATE"
		"BOSS_GATE": return "BOSS GATE"
		_: return "TRAVEL"


func _configure_route_choice() -> void:
	var bypass: Dictionary = _session.pending_bypass()
	if bypass.is_empty():
		return
	var saved_steps := int(bypass.get("saved_steps", 0))
	var route_id := str(bypass.get("route_id", ""))
	var risk_count := 0
	var item_count := 0
	if route_id == V06CourseModelScript.ROUTE_BYPASS_BAZAAR:
		risk_count = 1
		item_count = 1
	elif route_id == V06CourseModelScript.ROUTE_BYPASS_SIROCCO:
		risk_count = 2
		item_count = 1
	choice_detail_label.text = "%s　・　%dマス短縮" % [str(bypass.get("name_ja", "近道")), saved_steps]
	choice_main_button.text = "本線　・　見えている道を進む"
	choice_bypass_button.text = "近道　・　RISK×%d / ITEM×%d" % [risk_count, item_count]
	for connection: Dictionary in choice_bypass_button.pressed.get_connections():
		choice_bypass_button.pressed.disconnect(connection.callable)
	choice_bypass_button.pressed.connect(_on_route_chosen.bind(route_id))


func _apply_surface_styles() -> void:
	%HudPanel.add_theme_stylebox_override("panel", _panel_style(Color("#172625"), Color("#b88a46"), 22, 4))
	%StageBand.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#8d683b"), 8, 2))
	%AtlasFrame.add_theme_stylebox_override("panel", _panel_style(Color("#e8d7b5"), Color("#9c7742"), 12, 4))
	%TrayPanel.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#b88a46"), 24, 5))
	var tool_dock_style := _panel_style(Color("#241813"), Color("#8d683b"), 18, 3)
	tool_dock_style.content_margin_top = 8
	tool_dock_style.content_margin_bottom = 8
	%ToolDock.add_theme_stylebox_override("panel", tool_dock_style)
	for slot_panel: PanelContainer in [%SlotPanel0, %SlotPanel1, %SlotPanel2]:
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color("#efe0bf"), Color("#9c7742"), 14, 3))
	tray_status_label.add_theme_color_override("font_color", Color("#277c80"))
	tray_hint_label.add_theme_color_override("font_color", Color("#604b36"))
	action_hint_label.add_theme_color_override("font_color", Color("#604b36"))
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


func _refresh_score_hud() -> void:
	if not is_instance_valid(score_label) or _session == null:
		return
	coin_label.text = str(_session.coins())
	var target: int = int(_session.score())
	if target == _score_target:
		score_label.text = _format_score(roundi(_score_display_value))
		return
	var delta: int = target - _score_target
	_score_target = target
	if is_instance_valid(_score_tween):
		_score_tween.kill()
	var count_seconds := 0.32 if _session.pending_resolution_role() != &"" else 0.46
	_score_tween = create_tween()
	_score_tween.tween_method(_set_score_display, _score_display_value, float(target), count_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if delta > 0:
		var award: Dictionary = _session.last_score_award()
		score_delta_label.text = "+%d  %s" % [delta, str(award.get("label", "TRAVEL"))]
		score_delta_label.modulate = Color.WHITE
		if is_instance_valid(_score_delta_tween):
			_score_delta_tween.kill()
		_score_delta_tween = create_tween()
		_score_delta_tween.tween_interval(0.72)
		_score_delta_tween.tween_property(score_delta_label, "modulate:a", 0.0, 0.24)


func _set_score_display(value: float) -> void:
	_score_display_value = value
	score_label.text = _format_score(roundi(value))


func _format_score(value: int) -> String:
	var digits := str(maxi(value, 0))
	var grouped := ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return digits + grouped


func _heart_text(current: int, maximum: int) -> String:
	var result := ""
	for index: int in range(maxi(maximum, 0)):
		result += "♥" if index < current else "♡"
	return result


func _display_role(role: String) -> String:
	return "MIX" if role in ["", "NONE"] else role


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
	var terminal_result := phase in [V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER]
	boss_hp_label.visible = not terminal_result
	boss_action_label.visible = not terminal_result
	boss_round_ack_button.visible = phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT
	next_lap_button.visible = phase == V06PlaySessionScript.PHASE_LAP_RESULT
	retry_button.visible = phase == V06PlaySessionScript.PHASE_RUN_OVER
	if phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
		var result: Dictionary = _session.boss_result()
		boss_result_label.text = "%d vs DEF %d · %s\nPLAYER -%d / BOSS -%d" % [int(result.sum), int(result.defense), String(result.role), int(result.applied_player_damage), int(result.applied_boss_damage)]
	elif phase == V06PlaySessionScript.PHASE_LAP_RESULT:
		boss_title.text = "周回クリア"
		boss_result_label.text = _score_result_text(true)
	elif phase == V06PlaySessionScript.PHASE_RUN_OVER:
		boss_title.text = "旅の記録"
		boss_result_label.text = _score_result_text(false)
	else:
		boss_title.text = "SLEEPY SPHINX"
		boss_result_label.text = "3回振って攻撃しよう"


func _score_result_text(victory: bool) -> String:
	var score: int = int(_session.score())
	var best: int = int(_session.best_score())
	var breakdown: Dictionary = _session.score_breakdown()
	var lead := "スフィンクスを突破！" if victory else "旅はここまで。"
	var gap: int = best - score
	var chase := "自己ベスト更新！" if gap <= 0 else "あと%sで自己ベスト" % _format_score(gap)
	return "%s\nSCORE %s　BEST %s\n%s\n旅 %s / スロット %s / 発見 %s / ボス %s / 完走 %s" % [
		lead,
		_format_score(score),
		_format_score(best),
		chase,
		_format_score(int(breakdown.get("travel", 0))),
		_format_score(int(breakdown.get("slot", 0))),
		_format_score(int(breakdown.get("discovery", 0))),
		_format_score(int(breakdown.get("boss", 0))),
		_format_score(int(breakdown.get("finish", 0))),
	]


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
