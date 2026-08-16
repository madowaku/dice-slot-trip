class_name V06PlayScreen
extends Control

signal back_requested
signal resume_failed
signal postcard_unlocked(postcard_id: String)

const V06PlaySessionScript = preload("res://scripts/game/v06_play_session.gd")
const V06SessionSaveManagerScript = preload("res://scripts/game/v06_session_save_manager.gd")
const V06CourseModelScript = preload("res://scripts/game/v06_course_model.gd")
const UiTokensScript = preload("res://scripts/ui/ui_tokens.gd")
const UiThemeNamesScript = preload("res://scripts/ui/ui_theme_names.gd")
const V06LocalizationScript = preload("res://scripts/ui/v06_localization.gd")
const V06FeedbackControllerScript = preload("res://scripts/ui/v06_feedback_controller.gd")
const V11BossLaneBoardScript = preload("res://scripts/ui/v11_boss_lane_board.gd")
const V06TravelCardCatalogScript = preload("res://scripts/ui/v06_travel_card_catalog.gd")
const DicePresentation3DScript = preload("res://scripts/game/dice_presentation_3d.gd")
const ITEM_CARD: Texture2D = preload("res://assets/art/v08/cards/item-card.png")
const SKILL_PINPOINT_ART: Texture2D = preload("res://assets/art/ui/common/skill-pinpoint-v1.png")
const SKILL_BOOK_ART: Texture2D = preload("res://assets/art/ui/common/skill-book-v1.png")
const MENU_GEAR_ART: Texture2D = preload("res://assets/art/ui/common/menu-gear-v1.png")
const WING_GATE_PICTOGRAM: Texture2D = preload("res://assets/art/v10/boss/wing-gate.png")
const QUICKSAND_PICTOGRAM: Texture2D = preload("res://assets/art/v10/boss/quicksand.png")
const DICE_UI_ART: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const SLOT_TRAY_ART: Texture2D = preload("res://assets/art/ui/common/slot-tray-luxury-v1.png")
const ROLL_BUTTON_ORNAMENTS: Texture2D = preload("res://assets/art/ui/common/roll-button-ornaments.png")
const ROLL_BUTTON_ROUND_ART: Texture2D = preload("res://assets/art/ui/common/roll-button-round-v1.png")
const SLOT_SNAP_SPARKLE: Texture2D = preload("res://assets/art/ui/common/slot-snap-sparkle.png")
const EVENT_ARTS := [
	preload("res://assets/art/events/cairo/cairo-event-ferry-offer.png"),
	preload("res://assets/art/events/cairo/cairo-event-market-hawker.png"),
	preload("res://assets/art/events/cairo/cairo-event-nile-tailwind.png"),
	preload("res://assets/art/events/cairo/cairo-event-ruin-whisper.png"),
]
const DISCOVERY_ARTS := [
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-coin.png"),
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-event.png"),
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-item.png"),
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-rest.png"),
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-risk.png"),
	preload("res://assets/art/cards/cairo/discovery/cairo-discovery-warp.png"),
]
const ITEM_ARTS := [
	preload("res://assets/art/items/cairo/cairo-item-brass-compass.png"),
	preload("res://assets/art/items/cairo/cairo-item-hourglass-shard.png"),
	preload("res://assets/art/items/cairo/cairo-item-linen-bandage.png"),
	preload("res://assets/art/items/cairo/cairo-item-sand-goggles.png"),
	preload("res://assets/art/items/cairo/cairo-item-scarab-seal.png"),
	preload("res://assets/art/items/cairo/cairo-item-water-canteen.png"),
]
const BOSS_START_ART: Texture2D = preload("res://assets/art/bosses/cairo/cairo-boss-start.png")
const BOSS_VICTORY_ART: Texture2D = preload("res://assets/art/bosses/cairo/cairo-boss-victory.png")
const BOSS_NEAR_MISS_ART: Texture2D = preload("res://assets/art/bosses/cairo/cairo-boss-near-miss.png")
const POSTCARD_ART: Texture2D = preload("res://assets/art/postcards/cairo/cairo-journey-postcard.png")

const QA_SCENARIO_ATLAS_18 := "atlas_18"
const QA_SCENARIO_BOSS_READY := "boss_ready"
const QA_SCENARIO_BOSS_ROUND := "boss_round"
const SLOT_BREATH_PERIOD_SECONDS := 2.0
const SLOT_BREATH_ALPHA_AMPLITUDE := 0.025
const TARGET_PREVIEW_SECONDS := 0.20
const ROUTE_CHOICE_REVIEW_SECONDS := 0.85
const SLOT_STOP_DELAY_SECONDS := 0.12
const BOSS_DICE_SETTLE_SECONDS := 0.14
const BOSS_YOU_REVEAL_SECONDS := 0.14
const BOSS_SPHINX_REVEAL_SECONDS := 0.26
const BOSS_SLOT_TRANSFER_SECONDS := 0.12
const BOSS_CHARGE_SECONDS := 0.08
const BOSS_EFFECT_SECONDS := 0.18
const BOSS_STEP_SECONDS := 0.20
const BOSS_GOAL_GATE_SECONDS := 0.34
const BOSS_INTRO_SECONDS := 5.2
const BOSS_REPEAT_INTRO_SECONDS := 1.4
const BOSS_DICE_EXPLAIN_SCALE := Vector2(1.22, 1.22)
const BOSS_DICE_REST_Y := 900.0
const BOSS_DICE_STOP_Y := 878.0
const BOSS_DICE_SHADOW_OFFSET_Y := 128.0
const BOSS_BASE_VIEWPORT_HEIGHT := 1280.0
const BOSS_CAMERA_SCROLL_SECONDS := 0.62
const BOSS_CAMERA_HOLD_SECONDS := 0.12
const BOSS_BACKDROP_FADE_SECONDS := 0.28
const NORMAL_DICE_ROLL_SPEED_SCALE := 0.92
const BOSS_DICE_ROLL_SPEED_SCALE := 1.16
const BOSS_DICE_LAP_SPEED_STEP := 0.035
const BOSS_DICE_MAX_SPEED_SCALE := 1.30
const HEART_ROULETTE_FAST_STEP_SECONDS := 0.105
const HEART_ROULETTE_SLOW_STEP_SECONDS := 0.215
const HEART_ROULETTE_SLOW_MARGIN_SPACES := 10.0
const HEART_ROULETTE_VISUAL_SLOT_ORDER: Array[int] = [0, 1, 2, 3, 4, 5]
const INLINE_SLOT_RESULT_SECONDS := 0.46
const DICE_ANCHOR_NORMAL := Vector2(0.45, 0.82)
const DICE_ANCHOR_LOOP := Vector2(0.88, 0.82)
const ROLL_BUTTON_ATLAS_CELL := Vector2(941.0, 418.0)
const SLOT_RESULT_GLOW := Color(1.45, 1.42, 1.30, 1.0)
const SLOT_RESULT_STRONG_GLOW := Color(1.75, 1.68, 1.42, 1.0)

@onready var lap_label: Label = %LapLabel
@onready var roll_count_label: Label = %RollCountLabel
@onready var hp_label: Label = %HPLabel
@onready var life_label: Label = %LifeLabel
@onready var pb_label: Label = %PBLabel
@onready var time_label: Label = %TimeLabel
@onready var score_label: Label = %ScoreLabel
@onready var score_delta_label: Label = %ScoreDeltaLabel
@onready var best_label: Label = %BestLabel
@onready var coin_label: Label = %CoinLabel
@onready var coin_tool_button: Button = %CoinToolButton
@onready var progress_label: Label = %ProgressLabel
@onready var stage_label: Label = %StageLabel
@onready var route_label: Label = %RouteLabel
@onready var tile_kind_label: Label = %TileKindLabel
@onready var atlas_view: V06AtlasView = %AtlasView
@onready var message_label: Label = %MessageLabel
@onready var message_band: PanelContainer = %MessageBand
@onready var tray_status_label: Label = %TrayStatusLabel
@onready var role_label: Label = %RoleLabel
@onready var role_reward_label: Label = %RoleRewardLabel
@onready var next_need_label: Label = %NextNeedLabel
@onready var action_hint_label: Label = %ActionHintLabel
@onready var slot_column: Control = %SlotColumn
@onready var slot_layout: Control = $SafeMargin/Page/TrayPanel/TrayContent/RollRow/SlotColumn/SlotLayout
@onready var slot_row: Control = $SafeMargin/Page/TrayPanel/TrayContent/RollRow/SlotColumn/SlotLayout/SlotsRow
@onready var slot_tray_art: TextureRect = %SlotTrayArt
@onready var slot_snap_sparkle: TextureRect = %SlotSnapSparkle
@onready var slot_panels: Array[PanelContainer] = [%SlotPanel0, %SlotPanel1, %SlotPanel2]
@onready var slot_labels: Array[Label] = [%Slot0, %Slot1, %Slot2]
@onready var pair_link: Line2D = %PairLink
@onready var dice_presentation: DicePresentation3D = %DicePresentation
@onready var die_hero_art: TextureRect = %DieHeroArt
@onready var boss_dice_presentation: DicePresentation3D = %BossDicePresentation
@onready var die_button: Button = %DieButton
@onready var roll_button_ornament: TextureRect = %RollButtonOrnament
@onready var roll_button_die_icon: TextureRect = %RollButtonDieIcon
@onready var roll_button_copy: Label = %RollButtonCopy
@onready var tray_hint_label: Label = %TrayHintLabel
@onready var back_button: Button = %BackButton
@onready var item_tool_button: Button = %ItemToolButton
@onready var skill_tool_button: Button = %SkillToolButton
@onready var utility_overlay: Control = %UtilityOverlay
@onready var utility_panel: PanelContainer = %UtilityPanel
@onready var utility_title: Label = %UtilityTitle
@onready var utility_card_art: TextureRect = %UtilityCardArt
@onready var utility_detail: Label = %UtilityDetail
@onready var utility_nav_row: HBoxContainer = %UtilityNavRow
@onready var utility_previous_button: Button = %UtilityPreviousButton
@onready var utility_page_label: Label = %UtilityPageLabel
@onready var utility_next_button: Button = %UtilityNextButton
@onready var utility_action_button: Button = %UtilityActionButton
@onready var pinpoint_face_row: GridContainer = %PinpointFaceRow
@onready var pinpoint_face_buttons: Array[Button] = [%PinpointFace1, %PinpointFace2, %PinpointFace3, %PinpointFace4, %PinpointFace5, %PinpointFace6]
@onready var utility_close_button: Button = %UtilityCloseButton
@onready var travel_menu_overlay: Control = %TravelMenuOverlay
@onready var travel_menu_panel: PanelContainer = %TravelMenuPanel
@onready var travel_menu_title: Label = %TravelMenuTitle
@onready var travel_menu_detail: Label = %TravelMenuDetail
@onready var travel_bgm_label: Label = %TravelBgmLabel
@onready var travel_bgm_slider: HSlider = %TravelBgmSlider
@onready var travel_se_label: Label = %TravelSeLabel
@onready var travel_se_slider: HSlider = %TravelSeSlider
@onready var travel_menu_encyclopedia_button: Button = %TravelMenuEncyclopediaButton
@onready var travel_menu_continue_button: Button = %TravelMenuContinueButton
@onready var travel_menu_exit_button: Button = %TravelMenuExitButton
@onready var travel_encyclopedia_overlay: Control = %TravelEncyclopediaOverlay
@onready var map_button: Button = %MapButton
@onready var map_overlay: Control = %MapOverlay
@onready var overview_atlas_view: V06AtlasView = %OverviewAtlasView
@onready var overview_title: Label = %OverviewTitle
@onready var map_close_button: Button = %MapCloseButton
@onready var choice_overlay: Control = %ChoiceOverlay
@onready var choice_main_button: Button = %ChoiceMainButton
@onready var choice_bypass_button: Button = %ChoiceBypassButton
@onready var branch_choice_atlas_view: V06AtlasView = %BranchChoiceAtlasView
@onready var choice_roll_label: Label = %ChoiceRollLabel
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
@onready var boss_coin_button: Button = %BossCoinButton
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
@onready var boss_start_rule_dismiss_layer: Control = %BossStartRuleDismissLayer
@onready var boss_start_button: Button = %BossStartButton
@onready var boss_quick_rule_panel: PanelContainer = %BossQuickRulePanel
@onready var mirror_panel: PanelContainer = %MirrorPanel
@onready var boss_arena_backdrop: TextureRect = %BossArenaBackdrop
@onready var boss_arena_backdrop_next: TextureRect = %BossArenaBackdropNext
@onready var race_stage: Control = %RaceStage
@onready var boss_lane_board: Control = %BossLaneBoard
@onready var golden_gate_sprite: TextureRect = %GoldenGateSprite
@onready var boss_dice_shadow: PanelContainer = %BossDiceShadow
@onready var boss_dice_owner_label: Label = %BossDiceOwnerLabel
@onready var boss_finish_dim: ColorRect = %BossFinishDim
@onready var boss_finish_kicker_label: Label = %BossFinishKickerLabel
@onready var boss_finish_score_label: Label = %BossFinishScoreLabel
@onready var boss_finish_mission_label: Label = %BossFinishMissionLabel
@onready var boss_finish_summary_label: Label = %BossFinishSummaryLabel
@onready var heart_roulette_panel: V06HeartRouletteView = %HeartRoulettePanel
@onready var heart_roulette_label: Label = %HeartRouletteLabel
@onready var player_track: ProgressBar = %PlayerTrack
@onready var boss_track: ProgressBar = %BossTrack
@onready var player_token: TextureRect = %PlayerToken
@onready var boss_token: TextureRect = %BossToken
@onready var player_start_label: Label = %PlayerStartLabel
@onready var boss_start_label: Label = %BossStartLabel
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
@onready var landing_art_overlay: Control = %LandingArtOverlay
@onready var landing_art_panel: PanelContainer = %LandingArtPanel
@onready var landing_art_title: Label = %LandingArtTitle
@onready var landing_art: TextureRect = %LandingArt
@onready var landing_discovery_thumb: TextureRect = %LandingDiscoveryThumb
@onready var landing_art_caption: Label = %LandingArtCaption
@onready var landing_art_prompt: Button = %LandingArtPrompt
@onready var landing_paid_action_button: Button = %LandingPaidActionButton
@onready var low_hp_overlay: Control = %LowHpOverlay
@onready var low_hp_panel: PanelContainer = %LowHpPanel
@onready var low_hp_close_button: Button = %LowHpCloseButton
@onready var boss_sequence_art: TextureRect = %BossSequenceArt
@onready var postcard_art: TextureRect = %PostcardArt
@onready var boost_pictogram: TextureRect = %BoostPictogram
@onready var sand_pictogram: TextureRect = %SandPictogram
@onready var boss_pause_overlay: Control = %BossPauseOverlay
@onready var boss_resume_button: Button = %BossResumeButton
@onready var normal_hud_panel: PanelContainer = %HudPanel
@onready var normal_stage_band: PanelContainer = %StageBand
@onready var normal_tool_dock: PanelContainer = %ToolDock
@onready var mission_band: PanelContainer = %MissionBand
@onready var mission_header: Label = %MissionHeader
@onready var mission_no_damage_label: Label = %MissionNoDamageLabel
@onready var mission_coin_label: Label = %MissionCoinLabel
@onready var mission_role_label: Label = %MissionRoleLabel
@onready var mission_no_damage_caption: Label = $SafeMargin/Page/MissionBand/MissionStrip/MissionNoDamageCell/Content/Copy/Caption
@onready var mission_shield_icon: TextureRect = %MissionShieldIcon
@onready var mission_coin_icon: TextureRect = %MissionCoinIcon
@onready var mission_role_icon: TextureRect = %MissionRoleIcon
@onready var mission_no_damage_cell: PanelContainer = %MissionNoDamageCell
@onready var mission_coin_cell: PanelContainer = %MissionCoinCell
@onready var mission_role_cell: PanelContainer = %MissionRoleCell
@onready var mission_toast: PanelContainer = %MissionToast
@onready var mission_toast_label: Label = %MissionToastLabel

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
var _map_clock_pause_owned := false
var _utility_open := false
var _utility_mode := ""
var _utility_entries: Array[Dictionary] = []
var _utility_index := 0
var _travel_menu_open := false
var _travel_encyclopedia_open := false
var _motion_generation := 0
var _score_display_value := 0.0
var _score_target := 0
var _score_tween: Tween
var _score_delta_tween: Tween
var _inline_slot_result_active := false
var _distance_announcement_active := false
var _roll_button_ornament_atlas: AtlasTexture
var _roll_button_pressed := false
var _landing_art_tween: Tween
var _tile_help_open := false
var _tile_help_clock_paused := false
var _tile_help_pending_kind := ""
var _three_roll_onboarding_open := false
var _three_roll_onboarding_clock_paused := false
var _onboarding_kind := ""
var _skill_ready_discovery_open := false
var _skill_ready_button_pulse_tween: Tween
var _event_card_open := false
var _event_card_clock_paused := false
var _low_hp_warning_open := false
var _low_hp_warning_clock_paused := false
var _start_stage_id: StringName = V06PlaySessionScript.DEFAULT_STAGE_ID
var _start_character_id: StringName = V06PlaySessionScript.DEFAULT_CHARACTER_ID
var _save_manager: RefCounted
var _save_enabled := false
var _resume_data: Dictionary = {}
var _compact_phone_layout_active := false
var _phone_layout_profile_initialized := false
var _runtime_layout_queued := false
var _boss_last_player_position := -1
var _boss_last_position := -1
var _boss_last_revealed_turn := -1
var _boss_reach_signature := ""
var _slot_reach_message_active := false
var _boss_pause_open := false
var _boss_roll_animation_active := false
var _boss_roll_sequence_id := 0
var _boss_intro_active := false
var _boss_intro_complete := false
var _boss_finished_saved_turn := -1
var _boss_mirror_reveal_tween: Tween
var _boss_mirror_values_visible := false
var _boss_camera_tween: Tween
var _boss_pictogram_anchors: Dictionary = {}
var _mission_seen_event_serial := 0
var _mission_toast_generation := 0
var _mission_shield_texture: Texture2D
var _operation_message_generation := 0
var _operation_message_override_active := false
var _roll_cancel_tip_seen := false
var _boss_background_phase := -1
var _boss_backdrop_active := 0
var _boss_goal_presentation_active := false
var _boss_goal_victory := false
var _stage_intro_active := false
var _boss_visual_player_position := 0.0
var _boss_visual_sphinx_position := 0.0
var _boss_entry_sync_generation := 0
var _feedback: V06FeedbackController
var _victory_postcard_emitted := false
var _exit_transition_requested := false
var _heart_roulette_elapsed := 0.0
var _heart_roulette_display_index := 0
var _last_presented_life := -1


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
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_stage", _start_stage_id)
		var state_for_audio := get_node_or_null("/root/GameState")
		if state_for_audio != null:
			ui_sfx.call("set_volume", float(state_for_audio.get("se_volume")))
	_session = V06PlaySessionScript.new(_start_stage_id, _start_character_id)
	_feedback = V06FeedbackControllerScript.new()
	_feedback.name = "JourneyFeedback"
	add_child(_feedback)
	var global_state := get_node_or_null("/root/GameState")
	if global_state != null:
		_feedback.set_levels(1.0, float(global_state.get("se_volume")), bool(global_state.get("dice_se_muted")))
		_feedback.set_haptics_enabled(bool(global_state.get("haptics_enabled")))
	var resume_requested := not _resume_data.is_empty()
	var restored := false
	if not _resume_data.is_empty():
		var state: Variant = _resume_data.get("session_state", {})
		if state is Dictionary:
			restored = _session.restore_stable_snapshot(state as Dictionary, Time.get_ticks_msec())
		if not restored:
			call_deferred("_emit_resume_failed")
	_mission_seen_event_serial = int(_session.mission_state().get("event_serial", 0))
	_last_presented_life = _session.life()
	_sync_travel_collection_from_session()
	_configure_generated_art()
	_prepare_operation_message_band()
	_apply_surface_styles()
	var layout_parent := get_parent_control()
	if layout_parent != null:
		layout_parent.resized.connect(_queue_runtime_screen_layout)
	else:
		get_viewport().size_changed.connect(_queue_runtime_screen_layout)
	_queue_runtime_screen_layout()
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
		_sync_bgm_to_session_phase()
		_present_session_phase()
		if qa_scenario.is_empty() and DisplayServer.get_name() != "headless":
			call_deferred("_open_start_onboarding_if_eligible")
	elif not resume_requested:
		_save_stable_checkpoint()
		if qa_scenario.is_empty() and DisplayServer.get_name() != "headless":
			_play_bgm(&"play_stage_select")
			_stage_intro_active = true
			call_deferred("_play_stage_intro")
		else:
			_sync_bgm_to_session_phase()


