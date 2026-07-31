class_name V06PlayScreen
extends Control

signal back_requested
signal resume_failed

const V06PlaySessionScript = preload("res://scripts/game/v06_play_session.gd")
const V06SessionSaveManagerScript = preload("res://scripts/game/v06_session_save_manager.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const UiThemeNamesScript = preload("res://scripts/ui/ui_theme_names.gd")
const V11BossLaneBoardScript = preload("res://scripts/ui/v11_boss_lane_board.gd")
const ITEM_CARD: Texture2D = preload("res://assets/art/v08/cards/item-card.png")
const SKILL_CARD: Texture2D = preload("res://assets/art/v08/cards/skill-card.png")
const WING_GATE_PICTOGRAM: Texture2D = preload("res://assets/art/v10/boss/wing-gate.png")
const QUICKSAND_PICTOGRAM: Texture2D = preload("res://assets/art/v10/boss/quicksand.png")

const QA_SCENARIO_ATLAS_18 := "atlas_18"
const QA_SCENARIO_BOSS_READY := "boss_ready"
const QA_SCENARIO_BOSS_ROUND := "boss_round"
const SLOT_BREATH_PERIOD_SECONDS := 2.0
const SLOT_BREATH_ALPHA_AMPLITUDE := 0.025
const TARGET_PREVIEW_SECONDS := 0.20
const SLOT_STOP_DELAY_SECONDS := 0.12
const BOSS_DICE_SETTLE_SECONDS := 0.14
const BOSS_YOU_REVEAL_SECONDS := 0.14
const BOSS_SPHINX_REVEAL_SECONDS := 0.26
const BOSS_SLOT_TRANSFER_SECONDS := 0.12
const BOSS_CHARGE_SECONDS := 0.08
const BOSS_EFFECT_SECONDS := 0.18
const BOSS_STEP_SECONDS := 0.20
const BOSS_GOAL_GATE_SECONDS := 0.34
const BOSS_INTRO_SECONDS := 0.82
const BOSS_REPEAT_INTRO_SECONDS := 0.42
const BOSS_DICE_EXPLAIN_SCALE := Vector2(1.22, 1.22)
const BOSS_DICE_REST_Y := 850.0
const BOSS_DICE_STOP_Y := 828.0
const BOSS_CAMERA_SCROLL_SECONDS := 0.42
const BOSS_CAMERA_HOLD_SECONDS := 0.12
const BOSS_BACKDROP_FADE_SECONDS := 0.28
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
@onready var boss_dice_presentation: DicePresentation3D = %BossDicePresentation
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
@onready var boss_hud: PanelContainer = %BossHud
@onready var boss_you_progress_label: Label = %BossYouProgressLabel
@onready var boss_sphinx_progress_label: Label = %BossSphinxProgressLabel
@onready var boss_pause_button: Button = %BossPauseButton
@onready var boss_title: Label = %BossTitle
@onready var boss_hp_label: Label = %BossHPLabel
@onready var boss_race_track_label: Label = %BossRaceTrackLabel
@onready var boss_action_label: Label = %BossActionLabel
@onready var boss_result_label: Label = %BossResultLabel
@onready var boss_round_ack_button: Button = %BossRoundAckButton
@onready var next_lap_button: Button = %NextLapButton
@onready var retry_button: Button = %RetryButton
@onready var boss_back_button: Button = %BossBackButton
@onready var boss_panel: PanelContainer = %BossPanel
@onready var boss_start_rule_panel: PanelContainer = %BossStartRulePanel
@onready var boss_quick_rule_panel: PanelContainer = %BossQuickRulePanel
@onready var mirror_panel: PanelContainer = %MirrorPanel
@onready var boss_arena_backdrop: TextureRect = %BossArenaBackdrop
@onready var boss_arena_backdrop_next: TextureRect = %BossArenaBackdropNext
@onready var race_stage: Control = %RaceStage
@onready var boss_lane_board: Control = %BossLaneBoard
@onready var golden_gate_sprite: TextureRect = %GoldenGateSprite
@onready var boss_dice_owner_label: Label = %BossDiceOwnerLabel
@onready var boss_finish_dim: ColorRect = %BossFinishDim
@onready var boss_finish_summary_label: Label = %BossFinishSummaryLabel
@onready var player_track: ProgressBar = %PlayerTrack
@onready var boss_track: ProgressBar = %BossTrack
@onready var player_token: TextureRect = %PlayerToken
@onready var boss_token: TextureRect = %BossToken
@onready var player_foot_marker: PanelContainer = %PlayerFootMarker
@onready var boss_foot_marker: PanelContainer = %BossFootMarker
@onready var player_roll_value: Label = %PlayerRollValue
@onready var boss_roll_value: Label = %BossRollValue
@onready var boss_forward_step_labels: Array[Label] = [%BossForwardStep1, %BossForwardStep2, %BossForwardStep3, %BossForwardStep4, %BossForwardStep5, %BossForwardStep6]
@onready var boss_player_target_label: Label = %BossPlayerTargetLabel
@onready var boss_sphinx_target_label: Label = %BossSphinxTargetLabel
@onready var player_landing_ring: PanelContainer = %PlayerLandingRing
@onready var boss_landing_ring: PanelContainer = %BossLandingRing
@onready var player_landing_ring_value: Label = %PlayerLandingRing/Value
@onready var boss_landing_ring_value: Label = %BossLandingRing/Value
@onready var player_state_badge: TextureRect = %PlayerStateBadge
@onready var player_state_badge_value: Label = %PlayerStateBadge/Value
@onready var boss_state_badge: TextureRect = %BossStateBadge
@onready var boss_state_badge_value: Label = %BossStateBadge/Value
@onready var boost_pictogram: TextureRect = %BoostPictogram
@onready var sand_pictogram: TextureRect = %SandPictogram
@onready var boss_pause_overlay: Control = %BossPauseOverlay
@onready var boss_resume_button: Button = %BossResumeButton
@onready var normal_hud_panel: PanelContainer = %HudPanel
@onready var normal_stage_band: PanelContainer = %StageBand
@onready var normal_tool_dock: PanelContainer = %ToolDock

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
var _boss_last_player_position := -1
var _boss_last_position := -1
var _boss_last_revealed_turn := -1
var _boss_pause_open := false
var _boss_roll_animation_active := false
var _boss_roll_sequence_id := 0
var _boss_intro_active := false
var _boss_intro_complete := false
var _boss_finished_saved_turn := -1
var _boss_mirror_reveal_tween: Tween
var _boss_mirror_values_visible := false
var _boss_camera_tween: Tween
var _boss_background_phase := -1
var _boss_backdrop_active := 0
var _boss_goal_presentation_active := false
var _stage_intro_active := false
var _boss_visual_player_position := 0.0
var _boss_visual_sphinx_position := 0.0


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
	if qa_scenario in [QA_SCENARIO_BOSS_READY, QA_SCENARIO_BOSS_ROUND] and _session.enter_boss(Time.get_ticks_msec()):
		_present_session_phase()
		_refresh_ui()
		if qa_scenario == QA_SCENARIO_BOSS_ROUND:
			call_deferred("_run_face", 2)
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
		if _session != null and _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
			_refresh_boss_landing_preview(_rolling_slot_face)
	if is_instance_valid(boss_lane_board) and boss_overlay.visible:
		_sync_boss_board_tokens()
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
	_boss_roll_sequence_id += 1
	if _boss_camera_tween != null:
		_boss_camera_tween.kill()
	if is_instance_valid(atlas_view):
		atlas_view.cancel_visual_motion()


func _cancel_motion(route_position := {}) -> void:
	_motion_generation += 1
	_stage_intro_active = false
	_boss_roll_sequence_id += 1
	if _boss_camera_tween != null:
		_boss_camera_tween.kill()
		_boss_camera_tween = null
	_rolling = false
	_slot_settling = false
	_movement_active = false
	_boss_roll_animation_active = false
	_boss_intro_active = false
	_boss_intro_complete = false
	_boss_mirror_values_visible = false
	_boss_goal_presentation_active = false
	_boss_finished_saved_turn = -1
	boss_finish_dim.hide()
	boss_finish_dim.modulate.a = 1.0
	boss_finish_summary_label.hide()
	boss_result_label.hide()
	for token: Control in [player_token, boss_token]:
		token.show()
		token.z_index = 5
		token.scale = Vector2.ONE
	for marker: Control in [player_foot_marker, boss_foot_marker]:
		marker.show()
	boss_dice_presentation.scale = Vector2.ONE
	boss_dice_presentation.position.y = BOSS_DICE_REST_Y
	boss_dice_owner_label.hide()
	if _boss_mirror_reveal_tween != null:
		_boss_mirror_reveal_tween.kill()
		_boss_mirror_reveal_tween = null
	_reset_inline_slot_result()
	_reset_slot_preview_style()
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
	boss_pause_button.pressed.connect(_on_boss_pause_pressed)
	boss_resume_button.pressed.connect(_on_boss_resume_pressed)
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
	if _boss_intro_active or _session == null or _session.phase() == V06PlaySessionScript.PHASE_BOSS_FINISHED:
		return
	if _session != null and _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
		if _session.acknowledge_boss_round():
			_refresh_ui()
			_present_session_phase()
			_start_roll()
		return
	if _rolling:
		_stop_roll()
	elif not _movement_active and _session.can_roll():
		_start_roll()


func _start_roll() -> void:
	if _session == null or _boss_intro_active or not _session.can_roll():
		return
	if _session != null and _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		_boss_roll_sequence_id += 1
		_clear_boss_state_badges()
		boss_dice_presentation.position.y = BOSS_DICE_REST_Y
	atlas_view.clear_roll_preview()
	_rolling = true
	_boss_mirror_values_visible = false
	_slot_settling = false
	_rolling_slot_elapsed = 0.0
	_rolling_slot_face = 1
	message_label.text = "回転中…もう一度タップで止める"
	message_label.show()
	_refresh_ui()
	_refresh_rolling_slot_preview()
	if _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		boss_dice_owner_label.hide()
		boss_dice_presentation.scale = Vector2.ONE
		boss_dice_presentation.present([_rolling_slot_face], true, 0)
		_refresh_boss_landing_preview(_rolling_slot_face)


func _stop_roll() -> void:
	if not _rolling or _boss_intro_active or _session == null or not _session.can_roll():
		return
	_rolling = false
	_slot_settling = true
	_movement_active = _session.can_roll()
	var face := _rng.randi_range(1, 6)
	_shown_face = face
	if _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		boss_dice_presentation.present([face], false, 1)
		boss_dice_presentation.pivot_offset = boss_dice_presentation.size * 0.5
		boss_dice_presentation.scale = BOSS_DICE_EXPLAIN_SCALE
		boss_dice_presentation.position.y = BOSS_DICE_STOP_Y
		boss_dice_owner_label.text = "YOU"
		boss_dice_owner_label.add_theme_color_override("font_color", Color("#f0c76a"))
		boss_dice_owner_label.show()
	_refresh_ui()
	_run_face(face)


func _run_face(face: int) -> void:
	var pre_roll_phase: StringName = _session.phase()
	var pre_roll_position: Dictionary = _session.position()
	var motion_generation := _motion_generation
	var roll_sequence_id := _boss_roll_sequence_id
	if pre_roll_phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		# QA hooks and keyboard/controller callers may enter through this method;
		# once an actual face is being resolved, the intro gate is over.
		_boss_intro_active = false
		_boss_intro_complete = true
	_movement_active = pre_roll_phase == V06PlaySessionScript.PHASE_READY
	if _slot_settling:
		var settle_seconds := BOSS_DICE_SETTLE_SECONDS if pre_roll_phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY else SLOT_STOP_DELAY_SECONDS
		await get_tree().create_timer(settle_seconds).timeout
		if motion_generation != _motion_generation:
			return
		if pre_roll_phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and roll_sequence_id != _boss_roll_sequence_id:
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
		var race_result: Dictionary = _session.boss_result()
		if bool(race_result.get("victory", false)) or bool(race_result.get("defeat", false)):
			# A terminal result invalidates every older await immediately. The
			# final presentation below gets a fresh id and can finish once.
			_boss_roll_sequence_id += 1
			roll_sequence_id = _boss_roll_sequence_id
			if _boss_mirror_reveal_tween != null:
				_boss_mirror_reveal_tween.kill()
				_boss_mirror_reveal_tween = null
		_boss_roll_animation_active = true
		message_label.text = "PLAYER %d / SPHINX %d" % [face, int(race_result.get("boss_roll", 7 - face))]
		_refresh_ui()
		_present_session_phase()
		var sequence_completed := await _play_boss_roll_sequence(race_result, roll_sequence_id)
		if not sequence_completed or roll_sequence_id != _boss_roll_sequence_id:
			return
		_boss_roll_animation_active = false
		_rolling = false
		_slot_settling = false
		_movement_active = false
		_refresh_ui()
		_present_session_phase()
		if _session.phase() == V06PlaySessionScript.PHASE_BOSS_FINISHED:
			var finished_turn := int(race_result.get("turn", -1))
			if _boss_finished_saved_turn != finished_turn:
				_boss_finished_saved_turn = finished_turn
				if _session.is_stable_for_save():
					_save_stable_checkpoint()
		elif _session.is_stable_for_save():
			_save_stable_checkpoint()
		_boss_roll_sequence_id += 1
		return
	var move_distance: int = _session.pending_move_distance()
	message_label.text = "%dマス進む" % move_distance if move_distance == face else "出目%d・移動%d（低下中）" % [face, move_distance]
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


func _play_boss_roll_sequence(result: Dictionary, sequence_id: int) -> bool:
	var player_roll := int(result.get("player_roll", 0))
	var boss_roll := int(result.get("boss_roll", 7 - player_roll))
	var slot_index := clampi(_session.faces().size() - 1, 0, slot_labels.size() - 1)
	_clear_boss_state_badges()
	_boss_mirror_values_visible = false
	mirror_panel.hide()
	boss_dice_presentation.present([player_roll], false, 1)
	boss_dice_presentation.pivot_offset = boss_dice_presentation.size * 0.5
	boss_dice_presentation.scale = BOSS_DICE_EXPLAIN_SCALE
	boss_dice_presentation.position.y = BOSS_DICE_STOP_Y
	boss_dice_owner_label.text = "YOU"
	boss_dice_owner_label.add_theme_color_override("font_color", Color("#f0c76a"))
	boss_dice_owner_label.show()
	if slot_index >= 0 and slot_index < slot_labels.size():
		slot_labels[slot_index].text = "—"
	if not await _boss_roll_wait(BOSS_YOU_REVEAL_SECONDS, sequence_id): return false
	_reveal_boss_value(player_roll_value, str(player_roll))
	boss_dice_presentation.flip_to_face(boss_roll)
	if not await _boss_roll_wait(0.10, sequence_id): return false
	boss_dice_owner_label.text = "SPHINX"
	boss_dice_owner_label.add_theme_color_override("font_color", Color("#66d2c8"))
	if not await _boss_roll_wait(maxf(BOSS_SPHINX_REVEAL_SECONDS - 0.10, 0.0), sequence_id): return false
	_reveal_boss_value(boss_roll_value, str(boss_roll))
	_boss_mirror_values_visible = true
	mirror_panel.show()
	_animate_mirror_reveal()
	if not await _boss_roll_wait(BOSS_SLOT_TRANSFER_SECONDS, sequence_id): return false
	boss_dice_owner_label.hide()
	var die_scale_down := create_tween()
	die_scale_down.tween_property(boss_dice_presentation, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	die_scale_down.parallel().tween_property(boss_dice_presentation, "position:y", BOSS_DICE_REST_Y, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if slot_index >= 0 and slot_index < slot_labels.size():
		slot_labels[slot_index].text = str(player_roll)
		slot_labels[slot_index].modulate = Color.WHITE
		_flash_slot_panels([slot_index], SLOT_RESULT_GLOW, 1.03)
	if not await _boss_roll_wait(BOSS_CHARGE_SECONDS, sequence_id): return false
	_charge_boss_tokens()
	if not await _boss_roll_wait(BOSS_CHARGE_SECONDS, sequence_id): return false
	var goal := int(_session.boss_snapshot().get("course_length", 20))
	var player_before := int(result.get("player_position_before", 0))
	var boss_before := int(result.get("boss_position_before", 0))
	var player_base_after := int(result.get("player_base_position_after", result.get("player_position_after", 0)))
	var boss_base_after := int(result.get("boss_base_position_after", result.get("boss_position_after", 0)))
	var base_steps := maxi(player_base_after - player_before, boss_base_after - boss_before)
	for step: int in range(1, base_steps + 1):
		var player_step_position := mini(player_before + step, player_base_after)
		var boss_step_position := mini(boss_before + step, boss_base_after)
		_position_boss_tokens(player_step_position, boss_step_position, goal, true, BOSS_STEP_SECONDS * 0.82)
		if not await _boss_roll_wait(BOSS_STEP_SECONDS, sequence_id): return false
	if not await _animate_boss_landing_effects(result, sequence_id, player_base_after, boss_base_after, goal): return false
	var terminal_turn := bool(result.get("victory", false)) or bool(result.get("defeat", false))
	var player_after := int(result.get("player_position_after", player_base_after))
	var boss_after := int(result.get("boss_position_after", boss_base_after))
	if not terminal_turn:
		if not await _settle_boss_camera_after_movement(player_after, sequence_id): return false
	if not await _crossfade_boss_background(maxi(player_after, boss_after), sequence_id): return false
	if terminal_turn:
		if not await _play_boss_goal_sequence(result, sequence_id, goal): return false
	return true


func _animate_boss_landing_effects(result: Dictionary, sequence_id: int, player_base: int, boss_base: int, goal: int) -> bool:
	var player_effect := str(result.get("player_effect", ""))
	var boss_effect := str(result.get("boss_effect", ""))
	if player_effect.is_empty() and boss_effect.is_empty():
		return true
	_set_target_pictogram(boost_pictogram, player_effect, player_base, true)
	_set_target_pictogram(sand_pictogram, boss_effect, boss_base, false)
	for effect_icon: TextureRect in [boost_pictogram, sand_pictogram]:
		if not effect_icon.visible:
			continue
		effect_icon.scale = Vector2.ONE
		effect_icon.modulate.a = 0.45
		var pulse := create_tween()
		pulse.tween_property(effect_icon, "modulate:a", 1.0, 0.10)
		pulse.tween_property(effect_icon, "modulate:a", 0.82, 0.10)
	if not await _boss_roll_wait(BOSS_EFFECT_SECONDS, sequence_id): return false
	var player_after := int(result.get("player_position_after", player_base))
	var boss_after := int(result.get("boss_position_after", boss_base))
	var effect_steps := maxi(absi(player_after - player_base), absi(boss_after - boss_base))
	for step: int in range(1, effect_steps + 1):
		var player_position := player_base + clampi(player_after - player_base, -step, step)
		var boss_position := boss_base + clampi(boss_after - boss_base, -step, step)
		_position_boss_tokens(player_position, boss_position, goal, true, BOSS_STEP_SECONDS * 0.82)
		if not await _boss_roll_wait(BOSS_STEP_SECONDS, sequence_id): return false
	return true


func _play_boss_goal_sequence(result: Dictionary, sequence_id: int, goal: int) -> bool:
	_boss_goal_presentation_active = true
	boss_result_label.hide()
	boss_finish_summary_label.hide()
	boss_pause_button.hide()
	mirror_panel.hide()
	boss_dice_owner_label.hide()
	boss_dice_presentation.hide()
	boss_player_target_label.hide()
	boss_sphinx_target_label.hide()
	boss_lane_board.clear_preview()
	%TrayPanel.modulate = Color(0.42, 0.42, 0.42, 1.0)
	%GoalLabel.show()
	%GoalLabel.text = "GATE OPEN"
	%GoalLabel.pivot_offset = %GoalLabel.size * 0.5
	var gate_open := create_tween().set_parallel(true)
	gate_open.tween_property(%GoalLabel, "scale", Vector2.ONE * 1.34, BOSS_GOAL_GATE_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	gate_open.tween_property(%GoalLabel, "modulate", Color(1.6, 1.35, 0.72, 1.0), BOSS_GOAL_GATE_SECONDS)
	var active_backdrop: TextureRect = boss_arena_backdrop if _boss_backdrop_active == 0 else boss_arena_backdrop_next
	var backdrop_color := active_backdrop.modulate
	gate_open.tween_property(active_backdrop, "modulate", Color(1.35, 1.18, 0.72, backdrop_color.a), BOSS_GOAL_GATE_SECONDS * 0.5)
	gate_open.chain().tween_property(active_backdrop, "modulate", backdrop_color, BOSS_GOAL_GATE_SECONDS * 0.5)
	if not await _boss_roll_wait(BOSS_GOAL_GATE_SECONDS, sequence_id): return false
	var player_won := bool(result.get("victory", false))
	var winner_token: Control = player_token if player_won else boss_token
	var loser_token: Control = boss_token if player_won else player_token
	var winner_foot: Control = player_foot_marker if player_won else boss_foot_marker
	var loser_foot: Control = boss_foot_marker if player_won else player_foot_marker
	loser_token.hide()
	loser_foot.hide()
	winner_foot.hide()
	winner_token.show()
	winner_token.z_index = 22
	winner_token.position = Vector2(race_stage.size.x * 0.5 - winner_token.size.x * 0.5, 118.0)
	winner_token.pivot_offset = winner_token.size * 0.5
	var victory_jump := create_tween()
	victory_jump.tween_property(winner_token, "position:y", winner_token.position.y - 34.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	victory_jump.parallel().tween_property(winner_token, "scale", Vector2.ONE * 1.18, 0.16)
	victory_jump.tween_property(winner_token, "position:y", winner_token.position.y - 8.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if not await _boss_roll_wait(0.34, sequence_id): return false
	boss_finish_dim.modulate.a = 0.0
	boss_finish_dim.show()
	var finish_dim_in := create_tween()
	finish_dim_in.tween_property(boss_finish_dim, "modulate:a", 1.0, 0.22)
	if not await _boss_roll_wait(0.22, sequence_id): return false
	boss_result_label.text = "YOU WIN" if player_won else "SPHINX WIN"
	boss_result_label.add_theme_font_size_override("font_size", 46)
	boss_result_label.show()
	if not await _boss_roll_wait(0.50, sequence_id): return false
	boss_finish_summary_label.text = _boss_finish_summary(result)
	boss_finish_summary_label.show()
	return true


func _boss_roll_wait(seconds: float, sequence_id: int) -> bool:
	await get_tree().create_timer(seconds).timeout
	return is_inside_tree() and sequence_id == _boss_roll_sequence_id


func _reveal_boss_value(label: Label, value: String) -> void:
	label.text = value
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 0.72
	label.modulate.a = 0.4
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(label, "modulate:a", 1.0, 0.14)


func _charge_boss_tokens() -> void:
	for control: Control in [player_token, boss_token, player_foot_marker, boss_foot_marker]:
		control.scale = Vector2.ONE
		control.modulate = Color.WHITE
		var charge := create_tween()
		charge.tween_property(control, "modulate", Color(1.18, 1.12, 0.92, 1.0), BOSS_CHARGE_SECONDS * 0.5)
		charge.tween_property(control, "modulate", Color.WHITE, BOSS_CHARGE_SECONDS * 0.5)


func _animate_boss_state_badges(result: Dictionary, sequence_id: int) -> bool:
	var player_effect := str(result.get("player_effect", ""))
	var boss_effect := str(result.get("boss_effect", ""))
	var player_tween := _fly_state_badge(player_state_badge, player_state_badge_value, player_effect, player_token, boost_pictogram if player_effect == "WING_GATE" else sand_pictogram)
	var boss_tween := _fly_state_badge(boss_state_badge, boss_state_badge_value, boss_effect, boss_token, boost_pictogram if boss_effect == "WING_GATE" else sand_pictogram)
	if player_tween or boss_tween:
		if not await _boss_roll_wait(BOSS_EFFECT_SECONDS, sequence_id): return false
	return true


func _fly_state_badge(badge: TextureRect, value_label: Label, effect: String, token: Control, source: TextureRect) -> bool:
	if effect not in ["WING_GATE", "QUICKSAND"]:
		badge.hide()
		return false
	badge.texture = WING_GATE_PICTOGRAM if effect == "WING_GATE" else QUICKSAND_PICTOGRAM
	value_label.text = "+3" if effect == "WING_GATE" else "−2"
	badge.position = source.position
	badge.scale = Vector2.ONE
	badge.modulate.a = 1.0
	badge.show()
	var target := token.position + Vector2(token.size.x - 26.0 if token == player_token else -30.0, -18.0)
	var flight := create_tween().set_parallel(true)
	flight.tween_property(badge, "position", target, BOSS_EFFECT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return true


func _clear_boss_state_badges() -> void:
	if is_instance_valid(player_state_badge):
		player_state_badge.hide()
	if is_instance_valid(boss_state_badge):
		boss_state_badge.hide()


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
	var tile_effect: Dictionary = _session.last_tile_effect_result()
	_refresh_ui()
	if not tile_effect.is_empty() and not str(tile_effect.get("text", "")).is_empty():
		message_label.text = str(tile_effect.text)
		message_label.show()
	if visual_path.is_empty():
		atlas_view.clear_roll_preview()
	elif loop_mode:
		if atlas_view.current_route_position() != stable_position:
			await atlas_view.animate_portal_transfer_to(stable_position)
		else:
			atlas_view.set_route_position(stable_position)
		if _session.phase() != V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			await atlas_view.play_landing_effect(stable_position, str(tile_effect.get("text", "")), str(tile_effect.get("tile_kind", "")))
		if motion_generation >= 0 and motion_generation != _motion_generation:
			return false
	else:
		if _session.phase() != V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			await atlas_view.play_landing_effect(stable_position, str(tile_effect.get("text", "")), str(tile_effect.get("tile_kind", "")))
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
			_show_boss_overlay()
			_refresh_boss_panel()
			die_button.grab_focus()
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED, V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER:
			choice_overlay.hide()
			resolution_overlay.hide()
			_show_boss_overlay()
			_refresh_boss_panel()


func _show_boss_overlay() -> void:
	var entering := not boss_overlay.visible
	boss_overlay.show()
	if not entering:
		return
	_boss_intro_active = false
	_boss_intro_complete = false
	_boss_finished_saved_turn = -1
	var boss: Dictionary = _session.boss_snapshot()
	boss_lane_board.configure(int(boss.get("course_length", 20)), _session.boss_course_tiles(true), _session.boss_course_tiles(false))
	_boss_visual_player_position = float(boss.get("player_position", 0))
	_boss_visual_sphinx_position = float(boss.get("boss_position", 0))
	# The first boss frame is a stable reference frame.  Seed the logical
	# positions before the first deferred refresh so entering the overlay cannot
	# be mistaken for a race movement tween.
	_boss_last_player_position = int(_boss_visual_player_position)
	_boss_last_position = int(_boss_visual_sphinx_position)
	boss_lane_board.set_racers(_boss_visual_player_position, _boss_visual_sphinx_position)
	boss_lane_board.set_camera_position(boss_lane_board.snapped_camera_for(_boss_visual_player_position))
	if _boss_camera_tween != null:
		_boss_camera_tween.kill()
		_boss_camera_tween = null
	_boss_background_phase = -1
	_boss_backdrop_active = 0
	_set_boss_background_phase_immediate(_boss_phase_for_progress(maxf(_boss_visual_player_position, _boss_visual_sphinx_position)))
	_sync_boss_board_tokens()
	boss_arena_backdrop.modulate.a = 0.0
	boss_arena_backdrop_next.modulate.a = 0.0
	boss_panel.modulate.a = 0.0
	# Keep the board, lanes, and die at their authored scale while the intro
	# appears.  A BACK scale tween here reads as a camera wobble on entry.
	boss_panel.scale = Vector2.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(boss_arena_backdrop, "modulate:a", 1.0, 0.30)
	tween.tween_property(boss_panel, "modulate:a", 1.0, 0.30)


func _begin_boss_intro_if_needed() -> void:
	if _boss_intro_active or _boss_intro_complete or _session == null:
		return
	if _session.phase() != V06PlaySessionScript.PHASE_BOSS_ROLL_READY or not _session.faces().is_empty():
		return
	_boss_intro_active = true
	var intro_sequence_id := _boss_roll_sequence_id
	call_deferred("_finish_boss_intro", intro_sequence_id)


func _finish_boss_intro(intro_sequence_id: int) -> void:
	var intro_seconds := BOSS_INTRO_SECONDS if _session != null and _session.lap() <= 1 else BOSS_REPEAT_INTRO_SECONDS
	await get_tree().create_timer(intro_seconds).timeout
	if not is_inside_tree() or intro_sequence_id != _boss_roll_sequence_id:
		return
	if _session == null or _session.phase() != V06PlaySessionScript.PHASE_BOSS_ROLL_READY or not _session.faces().is_empty():
		_boss_intro_active = false
		_boss_intro_complete = true
		return
	_boss_intro_active = false
	_boss_intro_complete = true
	_refresh_ui()
	_present_session_phase()


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


func _on_boss_pause_pressed() -> void:
	if _boss_pause_open or not boss_overlay.visible or _session == null:
		return
	_boss_pause_open = true
	_session.pause_clock(Time.get_ticks_msec())
	boss_pause_overlay.show()
	boss_resume_button.grab_focus()
	_refresh_ui()


func _on_boss_resume_pressed() -> void:
	if not _boss_pause_open or _session == null:
		return
	_boss_pause_open = false
	boss_pause_overlay.hide()
	_session.resume_clock(Time.get_ticks_msec())
	boss_pause_button.grab_focus()
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
	if not is_inside_tree() or not is_instance_valid(lap_label) or _session == null:
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
	_reset_slot_preview_style()
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
				tray_status_label.text = "3 ROLL SLOT　　%d / 3" % _slot_fill_count(values)
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
			tray_status_label.text = "3 ROLL SLOT　　%d / 3" % values.size()
			tray_hint_label.text = "自分の出目 x / スフィンクス 7-x"
			message_label.text = "スフィンクスとの鏡面レース"
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
			tray_status_label.text = "3 ROLL SLOT　　%d / 3" % _slot_fill_count(values)
			tray_hint_label.text = "鏡面出目を確認して次へ"
		V06PlaySessionScript.PHASE_BOSS_FINISHED:
			tray_status_label.text = "3 ROLL SLOT　　%d / 3" % _slot_fill_count(values)
			tray_hint_label.text = "レース終了"
		V06PlaySessionScript.PHASE_LAP_RESULT:
			tray_status_label.text = "LAP CLEAR"
		V06PlaySessionScript.PHASE_RUN_OVER:
			tray_status_label.text = "RUN OVER"
	_refresh_boss_panel()
	var boss_active: bool = not _session.boss_snapshot().is_empty() and phase in [
		V06PlaySessionScript.PHASE_BOSS_ROLL_READY,
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT,
		V06PlaySessionScript.PHASE_BOSS_FINISHED,
		V06PlaySessionScript.PHASE_LAP_RESULT,
		V06PlaySessionScript.PHASE_RUN_OVER,
	]
	_set_boss_chrome_active(boss_active)
	skill_tool_button.text = "スキル\nピンポイント READY" if _session.skill_gauge() >= V06PlaySessionScript.SKILL_GAUGE_MAX else "スキル\nピンポイント %d/%d" % [_session.skill_gauge(), V06PlaySessionScript.SKILL_GAUGE_MAX]
	if _rolling:
		die_button.text = "STOP" if boss_active else "止める"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
		die_button.text = "ROLL"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		die_button.text = "ROLL"
	elif _shown_face > 0:
		die_button.text = "%dマス進む" % _shown_face
	else:
		die_button.text = "サイコロを振る"
	_refresh_die_layout(route_id)
	_refresh_die_presentation()
	var boss_result_phase := phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT
	var boss_finished := phase == V06PlaySessionScript.PHASE_BOSS_FINISHED
	die_button.visible = not boss_finished
	die_button.disabled = _boss_intro_active or _boss_roll_animation_active or boss_finished or _boss_pause_open or _utility_open or _movement_active or (not boss_result_phase and not _rolling and not _session.can_roll())
	boss_pause_button.disabled = boss_finished
	var utility_disabled := _utility_open or _map_open or _movement_active or _rolling or phase != V06PlaySessionScript.PHASE_READY
	item_tool_button.disabled = utility_disabled
	skill_tool_button.disabled = utility_disabled
	back_button.disabled = _movement_active


func _set_boss_chrome_active(active: bool) -> void:
	if not is_instance_valid(normal_hud_panel) or not is_instance_valid(normal_stage_band) or not is_instance_valid(normal_tool_dock):
		return
	normal_hud_panel.visible = not active
	normal_stage_band.visible = not active
	normal_tool_dock.visible = not active
	dice_presentation.visible = not active
	message_label.visible = not active
	boss_hud.visible = active
	var tray_panel := %TrayPanel as Control
	var roll_row := $SafeMargin/Page/TrayPanel/TrayContent/RollRow as Control
	var action_column := $SafeMargin/Page/TrayPanel/TrayContent/RollRow/ActionColumn as Control
	if active:
		_apply_boss_tray_styles()
		tray_panel.custom_minimum_size.y = 148.0
		roll_row.custom_minimum_size.y = 116.0
		action_column.custom_minimum_size.x = 420.0
		die_button.custom_minimum_size = Vector2(420.0, 104.0)
		tray_status_label.hide()
		tray_hint_label.hide()
		slot_column.hide()
		action_hint_label.hide()
	else:
		_apply_normal_tray_styles()
		tray_panel.custom_minimum_size.y = 252.0
		roll_row.custom_minimum_size.y = 178.0
		action_column.custom_minimum_size.x = 220.0
		die_button.custom_minimum_size = Vector2(220.0, 112.0)
		tray_status_label.show()
		slot_column.show()
		if _boss_pause_open:
			_boss_pause_open = false
			boss_pause_overlay.hide()


func _refresh_slot_guidance(values: Array[int], phase: StringName) -> void:
	if _inline_slot_result_active:
		return
	role_label.add_theme_color_override("font_color", Color(0.73, 0.59, 0.37, 1))
	if phase in [V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED, V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER]:
		role_label.text = ""
		role_label.hide()
		next_need_label.text = ""
		action_hint_label.text = ""
		return
	role_label.show()
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
	action_hint_label.text = "次の基本移動 -%d" % _session.next_basic_move_penalty() if _session.next_basic_move_penalty() > 0 else ""


func _slot_fill_count(values: Array[int]) -> int:
	var count := values.size()
	if _session != null and _session.phase() in [V06PlaySessionScript.PHASE_MOVING, V06PlaySessionScript.PHASE_CHOICE_REQUIRED] and _session.pending_face() > 0:
		count += 1
	return mini(count, slot_labels.size())


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
		slot_labels[next_slot].modulate = Color(1.0, 1.0, 1.0, 0.42)


func _refresh_rolling_slot_preview() -> void:
	if not _rolling or _session == null:
		return
	var next_slot: int = _session.faces().size()
	if next_slot < 0 or next_slot >= slot_labels.size():
		return
	_rolling_slot_face = 1 + (int(_rolling_slot_elapsed / ROLLING_SLOT_STEP_SECONDS) % 6)
	slot_labels[next_slot].text = str(_rolling_slot_face)
	slot_labels[next_slot].modulate = Color(1.0, 1.0, 1.0, 0.42)
	if _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		boss_dice_presentation.present([_rolling_slot_face], true, 0)
		_refresh_boss_landing_preview(_rolling_slot_face)


func _refresh_boss_landing_preview(face: int) -> void:
	if _session == null or not is_instance_valid(boss_player_target_label):
		return
	var preview: Dictionary = _session.boss_landing_preview(face)
	if preview.is_empty():
		return
	var player_tile := str(preview.get("player_tile", "NORMAL"))
	var sphinx_tile := str(preview.get("boss_tile", "NORMAL"))
	var player_roll := int(preview.get("player_roll", face))
	var sphinx_roll := int(preview.get("boss_roll", 7 - face))
	boss_player_target_label.text = "YOU %d → %s" % [player_roll, _boss_tile_short_name(player_tile)]
	boss_sphinx_target_label.text = "SPHINX %d → %s" % [sphinx_roll, _boss_tile_short_name(sphinx_tile)]
	boss_player_target_label.modulate = Color(1.35, 1.2, 0.78, 1.0) if player_tile != "NORMAL" else Color.WHITE
	boss_sphinx_target_label.modulate = Color(0.72, 1.35, 1.25, 1.0) if sphinx_tile != "NORMAL" else Color.WHITE
	player_roll_value.text = str(player_roll)
	boss_roll_value.text = str(sphinx_roll)
	boss_lane_board.set_preview(preview)
	_sync_boss_board_tokens()
	player_landing_ring.hide()
	boss_landing_ring.hide()
	boost_pictogram.hide()
	sand_pictogram.hide()


func _position_boss_landing_ring(ring: PanelContainer, value_label: Label, position: int, is_player: bool, text: String) -> void:
	var goal := int(_session.boss_snapshot().get("course_length", 20))
	var point := _boss_lane_point(position, is_player, goal)
	value_label.text = text
	ring.position = point - Vector2(ring.size.x * 0.5, ring.size.y * 0.5)
	ring.show()


func _set_target_pictogram(pictogram: TextureRect, tile: String, position: int, is_player: bool) -> void:
	pictogram.visible = tile in ["WING_GATE", "QUICKSAND"]
	if not pictogram.visible:
		return
	pictogram.scale = Vector2.ONE
	pictogram.texture = WING_GATE_PICTOGRAM if tile == "WING_GATE" else QUICKSAND_PICTOGRAM
	var value_label := pictogram.get_child(0) as Label
	value_label.text = "+3" if tile == "WING_GATE" else "−2"
	var goal := int(_session.boss_snapshot().get("course_length", 20))
	var point := _boss_lane_point(position, is_player, goal)
	pictogram.position = point + Vector2(-pictogram.size.x * 0.5, -pictogram.size.y - 24.0)


func _boss_lane_point(position: int, is_player: bool, goal: int) -> Vector2:
	if is_instance_valid(boss_lane_board):
		return boss_lane_board.lane_point(float(position), is_player)
	return Vector2.ZERO


func _boss_tile_short_name(tile: String) -> String:
	match tile:
		"WING_GATE": return "翼 +3"
		"QUICKSAND": return "流砂 −2"
		"GOAL": return "GOAL"
		_: return "通常"


func _reset_slot_preview_style() -> void:
	for label: Label in slot_labels:
		label.modulate = Color.WHITE


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
	if is_instance_valid(boss_dice_presentation) and _session != null and not _session.boss_snapshot().is_empty():
		var boss_face := _rolling_slot_face if _rolling else (_shown_face if _shown_face > 0 else 1)
		boss_dice_presentation.present([boss_face], _rolling, 0 if _rolling else 1)


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
	_apply_normal_tray_styles()
	var tool_dock_style := _panel_style(Color("#241813"), Color("#8d683b"), 18, 3)
	tool_dock_style.content_margin_top = 8
	tool_dock_style.content_margin_bottom = 8
	%ToolDock.add_theme_stylebox_override("panel", tool_dock_style)
	for modal_panel: PanelContainer in [%ChoicePanel, %ResolutionPanel, %UtilityPanel]:
		modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f1e2c2"), Color("#9b743d"), 22, 4))
	%BossPanel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	%BossHud.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.07, 0.08, 0.96), Color("#d6a84f"), 18, 3))
	%BossStartRulePanel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.018, 0.022, 0.94), Color("#d6a84f"), 18, 3))
	%BossQuickRulePanel.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.018, 0.022, 0.92), Color("#8e6c35"), 14, 2))
	%MirrorPanel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.12, 0.14, 0.95), Color("#8e6c35"), 14, 2))
	%PlayerRollBox.add_theme_stylebox_override("panel", _panel_style(Color("#132a31"), Color("#d6a84f"), 12, 2))
	%BossRollBox.add_theme_stylebox_override("panel", _panel_style(Color("#132a31"), Color("#3d8f89"), 12, 2))
	%PlayerFootMarker.add_theme_stylebox_override("panel", _panel_style(Color(0.84, 0.66, 0.31, 0.42), Color("#f0c76a"), 22, 3))
	%BossFootMarker.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.55, 0.53, 0.42), Color("#66d2c8"), 22, 3))
	%PlayerLandingRing.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.08, 0.09, 0.82), Color("#f0c76a"), 20, 4))
	%BossLandingRing.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.08, 0.09, 0.82), Color("#66d2c8"), 20, 4))
	%BossDiceShadow.add_theme_stylebox_override("panel", _panel_style(Color(0.0, 0.0, 0.0, 0.48), Color(0, 0, 0, 0), 18, 0))
	%PausePanel.add_theme_stylebox_override("panel", _panel_style(Color("#071b21"), Color("#d6a84f"), 24, 4))
	_apply_race_track_styles()
	die_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	for button: Button in [item_tool_button, skill_tool_button, back_button, utility_close_button, choice_main_button, choice_bypass_button, resolution_ack_button, boss_round_ack_button, next_lap_button, retry_button, boss_pause_button, boss_resume_button, boss_back_button]:
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
	boss_pause_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	boss_resume_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	boss_back_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON


func _apply_normal_tray_styles() -> void:
	%TrayPanel.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#b88a46"), 24, 5))
	for slot_panel: PanelContainer in slot_panels:
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color("#efe0bf"), Color("#9c7742"), 14, 3))
	for slot_label: Label in slot_labels:
		slot_label.add_theme_color_override("font_color", Color("#173b3b"))
	tray_status_label.add_theme_color_override("font_color", Color("#277c80"))
	tray_hint_label.add_theme_color_override("font_color", Color("#604b36"))
	role_label.add_theme_color_override("font_color", Color("#604b36"))
	role_reward_label.add_theme_color_override("font_color", Color("#604b36"))
	next_need_label.add_theme_color_override("font_color", Color("#604b36"))
	action_hint_label.add_theme_color_override("font_color", Color("#604b36"))


func _apply_boss_tray_styles() -> void:
	%TrayPanel.add_theme_stylebox_override("panel", _panel_style(Color("#071b21"), Color("#d6a84f"), 24, 5))
	for slot_panel: PanelContainer in slot_panels:
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color("#102b31"), Color("#3d8f89"), 14, 3))
	for slot_label: Label in slot_labels:
		slot_label.add_theme_color_override("font_color", Color("#f3dfad"))
	tray_status_label.add_theme_color_override("font_color", Color("#e8ba5c"))
	tray_hint_label.add_theme_color_override("font_color", Color("#c6d8ce"))
	role_label.add_theme_color_override("font_color", Color("#dfc27d"))
	role_reward_label.add_theme_color_override("font_color", Color("#c6d8ce"))
	next_need_label.add_theme_color_override("font_color", Color("#c6d8ce"))
	action_hint_label.add_theme_color_override("font_color", Color("#c6d8ce"))


func _apply_race_track_styles() -> void:
	var track_bg := StyleBoxFlat.new()
	track_bg.bg_color = Color(0.02, 0.04, 0.05, 0.82)
	track_bg.border_color = Color("#80663c")
	track_bg.set_border_width_all(2)
	track_bg.set_corner_radius_all(12)
	var player_fill := StyleBoxFlat.new()
	player_fill.bg_color = Color("#d6a84f")
	player_fill.set_corner_radius_all(10)
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color("#3d8f89")
	boss_fill.set_corner_radius_all(10)
	player_track.add_theme_stylebox_override("background", track_bg)
	player_track.add_theme_stylebox_override("fill", player_fill)
	boss_track.add_theme_stylebox_override("background", track_bg.duplicate())
	boss_track.add_theme_stylebox_override("fill", boss_fill)


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
	if not is_inside_tree() or not is_instance_valid(boss_overlay) or _session == null:
		return
	var boss: Dictionary = _session.boss_snapshot()
	var phase: StringName = _session.phase()
	if boss.is_empty():
		return
	var player_position := int(boss.get("player_position", 0))
	var boss_position := int(boss.get("boss_position", 0))
	var goal := int(boss.get("course_length", 20))
	player_track.max_value = goal
	boss_track.max_value = goal
	player_track.value = player_position
	boss_track.value = boss_position
	boss_you_progress_label.text = "%d / %d" % [player_position, goal]
	boss_sphinx_progress_label.text = "%d / %d" % [boss_position, goal]
	boss_hp_label.text = "PLAYER %d/%d    SPHINX %d/%d" % [player_position, goal, boss_position, goal]
	boss_action_label.text = "反対面ルール\n1↔6 / 2↔5 / 3↔4"
	var boss_finished := phase == V06PlaySessionScript.PHASE_BOSS_FINISHED
	var finish_presented := boss_finished and not _boss_roll_animation_active
	var terminal_result := phase in [V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER]
	var player_history: Array = boss.get("player_roll_history", [])
	var boss_history: Array = boss.get("boss_roll_history", [])
	var intro_visible := not terminal_result and player_history.is_empty() and phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and not _rolling and not _boss_intro_complete
	var detailed_intro: bool = intro_visible and int(_session.lap()) <= 1
	if intro_visible:
		_begin_boss_intro_if_needed()
	boss_hp_label.hide()
	boss_race_track_label.hide()
	boss_pause_button.text = "PAUSE"
	race_stage.visible = not terminal_result
	boss_start_rule_panel.visible = detailed_intro
	boss_quick_rule_panel.visible = intro_visible and not detailed_intro
	boss_action_label.visible = detailed_intro
	mirror_panel.visible = _boss_mirror_values_visible and not intro_visible and not terminal_result and not finish_presented
	boss_pause_button.visible = not finish_presented
	boss_dice_presentation.visible = not finish_presented
	var target_preview_visible := phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and not intro_visible
	boss_player_target_label.visible = target_preview_visible
	boss_sphinx_target_label.visible = target_preview_visible
	player_landing_ring.hide()
	boss_landing_ring.hide()
	%MirrorPairsLabel.hide()
	if not target_preview_visible and not _boss_roll_animation_active:
		boost_pictogram.hide()
		sand_pictogram.hide()
		boss_lane_board.clear_preview()
	boss_round_ack_button.hide()
	next_lap_button.visible = (phase == V06PlaySessionScript.PHASE_BOSS_FINISHED and not _boss_roll_animation_active) or phase == V06PlaySessionScript.PHASE_LAP_RESULT
	retry_button.visible = phase == V06PlaySessionScript.PHASE_RUN_OVER
	boss_back_button.visible = true
	var live_face := _rolling_slot_face if _rolling else (_shown_face if _shown_face > 0 else 1)
	player_roll_value.text = str(live_face) if player_history.is_empty() else str(player_history.back())
	boss_roll_value.text = str(7 - live_face) if boss_history.is_empty() else str(boss_history.back())
	var animate_tokens := player_position != _boss_last_player_position or boss_position != _boss_last_position
	if not _boss_roll_animation_active:
		if finish_presented:
			call_deferred("_position_boss_finish_winner", bool(_session.boss_result().get("victory", false)))
		else:
			call_deferred("_position_boss_tokens", player_position, boss_position, goal, animate_tokens)
			call_deferred("_position_boss_forward_markers", player_position, goal)
	if target_preview_visible and not _boss_roll_animation_active:
		_refresh_boss_landing_preview(_rolling_slot_face if _rolling else (_shown_face if _shown_face > 0 else 1))
	if not boss_finished:
		boss_finish_dim.hide()
		boss_finish_summary_label.hide()
		%TrayPanel.modulate = Color.WHITE
		%GoalLabel.text = "GOLDEN GATE"
		%GoalLabel.hide()
		%GoalLabel.scale = Vector2.ONE
		%GoalLabel.modulate = Color.WHITE
	if phase in [V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED]:
		var result: Dictionary = _session.boss_result()
		player_roll_value.text = str(int(result.get("player_roll", 0)))
		boss_roll_value.text = str(int(result.get("boss_roll", 0)))
		boss_result_label.hide()
		boss_result_label.text = ""
		var revealed_turn := int(result.get("turn", -1))
		if phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT and not _boss_roll_animation_active and revealed_turn != _boss_last_revealed_turn:
			_boss_last_revealed_turn = revealed_turn
			call_deferred("_animate_mirror_reveal")
		if phase == V06PlaySessionScript.PHASE_BOSS_FINISHED and not _boss_roll_animation_active:
			var finished_victory := bool(result.get("victory", false))
			boss_result_label.text = "YOU WIN" if finished_victory else "SPHINX WIN"
			boss_result_label.add_theme_font_size_override("font_size", 46)
			boss_result_label.show()
			boss_finish_dim.show()
			boss_finish_summary_label.text = _boss_finish_summary(result)
			boss_finish_summary_label.show()
			%TrayPanel.modulate = Color(0.42, 0.42, 0.42, 1.0)
	elif phase == V06PlaySessionScript.PHASE_LAP_RESULT:
		boss_result_label.show()
		boss_result_label.add_theme_font_size_override("font_size", 20)
		var victory := bool(boss.get("victory", false))
		boss_title.text = "スフィンクスに勝利！" if victory else "スフィンクスに惜敗"
		boss_result_label.text = _score_result_text(victory)
	elif phase == V06PlaySessionScript.PHASE_RUN_OVER:
		boss_result_label.show()
		boss_result_label.add_theme_font_size_override("font_size", 20)
		boss_title.text = "旅の記録"
		boss_result_label.text = _score_result_text(false)
	else:
		boss_result_label.hide()
		boss_title.text = "鏡面レース  ·  スフィンクス"
		boss_result_label.text = ""
	_boss_last_player_position = player_position
	_boss_last_position = boss_position