func _configure_generated_art() -> void:
	slot_tray_art.texture = SLOT_TRAY_ART
	slot_snap_sparkle.texture = SLOT_SNAP_SPARKLE
	die_hero_art.texture = DICE_UI_ART
	skill_tool_button.icon = SKILL_BOOK_ART
	skill_tool_button.expand_icon = true
	back_button.icon = MENU_GEAR_ART
	back_button.expand_icon = true
	boss_sequence_art.texture = BOSS_START_ART
	postcard_art.texture = POSTCARD_ART
	_roll_button_ornament_atlas = AtlasTexture.new()
	_roll_button_ornament_atlas.atlas = ROLL_BUTTON_ORNAMENTS
	roll_button_ornament.texture = ROLL_BUTTON_ROUND_ART
	roll_button_ornament.self_modulate = Color.WHITE
	_mission_shield_texture = mission_shield_icon.texture
	back_button.text = V06LocalizationScript.text(&"TRAVEL_MENU_BUTTON")
	travel_menu_title.text = V06LocalizationScript.text(&"TRAVEL_MENU_TITLE")
	travel_menu_detail.text = V06LocalizationScript.text(&"TRAVEL_MENU_DETAIL")
	travel_menu_continue_button.text = V06LocalizationScript.text(&"TRAVEL_MENU_CONTINUE")
	travel_menu_exit_button.text = V06LocalizationScript.text(&"TRAVEL_MENU_EXIT")
	_sync_travel_audio_controls()
	travel_menu_overlay.hide()
	landing_art_overlay.hide()
	landing_paid_action_button.hide()
	landing_discovery_thumb.hide()
	boss_sequence_art.hide()
	postcard_art.hide()
	_prepare_inline_slot_layout()


func _prepare_operation_message_band() -> void:
	# Keep the guidance in the document flow between map and controls. This
	# protects both surfaces at tall and half-scale mobile viewports.
	var page := %Page as VBoxContainer
	var tray_panel := %TrayPanel as PanelContainer
	if message_band.get_parent() != page:
		message_band.reparent(page, false)
	page.move_child(message_band, tray_panel.get_index())
	message_band.custom_minimum_size = Vector2(0.0, 72.0)
	message_band.layout_mode = 2
	if message_label.get_parent() != message_band:
		message_label.reparent(message_band, false)
	message_label.layout_mode = 2
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _runtime_layout_reference_size() -> Vector2:
	var parent_control := get_parent_control()
	if parent_control != null and parent_control.size.x > 0.0 and parent_control.size.y > 0.0:
		return parent_control.size
	return size


func _uses_compact_phone_layout() -> bool:
	var reference_size := _runtime_layout_reference_size()
	return reference_size.x <= 720.0 and reference_size.y <= BOSS_BASE_VIEWPORT_HEIGHT


func _queue_runtime_screen_layout() -> void:
	if _runtime_layout_queued or not is_inside_tree():
		return
	_runtime_layout_queued = true
	call_deferred("_apply_runtime_screen_layout")


func _apply_runtime_screen_layout() -> void:
	if not is_node_ready():
		_runtime_layout_queued = false
		return
	var compact := _uses_compact_phone_layout()
	if not _phone_layout_profile_initialized or compact != _compact_phone_layout_active:
		_phone_layout_profile_initialized = true
		_compact_phone_layout_active = compact
		(%Page as VBoxContainer).add_theme_constant_override("separation", 0 if compact else 8)
		message_band.custom_minimum_size.y = 72.0
		_apply_compact_panel_padding(%StageBand as PanelContainer)
		_apply_compact_panel_padding(%MissionBand as PanelContainer)
		_apply_compact_panel_padding(%AtlasFrame as PanelContainer)
	_apply_tall_screen_boss_layout()
	_runtime_layout_queued = false


func _apply_compact_panel_padding(panel: PanelContainer) -> void:
	var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var vertical_margin := 0.0 if _uses_compact_phone_layout() else 12.0
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	panel.add_theme_stylebox_override("panel", style)


func _boss_tall_screen_offset_y() -> float:
	return maxf(_runtime_layout_reference_size().y - BOSS_BASE_VIEWPORT_HEIGHT, 0.0)


func _boss_dice_rest_y() -> float:
	if is_node_ready() and is_instance_valid(race_stage) and is_instance_valid(boss_dice_presentation) and is_instance_valid(%TrayPanel):
		var tray_top_in_race := (%TrayPanel as Control).global_position.y - race_stage.global_position.y
		return tray_top_in_race - boss_dice_presentation.size.y - 26.0
	return BOSS_DICE_REST_Y + _boss_tall_screen_offset_y()


func _boss_dice_stop_y() -> float:
	return _boss_dice_rest_y() - 22.0


func _apply_tall_screen_boss_layout() -> void:
	if not is_node_ready():
		return
	var die_x := maxf((race_stage.size.x - boss_dice_presentation.size.x) * 0.5, 0.0)
	var die_y := _boss_dice_rest_y()
	boss_dice_owner_label.position = Vector2(die_x + 11.0, die_y - 42.0)
	boss_player_target_label.hide()
	boss_sphinx_target_label.hide()
	var die_global_y_in_center := race_stage.global_position.y + die_y - mirror_panel.get_parent_control().global_position.y
	mirror_panel.position.y = die_global_y_in_center - mirror_panel.size.y - 14.0
	%MirrorPairsLabel.position.y = mirror_panel.position.y - 42.0
	if not _rolling and _shown_face <= 0:
		boss_dice_presentation.position = Vector2(die_x, die_y)
	boss_dice_shadow.position = Vector2(
		die_x + 5.0,
		boss_dice_presentation.position.y + BOSS_DICE_SHADOW_OFFSET_Y
	)


func _prepare_inline_slot_layout() -> void:
	if not is_instance_valid(slot_layout):
		return
	slot_column.clip_contents = false
	slot_layout.clip_contents = false
	for inline_label: Label in [role_label, role_reward_label]:
		inline_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inline_label.z_index = 8
	pair_link.z_index = 9
	slot_layout.queue_redraw()


func _refresh_inline_slot_layout() -> void:
	_prepare_inline_slot_layout()
	_place_inline_result_labels()


func _place_inline_result_labels() -> void:
	if not is_instance_valid(slot_column) or not is_instance_valid(role_label) or not is_instance_valid(role_reward_label):
		return
	role_label.position = Vector2(8.0, 4.0)
	role_label.size = Vector2(maxf(slot_column.size.x - 16.0, 1.0), 38.0)
	role_reward_label.position = Vector2(8.0, 142.0)
	role_reward_label.size = Vector2(maxf(slot_column.size.x - 16.0, 1.0), 48.0)


func _play_stage_intro() -> void:
	if not _stage_intro_active or _session == null:
		return
	_movement_active = true
	_map_open = true
	_map_clock_pause_owned = _session.pause_clock(Time.get_ticks_msec())
	overview_title.text = "カイロの旅路を見渡そう"
	map_close_button.text = "コースを確認したら旅を始める"
	overview_atlas_view.set_route_position(_session.position(), true)
	map_overlay.show()
	map_close_button.grab_focus()
	message_label.text = "スタートからゴールまでの道を確認"
	message_label.show()
	_refresh_ui()
	await overview_atlas_view.play_stage_overview_sweep(true)
	if not is_inside_tree() or not _stage_intro_active:
		return
	overview_title.text = "全体マップ　・　好きなだけ確認できます"


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
	if _session != null and _session.heart_roulette_pending() and is_instance_valid(heart_roulette_panel) and heart_roulette_panel.visible:
		_heart_roulette_elapsed += delta
		var options: Array[int] = _heart_roulette_visual_options()
		if not options.is_empty():
			var display_index := int(_heart_roulette_elapsed / _heart_roulette_step_seconds()) % options.size()
			if display_index != _heart_roulette_display_index:
				_heart_roulette_display_index = display_index
				_set_heart_roulette_copy(options[_heart_roulette_display_index])
	if is_instance_valid(boss_lane_board) and boss_overlay.visible:
		_sync_boss_board_tokens()
		# Container layout can settle one frame after the intro panel changes its
		# minimum size. Re-anchor the idle die from the final tray position.
		if not _rolling and not _boss_roll_animation_active and _shown_face <= 0:
			_apply_tall_screen_boss_layout()
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
	if _session == null or _exit_transition_requested or not is_node_ready() or not is_inside_tree():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_session.pause_clock(Time.get_ticks_msec())
		_save_stable_checkpoint()
		_refresh_ui()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if not (_travel_menu_open or _utility_open or _map_open or _boss_pause_open or _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open):
			_session.resume_clock(Time.get_ticks_msec())
		_refresh_ui()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_stable_checkpoint()


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
	_clear_boss_pictogram_anchors()
	_rolling = false
	_slot_settling = false
	_movement_active = false
	if is_instance_valid(message_band):
		message_band.hide()
	_boss_roll_animation_active = false
	_boss_intro_active = false
	_boss_intro_complete = false
	_boss_mirror_values_visible = false
	_boss_goal_presentation_active = false
	_boss_goal_victory = false
	_boss_finished_saved_turn = -1
	boss_finish_dim.hide()
	boss_finish_dim.modulate.a = 1.0
	_hide_boss_finish_copy()
	boss_finish_summary_label.hide()
	boss_result_label.hide()
	_tile_help_open = false
	_tile_help_pending_kind = ""
	_three_roll_onboarding_open = false
	_event_card_open = false
	_low_hp_warning_open = false
	if _low_hp_warning_clock_paused and _session != null:
		_session.resume_clock(Time.get_ticks_msec())
	_low_hp_warning_clock_paused = false
	low_hp_overlay.hide()
	if _event_card_clock_paused and _session != null:
		_session.resume_clock(Time.get_ticks_msec())
	_event_card_clock_paused = false
	if _three_roll_onboarding_clock_paused and _session != null:
		_session.resume_clock(Time.get_ticks_msec())
	_three_roll_onboarding_clock_paused = false
	landing_art_overlay.hide()
	_resume_tile_help_clock()
	_travel_menu_open = false
	_travel_encyclopedia_open = false
	travel_menu_overlay.hide()
	if is_instance_valid(travel_encyclopedia_overlay):
		travel_encyclopedia_overlay.call("hide_view")
	boss_sequence_art.hide()
	postcard_art.hide()
	if _landing_art_tween != null:
		_landing_art_tween.kill()
		_landing_art_tween = null
	for token: Control in [player_token, boss_token]:
		token.show()
		token.z_index = 5
		token.scale = Vector2.ONE
	for marker: Control in [player_foot_marker, boss_foot_marker]:
		marker.show()
	boss_dice_presentation.scale = Vector2.ONE
	boss_dice_presentation.position.y = _boss_dice_rest_y()
	boss_dice_owner_label.hide()
	if _boss_mirror_reveal_tween != null:
		_boss_mirror_reveal_tween.kill()
		_boss_mirror_reveal_tween = null
	_reset_inline_slot_result()
	_reset_move_announcement_style()
	_reset_slot_preview_style()
	if is_instance_valid(atlas_view):
		atlas_view.cancel_visual_motion(route_position)
		atlas_view.clear_roll_preview()


func session_snapshot() -> Dictionary:
	return _session.snapshot(Time.get_ticks_msec())


func session_for_test() -> RefCounted:
	return _session


func feedback_receipt_for_test() -> Dictionary:
	return _feedback.feedback_receipt() if is_instance_valid(_feedback) else {}


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
	await _show_skill_ready_discovery_if_eligible(_motion_generation)
	return true


func _wire_controls() -> void:
	die_button.pressed.connect(_on_die_pressed)
	back_button.pressed.connect(_request_back)
	item_tool_button.pressed.connect(_on_item_tool_pressed)
	coin_tool_button.pressed.connect(_on_coin_tool_pressed)
	boss_coin_button.pressed.connect(_on_boss_coin_pressed)
	skill_tool_button.pressed.connect(_on_skill_tool_pressed)
	utility_close_button.pressed.connect(_on_utility_closed)
	utility_previous_button.pressed.connect(_on_utility_previous)
	utility_next_button.pressed.connect(_on_utility_next)
	utility_action_button.pressed.connect(_on_utility_action)
	for index: int in range(pinpoint_face_buttons.size()):
		pinpoint_face_buttons[index].pressed.connect(_on_pinpoint_face_selected.bind(index + 1))
	travel_menu_encyclopedia_button.pressed.connect(_on_travel_encyclopedia_pressed)
	travel_menu_continue_button.pressed.connect(_on_travel_menu_continue)
	travel_menu_exit_button.pressed.connect(_leave_stage_requested)
	travel_encyclopedia_overlay.connect("close_requested", Callable(self, "_on_travel_encyclopedia_closed"))
	travel_bgm_slider.value_changed.connect(_on_travel_bgm_changed)
	travel_se_slider.value_changed.connect(_on_travel_se_changed)
	landing_art_prompt.pressed.connect(_on_landing_art_prompt_pressed)
	landing_paid_action_button.pressed.connect(_on_event_paid_action_pressed)
	low_hp_close_button.pressed.connect(_dismiss_low_hp_warning)
	map_button.pressed.connect(_on_map_pressed)
	map_close_button.pressed.connect(_on_map_closed)
	choice_main_button.pressed.connect(_on_route_chosen.bind(V06CourseModelScript.ROUTE_MAIN))
	choice_bypass_button.pressed.connect(_on_route_chosen.bind(V06CourseModelScript.ROUTE_BYPASS))
	boss_round_ack_button.pressed.connect(_on_boss_round_acknowledged)
	next_lap_button.pressed.connect(_on_next_lap_requested)
	retry_button.pressed.connect(_on_replay_requested)
	boss_pause_button.pressed.connect(_on_boss_pause_pressed)
	boss_resume_button.pressed.connect(_on_boss_resume_pressed)
	boss_back_button.pressed.connect(_leave_stage_requested)
	boss_start_button.pressed.connect(_dismiss_boss_intro)
	boss_start_rule_panel.gui_input.connect(_on_boss_intro_gui_input)
	boss_start_rule_dismiss_layer.gui_input.connect(_on_boss_intro_gui_input)
	boss_quick_rule_panel.gui_input.connect(_on_boss_intro_gui_input)
	landing_art_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	for child: Node in landing_art_overlay.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_STOP if child in [landing_art_prompt, landing_paid_action_button] else Control.MOUSE_FILTER_IGNORE


func _wire_press_feedback() -> void:
	for button: Button in [die_button, map_button, item_tool_button, coin_tool_button, boss_coin_button, skill_tool_button, back_button, utility_close_button, travel_menu_encyclopedia_button, travel_menu_continue_button, travel_menu_exit_button, boss_start_button]:
		button.button_down.connect(_set_button_pressed.bind(button, true))
		button.button_up.connect(_set_button_pressed.bind(button, false))
		button.mouse_exited.connect(_set_button_pressed.bind(button, false))
	for button: Button in [map_button, item_tool_button, coin_tool_button, boss_coin_button, skill_tool_button, back_button, utility_close_button, utility_previous_button, utility_next_button, utility_action_button, travel_menu_encyclopedia_button, travel_menu_continue_button, travel_menu_exit_button, map_close_button, choice_main_button, choice_bypass_button, landing_paid_action_button, low_hp_close_button, boss_round_ack_button, next_lap_button, retry_button, boss_pause_button, boss_resume_button, boss_back_button, boss_start_button]:
		button.pressed.connect(_emit_feedback.bind(V06FeedbackControllerScript.EVENT_BUTTON))
	for button: Button in pinpoint_face_buttons:
		button.pressed.connect(_emit_feedback.bind(V06FeedbackControllerScript.EVENT_BUTTON))


func _emit_feedback(event: StringName) -> void:
	if is_instance_valid(_feedback):
		_feedback.emit_feedback(event)


func _play_ui_sfx(cue: StringName, world_specific := false) -> void:
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)


func _set_button_pressed(button: Button, pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	if button == die_button:
		_roll_button_pressed = pressed
		_refresh_roll_button_ornament()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.97, 0.97) if pressed else Vector2.ONE, 0.08)


func _set_roll_button_ornament_state(state: int) -> void:
	if _roll_button_ornament_atlas == null:
		return
	var clamped_state := clampi(state, 0, 3)
	_roll_button_ornament_atlas.region = Rect2(
		0.0,
		float(clamped_state) * ROLL_BUTTON_ATLAS_CELL.y,
		ROLL_BUTTON_ATLAS_CELL.x,
		ROLL_BUTTON_ATLAS_CELL.y,
	)


func _refresh_roll_button_ornament() -> void:
	if _roll_button_ornament_atlas == null or not is_instance_valid(die_button):
		return
	var state := 0
	if _inline_slot_result_active:
		state = 3
	elif die_button.disabled:
		state = 2
	elif _roll_button_pressed or _rolling:
		state = 1
	if slot_column.visible or (is_instance_valid(boss_overlay) and boss_overlay.visible):
		roll_button_ornament.texture = ROLL_BUTTON_ROUND_ART
		match state:
			1: roll_button_ornament.self_modulate = Color(1.0, 0.94, 0.78, 1.0)
			2: roll_button_ornament.self_modulate = Color(0.82, 0.79, 0.70, 1.0)
			3: roll_button_ornament.self_modulate = Color(1.0, 0.90, 0.58, 1.0)
			_: roll_button_ornament.self_modulate = Color.WHITE
	else:
		roll_button_ornament.texture = _roll_button_ornament_atlas
		roll_button_ornament.self_modulate = Color.WHITE
		_set_roll_button_ornament_state(state)


func _on_die_pressed() -> void:
	if _event_card_open:
		return
	if _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _boss_intro_active or _session == null or _session.phase() == V06PlaySessionScript.PHASE_BOSS_FINISHED:
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
	_emit_feedback(V06FeedbackControllerScript.EVENT_BUTTON)
	if _session != null and _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		_boss_roll_sequence_id += 1
		_clear_boss_state_badges()
		boss_dice_presentation.position.y = _boss_dice_rest_y()
	atlas_view.clear_roll_preview()
	_rolling = true
	_boss_mirror_values_visible = false
	_slot_settling = false
	_rolling_slot_elapsed = 0.0
	_rolling_slot_face = 1
	_show_operation_message("STOPで決定　／　下の道具で準備に戻る", 0.0, 24)
	_refresh_ui()
	_refresh_rolling_slot_preview()
	if _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		boss_dice_owner_label.hide()
		boss_dice_presentation.scale = Vector2.ONE
		boss_dice_presentation.present([_rolling_slot_face], true, 0)
		_refresh_boss_landing_preview(_rolling_slot_face)


func _cancel_active_roll_for_utility() -> String:
	if not _rolling or _session == null or _session.phase() != V06PlaySessionScript.PHASE_READY:
		return ""
	_rolling = false
	_slot_settling = false
	_rolling_slot_elapsed = 0.0
	_rolling_slot_face = 1
	_shown_face = 0
	_roll_button_pressed = false
	atlas_view.clear_roll_preview()
	_reset_slot_preview_style()
	_refresh_ui()
	if _roll_cancel_tip_seen:
		return ""
	_roll_cancel_tip_seen = true
	return "サイコロの回転を中止しました。\n出目・投数・スキル効果は消費していません。"


func _stop_roll() -> void:
	if not _rolling or _boss_intro_active or _session == null or not _session.can_roll():
		return
	_rolling = false
	_slot_settling = true
	_movement_active = _session.can_roll()
	var pinpoint_face: int = int(_session.consume_pinpoint_face())
	# The visible rolling face is authoritative: the face under the player's
	# tap must be the same face committed to the session.
	var face: int = pinpoint_face if pinpoint_face > 0 else _rolling_slot_face
	_show_operation_message("%dマス進む！" % face, 1.0, 38)
	_emit_feedback(V06FeedbackControllerScript.EVENT_ROLL_STOP)
	_shown_face = face
	if _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		boss_dice_presentation.present([face], false, 1)
		boss_dice_presentation.pivot_offset = boss_dice_presentation.size * 0.5
		boss_dice_presentation.scale = BOSS_DICE_EXPLAIN_SCALE
		boss_dice_presentation.position.y = _boss_dice_stop_y()
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
	_present_move_announcement(move_distance, motion_generation, face)
	atlas_view.set_roll_preview(face)
	_refresh_ui()
	_show_slot_snap_sparkle(0.56)
	var pending_role := String(_session.pending_resolution_role())
	var pending_positions: Array[Dictionary] = _session.pending_hop_positions()
	var pending_event: bool = not pending_positions.is_empty() and str(pending_positions[-1].get("route_id", "")) == "main" and int(pending_positions[-1].get("tile_index", -1)) in [30, 43, 61, 77]
	if pending_role != "" and not pending_event:
		await _play_inline_slot_result(pending_role, face, motion_generation)
		if not _movement_active or motion_generation != _motion_generation:
			return
		var pending_boss_gate := not pending_positions.is_empty() and str(pending_positions[-1].get("route_id", "")) == "main" and int(pending_positions[-1].get("tile_index", -1)) == 89
		if not pending_boss_gate:
			await _show_skill_ready_discovery_if_eligible(motion_generation)
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
	var result_faces: Array = result.get("faces", [])
	var slot_index := clampi(result_faces.size() - 1, 0, slot_labels.size() - 1)
	_clear_boss_state_badges()
	_boss_mirror_values_visible = false
	mirror_panel.hide()
	boss_dice_presentation.present([player_roll], false, 1)
	boss_dice_presentation.pivot_offset = boss_dice_presentation.size * 0.5
	boss_dice_presentation.scale = BOSS_DICE_EXPLAIN_SCALE
	boss_dice_presentation.position.y = _boss_dice_stop_y()
	boss_dice_owner_label.text = "YOU"
	boss_dice_owner_label.add_theme_color_override("font_color", Color("#f0c76a"))
	boss_dice_owner_label.show()
	if slot_index >= 0 and slot_index < slot_labels.size():
		slot_labels[slot_index].text = ""
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
	die_scale_down.parallel().tween_property(boss_dice_presentation, "position:y", _boss_dice_rest_y(), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if slot_index >= 0 and slot_index < slot_labels.size():
		slot_labels[slot_index].text = str(player_roll)
		slot_labels[slot_index].modulate = Color.WHITE
		_flash_slot_panels([slot_index], SLOT_RESULT_GLOW, 1.03)
	var completed_role := str(result.get("role", ""))
	if not completed_role.is_empty():
		if not await _play_boss_slot_result(completed_role, result_faces, sequence_id): return false
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
	_clear_boss_pictogram_anchors()
	if terminal_turn:
		if not await _play_boss_goal_sequence(result, sequence_id, goal): return false
	return true


func _play_boss_slot_result(role: String, values: Array, sequence_id: int) -> bool:
	_inline_slot_result_active = true
	role_label.text = "%s！" % role
	role_label.add_theme_font_size_override("font_size", 20)
	role_label.add_theme_color_override("font_color", Color("#f0c76a"))
	match role:
		"PAIR": role_reward_label.text = "盾：次のボス移動を半分"
		"STRAIGHT": role_reward_label.text = "加速：さらに3マス進む"
		"TRIPLE": role_reward_label.text = "必殺：+5マス / ボス1回休み"
		_: role_reward_label.text = "役なし　次の3投へ"
	role_reward_label.add_theme_font_size_override("font_size", 18)
	role_label.show()
	role_reward_label.show()
	_refresh_inline_slot_layout()
	var typed_values: Array[int] = []
	for value: Variant in values:
		typed_values.append(int(value))
	var spec := inline_slot_result_spec(role, typed_values)
	if str(spec.effect) == "pair_link":
		var pair_indices: Array = spec.indices
		if pair_indices.size() == 2:
			_position_pair_link(pair_indices[0], pair_indices[1])
			pair_link.show()
	_flash_slot_panels(spec.indices, SLOT_RESULT_STRONG_GLOW if role == "TRIPLE" else SLOT_RESULT_GLOW, 1.05 if role == "TRIPLE" else 1.03)
	if not await _boss_roll_wait(0.9, sequence_id): return false
	_reset_inline_slot_result()
	return true


func _animate_boss_landing_effects(result: Dictionary, sequence_id: int, player_base: int, boss_base: int, goal: int) -> bool:
	var player_effect := str(result.get("player_effect", ""))
	var boss_effect := str(result.get("boss_effect", ""))
	var player_effect_after := int(result.get("player_effect_position_after", player_base))
	var boss_effect_after := int(result.get("boss_effect_position_after", boss_base))
	if not player_effect.is_empty() or not boss_effect.is_empty():
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
	var effect_steps := maxi(absi(player_effect_after - player_base), absi(boss_effect_after - boss_base))
	for step: int in range(1, effect_steps + 1):
		var player_position := player_base + clampi(player_effect_after - player_base, -step, step)
		var boss_position := boss_base + clampi(boss_effect_after - boss_base, -step, step)
		_position_boss_tokens(player_position, boss_position, goal, true, BOSS_STEP_SECONDS * 0.82)
		if not await _boss_roll_wait(BOSS_STEP_SECONDS, sequence_id): return false
	var player_after := int(result.get("player_position_after", player_effect_after))
	var role_steps := maxi(player_after - player_effect_after, 0)
	for step: int in range(1, role_steps + 1):
		_position_boss_tokens(player_effect_after + step, boss_effect_after, goal, true, BOSS_STEP_SECONDS * 0.72)
		if not await _boss_roll_wait(BOSS_STEP_SECONDS * 0.82, sequence_id): return false
	return true


func _play_boss_goal_sequence(result: Dictionary, sequence_id: int, goal: int) -> bool:
	_boss_goal_presentation_active = true
	_boss_goal_victory = bool(result.get("victory", false))
	boss_sequence_art.texture = BOSS_VICTORY_ART if _boss_goal_victory else BOSS_NEAR_MISS_ART
	boss_sequence_art.modulate = Color(1.0, 1.0, 1.0, 0.0)
	boss_sequence_art.show()
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
	gate_open.tween_property(boss_sequence_art, "modulate:a", 0.94, BOSS_GOAL_GATE_SECONDS)
	var active_backdrop: TextureRect = boss_arena_backdrop if _boss_backdrop_active == 0 else boss_arena_backdrop_next
	var backdrop_color := active_backdrop.modulate
	gate_open.tween_property(active_backdrop, "modulate", Color(1.35, 1.18, 0.72, backdrop_color.a), BOSS_GOAL_GATE_SECONDS * 0.5)
	gate_open.chain().tween_property(active_backdrop, "modulate", backdrop_color, BOSS_GOAL_GATE_SECONDS * 0.5)
	if not await _boss_roll_wait(BOSS_GOAL_GATE_SECONDS, sequence_id): return false
	var player_won := _boss_goal_victory
	_emit_feedback(V06FeedbackControllerScript.EVENT_VICTORY if player_won else V06FeedbackControllerScript.EVENT_DEFEAT)
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
	_configure_boss_finish_copy(result, player_won)
	boss_result_label.add_theme_font_size_override("font_size", 46)
	boss_result_label.show()
	if not await _boss_roll_wait(0.50, sequence_id): return false
	_show_boss_finish_copy()
	_boss_goal_presentation_active = false
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
	var hp_before_landing: int = int(_session.player_hp())
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
	var discovered_item_id := str(tile_effect.get("item_id", ""))
	if not discovered_item_id.is_empty():
		_register_travel_card("item:%s" % discovered_item_id)
	_emit_landing_feedback(tile_effect)
	_refresh_ui()
	if not tile_effect.is_empty() and not str(tile_effect.get("text", "")).is_empty():
		message_label.text = str(tile_effect.text)
		message_label.show()
	if visual_path.is_empty():
		atlas_view.clear_roll_preview()
	elif loop_mode:
		var returned_from_loop := str(stable_position.get("route_id", "")) == V06CourseModelScript.ROUTE_MAIN
		if atlas_view.current_route_position() != stable_position:
			await atlas_view.animate_portal_transfer_to(stable_position)
		else:
			atlas_view.set_route_position(stable_position)
		if returned_from_loop:
			message_label.text = V06LocalizationScript.text(&"LOOP_RESCUE_TOAST") if _session.last_loop_rescue_triggered() else "本線のこの地点へ戻ってきた"
			message_label.show()
			await atlas_view.play_loop_return_context(stable_position)
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
	if _session.phase() == V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
		_show_operation_message("出目%dで分岐に到着　あと%dマス" % [_session.pending_face(), _session.pending_remaining_steps()], ROUTE_CHOICE_REVIEW_SECONDS, 32)
		await get_tree().create_timer(ROUTE_CHOICE_REVIEW_SECONDS).timeout
		if motion_generation >= 0 and motion_generation != _motion_generation:
			return false
	atlas_view.clear_roll_preview()
	var landing_tile_kind := str(tile_effect.get("tile_kind", _session.current_tile_kind()))
	if _session.phase() == V06PlaySessionScript.PHASE_EVENT_REQUIRED:
		if not await _show_event_card(motion_generation): return false
	elif not await _show_landing_art(landing_tile_kind, int(stable_position.get("tile_index", 0)), motion_generation):
		return false
	if hp_before_landing > 1 and _session.player_hp() == 1:
		if not await _show_low_hp_warning(motion_generation):
			return false
	_movement_active = false
	_shown_face = 0
	_refresh_ui()
	_present_session_phase()
	_save_stable_checkpoint()
	return true


func _present_session_phase() -> void:
	match _session.phase():
		V06PlaySessionScript.PHASE_EVENT_REQUIRED:
			if not _event_card_open:
				_show_event_card(-1)
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
	_boss_entry_sync_generation += 1
	var entry_sync_generation := _boss_entry_sync_generation
	_play_bgm(&"play_boss")
	_boss_intro_active = false
	_boss_intro_complete = false
	_boss_finished_saved_turn = -1
	var boss: Dictionary = _session.boss_snapshot()
	if _session.phase() == V06PlaySessionScript.PHASE_RUN_OVER and boss.is_empty():
		boss_overlay.show()
		boss_panel.modulate.a = 1.0
		boss_panel.scale = Vector2.ONE
		_refresh_boss_panel()
		return
	_register_travel_card("boss:sleepy_sphinx")
	boss_lane_board.configure(int(boss.get("course_length", 20)), _session.boss_course_tiles(true), _session.boss_course_tiles(false))
	_boss_visual_player_position = float(boss.get("player_position", 0))
	_boss_visual_sphinx_position = float(boss.get("boss_position", 0))
	# The first boss frame is a stable reference frame.  Seed the logical
	# positions before the first deferred refresh so entering the overlay cannot
	# be mistaken for a race movement tween.
	_boss_last_player_position = int(_boss_visual_player_position)
	_boss_last_position = int(_boss_visual_sphinx_position)
	boss_lane_board.set_racers(_boss_visual_player_position, _boss_visual_sphinx_position)
	if _boss_camera_tween != null:
		_boss_camera_tween.kill()
		_boss_camera_tween = null
	boss_lane_board.set_camera_position(_boss_entry_camera_target())
	_boss_background_phase = -1
	_boss_backdrop_active = 0
	_set_boss_background_phase_immediate(_boss_phase_for_progress(maxf(_boss_visual_player_position, _boss_visual_sphinx_position)))
	_sync_boss_board_tokens()
	call_deferred("_stabilize_boss_entry_view", entry_sync_generation)
	boss_arena_backdrop.modulate.a = 0.0
	boss_arena_backdrop_next.modulate.a = 0.0
	boss_panel.modulate.a = 0.0
	# Keep the board, lanes, and die at their authored scale while the intro
	# appears.  A BACK scale tween here reads as a camera wobble on entry.
	boss_panel.scale = Vector2.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(boss_arena_backdrop, "modulate:a", 1.0, 0.30)
	tween.tween_property(boss_panel, "modulate:a", 1.0, 0.30)


func _sync_bgm_to_session_phase() -> void:
	if _session == null:
		return
	if _session.phase() in [
		V06PlaySessionScript.PHASE_BOSS_GATE,
		V06PlaySessionScript.PHASE_BOSS_ROLL_READY,
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT,
		V06PlaySessionScript.PHASE_BOSS_FINISHED,
		V06PlaySessionScript.PHASE_LAP_RESULT,
		V06PlaySessionScript.PHASE_RUN_OVER,
	]:
		_play_bgm(&"play_boss")
	else:
		_play_bgm(&"play_normal_map")


func _play_bgm(method: StringName) -> void:
	var manager := get_node_or_null("/root/BgmManager")
	if manager != null:
		manager.call(method)


func _begin_boss_intro_if_needed() -> void:
	if _boss_intro_active or _boss_intro_complete or _session == null:
		return
	if _session.phase() != V06PlaySessionScript.PHASE_BOSS_ROLL_READY or not _session.faces().is_empty():
		return
	_boss_intro_active = true
	# The full first-lap explanation is player-paced. Later laps keep the brief
	# automatic reminder, which can also be dismissed early by tapping it.
	if _session.lap() > 1:
		var intro_sequence_id := _boss_roll_sequence_id
		call_deferred("_finish_boss_intro", intro_sequence_id)


func _on_boss_intro_gui_input(event: InputEvent) -> void:
	if not _boss_intro_active:
		return
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	_dismiss_boss_intro()


func _dismiss_boss_intro() -> void:
	if not _boss_intro_active:
		return
	_boss_intro_active = false
	_boss_intro_complete = true
	_boss_roll_sequence_id += 1
	_refresh_ui()
	_present_session_phase()


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
		_play_ui_sfx(&"blocked")
		message_label.text = "今はそのルートを選べません"
		message_label.show()
		_refresh_ui()
		return
	choice_overlay.hide()
	_play_ui_sfx(&"select")
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
		_play_ui_sfx(&"blocked")
		return
	_play_ui_sfx(&"retry")
	_heart_roulette_elapsed = 0.0
	_heart_roulette_display_index = 0
	_play_bgm(&"play_normal_map")
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
	if _session != null and _session.heart_roulette_pending():
		var resolved: Dictionary = _session.resolve_heart_roulette(_heart_roulette_session_index_for_visual(_heart_roulette_display_index))
		if bool(resolved.get("ok", false)):
			_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)
			_refresh_ui()
			_configure_boss_finish_copy(_session.boss_result(), true)
			_save_stable_checkpoint()
		return
	var completed_lap: int = int(_session.lap())
	var life_before: int = int(_session.life())
	if not _session.next_lap():
		_play_ui_sfx(&"blocked")
		return
	_play_ui_sfx(&"complete", true)
	_last_presented_life = _session.life()
	if completed_lap % 10 == 0:
		_show_operation_message(lap_life_stamp_text(completed_lap, life_before, _session.life()), 1.3, 25)
	_heart_roulette_elapsed = 0.0
	_heart_roulette_display_index = 0
	_play_bgm(&"play_normal_map")
	_shown_face = 0
	_cancel_motion(_session.position())
	# The boss viewport owns its own die pool. Clear it before revealing the
	# normal map so a retained last face cannot survive into later laps.
	boss_dice_presentation.present([], false, 0)
	boss_dice_presentation.hide()
	boss_dice_owner_label.hide()
	boss_overlay.hide()
	atlas_view.set_route_position(_session.position(), true)
	_refresh_ui()
	_save_stable_checkpoint()


func _on_boss_pause_pressed() -> void:
	if _boss_pause_open or not boss_overlay.visible or _session == null:
		return
	_boss_pause_open = true
	_play_ui_sfx(&"open")
	_session.pause_clock(Time.get_ticks_msec())
	boss_pause_overlay.show()
	boss_resume_button.grab_focus()
	_refresh_ui()


func _on_boss_resume_pressed() -> void:
	if not _boss_pause_open or _session == null:
		return
	_boss_pause_open = false
	_play_ui_sfx(&"close")
	boss_pause_overlay.hide()
	_session.resume_clock(Time.get_ticks_msec())
	boss_pause_button.grab_focus()
	_refresh_ui()


func _request_back() -> void:
	if _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open:
		return
	if _travel_encyclopedia_open:
		_on_travel_encyclopedia_closed()
		return
	if _travel_menu_open:
		_on_travel_menu_continue()
		return
	if _utility_open:
		_on_utility_closed()
		return
	if _map_open:
		_on_map_closed()
		return
	if _movement_active:
		return
	_on_travel_menu_pressed()