func _position_boss_forward_markers(player_position: int, goal: int) -> void:
	if not is_instance_valid(race_stage) or race_stage.size.x <= 0.0:
		return
	for label: Label in boss_forward_step_labels:
		label.hide()


func _position_boss_tokens(player_position: int, sphinx_position: int, goal: int, animated: bool, duration: float = 0.42) -> void:
	if not is_instance_valid(race_stage) or race_stage.size.x <= 0.0:
		return
	if animated and _boss_last_player_position >= 0:
		var start_player := _boss_visual_player_position
		var start_sphinx := _boss_visual_sphinx_position
		var tween := create_tween()
		tween.tween_method(
			_apply_boss_visual_lerp.bind(start_player, start_sphinx, float(player_position), float(sphinx_position)),
			0.0,
			1.0,
			duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_boss_visual_player_position = float(player_position)
		_boss_visual_sphinx_position = float(sphinx_position)
		_sync_boss_board_tokens()


func _position_boss_finish_winner(player_won: bool) -> void:
	var winner_token: Control = player_token if player_won else boss_token
	var loser_token: Control = boss_token if player_won else player_token
	var winner_foot: Control = player_foot_marker if player_won else boss_foot_marker
	var loser_foot: Control = boss_foot_marker if player_won else player_foot_marker
	loser_token.hide()
	loser_foot.hide()
	winner_foot.hide()
	winner_token.show()
	winner_token.z_index = 22
	winner_token.position = Vector2(race_stage.size.x * 0.5 - winner_token.size.x * 0.5, 110.0)


func _apply_boss_visual_lerp(weight: float, start_player: float, start_sphinx: float, end_player: float, end_sphinx: float) -> void:
	_boss_visual_player_position = lerpf(start_player, end_player, weight)
	_boss_visual_sphinx_position = lerpf(start_sphinx, end_sphinx, weight)
	_sync_boss_board_tokens()


func _sync_boss_board_tokens() -> void:
	if not is_instance_valid(boss_lane_board) or not is_instance_valid(player_token):
		return
	if _boss_goal_presentation_active:
		return
	boss_lane_board.set_racers(_boss_visual_player_position, _boss_visual_sphinx_position)
	var player_center: Vector2 = boss_lane_board.lane_point(_boss_visual_player_position, true)
	var sphinx_center: Vector2 = boss_lane_board.lane_point(_boss_visual_sphinx_position, false)
	# The explorer is the camera anchor and must never disappear. During a
	# long hop, keep the actual token pinned to its lane edge until the
	# post-movement two-space camera segments catch up.
	player_center.y = clampf(
		player_center.y,
		maxf(player_token.size.y - 20.0, 92.0),
		boss_lane_board.size.y - 20.0
	)
	player_token.scale = Vector2.ONE
	boss_token.scale = Vector2.ONE
	player_foot_marker.scale = Vector2.ONE
	boss_foot_marker.scale = Vector2.ONE
	var sphinx_on_screen := sphinx_center.y >= 0.0 and sphinx_center.y <= boss_lane_board.size.y
	player_token.show()
	player_foot_marker.show()
	boss_token.visible = sphinx_on_screen
	boss_foot_marker.visible = sphinx_on_screen
	player_token.position = player_center - Vector2(player_token.size.x * 0.5, player_token.size.y - 20.0)
	boss_token.position = sphinx_center - Vector2(boss_token.size.x * 0.5, boss_token.size.y - 20.0)
	player_foot_marker.position = player_center - Vector2(player_foot_marker.size.x * 0.5, player_foot_marker.size.y * 0.5)
	boss_foot_marker.position = sphinx_center - Vector2(boss_foot_marker.size.x * 0.5, boss_foot_marker.size.y * 0.5)


func _settle_boss_camera_after_movement(player_position: int, sequence_id: int) -> bool:
	# Keep the board fully still after the last hop/effect, then make one
	# restrained fixed-distance translation. The second hold prevents the
	# next ROLL affordance from appearing on the final moving frame.
	if not await _boss_roll_wait(BOSS_CAMERA_HOLD_SECONDS, sequence_id):
		return false
	var segment_count := 0
	while segment_count < 10:
		var start := float(boss_lane_board.get("camera_position"))
		var target := float(boss_lane_board.next_camera_scroll_target(float(player_position)))
		if is_equal_approx(start, target):
			break
		if _boss_camera_tween != null:
			_boss_camera_tween.kill()
		_boss_camera_tween = null
		_boss_camera_tween = create_tween()
		_boss_camera_tween.tween_method(_apply_boss_camera_position.bind(sequence_id), start, target, BOSS_CAMERA_SCROLL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		if not await _boss_roll_wait(BOSS_CAMERA_SCROLL_SECONDS, sequence_id):
			if _boss_camera_tween != null:
				_boss_camera_tween.kill()
			return false
		boss_lane_board.set_camera_position(target)
		_sync_boss_board_tokens()
		_boss_camera_tween = null
		segment_count += 1
	return await _boss_roll_wait(BOSS_CAMERA_HOLD_SECONDS, sequence_id)


func _apply_boss_camera_position(value: float, sequence_id: int) -> void:
	if sequence_id != _boss_roll_sequence_id or _boss_goal_presentation_active:
		return
	boss_lane_board.set_camera_position(value)
	_sync_boss_board_tokens()


func _boss_phase_for_progress(progress: float) -> int:
	if progress >= 17.0:
		return 3
	if progress >= 12.0:
		return 2
	if progress >= 6.0:
		return 1
	return 0


func _backdrop_phase_spec(phase: int) -> Dictionary:
	match clampi(phase, 0, 3):
		1: return {"scale": Vector2(1.06, 1.06), "y": 30.0, "tint": Color(0.59, 0.65, 0.70, 1.0)}
		2: return {"scale": Vector2(1.12, 1.12), "y": 64.0, "tint": Color(0.64, 0.68, 0.72, 1.0)}
		3: return {"scale": Vector2(1.18, 1.18), "y": 96.0, "tint": Color(0.70, 0.72, 0.74, 1.0)}
		_: return {"scale": Vector2.ONE, "y": 0.0, "tint": Color(0.55, 0.62, 0.68, 1.0)}


func _configure_backdrop_phase(backdrop: TextureRect, phase: int, alpha: float) -> void:
	var spec := _backdrop_phase_spec(phase)
	var tint: Color = spec.get("tint", Color.WHITE)
	backdrop.pivot_offset = backdrop.size * 0.5
	backdrop.scale = spec.get("scale", Vector2.ONE)
	backdrop.position.y = float(spec.get("y", 0.0))
	backdrop.modulate = Color(tint.r, tint.g, tint.b, alpha)


func _set_boss_background_phase_immediate(phase: int) -> void:
	_boss_background_phase = clampi(phase, 0, 3)
	_boss_backdrop_active = 0
	_configure_backdrop_phase(boss_arena_backdrop, _boss_background_phase, 1.0)
	_configure_backdrop_phase(boss_arena_backdrop_next, _boss_background_phase, 0.0)


func _crossfade_boss_background(progress: int, sequence_id: int) -> bool:
	var next_phase := _boss_phase_for_progress(float(progress))
	if next_phase == _boss_background_phase:
		return true
	var current: TextureRect = boss_arena_backdrop if _boss_backdrop_active == 0 else boss_arena_backdrop_next
	var incoming: TextureRect = boss_arena_backdrop_next if _boss_backdrop_active == 0 else boss_arena_backdrop
	_configure_backdrop_phase(incoming, next_phase, 0.0)
	var fade := create_tween().set_parallel(true)
	fade.tween_property(current, "modulate:a", 0.0, BOSS_BACKDROP_FADE_SECONDS)
	fade.tween_property(incoming, "modulate:a", 1.0, BOSS_BACKDROP_FADE_SECONDS)
	if not await _boss_roll_wait(BOSS_BACKDROP_FADE_SECONDS, sequence_id):
		fade.kill()
		return false
	_boss_backdrop_active = 1 - _boss_backdrop_active
	_boss_background_phase = next_phase
	return true


func _animate_mirror_reveal() -> void:
	if _boss_mirror_reveal_tween != null:
		_boss_mirror_reveal_tween.kill()
	for label: Label in [player_roll_value, boss_roll_value]:
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * 0.72
		label.modulate.a = 0.4
	var reveal := create_tween().set_parallel(true)
	_boss_mirror_reveal_tween = reveal
	reveal.tween_property(player_roll_value, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(player_roll_value, "modulate:a", 1.0, 0.14)
	reveal.tween_property(boss_roll_value, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	reveal.tween_property(boss_roll_value, "modulate:a", 1.0, 0.14).set_delay(0.1)


func _boss_effect_text(player_effect: String, sphinx_effect: String) -> String:
	var parts: Array[String] = []
	if not player_effect.is_empty():
		parts.append("YOU %s" % _localized_boss_effect(player_effect))
	if not sphinx_effect.is_empty():
		parts.append("SPHINX %s" % _localized_boss_effect(sphinx_effect))
	return " / ".join(parts) if not parts.is_empty() else "停止効果なし"


func _boss_finish_summary(result: Dictionary) -> String:
	var turn_count := int(result.get("turn_count", 0))
	var player_wings := int(result.get("player_wing_count", 0))
	var player_sands := int(result.get("player_sand_count", 0))
	var boss_wings := int(result.get("boss_wing_count", 0))
	var boss_sands := int(result.get("boss_sand_count", 0))
	var non_six_count := 0
	for face: int in result.get("player_roll_history", []):
		if face != 6:
			non_six_count += 1
	var pre_final_gap := absi(int(result.get("player_position_before", 0)) - int(result.get("boss_position_before", 0)))
	return "%d投・非6選択 %d回・最終投前差 %d\nYOU　翼 %d回・流砂 %d回\nSPHINX　翼 %d回・流砂 %d回" % [
		turn_count,
		non_six_count,
		pre_final_gap,
		player_wings,
		player_sands,
		boss_wings,
		boss_sands,
	]


func _localized_boss_effect(effect: String) -> String:
	match effect:
		"WING_GATE": return "翼の門 +3"
		"QUICKSAND": return "流砂 −2"
		_: return effect.replace("_", " ")


func _score_result_text(victory: bool) -> String:
	var score: int = int(_session.score())
	var best: int = int(_session.best_score())
	var breakdown: Dictionary = _session.score_breakdown()
	var lead := "スフィンクスに勝利！" if victory else "スフィンクスには惜敗。"
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