func _on_travel_menu_pressed() -> void:
	if _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open or _travel_menu_open or _utility_open or _map_open or _movement_active or _rolling or _session == null:
		return
	if _session.phase() != V06PlaySessionScript.PHASE_READY:
		return
	_travel_menu_open = true
	_play_ui_sfx(&"open")
	_session.pause_clock(Time.get_ticks_msec())
	_save_stable_checkpoint()
	travel_menu_overlay.show()
	travel_menu_continue_button.grab_focus()
	_refresh_ui()


func _on_travel_encyclopedia_pressed() -> void:
	if not _travel_menu_open or _travel_encyclopedia_open:
		return
	_travel_encyclopedia_open = true
	_play_ui_sfx(&"open")
	travel_menu_overlay.hide()
	travel_encyclopedia_overlay.call("open", _global_travel_card_ids(), "設定へ戻る")


func _on_travel_encyclopedia_closed() -> void:
	if not _travel_encyclopedia_open:
		return
	_travel_encyclopedia_open = false
	_play_ui_sfx(&"close")
	travel_encyclopedia_overlay.call("hide_view")
	if _travel_menu_open:
		travel_menu_overlay.show()
		travel_menu_encyclopedia_button.grab_focus()


func _on_travel_menu_continue() -> void:
	if not _travel_menu_open or _session == null:
		return
	if _travel_encyclopedia_open:
		_on_travel_encyclopedia_closed()
		return
	_travel_menu_open = false
	_play_ui_sfx(&"close")
	travel_menu_overlay.hide()
	_session.resume_clock(Time.get_ticks_msec())
	_persist_global_audio_settings()
	back_button.grab_focus()
	_refresh_ui()


func _leave_stage_requested() -> void:
	if _session == null or _exit_transition_requested:
		return
	_play_ui_sfx(&"back")
	_save_stable_checkpoint()
	_persist_global_audio_settings()
	_exit_transition_requested = true
	set_process(false)
	_motion_generation += 1
	_boss_roll_sequence_id += 1
	_travel_menu_open = false
	_travel_encyclopedia_open = false
	travel_menu_overlay.hide()
	travel_encyclopedia_overlay.call("hide_view")
	back_requested.emit()


func _sync_travel_audio_controls() -> void:
	var global_state := get_node_or_null("/root/GameState")
	if global_state == null:
		return
	travel_bgm_slider.set_value_no_signal(float(global_state.get("master_volume")) * 100.0)
	travel_se_slider.set_value_no_signal(float(global_state.get("se_volume")) * 100.0)
	travel_bgm_label.text = "BGM音量　%d%%" % roundi(travel_bgm_slider.value)
	travel_se_label.text = "SE音量　%d%%" % roundi(travel_se_slider.value)


func _on_travel_bgm_changed(value: float) -> void:
	var global_state := get_node_or_null("/root/GameState")
	if global_state == null:
		return
	global_state.set("master_volume", clampf(value / 100.0, 0.0, 1.0))
	travel_bgm_label.text = "BGM音量　%d%%" % roundi(value)
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm != null:
		bgm.call("set_master_volume", global_state.get("master_volume"))


func _on_travel_se_changed(value: float) -> void:
	var global_state := get_node_or_null("/root/GameState")
	if global_state == null:
		return
	global_state.set("se_volume", clampf(value / 100.0, 0.0, 1.0))
	travel_se_label.text = "SE音量　%d%%" % roundi(value)
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("set_volume", global_state.get("se_volume"))
	if is_instance_valid(_feedback):
		_feedback.set_levels(1.0, float(global_state.get("se_volume")), bool(global_state.get("dice_se_muted")))


func _persist_global_audio_settings() -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.call("save_now")


func _global_travel_card_ids() -> Array:
	var global_state := get_node_or_null("/root/GameState")
	if global_state == null or not global_state.has_method("discovered_travel_card_ids"):
		return []
	var raw_ids: Variant = global_state.call("discovered_travel_card_ids")
	return (raw_ids as Array).duplicate() if raw_ids is Array else []


func _register_travel_card(card_id: String) -> void:
	if not V06TravelCardCatalogScript.valid_id(card_id):
		return
	var global_state := get_node_or_null("/root/GameState")
	if global_state == null or not global_state.has_method("register_travel_card"):
		return
	if not bool(global_state.call("register_travel_card", card_id)):
		return
	_persist_global_audio_settings()
	if _travel_encyclopedia_open:
		travel_encyclopedia_overlay.call("refresh_discoveries", _global_travel_card_ids())


func _sync_travel_collection_from_session() -> void:
	if _session == null:
		return
	for raw_item_id: Variant in _session.inventory().keys():
		_register_travel_card("item:%s" % str(raw_item_id))
	if _session.has_method("seen_event_ids"):
		for raw_event_id: Variant in _session.call("seen_event_ids"):
			_register_travel_card("event:%s" % str(raw_event_id))
	if not _session.boss_snapshot().is_empty():
		_register_travel_card("boss:sleepy_sphinx")


func _on_item_tool_pressed() -> void:
	if _three_roll_onboarding_open:
		return
	var cancel_notice := _cancel_active_roll_for_utility()
	_utility_mode = "item"
	_utility_index = 0
	_utility_entries = _session.inventory_entries() if _session != null else []
	_open_utility_card("旅のアイテム", ITEM_CARD, "")
	_refresh_item_utility(cancel_notice)


func _on_coin_tool_pressed() -> void:
	if _three_roll_onboarding_open:
		return
	var cancel_notice := _cancel_active_roll_for_utility()
	_utility_mode = "coin"
	_utility_index = 0
	_utility_entries = _session.coin_action_catalog() if _session != null else []
	_open_utility_card("旅のコイン", DISCOVERY_ARTS[0], "")
	_refresh_coin_utility(cancel_notice)


func _on_boss_coin_pressed() -> void:
	if _session == null or not _boss_support_window_open():
		return
	_utility_mode = "boss_coin"
	_utility_index = 0
	_utility_entries = _boss_coin_entries()
	_open_utility_card("ボスレース前の支援", DISCOVERY_ARTS[0], "")
	_refresh_coin_utility()


func _boss_support_window_open() -> bool:
	if _session == null or _session.phase() != V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		return false
	var boss: Dictionary = _session.boss_snapshot()
	return not boss.is_empty() and (boss.get("player_roll_history", []) as Array).is_empty() and _session.faces().is_empty()


func _boss_coin_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if _session == null:
		return entries
	for entry: Dictionary in _session.coin_action_catalog():
		if str(entry.get("id", "")).begins_with("boss_"):
			entries.append(entry)
	return entries


func _on_skill_tool_pressed() -> void:
	if _three_roll_onboarding_open:
		return
	var cancel_notice := _cancel_active_roll_for_utility()
	_utility_mode = "skill"
	_utility_entries.clear()
	_utility_index = 0
	_open_utility_card("次の出目を選ぶ", SKILL_PINPOINT_ART, "")
	_refresh_skill_utility(cancel_notice)


func _open_utility_card(title: String, texture: Texture2D, detail: String) -> void:
	if _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _travel_menu_open or _utility_open or _map_open or _movement_active or _rolling or _session == null:
		return
	if _session.phase() != V06PlaySessionScript.PHASE_READY and not (_utility_mode == "boss_coin" and _boss_support_window_open()):
		return
	_utility_open = true
	_play_ui_sfx(&"open")
	_session.pause_clock(Time.get_ticks_msec())
	_save_stable_checkpoint()
	utility_panel.custom_minimum_size.y = 800.0 if _utility_mode == "skill" else 700.0
	utility_title.text = title
	utility_card_art.texture = texture
	utility_detail.text = detail
	utility_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	utility_overlay.show()
	utility_close_button.grab_focus()
	_refresh_ui()


func _refresh_item_utility(status_text := "") -> void:
	utility_nav_row.show()
	pinpoint_face_row.hide()
	utility_action_button.show()
	_utility_entries = _session.inventory_entries()
	if _utility_entries.is_empty():
		utility_title.text = "旅のアイテム"
		utility_card_art.texture = ITEM_CARD
		utility_detail.text = "バッグ  0 / %d\n\nITEMマスで道具をゲット%s" % [
			V06PlaySessionScript.ITEM_CAPACITY,
			"\n%s" % status_text if not status_text.is_empty() else "",
		]
		utility_page_label.text = "0 / 0"
		utility_previous_button.disabled = true
		utility_next_button.disabled = true
		utility_action_button.text = "使えるアイテムなし"
		utility_action_button.disabled = true
		return
	_utility_index = posmod(_utility_index, _utility_entries.size())
	var entry: Dictionary = _utility_entries[_utility_index]
	var art_index := clampi(int(entry.get("art_index", 0)), 0, ITEM_ARTS.size() - 1)
	utility_title.text = str(entry.get("name", "アイテム"))
	utility_card_art.texture = ITEM_ARTS[art_index]
	utility_detail.text = "%s\n\n所持 ×%d　バッグ %d/%d%s" % [
		str(entry.get("description", "")),
		int(entry.get("amount", 0)),
		_session.inventory_total(),
		V06PlaySessionScript.ITEM_CAPACITY,
		"\n%s" % status_text if not status_text.is_empty() else "",
	]
	utility_page_label.text = "%d / %d" % [_utility_index + 1, _utility_entries.size()]
	utility_previous_button.disabled = _utility_entries.size() <= 1
	utility_next_button.disabled = _utility_entries.size() <= 1
	utility_action_button.text = "このアイテムを使う"
	utility_action_button.disabled = false


func _refresh_skill_utility(status_text := "") -> void:
	utility_nav_row.hide()
	utility_action_button.hide()
	pinpoint_face_row.show()
	utility_title.text = "次の出目を選ぶ"
	utility_card_art.texture = SKILL_PINPOINT_ART
	var armed_face: int = int(_session.pinpoint_face())
	var ready: bool = _session.skill_state() == V06PlaySessionScript.SKILL_STATE_READY and _session.skill_gauge() >= V06PlaySessionScript.SKILL_GAUGE_MAX
	if armed_face > 0:
		utility_detail.text = "次のサイコロ → %d" % armed_face
	elif ready:
		utility_detail.text = "READY!\n\n止めたい出目をタップ"
	else:
		utility_detail.text = "CHARGE  %d/%d\n\n満タンRESTでSKILL +1\nSLOT成立報酬はTRIP COIN" % [_session.skill_gauge(), V06PlaySessionScript.SKILL_GAUGE_MAX]
	if not status_text.is_empty():
		utility_detail.text += "\n%s" % status_text
	for index: int in range(pinpoint_face_buttons.size()):
		var button := pinpoint_face_buttons[index]
		button.disabled = not ready
		button.text = "✓%d" % (index + 1) if armed_face == index + 1 else str(index + 1)


func _refresh_coin_utility(status_text := "") -> void:
	utility_nav_row.show()
	pinpoint_face_row.hide()
	utility_action_button.show()
	_utility_entries = _boss_coin_entries() if _utility_mode == "boss_coin" else _session.coin_action_catalog()
	_utility_index = posmod(_utility_index, _utility_entries.size())
	var entry: Dictionary = _utility_entries[_utility_index]
	var cost := int(entry.get("cost", 0))
	var active := bool(entry.get("active", false))
	var action_id := str(entry.get("id", ""))
	var category := str(entry.get("category", "コイン支援"))
	var state_copy := "未所持"
	if active:
		if action_id.begins_with("boss_"):
			state_copy = "このボス戦で発動" if _utility_mode == "boss_coin" else "次のボス戦で発動"
		else:
			state_copy = "所持中"
	elif _session.coins() < cost:
		state_copy = "コイン不足"
	utility_title.text = "コインショップ"
	utility_card_art.texture = DISCOVERY_ARTS[0]
	utility_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	utility_detail.text = "%s｜%s\n%s\n%s\n%s\n所持TRIP COIN：%d　価格：%d\n状態：%s%s" % [
		category,
		str(entry.get("name", "コイン支援")),
		str(entry.get("description", "")),
		str(entry.get("timing", "")),
		str(entry.get("use_rule", "1回だけ使えます")),
		_session.coins(),
		cost,
		state_copy,
		"\n%s" % status_text if not status_text.is_empty() else "",
	]
	utility_page_label.text = "%s　%d / %d" % [category, _utility_index + 1, _utility_entries.size()]
	utility_previous_button.disabled = _utility_entries.size() <= 1
	utility_next_button.disabled = _utility_entries.size() <= 1
	if active:
		utility_action_button.text = "すでに所持しています"
	elif _session.coins() < cost:
		utility_action_button.text = "コインが足りません"
	else:
		utility_action_button.text = "コイン%dで買う" % cost
	utility_action_button.disabled = active or _session.coins() < cost


func _on_utility_previous() -> void:
	if _utility_mode not in ["item", "coin", "boss_coin"] or _utility_entries.is_empty():
		return
	_utility_index = posmod(_utility_index - 1, _utility_entries.size())
	if _utility_mode in ["coin", "boss_coin"]: _refresh_coin_utility()
	else: _refresh_item_utility()


func _on_utility_next() -> void:
	if _utility_mode not in ["item", "coin", "boss_coin"] or _utility_entries.is_empty():
		return
	_utility_index = posmod(_utility_index + 1, _utility_entries.size())
	if _utility_mode in ["coin", "boss_coin"]: _refresh_coin_utility()
	else: _refresh_item_utility()


func _on_utility_action() -> void:
	if _utility_entries.is_empty():
		return
	if _utility_mode in ["coin", "boss_coin"]:
		var action_id := str(_utility_entries[_utility_index].get("id", ""))
		var purchase: Dictionary = _session.purchase_coin_action(action_id)
		if bool(purchase.get("ok", false)):
			_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)
			message_label.text = "%sを準備" % str(_utility_entries[_utility_index].get("name", "コイン支援"))
			message_label.show()
			_save_stable_checkpoint()
			_refresh_ui()
			_refresh_coin_utility("準備OK")
		else:
			_emit_feedback(V06FeedbackControllerScript.EVENT_BLOCKED)
			_refresh_coin_utility("コイン不足 / 準備済み")
		return
	if _utility_mode != "item":
		return
	var item_id := str(_utility_entries[_utility_index].get("id", ""))
	var result: Dictionary = _session.use_item(item_id)
	if bool(result.get("ok", false)):
		_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)
		message_label.text = str(result.get("text", "ITEM USED"))
		message_label.show()
		_save_stable_checkpoint()
		_refresh_ui()
		_refresh_item_utility("使用しました")
	else:
		_emit_feedback(V06FeedbackControllerScript.EVENT_BLOCKED)
		var reason := str(result.get("error", result.get("status", "使えません")))
		var reason_copy := "HPは満タンです" if reason == "HP_FULL" else "同じ効果がすでに有効です"
		_refresh_item_utility(reason_copy)


func _on_pinpoint_face_selected(face: int) -> void:
	if _utility_mode != "skill" or _session == null:
		return
	var result: Dictionary = _session.arm_pinpoint(face)
	if not bool(result.get("ok", false)):
		_emit_feedback(V06FeedbackControllerScript.EVENT_BLOCKED)
		_refresh_skill_utility()
		return
	_emit_feedback(V06FeedbackControllerScript.EVENT_LEVEL_UP)
	message_label.text = "ピンポイント　出目 %d を予約" % face
	message_label.show()
	_save_stable_checkpoint()
	_refresh_skill_utility()


func _on_utility_closed() -> void:
	if not _utility_open:
		return
	var closing_boss_support := _utility_mode == "boss_coin"
	_play_ui_sfx(&"cancel")
	_utility_open = false
	_utility_mode = ""
	utility_overlay.hide()
	_session.resume_clock(Time.get_ticks_msec())
	if closing_boss_support and boss_coin_button.visible:
		boss_coin_button.grab_focus()
	else:
		item_tool_button.grab_focus()
	_refresh_ui()


func _on_map_pressed() -> void:
	if _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _travel_menu_open or _map_open or _movement_active or _rolling or _session == null:
		return
	if _session.phase() not in [V06PlaySessionScript.PHASE_READY]:
		return
	_map_clock_pause_owned = _session.pause_clock(Time.get_ticks_msec())
	_save_stable_checkpoint()
	_map_open = true
	_play_ui_sfx(&"open")
	message_band.hide()
	message_label.hide()
	overview_title.text = "全体ミニマップ"
	map_close_button.text = "閉じる"
	overview_atlas_view.set_route_position(_session.position(), true)
	overview_atlas_view.set_overview_mode(true)
	map_overlay.show()
	map_close_button.grab_focus()


func _on_map_closed() -> void:
	if not _map_open:
		return
	var closing_stage_intro := _stage_intro_active
	var owned_pause := _map_clock_pause_owned
	_map_clock_pause_owned = false
	_map_open = false
	_play_ui_sfx(&"close")
	map_overlay.hide()
	overview_atlas_view.cancel_visual_motion(_session.position())
	overview_atlas_view.set_overview_mode(false)
	if closing_stage_intro:
		_stage_intro_active = false
		_movement_active = false
		_play_bgm(&"play_normal_map")
		message_label.text = "カイロの旅を始めよう"
		map_close_button.text = "閉じる"
		overview_title.text = "全体ミニマップ"
		if not _open_start_onboarding_if_eligible() and owned_pause:
			_session.resume_clock(Time.get_ticks_msec())
			die_button.grab_focus()
	else:
		if owned_pause:
			_session.resume_clock(Time.get_ticks_msec())
		map_button.grab_focus()
	_refresh_ui()


func _refresh_ui() -> void:
	if not is_inside_tree() or not is_instance_valid(lap_label) or _session == null:
		return
	if not _qa_hud_override:
		_lap_number = _session.lap()
		_hp_current = _session.player_hp()
		_hp_max = _session.player_max_hp()
		_pb_text = _format_pb_delta(_session.pb_delta_ms(Time.get_ticks_msec()))
		if _session.phase() == V06PlaySessionScript.PHASE_LAP_RESULT and _session.snapshot().pb_updated and _session.pb_delta_ms() == null:
			_pb_text = "NEW"
	lap_label.text = str(_lap_number)
	roll_count_label.text = "ROLLS %d" % _session.roll_count()
	hp_label.text = _heart_text(_hp_current, _hp_max)
	life_label.text = "復活 ×%d" % _session.life()
	if _last_presented_life >= 0 and _session.life() < _last_presented_life:
		_show_operation_message(revival_stamp_text(_session.life()), 1.3, 25)
	_last_presented_life = _session.life()
	pb_label.text = "PB %s" % _pb_text
	if is_instance_valid(atlas_view):
		atlas_view.set_consumed_route_state(_session.consumed_warp_gate_ids(), _session.consumed_reward_node_keys())
		atlas_view.set_loop_rescue_progress(_session.loop_wrap_count(), _session.loop_rescue_threshold())
	if is_instance_valid(overview_atlas_view):
		overview_atlas_view.set_consumed_route_state(_session.consumed_warp_gate_ids(), _session.consumed_reward_node_keys())
		overview_atlas_view.set_loop_rescue_progress(_session.loop_wrap_count(), _session.loop_rescue_threshold())
	_refresh_score_hud()
	_refresh_mission_band()
	best_label.text = _format_score(int(_session.best_score()))
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
	if _session.phase() in [V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED]:
		var result_faces: Variant = _session.boss_result().get("faces", [])
		if result_faces is Array and not (result_faces as Array).is_empty():
			values.assign(result_faces)
	_reset_slot_preview_style()
	for index: int in range(slot_labels.size()):
		slot_labels[index].text = str(values[index]) if index < values.size() else "—"
	_refresh_slot_display(values)
	var phase: StringName = _session.phase()
	_refresh_slot_guidance(values, phase)
	match phase:
		V06PlaySessionScript.PHASE_READY:
			tray_status_label.text = ""
			tray_hint_label.text = ""
			next_need_label.text = ""
			action_hint_label.text = ""
			pass
		V06PlaySessionScript.PHASE_MOVING:
			if _session.pending_resolution_role() != &"":
				tray_status_label.text = ""
				tray_hint_label.text = ""
			else:
				tray_status_label.text = ""
				tray_hint_label.text = ""
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
	if phase == V06PlaySessionScript.PHASE_RUN_OVER and _session.boss_snapshot().is_empty():
		_hide_normal_chrome_for_bossless_run_over()
	if _utility_open or _map_open:
		message_band.hide()
		message_label.hide()
	elif _slot_reach_message_active:
		message_band.show()
		message_label.show()
	elif not boss_active and phase != V06PlaySessionScript.PHASE_RUN_OVER and not _operation_message_override_active:
		_refresh_default_operation_message(phase)
	if _inline_slot_result_active:
		# The inline role/reward replaces the tray copy for this short result;
		# keep the normal phase refresh from re-showing a stale slot header.
		tray_status_label.hide()
		tray_hint_label.hide()
	if phase == V06PlaySessionScript.PHASE_READY and not _inline_slot_result_active:
		tray_status_label.hide()
		tray_hint_label.hide()
		next_need_label.hide()
		action_hint_label.hide()
	item_tool_button.text = "アイテム\n%d / %d" % [_session.inventory_total(), V06PlaySessionScript.ITEM_CAPACITY]
	coin_tool_button.text = "コイン\n%d枚" % _session.coins()
	if _session.pinpoint_face() > 0:
		skill_tool_button.text = "スキル\n出目 %d" % _session.pinpoint_face()
	else:
		skill_tool_button.text = "スキル\nREADY" if _session.skill_gauge() >= V06PlaySessionScript.SKILL_GAUGE_MAX else "スキル\n%d/%d" % [_session.skill_gauge(), V06PlaySessionScript.SKILL_GAUGE_MAX]
	if _rolling:
		die_button.text = "STOP"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT:
		die_button.text = "ROLL"
	elif phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY:
		die_button.text = "ROLL"
	elif phase == V06PlaySessionScript.PHASE_MOVING:
		die_button.text = "移動中…"
	elif _shown_face > 0:
		die_button.text = "%dマス進む" % _shown_face
	else:
		die_button.text = "振る"
	roll_button_copy.text = die_button.text
	_refresh_die_layout(route_id)
	_refresh_die_presentation()
	var boss_result_phase := phase == V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT
	var boss_finished := phase == V06PlaySessionScript.PHASE_BOSS_FINISHED
	die_button.visible = not boss_finished and phase != V06PlaySessionScript.PHASE_RUN_OVER
	die_button.disabled = _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open or _travel_menu_open or _boss_intro_active or _boss_roll_animation_active or boss_finished or _boss_pause_open or _utility_open or _movement_active or (not boss_result_phase and not _rolling and not _session.can_roll())
	boss_pause_button.disabled = boss_finished
	boss_coin_button.text = "支援\n%d枚" % _session.coins()
	boss_coin_button.visible = boss_active and not boss_finished
	boss_coin_button.disabled = _boss_intro_active or _utility_open or not _boss_support_window_open()
	var utility_disabled := _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open or _travel_menu_open or _utility_open or _map_open or _movement_active or phase != V06PlaySessionScript.PHASE_READY
	item_tool_button.disabled = utility_disabled
	coin_tool_button.disabled = utility_disabled
	skill_tool_button.disabled = utility_disabled
	map_button.disabled = _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open or _travel_menu_open or _map_open or _movement_active or _rolling or phase != V06PlaySessionScript.PHASE_READY
	back_button.disabled = _tile_help_open or _three_roll_onboarding_open or _low_hp_warning_open or _event_card_open or _travel_menu_open or _movement_active or _rolling
	_refresh_roll_button_ornament()


func _refresh_mission_band() -> void:
	if _session == null or not is_instance_valid(mission_band):
		return
	var missions: Dictionary = _session.mission_state()
	var active_id := str(missions.get("active_id", ""))
	var gold := Color("#9a6613")
	var active := Color("#342314")
	var failed := Color("#756b5f")
	var mission_style := _panel_style(Color("#f2dfb9"), Color("#946f3d"), 10, 2)
	if _uses_compact_phone_layout():
		mission_style.content_margin_left = 6
		mission_style.content_margin_right = 6
		mission_style.content_margin_top = 0
		mission_style.content_margin_bottom = 0
	mission_band.add_theme_stylebox_override("panel", mission_style)
	mission_header.add_theme_color_override("font_color", Color("#69451e"))
	for cell: PanelContainer in [mission_no_damage_cell, mission_coin_cell, mission_role_cell]:
		cell.add_theme_stylebox_override("panel", _panel_style(Color("#ead3a5"), Color("#b28a50"), 7, 1))
	var active_mission: Dictionary = missions.get("active_mission", {})
	if not active_mission.is_empty():
		# Keep one large featured card. The existing Cairo textures are reused so
		# this remains a common stage pattern without a scene asset fork.
		mission_no_damage_cell.show()
		mission_coin_cell.hide()
		mission_role_cell.hide()
		mission_header.text = "MISSION"
		var mission_kind := str(active_mission.get("kind", "trip"))
		if mission_kind in ["coin", "trip"]:
			mission_shield_icon.texture = mission_coin_icon.texture
		elif mission_kind in ["dice", "slot"]:
			mission_shield_icon.texture = mission_role_icon.texture
		else:
			mission_shield_icon.texture = _mission_shield_texture
		var progress := int(active_mission.get("progress", 0))
		var target := maxi(int(active_mission.get("target", 1)), 1)
		var mission_copy := str(active_mission.get("short_text", active_id))
		if mission_kind == "dice" and bool(active_mission.get("target_face_enabled", false)):
			mission_copy = "DICE %dを%d回出す" % [int(active_mission.get("target_face", 0)), target if active_mission.has("target") else 1]
		var reward := int(active_mission.get("reward_coins", 0))
		mission_no_damage_caption.text = "%s　COIN × %d" % [mission_copy, reward]
		var completed := bool(active_mission.get("completed", false))
		var legacy := bool(active_mission.get("legacy_mode", false))
		var failed_no_damage := mission_kind == "shield" and not bool(missions.get("no_damage_active", true)) and not completed
		if completed:
			mission_no_damage_label.text = "✓ CLEAR!　獲得 COIN +%d" % reward
			mission_no_damage_label.add_theme_color_override("font_color", gold)
		elif failed_no_damage:
			mission_no_damage_label.text = "失敗　今周は終了"
			mission_no_damage_label.add_theme_color_override("font_color", failed)
		else:
			mission_no_damage_label.text = "進捗 %d/%d　%s%s" % [progress, target, _mission_progress_dots(progress, target), "　旧仕様" if legacy else ""]
			mission_no_damage_label.add_theme_color_override("font_color", active)
		var serial := int(missions.get("event_serial", 0))
		if serial > _mission_seen_event_serial:
			_mission_seen_event_serial = serial
			_show_mission_toast(missions.get("last_event", {}) as Dictionary)
		return
	# Defensive fallback for a malformed/very old state: retain the old rows
	# rather than leaving the band blank.
	var no_damage_completed := bool(missions.get("no_damage_completed", false))
	var no_damage_active := bool(missions.get("no_damage_active", true))
	mission_no_damage_label.text = "✓ 達成" if no_damage_completed else ("継続中" if no_damage_active else "失敗")
	mission_no_damage_label.add_theme_color_override("font_color", gold if no_damage_completed else (active if no_damage_active else failed))
	var coin_completed := bool(missions.get("coin_completed", false))
	mission_coin_label.text = "✓ COIN +12" if coin_completed else "COIN %d/12" % mini(int(missions.get("coin_gained", 0)), V06PlaySessionScript.MISSION_COIN_TARGET)
	mission_coin_label.add_theme_color_override("font_color", gold if coin_completed else active)
	var role_completed := bool(missions.get("role_completed", false))
	mission_role_label.text = "✓ 達成" if role_completed else "%d/5" % mini(int(missions.get("role_successes", 0)), V06PlaySessionScript.MISSION_ROLE_TARGET)
	mission_role_label.add_theme_color_override("font_color", gold if role_completed else active)
	var serial := int(missions.get("event_serial", 0))
	if serial > _mission_seen_event_serial:
		_mission_seen_event_serial = serial
		_show_mission_toast(missions.get("last_event", {}) as Dictionary)


func _mission_progress_dots(progress: int, target: int) -> String:
	var total := maxi(target, 1)
	var filled := clampi(progress, 0, total)
	return "●".repeat(filled) + "○".repeat(total - filled)


func _show_mission_toast(event: Dictionary) -> void:
	if event.is_empty():
		return
	var kind := str(event.get("kind", ""))
	var completed := bool(event.get("completed", false))
	if completed:
		_emit_feedback(V06FeedbackControllerScript.EVENT_MISSION_COMPLETE)
	elif kind == "no_damage":
		_emit_feedback(V06FeedbackControllerScript.EVENT_DAMAGE)
	else:
		_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)
	var missions: Dictionary = _session.mission_state()
	var active_mission: Dictionary = missions.get("active_mission", {})
	if active_mission.is_empty():
		return
	var target_cell: PanelContainer = mission_no_damage_cell
	var short_text := str(active_mission.get("short_text", "MISSION"))
	var progress := int(active_mission.get("progress", 0))
	var target := maxi(int(active_mission.get("target", 1)), 1)
	var reward := int(active_mission.get("reward_coins", 0))
	if completed:
		mission_toast_label.text = "MISSION CLEAR!　%s\nCOIN +%d" % [short_text, reward]
	elif kind == "no_damage":
		mission_toast_label.text = "MISSION FAILED　%s" % short_text
	else:
		mission_toast_label.text = "MISSION　%s　%d/%d" % [short_text, progress, target]
	mission_toast.hide()
	_show_operation_message(mission_toast_label.text, 1.2, 25)
	_flash_mission_cell(target_cell, completed)
	_mission_toast_generation += 1


func _hide_mission_toast_after_delay(generation: int) -> void:
	await get_tree().create_timer(1.0).timeout
	if generation == _mission_toast_generation and is_instance_valid(mission_toast):
		mission_toast.hide()


func _flash_mission_cell(cell: PanelContainer, completed: bool) -> void:
	if not is_instance_valid(cell):
		return
	cell.pivot_offset = cell.size * 0.5
	cell.scale = Vector2.ONE
	cell.self_modulate = Color.WHITE
	var flash := create_tween()
	flash.tween_property(cell, "self_modulate", Color("#ffe19a") if completed else Color("#fff3cf"), 0.10)
	flash.parallel().tween_property(cell, "scale", Vector2.ONE * 1.035, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flash.tween_interval(0.34)
	flash.tween_property(cell, "self_modulate", Color.WHITE, 0.22)
	flash.parallel().tween_property(cell, "scale", Vector2.ONE, 0.22)


func _set_boss_chrome_active(active: bool) -> void:
	if not is_instance_valid(normal_hud_panel) or not is_instance_valid(normal_stage_band) or not is_instance_valid(normal_tool_dock):
		return
	normal_hud_panel.visible = not active
	normal_stage_band.visible = not active
	normal_tool_dock.visible = not active
	dice_presentation.visible = not active
	if active:
		dice_presentation.present([], false, 0)
		die_hero_art.hide()
		message_band.hide()
		message_label.hide()
	else:
		boss_dice_presentation.present([], false, 0)
		boss_dice_presentation.hide()
		boss_dice_owner_label.hide()
		message_band.show()
		message_label.show()
	boss_hud.visible = active
	var tray_panel := %TrayPanel as Control
	tray_panel.show()
	mission_band.visible = not active
	var roll_row := $SafeMargin/Page/TrayPanel/TrayContent/RollRow as Control
	var action_column := $SafeMargin/Page/TrayPanel/TrayContent/RollRow/ActionColumn as Control
	if active:
		_apply_boss_tray_styles()
		tray_panel.custom_minimum_size.y = 252.0
		roll_row.custom_minimum_size.y = 190.0
		roll_row.alignment = BoxContainer.ALIGNMENT_END
		action_column.custom_minimum_size = Vector2(190.0, 190.0)
		die_button.custom_minimum_size = Vector2(190.0, 190.0)
		roll_button_die_icon.show()
		roll_button_copy.offset_top = 122.0
		roll_button_copy.offset_bottom = -15.0
		if not _rolling and _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and _shown_face <= 0:
			var die_x := maxf((race_stage.size.x - boss_dice_presentation.size.x) * 0.5, 0.0)
			boss_dice_presentation.position = Vector2(die_x, _boss_dice_rest_y())
			boss_dice_shadow.position = Vector2(die_x + 5.0, boss_dice_presentation.position.y + BOSS_DICE_SHADOW_OFFSET_Y)
			boss_dice_owner_label.position.x = die_x + 11.0
		tray_status_label.hide()
		tray_hint_label.hide()
		slot_column.show()
		action_hint_label.hide()
		die_hero_art.hide()
	else:
		_apply_normal_tray_styles()
		tray_panel.custom_minimum_size.y = 224.0
		roll_row.custom_minimum_size.y = 190.0
		roll_row.alignment = BoxContainer.ALIGNMENT_CENTER
		action_column.custom_minimum_size = Vector2(190.0, 190.0)
		die_button.custom_minimum_size = Vector2(190.0, 190.0)
		roll_button_die_icon.show()
		roll_button_copy.offset_top = 122.0
		roll_button_copy.offset_bottom = -15.0
		tray_status_label.hide()
		slot_column.show()
		if _boss_pause_open:
			_boss_pause_open = false
			boss_pause_overlay.hide()


func _hide_normal_chrome_for_bossless_run_over() -> void:
	normal_hud_panel.hide()
	normal_stage_band.hide()
	normal_tool_dock.hide()
	mission_band.hide()
	message_band.hide()
	message_label.hide()
	dice_presentation.hide()
	die_hero_art.hide()
	(%TrayPanel as Control).hide()


func _refresh_slot_guidance(values: Array[int], phase: StringName) -> void:
	if _inline_slot_result_active:
		_slot_reach_message_active = false
		# The role line is the inline result itself.  A phase refresh can run
		# while the short result is held, so preserve its text/style and hide only
		# the auxiliary guidance rows that would compete with the reward.
		role_label.add_theme_color_override("font_color", Color("#167f82"))
		role_label.show()
		_place_inline_result_labels()
		next_need_label.hide()
		action_hint_label.hide()
		return
	if phase in [V06PlaySessionScript.PHASE_BOSS_ROLL_READY, V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT]:
		role_reward_label.hide()
		var reach := _boss_slot_reach(values) if phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY else {}
		if not reach.is_empty():
			_show_boss_reach_cue(reach)
		else:
			_boss_reach_signature = ""
			_slot_reach_message_active = false
			role_label.hide()
		next_need_label.hide()
		action_hint_label.hide()
		return
	if phase == V06PlaySessionScript.PHASE_READY:
		var normal_reach := _normal_slot_reach(values)
		if not normal_reach.is_empty():
			_show_slot_reach_cue(normal_reach)
			return
	_boss_reach_signature = ""
	_slot_reach_message_active = false
	role_label.hide()
	role_reward_label.hide()
	next_need_label.hide()
	action_hint_label.hide()
	return


func _boss_slot_reach(values: Array[int]) -> Dictionary:
	if values.size() != 2:
		return {}
	var first := values[0]
	var second := values[1]
	if first == second:
		return {"role": "TRIPLE", "targets": [first], "hint": "同じ %d が出れば必殺！　+5マス＆ボス1回休み" % first, "boss": true}
	var targets: Array[int] = []
	var step := second - first
	if absi(step) == 1:
		var candidate := second + step
		if candidate >= 1 and candidate <= 6:
			targets.append(candidate)
	if targets.is_empty():
		return {}
	var target_labels := PackedStringArray()
	for target: int in targets:
		target_labels.append(str(target))
	return {"role": "STRAIGHT", "targets": targets, "hint": "%s が出れば加速！　さらに3マス" % "/".join(target_labels), "boss": true}


func _normal_slot_reach(values: Array[int]) -> Dictionary:
	if values.size() != 2 or _session == null:
		return {}
	var first := values[0]
	var second := values[1]
	var role := "PAIR"
	var targets: Array[int] = [first, second]
	var fallback_targets: Array[int] = []
	if first == second:
		role = "TRIPLE"
		targets = [first]
	else:
		var step := second - first
		if absi(step) == 1:
			var candidate := second + step
			if candidate >= 1 and candidate <= 6:
				role = "STRAIGHT"
				targets = [candidate]
				fallback_targets = [first, second]
		else:
			var map_only_rows := _normal_map_mission_rows(_session.mission_state().get("active_mission", {}), 0)
			if map_only_rows.is_empty():
				return {}
			return {"role": "", "targets": [], "fallback_targets": [], "rows": map_only_rows.slice(0, 2), "hint": "\n".join(map_only_rows.slice(0, 2)), "coin_reward": 0, "mission_overlap": false, "boss": false}
	var mission: Dictionary = _session.mission_state() if _session != null else {}
	var active_mission: Dictionary = mission.get("active_mission", {})
	var overlap := false
	var fallback_overlap := false
	var mission_face := 0
	var mission_role := ""
	var mission_is_target_face := bool(active_mission.get("target_face_enabled", false))
	if mission_is_target_face:
		mission_face = int(active_mission.get("target_face", 0))
		overlap = mission_face in targets
		fallback_overlap = not overlap and mission_face in fallback_targets
	elif str(active_mission.get("kind", "")) == "slot":
		mission_role = str(active_mission.get("target_role", ""))
		overlap = mission_role == role
	var labels := PackedStringArray()
	for target: int in targets: labels.append(str(target))
	var reward := 5 if role == "TRIPLE" else (3 if role == "STRAIGHT" else 1)
	var slot_row := "SLOT %s → %s　COIN +%d" % ["/".join(labels), role, reward]
	var rows: Array[String] = []
	var map_rows: Array[String] = _normal_map_mission_rows(active_mission, mission_face)
	var slot_line := slot_row
	if overlap:
		var mission_target := str(mission_face) if mission_face > 0 else mission_role
		rows.append("MISSION %s → ダブルチャンス　%s　COIN +%d" % [mission_target, role, reward])
	elif fallback_overlap:
		rows.append(slot_row)
		rows.append("MISSION %d → PAIR　COIN +1" % mission_face)
	elif not fallback_targets.is_empty():
		rows.append(slot_row)
		if mission_is_target_face and mission_face > 0:
			rows.append("DICE %d → MISSION %d/%d" % [mission_face, int(active_mission.get("progress", 0)), maxi(int(active_mission.get("target", 1)), 1)])
		else:
			var fallback_labels := PackedStringArray()
			for fallback_target: int in fallback_targets:
				fallback_labels.append(str(fallback_target))
			rows.append("SLOT %s → PAIR　COIN +1" % "/".join(fallback_labels))
	# Explicit precedence: ALL MATCH, MISSION+SLOT, MISSION+MAP, SLOT+MAP.
	if overlap and not map_rows.is_empty():
		rows = ["ALL MATCH　MISSION + %s + MAP　COIN +%d" % [role, reward]]
	elif overlap or fallback_overlap:
		pass
	elif not map_rows.is_empty():
		rows = [slot_line]
		rows.append_array(map_rows)
	elif rows.is_empty():
		rows = [slot_line]
	rows = rows.slice(0, 2)
	var hint := "\n".join(rows)
	return {"role": role, "targets": targets, "fallback_targets": fallback_targets, "rows": rows, "hint": hint, "coin_reward": reward, "mission_overlap": overlap or fallback_overlap, "boss": false}


func _normal_map_mission_rows(active_mission: Dictionary, mission_face: int = 0) -> Array[String]:
	if _session == null:
		return []
	var wanted := str(active_mission.get("short_text", ""))
	var previews: Array[Dictionary] = _session.preview_forward_landings()
	var rows: Array[String] = []
	for preview: Dictionary in previews:
		var kind := str(preview.get("raw_tile_kind", preview.get("tile_kind", "")))
		var mission_map_match := str(active_mission.get("kind", "")) == "map" and wanted.to_upper().contains(kind)
		var dice_map_match := bool(active_mission.get("target_face_enabled", false)) and mission_face > 0 and int(preview.get("distance", 0)) == mission_face and kind in ["COIN", "RISK", "ITEM"]
		if kind.is_empty() or not mission_map_match and not dice_map_match:
			continue
		var distance := int(preview.get("distance", 0))
		rows.append("%s +%d → %s MISSION" % [kind, distance, kind])
		if rows.size() >= 2:
			break
	return rows


func _show_boss_reach_cue(reach: Dictionary) -> void:
	_show_slot_reach_cue(reach)


func _show_slot_reach_cue(reach: Dictionary) -> void:
	var role := str(reach.get("role", ""))
	var signature := "%s:%s:%s" % [role, str(reach.get("targets", [])), str(reach.get("fallback_targets", []))]
	role_label.hide()
	role_reward_label.hide()
	_slot_reach_message_active = true
	message_band.show()
	message_label.show()
	if bool(reach.get("boss", false)):
		message_label.text = "%sリーチ！　%s" % [role, str(reach.get("hint", ""))]
		message_label.add_theme_font_size_override("font_size", 27)
	else:
		message_label.text = str(reach.get("hint", ""))
		message_label.add_theme_font_size_override("font_size", 26)
	if signature == _boss_reach_signature:
		return
	_boss_reach_signature = signature
	_show_slot_snap_sparkle(0.9)
	_flash_slot_panels([0, 1], SLOT_RESULT_STRONG_GLOW if role == "TRIPLE" else SLOT_RESULT_GLOW, 1.045)
	message_label.pivot_offset = message_label.size * 0.5
	message_label.scale = Vector2.ONE * 0.94
	var cue := create_tween()
	cue.tween_property(message_label, "scale", Vector2.ONE * 1.035, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cue.tween_property(message_label, "scale", Vector2.ONE, 0.18)


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
	var boss_roll: bool = _session.phase() == V06PlaySessionScript.PHASE_BOSS_ROLL_READY
	var visual_elapsed := scaled_dice_roll_elapsed(_rolling_slot_elapsed, boss_roll, _session.lap())
	_rolling_slot_face = DicePresentation3DScript.rolling_face_for_elapsed(visual_elapsed)
	slot_labels[next_slot].text = str(_rolling_slot_face)
	slot_labels[next_slot].modulate = Color(1.0, 1.0, 1.0, 0.42)
	if boss_roll:
		dice_presentation.present([], false, 0)
		boss_dice_presentation.present([_rolling_slot_face], true, 0)
		boss_dice_presentation.sync_rolling_elapsed(visual_elapsed)
		_refresh_boss_landing_preview(_rolling_slot_face)
	else:
		dice_presentation.present([_rolling_slot_face], true, 0)
		dice_presentation.sync_rolling_elapsed(visual_elapsed)


static func boss_dice_speed_scale_for_lap(lap: int) -> float:
	return minf(BOSS_DICE_ROLL_SPEED_SCALE + float(maxi(lap - 1, 0)) * BOSS_DICE_LAP_SPEED_STEP, BOSS_DICE_MAX_SPEED_SCALE)


static func scaled_dice_roll_elapsed(elapsed: float, boss_roll: bool, lap: int = 1) -> float:
	var speed_scale := boss_dice_speed_scale_for_lap(lap) if boss_roll else NORMAL_DICE_ROLL_SPEED_SCALE
	return maxf(elapsed, 0.0) * speed_scale


static func heart_roulette_step_seconds_for_margin(margin_spaces: int) -> float:
	var weight := clampf(float(maxi(margin_spaces, 0)) / HEART_ROULETTE_SLOW_MARGIN_SPACES, 0.0, 1.0)
	return lerpf(HEART_ROULETTE_FAST_STEP_SECONDS, HEART_ROULETTE_SLOW_STEP_SECONDS, weight)


func _heart_roulette_step_seconds() -> float:
	if _session == null:
		return HEART_ROULETTE_FAST_STEP_SECONDS
	var result: Dictionary = _session.boss_result()
	var margin := absi(int(result.get("player_final_position", 0)) - int(result.get("boss_final_position", 0)))
	return heart_roulette_step_seconds_for_margin(margin)


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
	_clear_boss_pictogram_anchors()


func _position_boss_landing_ring(ring: PanelContainer, value_label: Label, position: int, is_player: bool, text: String) -> void:
	var goal := int(_session.boss_snapshot().get("course_length", 20))
	var point := _boss_lane_point(position, is_player, goal)
	value_label.text = text
	ring.position = point - Vector2(ring.size.x * 0.5, ring.size.y * 0.5)
	ring.show()


func _set_target_pictogram(pictogram: TextureRect, tile: String, position: int, is_player: bool) -> void:
	pictogram.visible = tile in ["WING_GATE", "QUICKSAND"]
	if not pictogram.visible:
		_boss_pictogram_anchors.erase(pictogram)
		return
	pictogram.scale = Vector2.ONE
	pictogram.texture = WING_GATE_PICTOGRAM if tile == "WING_GATE" else QUICKSAND_PICTOGRAM
	var value_label := pictogram.get_child(0) as Label
	value_label.text = "+3" if tile == "WING_GATE" else "−2"
	_boss_pictogram_anchors[pictogram] = {"position": float(position), "is_player": is_player}
	var point := _boss_lane_point(position, is_player, int(_session.boss_snapshot().get("course_length", 20)))
	pictogram.position = point + Vector2(-pictogram.size.x * 0.5, -pictogram.size.y - 24.0)


func _sync_boss_pictogram_anchors() -> void:
	for pictogram: TextureRect in [boost_pictogram, sand_pictogram]:
		if not pictogram.visible or not _boss_pictogram_anchors.has(pictogram):
			continue
		var anchor: Dictionary = _boss_pictogram_anchors[pictogram]
		var point: Vector2 = boss_lane_board.lane_point(float(anchor.position), bool(anchor.is_player))
		pictogram.position = point + Vector2(-pictogram.size.x * 0.5, -pictogram.size.y - 24.0)


func _clear_boss_pictogram_anchors() -> void:
	_boss_pictogram_anchors.clear()


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


func _show_slot_snap_sparkle(strength: float = 1.0) -> void:
	if not is_instance_valid(slot_snap_sparkle) or not slot_column.visible:
		return
	slot_snap_sparkle.pivot_offset = slot_snap_sparkle.size * 0.5
	slot_snap_sparkle.modulate = Color(1.0, 1.0, 1.0, 0.0)
	slot_snap_sparkle.scale = Vector2(0.82, 0.82)
	slot_snap_sparkle.show()
	var flash := create_tween()
	flash.tween_property(slot_snap_sparkle, "modulate:a", clampf(strength, 0.0, 1.0), 0.08)
	flash.parallel().tween_property(slot_snap_sparkle, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flash.tween_interval(0.12)
	flash.tween_property(slot_snap_sparkle, "modulate:a", 0.0, 0.24)
	flash.parallel().tween_property(slot_snap_sparkle, "scale", Vector2.ONE * 1.12, 0.24)
	flash.tween_callback(slot_snap_sparkle.hide)


func _play_inline_slot_result(role: String, face: int, motion_generation: int) -> void:
	_inline_slot_result_active = true
	_refresh_roll_button_ornament()
	var values: Array[int] = _session.faces()
	if values.size() < 3:
		values.append(face)
	var spec := inline_slot_result_spec(role, values)
	role_label.text = "%s！" % _display_role(role)
	role_label.add_theme_font_size_override("font_size", 20)
	role_label.add_theme_color_override("font_color", Color("#167f82"))
	role_reward_label.text = str(spec.reward)
	role_reward_label.add_theme_font_size_override("font_size", 24)
	role_reward_label.show()
	role_label.show()
	_refresh_inline_slot_layout()
	tray_status_label.text = "3 ROLL SLOT　　%d / 3" % _slot_fill_count(values)
	tray_status_label.text = ""
	tray_status_label.hide()
	if String(spec.reward).contains("ゲージ") or String(spec.reward).contains("READY"):
		skill_tool_button.text = "スキル\n" + ("READY" if String(spec.reward).contains("READY") else "%d/%d" % [_session.skill_gauge(), V06PlaySessionScript.SKILL_GAUGE_MAX])
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
	_show_slot_snap_sparkle(1.0 if indices.size() >= slot_panels.size() else 0.66)
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
			return "COIN +1"
		"STRAIGHT":
			return "COIN +3"
		"TRIPLE":
			return "COIN +5"
		_:
			return "報酬なし"


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
	_refresh_roll_button_ornament()
	if is_instance_valid(role_reward_label):
		role_reward_label.hide()
	if is_instance_valid(role_label):
		role_label.remove_theme_font_size_override("font_size")
		role_label.hide()
	if is_instance_valid(role_reward_label):
		role_reward_label.remove_theme_font_size_override("font_size")
	if is_instance_valid(tray_status_label):
		tray_status_label.hide()
	if is_instance_valid(pair_link):
		pair_link.hide()
	for panel: PanelContainer in slot_panels:
		panel.scale = Vector2.ONE
		panel.self_modulate = Color.WHITE
	_refresh_inline_slot_layout()


func _reset_move_announcement_style() -> void:
	if not is_instance_valid(message_label):
		return
	message_label.remove_theme_font_size_override("font_size")
	message_label.scale = Vector2.ONE
	_distance_announcement_active = false


func _present_move_announcement(move_distance: int, motion_generation: int, face := 0) -> void:
	_distance_announcement_active = true
	var distance := maxi(move_distance, 0)
	var modifier := distance - face if face > 0 else 0
	var copy := "%dマス進む！" % distance
	if modifier > 0:
		copy = "%d＋%d＝%dマス進む！" % [face, modifier, distance]
	elif modifier < 0:
		copy = "%d−%d＝%dマス進む！" % [face, abs(modifier), distance]
	_show_operation_message(copy, 1.0, 42)


func _show_operation_message(text: String, duration := 0.0, font_size := 26) -> void:
	if not is_instance_valid(message_band) or not is_instance_valid(message_label):
		return
	_operation_message_generation += 1
	var generation := _operation_message_generation
	_operation_message_override_active = duration > 0.0
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", font_size)
	message_label.scale = Vector2.ONE
	message_label.modulate = Color.WHITE
	if _utility_open or _map_open:
		message_band.hide()
		message_label.hide()
	else:
		message_band.show()
		message_label.show()
	if duration <= 0.0:
		return
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if generation != _operation_message_generation or not is_instance_valid(message_label):
			return
		_operation_message_override_active = false
		_reset_move_announcement_style()
		if _session != null:
			_refresh_default_operation_message(_session.phase())
	)


func _refresh_default_operation_message(phase: StringName) -> void:
	if _rolling:
		_show_operation_message("STOPで決定　／　下の道具で準備に戻る", 0.0, 24)
		return
	match phase:
		V06PlaySessionScript.PHASE_READY:
			_show_operation_message("サイコロを振ろう")
		V06PlaySessionScript.PHASE_MOVING:
			_show_operation_message("プレイヤーが移動中…")
		V06PlaySessionScript.PHASE_CHOICE_REQUIRED:
			_show_operation_message("進むルートを選ぼう")
		V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
			_show_operation_message("次の3投を始めよう")
		_:
			_show_operation_message("旅を続けよう")


func _refresh_die_presentation() -> void:
	if not is_instance_valid(dice_presentation) or _session == null:
		return
	var phase: StringName = _session.phase()
	var boss_active: bool = not _session.boss_snapshot().is_empty() and phase in [
		V06PlaySessionScript.PHASE_BOSS_ROLL_READY,
		V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT,
		V06PlaySessionScript.PHASE_BOSS_FINISHED,
		V06PlaySessionScript.PHASE_LAP_RESULT,
		V06PlaySessionScript.PHASE_RUN_OVER,
	]
	# Use the simple 3D die for every normal-map state so rolling and settling
	# remain visible.  The antique raster stays available for the roll button,
	# but is hidden here to avoid a duplicate die over the map.
	var hero_visible := false
	die_hero_art.visible = hero_visible
	dice_presentation.visible = not boss_active
	if boss_active:
		dice_presentation.present([], false, 0)
	else:
		var display_face := _shown_face if _shown_face > 0 else 6
		dice_presentation.present([display_face], _rolling, 0 if _rolling else 1)
		dice_presentation.pivot_offset = dice_presentation.size * 0.5
		var target_scale := 1.08 if _rolling else (1.05 if _shown_face > 0 and _movement_active else 1.0)
		dice_presentation.scale = Vector2.ONE * target_scale
	if boss_active and is_instance_valid(boss_dice_presentation):
		var boss_face := _boss_display_face()
		boss_dice_presentation.present([boss_face], _rolling, 0 if _rolling else 1)
	elif is_instance_valid(boss_dice_presentation):
		boss_dice_presentation.present([], false, 0)
		boss_dice_presentation.hide()


func _boss_display_face() -> int:
	if _rolling:
		return clampi(_rolling_slot_face, 1, 6)
	if _shown_face > 0:
		return clampi(_shown_face, 1, 6)
	if _session != null:
		var result: Dictionary = _session.boss_result()
		var result_face := int(result.get("player_roll", 0))
		if result_face > 0:
			return clampi(result_face, 1, 6)
		var boss: Dictionary = _session.boss_snapshot()
		var history: Array = boss.get("player_roll_history", [])
		if not history.is_empty():
			return clampi(int(history.back()), 1, 6)
	return 1


func die_anchor_for_route(route_id: String) -> Vector2:
	return DICE_ANCHOR_LOOP if route_id in [V06CourseModelScript.ROUTE_LOOP_OASIS, V06CourseModelScript.ROUTE_LOOP_TOMB] else DICE_ANCHOR_NORMAL


func _refresh_die_layout(route_id: String) -> void:
	if not is_instance_valid(dice_presentation):
		return
	var anchor := die_anchor_for_route(route_id)
	for die_view: Control in [dice_presentation, die_hero_art]:
		die_view.anchor_left = anchor.x
		die_view.anchor_right = anchor.x
		die_view.anchor_top = anchor.y
		die_view.anchor_bottom = anchor.y


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
		"START": return "旅のスタート"
		"COIN": return "コイン"
		"ITEM": return "道具"
		"EVENT": return "？ 出来事"
		"REST": return "♥ 回復"
		"RISK": return "⚠ 危険"
		"BYPASS_FORK": return "近道を選ぶ"
		"WARP_OASIS", "WARP_TOMB", "WARP_GOLD": return "別ルートへ"
		"LOOP_ENTRY", "LOOP_ENTRY_GOLD": return "環状ルート"
		"EXIT_GATE": return "出口"
		"BOSS_GATE": return "ボスへ"
		_: return "旅路"


func _configure_route_choice() -> void:
	var bypass: Dictionary = _session.pending_bypass()
	if bypass.is_empty():
		return
	var saved_steps := int(bypass.get("saved_steps", 0))
	var route_id := str(bypass.get("route_id", ""))
	var risk_count := 0
	var rest_count := 0
	if route_id == V06CourseModelScript.ROUTE_BYPASS_BAZAAR:
		risk_count = 2
		rest_count = 1
	elif route_id == V06CourseModelScript.ROUTE_BYPASS_SIROCCO:
		risk_count = 3
		rest_count = 2
	var standard_distance := int(bypass.get("standard_distance", saved_steps * 2))
	var bypass_distance := int(bypass.get("bypass_distance", maxi(standard_distance - saved_steps, 1)))
	var previews: Dictionary = _session.route_choice_previews()
	var main_preview: Dictionary = previews.get(V06CourseModelScript.ROUTE_MAIN, {})
	var bypass_preview: Dictionary = previews.get(route_id, {})
	choice_roll_label.text = "出目 %d　→　分岐から あと%dマス" % [_session.pending_face(), _session.pending_remaining_steps()]
	choice_detail_label.text = "本線 %dマス ↔ %s %dマス（%dマス短縮）\n光る輪が今回の着地点" % [standard_distance, str(bypass.get("name_ja", "近道")), bypass_distance, saved_steps]
	choice_main_button.text = "本線　→　%s" % _route_choice_target_text(main_preview, "安全寄り")
	choice_bypass_button.text = "近道　⚠%d ↔ ♥%d　→ %s" % [risk_count, rest_count, _route_choice_target_text(bypass_preview, "危険と回復が交互")]
	choice_bypass_button.disabled = false
	choice_bypass_button.tooltip_text = "コイン不要・%dマス短縮" % saved_steps
	branch_choice_atlas_view.set_consumed_route_state(_session.consumed_warp_gate_ids(), _session.consumed_reward_node_keys())
	branch_choice_atlas_view.show_branch_comparison(route_id, previews)
	for connection: Dictionary in choice_bypass_button.pressed.get_connections():
		choice_bypass_button.pressed.disconnect(connection.callable)
	choice_bypass_button.pressed.connect(_on_route_chosen.bind(route_id))


func _route_choice_target_text(preview: Dictionary, fallback: String) -> String:
	if preview.is_empty():
		return fallback
	var position: Dictionary = preview.get("position", {})
	var route_id := str(position.get("route_id", ""))
	var tile_index := int(position.get("tile_index", -1))
	var location := "本線 %d" % tile_index if route_id == V06CourseModelScript.ROUTE_MAIN else "近道 %d" % (tile_index + 1)
	return "%s［%s］" % [location, _tile_kind_display(str(preview.get("tile_kind", "NORMAL")))]


func _apply_surface_styles() -> void:
	%HudPanel.add_theme_stylebox_override("panel", _panel_style(Color("#172625"), Color("#b88a46"), 22, 4))
	%StageBand.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#8d683b"), 8, 2))
	%AtlasFrame.add_theme_stylebox_override("panel", _panel_style(Color("#e8d7b5"), Color("#9c7742"), 12, 4))
	%MessageBand.add_theme_stylebox_override("panel", _panel_style(Color("#352015"), Color("#d1a14b"), 12, 2))
	_apply_normal_tray_styles()
	var tool_dock_style := _panel_style(Color("#241813"), Color("#8d683b"), 18, 3)
	tool_dock_style.content_margin_top = 8
	tool_dock_style.content_margin_bottom = 8
	%ToolDock.add_theme_stylebox_override("panel", tool_dock_style)
	for modal_panel: PanelContainer in [%ChoicePanel, %ResolutionPanel, %UtilityPanel]:
		modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f1e2c2"), Color("#9b743d"), 22, 4))
	travel_menu_panel.add_theme_stylebox_override("panel", _panel_style(Color("#102a2a"), Color("#d6a84f"), 24, 4))
	landing_art_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f1e2c2"), Color("#9b743d"), 22, 4))
	%BossPanel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	%BossHud.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.07, 0.08, 0.96), Color("#d6a84f"), 18, 3))
	low_hp_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f5dfbd"), Color("#b9402f"), 24, 5))
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
	var empty_roll_style := StyleBoxEmpty.new()
	for state_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		die_button.add_theme_stylebox_override(state_name, empty_roll_style)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		die_button.add_theme_color_override(color_name, Color(1.0, 1.0, 1.0, 0.0))
	for button: Button in [item_tool_button, coin_tool_button, boss_coin_button, skill_tool_button, back_button, utility_close_button, travel_menu_continue_button, travel_menu_exit_button, choice_main_button, choice_bypass_button, resolution_ack_button, low_hp_close_button, boss_round_ack_button, next_lap_button, retry_button, landing_paid_action_button, boss_pause_button, boss_resume_button, boss_back_button]:
		button.custom_minimum_size.y = UiTokensScript.TOUCH_MIN
	back_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	travel_menu_continue_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	travel_menu_exit_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	item_tool_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	coin_tool_button.theme_type_variation = UiThemeNamesScript.SELECTED_BUTTON
	boss_coin_button.theme_type_variation = UiThemeNamesScript.SELECTED_BUTTON
	low_hp_close_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	skill_tool_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	utility_close_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	choice_main_button.theme_type_variation = UiThemeNamesScript.SELECTED_BUTTON
	choice_bypass_button.theme_type_variation = UiThemeNamesScript.DANGER_BUTTON
	resolution_ack_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	boss_round_ack_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	next_lap_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	retry_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	landing_paid_action_button.theme_type_variation = UiThemeNamesScript.SELECTED_BUTTON
	boss_pause_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON
	boss_resume_button.theme_type_variation = UiThemeNamesScript.PRIMARY_BUTTON
	boss_back_button.theme_type_variation = UiThemeNamesScript.SECONDARY_BUTTON


func _apply_normal_tray_styles() -> void:
	%TrayPanel.add_theme_stylebox_override("panel", _panel_style(Color("#ead9b7"), Color("#b88a46"), 24, 5))
	%TrayPanel.modulate = Color.WHITE
	%SlotColumn.modulate = Color.WHITE
	%SlotTrayArt.modulate = Color.WHITE
	roll_button_ornament.self_modulate = Color.WHITE
	die_hero_art.modulate = Color.WHITE
	for slot_panel: PanelContainer in slot_panels:
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
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
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
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
		score_delta_label.text = "+%d マス" % delta
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
		boss_start_rule_dismiss_layer.hide()
		if phase == V06PlaySessionScript.PHASE_RUN_OVER:
			race_stage.hide()
			boss_start_rule_panel.hide()
			boss_quick_rule_panel.hide()
			mirror_panel.hide()
			%MirrorPairsLabel.hide()
			player_landing_ring.hide()
			boss_landing_ring.hide()
			boost_pictogram.hide()
			sand_pictogram.hide()
			boss_player_target_label.hide()
			boss_sphinx_target_label.hide()
			for marker: Label in boss_forward_step_labels:
				marker.hide()
			boss_pause_button.hide()
			boss_dice_presentation.hide()
			boss_dice_owner_label.hide()
			boss_sequence_art.hide()
			postcard_art.hide()
			boss_title.text = "GAME OVER"
			boss_result_label.add_theme_font_size_override("font_size", 20)
			boss_result_label.text = _run_over_result_text()
			boss_result_label.show()
			next_lap_button.hide()
			retry_button.show()
			boss_back_button.hide()
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
	boss_action_label.text = "① サイコロの表があなた、裏がボス\n　 1↔6　2↔5　3↔4\n② 翼に止まると +3マス / 流砂は −2マス\n③ 3投の数字で役を作ろう\n　 PAIR＝盾：次のボス移動を半分\n　 STRAIGHT＝加速：さらに3マス\n　 TRIPLE＝必殺：さらに5マス＋ボス1回休み"
	var boss_finished := phase == V06PlaySessionScript.PHASE_BOSS_FINISHED
	var finish_presented := boss_finished and not _boss_roll_animation_active
	var terminal_result := phase in [V06PlaySessionScript.PHASE_LAP_RESULT, V06PlaySessionScript.PHASE_RUN_OVER]
	var bossless_run_over := phase == V06PlaySessionScript.PHASE_RUN_OVER and boss.is_empty()
	var player_history: Array = boss.get("player_roll_history", [])
	var boss_history: Array = boss.get("boss_roll_history", [])
	var intro_visible := not terminal_result and player_history.is_empty() and phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and not _rolling and not _boss_intro_complete
	var detailed_intro: bool = intro_visible and int(_session.lap()) <= 1
	var boss_result_snapshot: Dictionary = _session.boss_result()
	var outcome_victory := bool(boss_result_snapshot.get("victory", false)) if not boss_result_snapshot.is_empty() else _boss_goal_victory
	if intro_visible:
		_begin_boss_intro_if_needed()
	boss_hp_label.hide()
	boss_race_track_label.hide()
	boss_pause_button.text = "PAUSE"
	race_stage.visible = not terminal_result and not finish_presented
	boss_start_rule_panel.visible = detailed_intro
	boss_start_rule_dismiss_layer.visible = detailed_intro
	boss_quick_rule_panel.visible = intro_visible and not detailed_intro
	boss_action_label.visible = detailed_intro
	mirror_panel.visible = _boss_mirror_values_visible and not intro_visible and not terminal_result and not finish_presented
	boss_pause_button.visible = not finish_presented and not bossless_run_over
	boss_dice_presentation.visible = not finish_presented and not bossless_run_over
	boss_sequence_art.hide()
	postcard_art.hide()
	if detailed_intro:
		# The rule panel already carries a compact Sphinx portrait. Keeping the
		# large start art hidden here prevents its higher z-index from covering
		# the explanation on narrow/tall phone layouts.
		boss_sequence_art.hide()
	elif _boss_goal_presentation_active:
		boss_sequence_art.texture = BOSS_VICTORY_ART if _boss_goal_victory else BOSS_NEAR_MISS_ART
		boss_sequence_art.show()
	elif finish_presented or terminal_result:
		if outcome_victory:
			postcard_art.texture = POSTCARD_ART
			postcard_art.show()
		else:
			boss_sequence_art.texture = BOSS_NEAR_MISS_ART
			boss_sequence_art.show()
	var target_preview_visible := phase == V06PlaySessionScript.PHASE_BOSS_ROLL_READY and not intro_visible
	# The lane rings already show both destinations. The old prose labels sat
	# behind the lower frame on tall phones and duplicated the same information.
	boss_player_target_label.hide()
	boss_sphinx_target_label.hide()
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
	boss_back_button.visible = not bossless_run_over
	var live_face := _boss_display_face()
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
		_refresh_boss_landing_preview(_boss_display_face())
	if not boss_finished:
		boss_finish_dim.hide()
		_hide_boss_finish_copy()
		boss_finish_summary_label.hide()
		%TrayPanel.modulate = Color.WHITE
		%GoalLabel.text = "GOLDEN GATE"
		%GoalLabel.hide()
		%GoalLabel.scale = Vector2.ONE
		%GoalLabel.modulate = Color.WHITE
	elif finish_presented:
		%GoalLabel.hide()
	if phase in [V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED]:
		var result: Dictionary = boss_result_snapshot
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
			_emit_victory_postcard_if_needed(finished_victory)
			_configure_boss_finish_copy(result, finished_victory)
			boss_result_label.add_theme_font_size_override("font_size", 46)
			boss_result_label.show()
			boss_finish_dim.show()
			_show_boss_finish_copy()
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
		boss_title.text = "GAME OVER"
		boss_result_label.text = _run_over_result_text()
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


func _boss_entry_camera_target() -> float:
	# The pre-race support can seed the player at +3 before the overlay opens.
	# Keep that authored opening pair on the START camera; movement uses the
	# separate post-hop camera path below.
	if _boss_visual_sphinx_position <= 0.01 and _boss_visual_player_position <= 3.01:
		return 0.0
	return float(boss_lane_board.snapped_camera_for(_boss_visual_player_position))


func _stabilize_boss_entry_view(entry_sync_generation: int) -> void:
	# Containers settle after the overlay becomes visible. Recalculate once from
	# the real lane height so an early zero-size camera sample cannot hide either
	# racer for the whole opening explanation.
	await get_tree().process_frame
	await get_tree().process_frame
	if entry_sync_generation != _boss_entry_sync_generation or not is_inside_tree() or not boss_overlay.visible:
		return
	if _rolling or _boss_roll_animation_active or _boss_goal_presentation_active:
		return
	_apply_tall_screen_boss_layout()
	if _boss_camera_tween != null:
		_boss_camera_tween.kill()
		_boss_camera_tween = null
	boss_lane_board.set_camera_position(_boss_entry_camera_target())
	_sync_boss_board_tokens()


func _apply_boss_visual_lerp(weight: float, start_player: float, start_sphinx: float, end_player: float, end_sphinx: float) -> void:
	_boss_visual_player_position = lerpf(start_player, end_player, weight)
	_boss_visual_sphinx_position = lerpf(start_sphinx, end_sphinx, weight)
	_sync_boss_board_tokens()


func _sync_boss_board_tokens() -> void:
	if not is_instance_valid(boss_lane_board) or not is_instance_valid(player_token):
		return
	if _boss_goal_presentation_active:
		return
	if boss_lane_board.size.x <= 1.0 or boss_lane_board.size.y <= V11BossLaneBoardScript.VIEW_BOTTOM_MARGIN:
		# Fail visible while anchors are unresolved. The next process frame will
		# place both racers from stable lane coordinates.
		player_token.show()
		boss_token.show()
		player_foot_marker.show()
		boss_foot_marker.show()
		return
	boss_lane_board.set_racers(_boss_visual_player_position, _boss_visual_sphinx_position)
	var player_center: Vector2 = boss_lane_board.lane_point(_boss_visual_player_position, true)
	var sphinx_center: Vector2 = boss_lane_board.lane_point(_boss_visual_sphinx_position, false)
	# The explorer is the camera anchor and must never disappear. During a
	# long hop, keep the actual token pinned to its lane edge until the single
	# post-movement camera translation reaches its final target.
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
	player_start_label.visible = _boss_visual_player_position <= 0.01
	boss_start_label.visible = _boss_visual_sphinx_position <= 0.01
	player_start_label.position = player_center + Vector2(-player_start_label.size.x * 0.5, 24.0)
	boss_start_label.position = sphinx_center + Vector2(-boss_start_label.size.x * 0.5, 24.0)
	_sync_boss_pictogram_anchors()


func _boss_token_fits_lane_viewport(center: Vector2, token: Control) -> bool:
	var footprint := Rect2(center - Vector2(token.size.x * 0.5, token.size.y - 20.0), token.size)
	return Rect2(Vector2.ZERO, boss_lane_board.size).encloses(footprint)


func _boss_racers_fit_lane_viewport(player_position: float, sphinx_position: float) -> bool:
	var player_center: Vector2 = boss_lane_board.lane_point(player_position, true)
	var sphinx_center: Vector2 = boss_lane_board.lane_point(sphinx_position, false)
	return _boss_token_fits_lane_viewport(player_center, player_token) and _boss_token_fits_lane_viewport(sphinx_center, boss_token)


func _settle_boss_camera_after_movement(player_position: int, sequence_id: int) -> bool:
	# Keep the board fully still after the last hop/effect, then make one
	# restrained fixed-distance translation. The second hold prevents the
	# next ROLL affordance from appearing on the final moving frame.
	if not await _boss_roll_wait(BOSS_CAMERA_HOLD_SECONDS, sequence_id):
		return false
	var start := float(boss_lane_board.get("camera_position"))
	var target := float(boss_lane_board.snapped_camera_for(float(player_position)))
	if not is_equal_approx(start, target):
		if _boss_camera_tween != null:
			_boss_camera_tween.kill()
		_boss_camera_tween = create_tween()
		_boss_camera_tween.tween_method(_apply_boss_camera_position.bind(sequence_id), start, target, BOSS_CAMERA_SCROLL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if not await _boss_roll_wait(BOSS_CAMERA_SCROLL_SECONDS, sequence_id):
			if _boss_camera_tween != null:
				_boss_camera_tween.kill()
			_boss_camera_tween = null
			return false
		boss_lane_board.set_camera_position(target)
		_sync_boss_board_tokens()
		_boss_camera_tween = null
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


func _show_low_hp_warning(motion_generation: int) -> bool:
	if _low_hp_warning_open or _session == null:
		return true
	_low_hp_warning_open = true
	_low_hp_warning_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	low_hp_overlay.show()
	low_hp_panel.modulate = Color.WHITE
	low_hp_panel.scale = Vector2.ONE * 0.92
	low_hp_close_button.grab_focus()
	var reveal := create_tween()
	reveal.tween_property(low_hp_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_ui()
	while _low_hp_warning_open:
		await get_tree().process_frame
		if not is_inside_tree() or (motion_generation >= 0 and motion_generation != _motion_generation):
			_dismiss_low_hp_warning()
			return false
	return true


func _dismiss_low_hp_warning() -> void:
	if not _low_hp_warning_open:
		return
	_low_hp_warning_open = false
	low_hp_overlay.hide()
	if _low_hp_warning_clock_paused and _session != null:
		_session.resume_clock(Time.get_ticks_msec())
	_low_hp_warning_clock_paused = false
	_refresh_ui()


func _show_landing_art(tile_kind: String, tile_index: int, motion_generation: int) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var normalized_kind: String = _session.tile_explanation_kind(tile_kind)
	if normalized_kind.is_empty() or _session.has_seen_tile_explanation(normalized_kind):
		return true
	landing_art_panel.custom_minimum_size.y = 556.0
	landing_art_caption.custom_minimum_size.y = 70.0
	landing_art_caption.add_theme_font_size_override("font_size", 24)
	if not _configure_tile_help_card(normalized_kind, tile_index):
		return true
	_tile_help_pending_kind = normalized_kind
	_tile_help_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	_tile_help_open = true
	landing_art_overlay.show()
	landing_art_panel.pivot_offset = landing_art_panel.size * 0.5
	landing_art_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	landing_art_panel.scale = Vector2(0.94, 0.94)
	if _landing_art_tween != null:
		_landing_art_tween.kill()
	_landing_art_tween = create_tween().set_parallel(true)
	_landing_art_tween.tween_property(landing_art_panel, "modulate:a", 1.0, 0.16)
	_landing_art_tween.tween_property(landing_art_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	while _tile_help_open:
		await get_tree().process_frame
		if not is_inside_tree() or (motion_generation >= 0 and motion_generation != _motion_generation):
			_tile_help_open = false
			_tile_help_pending_kind = ""
			landing_art_overlay.hide()
			_resume_tile_help_clock()
			return false
	landing_art_overlay.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE
	_landing_art_tween = null
	_resume_tile_help_clock()
	return true


func _open_three_roll_onboarding_if_eligible() -> bool:
	if _three_roll_onboarding_open or _tile_help_open or _session == null:
		return false
	if _session.has_seen_three_roll_onboarding() or not _session.is_untouched_journey_start():
		return false
	_three_roll_onboarding_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	_three_roll_onboarding_open = true
	_onboarding_kind = "slot"
	landing_art.texture = SLOT_TRAY_ART
	landing_art_panel.custom_minimum_size.y = 800.0
	landing_art_caption.custom_minimum_size.y = 260.0
	landing_art_caption.add_theme_font_size_override("font_size", 22)
	landing_art_title.text = V06LocalizationScript.text(&"THREE_ROLL_ONBOARDING_TITLE")
	landing_art_caption.text = V06LocalizationScript.text(&"THREE_ROLL_ONBOARDING_BODY")
	landing_art_prompt.text = V06LocalizationScript.text(&"THREE_ROLL_ONBOARDING_CTA")
	landing_paid_action_button.hide()
	landing_discovery_thumb.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE
	landing_art_overlay.show()
	landing_art_prompt.grab_focus()
	_refresh_ui()
	return true


func _open_start_onboarding_if_eligible() -> bool:
	if _open_survival_onboarding_if_eligible():
		return true
	return _open_three_roll_onboarding_if_eligible()


func _open_survival_onboarding_if_eligible() -> bool:
	if _three_roll_onboarding_open or _tile_help_open or _session == null:
		return false
	if _session.has_seen_survival_onboarding() or not _session.is_untouched_journey_start():
		return false
	_three_roll_onboarding_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	_three_roll_onboarding_open = true
	_onboarding_kind = "survival"
	landing_art.texture = DISCOVERY_ARTS[4]
	landing_art_panel.custom_minimum_size.y = 650.0
	landing_art_caption.custom_minimum_size.y = 130.0
	landing_art_caption.add_theme_font_size_override("font_size", 24)
	landing_art_title.text = "1マス = 1ポイント"
	landing_art_caption.text = "進んだマスが、そのままスコア！\n⚠ RISK：HP −1　　♥ REST：HP +1\nHPが0になると復活を1回使ってHP FULL。\n復活0でHPが尽きると旅は終了。\n\nボス勝利後はHP回復CHANCE！"
	landing_art_prompt.text = "わかった　スロットの説明へ"
	landing_paid_action_button.hide()
	landing_discovery_thumb.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE
	landing_art_overlay.show()
	landing_art_prompt.grab_focus()
	_refresh_ui()
	return true


func _on_landing_art_prompt_pressed() -> void:
	if _event_card_open:
		_dismiss_event_card()
	elif _skill_ready_discovery_open:
		_dismiss_skill_ready_discovery()
	elif _three_roll_onboarding_open:
		_dismiss_three_roll_onboarding()
	else:
		_dismiss_tile_help()


func _show_event_card(motion_generation: int) -> bool:
	if _session == null or _session.phase() != V06PlaySessionScript.PHASE_EVENT_REQUIRED: return false
	var event: Dictionary = _session.active_event()
	if event.is_empty(): return false
	_event_card_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	_event_card_open = true
	landing_art_panel.custom_minimum_size.y = 620.0
	landing_art_caption.custom_minimum_size.y = 110.0
	landing_art_caption.add_theme_font_size_override("font_size", 24)
	var event_id := str(event.get("event_id", ""))
	match event_id:
		"market_hawker": landing_art.texture = EVENT_ARTS[1]
		"nile_tailwind": landing_art.texture = EVENT_ARTS[2]
		"ruin_whisper": landing_art.texture = EVENT_ARTS[3]
		"ferry_offer": landing_art.texture = EVENT_ARTS[0]
		_: return false
	_register_travel_card("event:%s" % event_id)
	var stem := event_id.to_upper()
	landing_art_title.text = V06LocalizationScript.text(StringName("EVENT_%s_TITLE" % stem))
	var copy_suffix := "FIRST" if bool(event.get("first_visit", false)) else "REPEAT"
	landing_art_caption.text = event_card_body(event_id, copy_suffix, bool(event.get("score_awarded", false)))
	var paid_used := bool(event.get("paid_option_used", false))
	if paid_used:
		landing_art_caption.text += "\n\n%s" % str(event.get("paid_option_result", "有利な方法を選んだ"))
	var paid_cost := 3 if event_id in ["nile_tailwind", "ferry_offer"] else 2
	var paid_available: bool = not paid_used and _session.coins() >= paid_cost
	landing_paid_action_button.text = event_paid_cta_text(paid_cost, _session.coins(), paid_used)
	landing_paid_action_button.disabled = not paid_available
	landing_paid_action_button.self_modulate = Color.WHITE if paid_available else Color(0.62, 0.62, 0.62, 1.0)
	landing_paid_action_button.show()
	landing_art_prompt.text = V06LocalizationScript.text(&"EVENT_CONTINUE_CTA")
	landing_art_prompt.disabled = false
	landing_art_prompt.focus_mode = Control.FOCUS_ALL
	landing_art_prompt.show()
	landing_discovery_thumb.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE
	landing_art_overlay.show()
	landing_art_prompt.grab_focus()
	_refresh_ui()
	if DisplayServer.get_name() == "headless": return true
	while _event_card_open:
		await get_tree().process_frame
		if not is_inside_tree() or (motion_generation >= 0 and motion_generation != _motion_generation): return false
	return true


func event_card_body(event_id: String, copy_suffix: String, score_awarded: bool) -> String:
	var body := V06LocalizationScript.text(StringName("EVENT_%s_%s" % [event_id.to_upper(), copy_suffix.to_upper()]))
	if score_awarded:
		body += "\n" + V06LocalizationScript.text(&"EVENT_DISCOVERY_SCORE")
	return body


static func event_paid_cta_text(cost: int, coins: int, used: bool) -> String:
	if used:
		return "コイン ×%d　利用済み" % cost
	if coins < cost:
		return "コイン ×%d　不足（所持 %d）" % [cost, maxi(coins, 0)]
	return "コイン ×%d　有利な方法を選ぶ" % cost


func _dismiss_event_card() -> void:
	if not _event_card_open or _session == null: return
	if not _session.acknowledge_event(): return
	_event_card_open = false
	landing_paid_action_button.hide()
	landing_art_overlay.hide()
	var owned_pause := _event_card_clock_paused
	_event_card_clock_paused = false
	if owned_pause: _session.resume_clock(Time.get_ticks_msec())
	_refresh_ui()
	_save_stable_checkpoint()
	if _session.phase() == V06PlaySessionScript.PHASE_RESOLUTION_REQUIRED:
		_finish_event_role_resolution()
	else:
		die_button.grab_focus()


func _on_event_paid_action_pressed() -> void:
	if not _event_card_open or _session == null:
		return
	var result: Dictionary = _session.purchase_event_option()
	if not bool(result.get("ok", false)):
		landing_paid_action_button.disabled = true
		var event_id: String = str(_session.active_event().get("event_id", ""))
		var paid_cost: int = 3 if event_id in ["nile_tailwind", "ferry_offer"] else 2
		landing_paid_action_button.text = event_paid_cta_text(paid_cost, _session.coins(), false)
		landing_paid_action_button.self_modulate = Color(0.62, 0.62, 0.62, 1.0)
		landing_art_prompt.disabled = false
		landing_art_prompt.show()
		landing_art_prompt.grab_focus()
		return
	_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)
	landing_art_caption.text += "\n\n%s" % str(result.get("text", "有利な方法を選んだ"))
	var event_id: String = str(_session.active_event().get("event_id", ""))
	var paid_cost: int = 3 if event_id in ["nile_tailwind", "ferry_offer"] else 2
	landing_paid_action_button.text = event_paid_cta_text(paid_cost, _session.coins(), true)
	landing_paid_action_button.disabled = true
	landing_paid_action_button.self_modulate = Color(0.62, 0.62, 0.62, 1.0)
	landing_art_prompt.disabled = false
	landing_art_prompt.show()
	_refresh_ui()
	_save_stable_checkpoint()


func _finish_event_role_resolution() -> void:
	var role := String(_session.resolution_role())
	if not role.is_empty():
		await _play_inline_slot_result(role, 0, _motion_generation)
	_complete_nonmodal_resolution()
	await _show_skill_ready_discovery_if_eligible(_motion_generation)


func _show_skill_ready_discovery_if_eligible(motion_generation: int) -> bool:
	if _session == null or _skill_ready_discovery_open or _event_card_open or _session.has_seen_skill_ready_discovery():
		return false
	if _session.skill_state() != V06PlaySessionScript.SKILL_STATE_READY:
		return false
	if _session.phase() in [V06PlaySessionScript.PHASE_BOSS_GATE, V06PlaySessionScript.PHASE_BOSS_ROLL_READY, V06PlaySessionScript.PHASE_BOSS_ROUND_RESULT, V06PlaySessionScript.PHASE_BOSS_FINISHED]:
		return false
	_skill_ready_discovery_open = true
	_three_roll_onboarding_clock_paused = _session.pause_clock(Time.get_ticks_msec())
	landing_art.texture = SKILL_PINPOINT_ART
	landing_art_panel.custom_minimum_size.y = 620.0
	landing_art_caption.custom_minimum_size.y = 140.0
	landing_art_title.text = "SKILL READY!"
	landing_art_caption.text = "次のサイコロの出目を選べる！\n説明を閉じたら、画面下の「スキル READY」から使えます。"
	landing_art_prompt.text = "わかった（下のスキル READYから使う）"
	landing_paid_action_button.hide()
	landing_discovery_thumb.hide()
	landing_art_overlay.show()
	landing_art_prompt.grab_focus()
	if DisplayServer.get_name() == "headless":
		return true
	while _skill_ready_discovery_open:
		await get_tree().process_frame
		if not is_inside_tree() or (motion_generation >= 0 and motion_generation != _motion_generation):
			return false
	return true


func _dismiss_skill_ready_discovery() -> void:
	if not _skill_ready_discovery_open or _session == null:
		return
	_session.mark_skill_ready_discovery_seen()
	_skill_ready_discovery_open = false
	landing_art_overlay.hide()
	if _three_roll_onboarding_clock_paused:
		_session.resume_clock(Time.get_ticks_msec())
	_three_roll_onboarding_clock_paused = false
	_refresh_ui()
	_show_operation_message("画面下の「スキル READY」から出目を選ぶ", 2.8, 30)
	_pulse_skill_ready_button()
	die_button.grab_focus()
	_save_stable_checkpoint()


func _pulse_skill_ready_button() -> void:
	if not is_instance_valid(skill_tool_button):
		return
	if is_instance_valid(_skill_ready_button_pulse_tween):
		_skill_ready_button_pulse_tween.kill()
	skill_tool_button.self_modulate = Color("#fff0a0")
	var tween := create_tween()
	_skill_ready_button_pulse_tween = tween
	tween.set_loops(3)
	tween.tween_property(skill_tool_button, "self_modulate", Color.WHITE, 0.26)
	tween.tween_interval(0.10)
	tween.tween_property(skill_tool_button, "self_modulate", Color("#fff0a0"), 0.26)
	tween.finished.connect(func() -> void:
		if is_instance_valid(skill_tool_button):
			skill_tool_button.self_modulate = Color.WHITE
		_skill_ready_button_pulse_tween = null
	)


func _dismiss_three_roll_onboarding() -> void:
	if not _three_roll_onboarding_open or _session == null:
		return
	var dismissed_kind := _onboarding_kind
	if dismissed_kind == "survival":
		_session.mark_survival_onboarding_seen()
	else:
		_session.mark_three_roll_onboarding_seen()
	_three_roll_onboarding_open = false
	_onboarding_kind = ""
	landing_art_overlay.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE
	var owned_pause := _three_roll_onboarding_clock_paused
	_three_roll_onboarding_clock_paused = false
	if dismissed_kind == "survival" and _open_three_roll_onboarding_if_eligible():
		_three_roll_onboarding_clock_paused = owned_pause
		_save_stable_checkpoint()
		return
	if owned_pause:
		_session.resume_clock(Time.get_ticks_msec())
	_refresh_ui()
	die_button.grab_focus()
	_save_stable_checkpoint()


func _configure_tile_help_card(tile_kind: String, tile_index: int) -> bool:
	var normalized_kind := tile_kind.to_upper()
	if normalized_kind.begins_with("WARP"):
		normalized_kind = "WARP"
	var art: Texture2D = null
	var thumb: Texture2D = null
	var translation_stem := ""
	match normalized_kind:
		"EVENT":
			return false
		"ITEM":
			art = ITEM_ARTS[posmod(tile_index, ITEM_ARTS.size())]
			thumb = DISCOVERY_ARTS[2]
			translation_stem = "ITEM"
		"COIN":
			art = DISCOVERY_ARTS[0]
			translation_stem = "COIN"
		"REST":
			art = DISCOVERY_ARTS[3]
			translation_stem = "REST"
		"RISK":
			art = DISCOVERY_ARTS[4]
			translation_stem = "RISK"
		"WARP":
			art = DISCOVERY_ARTS[5]
			translation_stem = "WARP"
		_:
			return false
	landing_art.texture = art
	landing_art_title.text = V06LocalizationScript.text(StringName("TILE_HELP_%s_TITLE" % translation_stem))
	landing_art_caption.text = V06LocalizationScript.text(StringName("TILE_HELP_%s_BODY" % translation_stem))
	landing_art_prompt.text = V06LocalizationScript.text(&"TILE_HELP_TAP_TO_CLOSE")
	landing_discovery_thumb.texture = thumb
	landing_discovery_thumb.hide()
	return true


func _on_landing_art_gui_input(event: InputEvent) -> void:
	if not _tile_help_open:
		return
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if not pressed:
		return
	landing_art_overlay.accept_event()
	_dismiss_tile_help()


func _dismiss_tile_help() -> void:
	if not _tile_help_open:
		return
	_tile_help_open = false
	if _session != null and not _tile_help_pending_kind.is_empty():
		_session.mark_tile_explanation_seen(_tile_help_pending_kind)
	_tile_help_pending_kind = ""
	if _landing_art_tween != null:
		_landing_art_tween.kill()
		_landing_art_tween = null
	landing_art_overlay.hide()
	landing_art_panel.modulate = Color.WHITE
	landing_art_panel.scale = Vector2.ONE


func _resume_tile_help_clock() -> void:
	if not _tile_help_clock_paused:
		return
	_tile_help_clock_paused = false
	if _session != null:
		_session.resume_clock(Time.get_ticks_msec())


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
	var pre_final_gap := absi(int(result.get("player_position_before", 0)) - int(result.get("boss_position_before", 0)))
	var role_counts: Dictionary = result.get("role_counts", {})
	return "全%dターン　最後の差 %dマス\n翼%d / 流砂%d　ペア%d・ストレート%d・トリプル%d" % [
		turn_count,
		pre_final_gap,
		player_wings,
		player_sands,
		int(role_counts.get("PAIR", 0)),
		int(role_counts.get("STRAIGHT", 0)),
		int(role_counts.get("TRIPLE", 0)),
	]


func _localized_boss_effect(effect: String) -> String:
	match effect:
		"WING_GATE": return "翼の門 +3"
		"QUICKSAND": return "流砂 −2"
		_: return effect.replace("_", " ")


func _score_result_text(victory: bool) -> String:
	var score: int = int(_session.score())
	var best: int = int(_session.best_score())
	var lead := "スフィンクスに勝利！" if victory else "スフィンクスには惜敗。"
	return "%s\nこの旅 %sマス　合計 %sマス\nBEST %sマス" % [
		lead,
		_format_score(int(_session.lap_score())),
		_format_score(score),
		_format_score(best),
	]


func _run_over_result_text() -> String:
	return "旅したマス %s　BEST %s\nLAP %d　この旅 %s\nHP 0・復活 0　旅は終了です" % [_format_score(int(_session.score())), _format_score(int(_session.best_score())), int(_session.lap()), _format_score(int(_session.lap_score()))]


static func revival_stamp_text(life: int) -> String:
	return "復活！　復活 ×%d　HP FULL" % clampi(life, 0, V06PlaySessionScript.MAX_LIFE)


static func lap_life_stamp_text(completed_lap: int, life_before: int, life_after: int) -> String:
	if life_after > life_before:
		return "%d LAP BONUS　復活 +1" % completed_lap
	return "%d LAP達成　復活 FULL" % completed_lap


func _configure_boss_finish_copy(result: Dictionary, victory: bool) -> void:
	boss_finish_kicker_label.text = V06LocalizationScript.text(&"VICTORY_KICKER") if victory else V06LocalizationScript.text(&"DEFEAT_KICKER")
	boss_result_label.text = V06LocalizationScript.text(&"VICTORY_TITLE") if victory else V06LocalizationScript.text(&"DEFEAT_TITLE")
	boss_finish_score_label.text = "旅したマス  %s" % _format_score(int(_session.score()))
	var missions: Dictionary = _session.mission_state()
	var active_mission: Dictionary = missions.get("active_mission", {})
	if bool(active_mission.get("completed", false)):
		boss_finish_mission_label.text = "MISSION CLEAR　報酬 COIN +%d" % int(active_mission.get("reward_coins", 0))
	else:
		boss_finish_mission_label.text = "MISSION　%s　%d/%d" % [str(active_mission.get("short_text", "未達成")), int(active_mission.get("progress", 0)), maxi(int(active_mission.get("target", 1)), 1)]
	boss_finish_summary_label.text = _boss_finish_summary(result)
	_refresh_heart_roulette_copy(victory)


func _refresh_heart_roulette_copy(victory: bool) -> void:
	if not is_instance_valid(heart_roulette_panel):
		return
	if not victory:
		heart_roulette_panel.hide_view()
		next_lap_button.text = V06LocalizationScript.text(&"VICTORY_NEXT")
		return
	var options: Array[int] = _heart_roulette_visual_options()
	if _session.heart_roulette_pending():
		if not options.is_empty():
			_heart_roulette_display_index = clampi(_heart_roulette_display_index, 0, options.size() - 1)
			_set_heart_roulette_copy(options[_heart_roulette_display_index])
		next_lap_button.text = "STOP!"
		return
	var roulette_result: Dictionary = _session.heart_roulette_result()
	if roulette_result.is_empty():
		heart_roulette_panel.show_perfect()
	else:
		var result_index := _heart_roulette_visual_index_for_session(int(roulette_result.get("slot_index", 0)))
		heart_roulette_panel.show_result(options, result_index, str(roulette_result.get("label", "変化なし")), _heart_text(_session.player_hp(), _session.player_max_hp()))
	next_lap_button.text = V06LocalizationScript.text(&"VICTORY_NEXT")


func _set_heart_roulette_copy(_value: int) -> void:
	if not is_instance_valid(heart_roulette_panel) or _session == null:
		return
	heart_roulette_panel.show_pending(_heart_roulette_visual_options(), _heart_roulette_display_index)


func _heart_roulette_visual_options() -> Array[int]:
	var logical_options: Array[int] = _session.heart_roulette_options() if _session != null else []
	var visual_options: Array[int] = []
	for logical_index: int in HEART_ROULETTE_VISUAL_SLOT_ORDER:
		if logical_index >= 0 and logical_index < logical_options.size():
			visual_options.append(logical_options[logical_index])
	return visual_options


func _heart_roulette_session_index_for_visual(visual_index: int) -> int:
	if HEART_ROULETTE_VISUAL_SLOT_ORDER.is_empty():
		return 0
	return HEART_ROULETTE_VISUAL_SLOT_ORDER[clampi(visual_index, 0, HEART_ROULETTE_VISUAL_SLOT_ORDER.size() - 1)]


func _heart_roulette_visual_index_for_session(session_index: int) -> int:
	var visual_index := HEART_ROULETTE_VISUAL_SLOT_ORDER.find(session_index)
	return visual_index if visual_index >= 0 else 0


func _show_boss_finish_copy() -> void:
	# A reach/operation cue can still own the shared message band when the final
	# roll crosses the goal. The finish card has its own summary and roulette, so
	# retire that transient layer before it can cover the lower wheel segments.
	_slot_reach_message_active = false
	_boss_reach_signature = ""
	_operation_message_generation += 1
	_operation_message_override_active = false
	_reset_move_announcement_style()
	message_label.text = ""
	message_label.hide()
	message_band.hide()
	boss_finish_kicker_label.show()
	boss_finish_score_label.show()
	boss_finish_mission_label.show()
	boss_finish_summary_label.show()
	var victory := _session != null and bool(_session.boss_result().get("victory", false))
	if victory:
		_refresh_heart_roulette_copy(true)


func _hide_boss_finish_copy() -> void:
	if is_instance_valid(boss_finish_kicker_label):
		boss_finish_kicker_label.hide()
	if is_instance_valid(boss_finish_score_label):
		boss_finish_score_label.hide()
	if is_instance_valid(boss_finish_mission_label):
		boss_finish_mission_label.hide()
	if is_instance_valid(heart_roulette_panel):
		heart_roulette_panel.hide_view()


func _emit_landing_feedback(tile_effect: Dictionary) -> void:
	if tile_effect.is_empty():
		return
	var tile_kind := str(tile_effect.get("tile_kind", "")).to_lower()
	if tile_kind == "risk":
		_emit_feedback(V06FeedbackControllerScript.EVENT_DAMAGE)
	elif tile_kind in ["coin", "item", "rest", "event", "warp"]:
		_emit_feedback(V06FeedbackControllerScript.EVENT_REWARD)


func _emit_victory_postcard_if_needed(victory: bool) -> void:
	if not victory or _victory_postcard_emitted:
		return
	_victory_postcard_emitted = true
	postcard_unlocked.emit("cairo_journey_complete")


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
