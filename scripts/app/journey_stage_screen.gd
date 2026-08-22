class_name JourneyStageScreen
extends Control

signal back_requested
signal encyclopedia_requested

const AMAZON_MAP: Texture2D = preload("res://assets/art/backgrounds/amazon-suiu-falls-map.png")
const AMAZON_BOSS_BG: Texture2D = preload("res://assets/art/backgrounds/aquafall-waterfall-climb.png")
const KYOTO_MAP: Texture2D = preload("res://assets/art/backgrounds/kyoto-one-day-journey.png")
const KYOTO_BOSS_BG: Texture2D = preload("res://assets/art/backgrounds/white-fox-seal-board.png")
const WHITE_FOX: Texture2D = preload("res://assets/art/bosses/kyoto/white-fox-guardian.png")
const AQUAFALL_LOG: Texture2D = preload("res://assets/art/bosses/amazon/aquafall-log.png")
const AQUAFALL_SMALL_LOG: Texture2D = preload("res://assets/art/bosses/amazon/aquafall-small-log-v2.png")
const AQUAFALL_LARGE_LOG: Texture2D = preload("res://assets/art/bosses/amazon/aquafall-large-log-v2.png")
const AQUAFALL_GOAL_ICON: Texture2D = preload("res://assets/art/bosses/amazon/aquafall-goal-icon-v1.png")
const AQUAFALL_VICTORY: Texture2D = preload("res://assets/art/bosses/amazon/aquafall-victory-v1.png")
const EXPLORER_IDLE_STRIP: Texture2D = preload("res://assets/art/v06/characters/explorer_cat/explorer-cat-idle-strip.png")
const ICON_COIN: Texture2D = preload("res://assets/art/v06/tile_kind_icons/coin-tokens-stack.png")
const ICON_EVENT: Texture2D = preload("res://assets/art/v06/tile_kind_icons/event-book-open.png")
const ICON_REST: Texture2D = preload("res://assets/art/v06/tile_kind_icons/rest-campfire.png")
const ICON_RISK: Texture2D = preload("res://assets/art/v06/tile_kind_icons/risk-skull.png")
const ICON_NORMAL: Texture2D = preload("res://assets/art/v06/tile_kind_icons/normal-footprints.png")
const ICON_SPECIAL: Texture2D = preload("res://assets/art/v06/tile_kind_icons/item-pouch.png")
const HEART_WHEEL: Texture2D = preload("res://assets/art/ui/common/heart-roulette-wheel-v1.png")
const AMAZON_ITEM_CARD: Texture2D = preload("res://assets/art/cards/amazon/amazon-item-card.png")
const AMAZON_EVENT_CARD: Texture2D = preload("res://assets/art/cards/amazon/amazon-event-card.png")
const KYOTO_ITEM_CARD: Texture2D = preload("res://assets/art/cards/kyoto/kyoto-item-card.png")
const KYOTO_EVENT_CARD: Texture2D = preload("res://assets/art/cards/kyoto/kyoto-event-card.png")
const AMAZON_FLOW_TUTORIAL: Texture2D = preload("res://assets/art/tutorials/amazon-flow-tutorial.png")
const KYOTO_ROUTE_TUTORIAL: Texture2D = preload("res://assets/art/tutorials/kyoto-route-tutorial.png")
const KYOTO_GOSHUIN_TUTORIAL: Texture2D = preload("res://assets/art/tutorials/kyoto-goshuin-tutorial.png")
const LEATHER_BG: Texture2D = preload("res://assets/art/v07/ui/dark-walnut-leather.png")
const SLOT_TRAY_ART: Texture2D = preload("res://assets/art/ui/common/slot-tray-luxury-v1.png")
const ROLL_BUTTON_ART: Texture2D = preload("res://assets/art/ui/common/roll-button-round-v1.png")
const DICE_ART: Texture2D = preload("res://assets/art/ui/common/dice-ivory-brass.png")
const ITEM_CARD_ICON: Texture2D = preload("res://assets/art/v08/cards/item-card.png")
const SKILL_CARD_ICON: Texture2D = preload("res://assets/art/v08/cards/skill-card.png")
const MENU_ICON: Texture2D = preload("res://assets/art/ui/common/menu-gear-v1.png")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const DICE_PRESENTATION := preload("res://scripts/game/dice_presentation_3d.gd")
const BOSS_MAP_EMBLEM_SCRIPT := preload("res://scripts/ui/boss_map_emblem.gd")
const DICE_ROLL_SE: AudioStream = preload("res://assets/audio/dice/roll_01.wav")
const DICE_LAND_SE: AudioStream = preload("res://assets/audio/dice/land_01.wav")
const SAVE_MANAGER := preload("res://scripts/game/journey_save_manager.gd")
const FOX_FIRE_BATTLE_SCENE: PackedScene = preload("res://boss/kyoto/fox_fire_six_routes/FoxFireSixRoutesBattle.tscn")
const FOX_FIRE_CHASE_BATTLE_PATH := "res://boss/kyoto/fox_fire_chase/FoxFireChaseBattle.tscn"

const INK := Color("#2d241d")
const PAPER := Color("#f8ebca")
const GOLD := Color("#d6a43d")
const AMAZON_TEAL := Color("#0f7c75")
const KYOTO_RED := Color("#9d342d")
const AMAZON_INK := Color("#0d3d38")
const KYOTO_INK := Color("#211f3e")
const LOCAL_MAP_WINDOW_AMAZON := 0.13
const LOCAL_MAP_WINDOW_KYOTO := 0.12
const MAP_HOP_SECONDS := 0.24
const MAP_LANDING_SECONDS := 0.76
const MAP_CAMERA_FOLLOW_SECONDS := 0.52
const KYOTO_HORIZON_CARD_HEIGHT := 260.0
const KYOTO_HORIZON_CARD_MIN_HEIGHT := 220.0
const KYOTO_HORIZON_DIE_SIZE := 184.0
const KYOTO_HORIZON_DIE_MIN_SIZE := 152.0
const KYOTO_HORIZON_CAT_SIZE := 136.0
const KYOTO_HORIZON_ANCHOR_SIZE := 92.0
const KYOTO_HORIZON_GAP := 14.0
const AQUAFALL_STEP_SECONDS := 0.52
const AQUAFALL_STEP_PAUSE_SECONDS := 0.14
const AQUAFALL_HOP_ARC := 36.0
const AQUAFALL_HOP_SCALE := 0.10
const MAP_PLAYER_FOOT_OFFSET := Vector2(0.0, -22.0)
const SLOT_DESIGN_SIZE := Vector2(648.0, 224.0)
const KYOTO_MAIN_WAYPOINTS := {
	1: 0.50, 22: 0.49, 23: 0.58, 45: 0.62, 46: 0.45,
	68: 0.40, 69: 0.52, 89: 0.57, 90: 0.50,
}
const KYOTO_ROUTE_SIDES := {
	"gion_shortcut": 1.0,
	"arashiyama_shortcut": -1.0,
}
const TYPE_COLORS := {
	"START": Color("#3c9d88"), "NORMAL": Color("#f7edca"), "COIN": Color("#f3bd3d"),
	"EVENT": Color("#c9679e"), "REST": Color("#62b8a8"), "RISK": Color("#c44f43"),
	"FLOW": Color("#4ba2cf"), "SPECIAL": Color("#a96bc7"), "JUNCTION": Color("#a96bc7"),
	"GOSHUIN": Color("#e64d3f"), "ITEM": Color("#6e9faf"), "BOSS": Color("#e1982e"),
}

var stage_id: StringName = StageCatalog.STAGE_AMAZON
var journey: StageJourneyBase
var amazon_boss: AquafallBattle
var kyoto_boss: WhiteFoxBattle
var kyoto_boss_scene: FoxFireSixRoutesBattle
var kyoto_chase_scene: Control
var rng := RandomNumberGenerator.new()
var save_manager := SAVE_MANAGER.new()
var root_layer: Control
var top_hud: PanelContainer
var stage_band: PanelContainer
var mission_band: PanelContainer
var hp_label: Label
var life_label: Label
var life_icon: TextureRect
var coins_label: Label
var lap_label: Label
var progress_label: Label
var coin_info_chip: PanelContainer
var progress_info_chip: PanelContainer
var score_label: Label
var best_label: Label
var stage_route_label: Label
var status_label: Label
var content_host: Control
var controls_box: VBoxContainer
var roll_button: BaseButton
var item_card_button: Button
var coin_tool_button: Button
var skill_tool_button: Button
var event_card_button: Button
var goshuin_mission_label: Label
var mission_caption_label: Label
var mission_progress_label: Label
var mission_icon_view: TextureRect
var mission_value_labels: Dictionary = {}
var roll_slot_labels: Array[Label] = []
var roll_slot_panels: Array[PanelContainer] = []
var roll_slots: Array[int] = []
var pending_slot_role := ""
var slot_reach_signature := ""
var map_background: TextureRect
var map_node_layer: Control
var map_player: TextureRect
var map_dice: DicePresentation3D
var route_preview_row: HBoxContainer
var travel_tray_root: Control
var primary_roll_controls: Control
var roll_caption_label: Label
var local_view_y_min := 0.0
var local_view_y_max := 1.0
var active_modal: Control
var overview_overlay: Control
var overview_node_layer: Control
var overview_sweep_layer: Control
var overview_marker_occupancy: Array[Dictionary] = []
var overview_button: Button
var show_stage_intro := true
var selected_fox_die := -1
var idle_frame := 0
var idle_timer: Timer
var dice_se_player: AudioStreamPlayer
var roll_animation_active := false
var map_roll_active := false
var map_roll_elapsed := 0.0
var map_roll_face := 1
var map_movement_active := false
var map_camera_tween: Tween
var map_camera_follow_origin := 0.0
var amazon_boss_roll_active := false
var amazon_boss_roll_elapsed := 0.0
var amazon_boss_roll_face := 1
var amazon_boss_move_active := false
var aquafall_visual_lane := -1
var aquafall_visual_height := -1
var aquafall_visual_obstacles: Array[Dictionary] = []
var aquafall_animation_step := 0
var aquafall_animation_total := 0
var aquafall_lane_layer: Control
var aquafall_player_sprite: Control
var aquafall_rules_slide := 0
var aquafall_rules_slide_count := 4
var aquafall_rules_compact := false
var aquafall_rules_content: VBoxContainer
var aquafall_rules_prev_button: Button
var aquafall_rules_next_button: Button
var aquafall_rules_start_button: Button
var aquafall_rules_slide_index: Label
var aquafall_practice_active := false
var aquafall_practice_cat: Control
var aquafall_practice_logs: Array[Control] = []
var heart_roulette_spinning := false
var heart_roulette_resolved := false
var heart_roulette_elapsed := 0.0
var heart_roulette_display_index := -1
var heart_roulette_wheel_image: TextureRect
var heart_roulette_segments: Array[PanelContainer] = []
var heart_roulette_action_button: Button
var heart_roulette_result_label: Label


func configure_start_context(selected_stage_id: StringName, resume: bool = false) -> void:
	stage_id = selected_stage_id
	show_stage_intro = not resume
	if resume:
		call_deferred("_restore_saved_state")


func show_boss_for_qa() -> void:
	if journey == null:
		return
	_close_overview_map()
	_close_modal()
	journey.phase = StageJourneyBase.PHASE_BOSS
	if stage_id == StageCatalog.STAGE_AMAZON:
		_start_aquafall_boss()
	else:
		_start_white_fox_boss(true)


func show_roll_result_for_qa(face: int = 4) -> void:
	roll_slots = [clampi(face, 1, 6)]
	_refresh_roll_slots()
	if is_instance_valid(map_dice):
		map_dice.present([clampi(face, 1, 6)], false, 1)


func show_survival_state_for_qa(heart_count: int, life_count: int) -> void:
	if journey == null:
		return
	journey.hp = clampi(heart_count, 0, StageJourneyBase.MAX_HEARTS)
	journey.life = clampi(life_count, 0, StageJourneyBase.MAX_LIFE)
	_refresh_all()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	_build_shell()
	_start_journey()


func _process(delta: float) -> void:
	# The normal-map die intentionally waits for a second tap. Keeping the
	# preview clock here (rather than in the button callback) makes the visible
	# face and the 3D rotation share one deterministic timeline, just like Cairo.
	var dice_changed := false
	if map_roll_active:
		map_roll_elapsed += delta
		map_roll_face = DICE_PRESENTATION.rolling_face_for_elapsed(map_roll_elapsed)
		dice_changed = true
		if is_instance_valid(map_dice):
			map_dice.present([map_roll_face], true, 0)
			map_dice.sync_rolling_elapsed(map_roll_elapsed)
	elif amazon_boss_roll_active:
		amazon_boss_roll_elapsed += delta
		amazon_boss_roll_face = DICE_PRESENTATION.rolling_face_for_elapsed(amazon_boss_roll_elapsed)
		dice_changed = true
		if is_instance_valid(map_dice):
			map_dice.present([amazon_boss_roll_face], true, 0)
			map_dice.sync_rolling_elapsed(amazon_boss_roll_elapsed)
	if dice_changed:
		_refresh_roll_slots()
	if heart_roulette_spinning:
		heart_roulette_elapsed += delta
		var next_index := int(floor(heart_roulette_elapsed / 0.12)) % HeartRouletteModel.VALUES.size()
		if next_index != heart_roulette_display_index:
			heart_roulette_display_index = next_index
			_set_heart_roulette_selection(next_index)
		if is_instance_valid(heart_roulette_wheel_image):
			heart_roulette_wheel_image.rotation = heart_roulette_elapsed * 1.8


func _build_shell() -> void:
	var is_kyoto_ui := stage_id == StageCatalog.STAGE_KYOTO
	root_layer = Control.new()
	root_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_layer)
	var backdrop := TextureRect.new()
	backdrop.texture = LEATHER_BG
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_layer.add_child(backdrop)
	var tint := ColorRect.new()
	tint.color = Color(0.03, 0.05, 0.04, 0.50)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_layer.add_child(tint)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	root_layer.add_child(margin)
	var vertical := VBoxContainer.new()
	vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical.add_theme_constant_override("separation", 7)
	margin.add_child(vertical)
	top_hud = PanelContainer.new()
	top_hud.name = "HudPanel"
	top_hud.custom_minimum_size.y = 200 if is_kyoto_ui else 128
	top_hud.add_theme_stylebox_override("panel", _panel(_stage_ink(0.96), GOLD, 16, 3))
	var hud := VBoxContainer.new()
	hud.add_theme_constant_override("separation", 4)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 3)
	score_label = _hud_stat("旅したマス", "0")
	best_label = _hud_stat("BEST", "0")
	lap_label = _hud_stat("LAP", "1")
	for chip: Control in [score_label.get_parent(), best_label.get_parent(), lap_label.get_parent()]:
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(chip)
	hud.add_child(stats)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 5)
	var coin_chip := _cairo_coin_hud() if is_kyoto_ui else _info_value_chip("コイン", "0")
	coin_info_chip = coin_chip["chip"] as PanelContainer
	coins_label = coin_chip["value"] as Label
	var survival_chip := _survival_chip()
	var progress_chip := _cairo_progress_hud() if is_kyoto_ui else _info_value_chip("現在", "1/90")
	progress_info_chip = progress_chip["chip"] as PanelContainer
	progress_label = progress_chip["value"] as Label
	coin_info_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_info_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(coin_info_chip)
	survival_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(survival_chip)
	info.add_child(progress_info_chip)
	overview_button = _button("全体マップ", _show_overview_map, false)
	overview_button.name = "MapButton"
	overview_button.custom_minimum_size = Vector2(112, 96) if is_kyoto_ui else Vector2(104, 55)
	overview_button.add_theme_font_size_override("font_size", 17 if is_kyoto_ui else 15)
	if is_kyoto_ui:
		overview_button.add_theme_color_override("font_color", INK)
		overview_button.add_theme_color_override("font_hover_color", INK)
		overview_button.add_theme_color_override("font_pressed_color", INK)
		overview_button.add_theme_stylebox_override("normal", _panel(Color("#f8ebca"), Color("#c6a66a"), 12, 2))
		overview_button.add_theme_stylebox_override("hover", _panel(Color("#fff4d7"), GOLD, 12, 3))
		overview_button.add_theme_stylebox_override("pressed", _panel(Color("#ead7ac"), GOLD, 12, 3))
	info.add_child(overview_button)
	hud.add_child(info)
	top_hud.add_child(hud)
	vertical.add_child(top_hud)
	stage_band = PanelContainer.new()
	stage_band.name = "StageBand"
	stage_band.custom_minimum_size.y = 48 if is_kyoto_ui else 54
	stage_band.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 10, 2))
	var stage_row := HBoxContainer.new()
	var stage_title := _label("", 22, INK)
	stage_title.name = "StageTitle"
	stage_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_row.add_child(stage_title)
	stage_route_label = _label("本線　旅のスタート", 16, _stage_accent(), HORIZONTAL_ALIGNMENT_RIGHT)
	stage_row.add_child(stage_route_label)
	if stage_id == StageCatalog.STAGE_KYOTO:
		# Keep the goshuin collection visible as Kyoto-specific stage context,
		# separate from the shared lap mission below.
		goshuin_mission_label = stage_route_label
	var back := _button("‹", _request_back, false)
	back.name = "BackButton"
	back.custom_minimum_size = Vector2(46, 40)
	back.add_theme_font_size_override("font_size", 27)
	stage_row.add_child(back)
	stage_band.add_child(stage_row)
	vertical.add_child(stage_band)
	mission_band = PanelContainer.new()
	mission_band.name = "MissionBand"
	mission_value_labels.clear()
	mission_band.custom_minimum_size.y = 120 if is_kyoto_ui else 74
	mission_band.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 10, 2))
	var mission_row := HBoxContainer.new()
	mission_row.add_theme_constant_override("separation", 4)
	var mission_title := _label("MISSION", 22 if is_kyoto_ui else 14, INK, HORIZONTAL_ALIGNMENT_CENTER)
	mission_title.custom_minimum_size.x = 118 if is_kyoto_ui else 62
	mission_row.add_child(mission_title)
	if is_kyoto_ui:
		mission_row.add_child(_journey_mission_cell())
	else:
		mission_row.add_child(_mission_cell("無傷", "継続中", ICON_REST))
		mission_row.add_child(_mission_cell("コイン", "獲得 0/12", ICON_COIN))
		mission_row.add_child(_mission_cell("発見", "0/5", ICON_SPECIAL))
	mission_band.add_child(mission_row)
	vertical.add_child(mission_band)
	content_host = Control.new()
	content_host.name = "StageContent"
	content_host.custom_minimum_size.y = 360
	content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_host.clip_contents = true
	vertical.add_child(content_host)
	var status_panel := PanelContainer.new()
	status_panel.name = "MessageBand"
	status_panel.custom_minimum_size.y = 72 if is_kyoto_ui else 52
	status_panel.add_theme_stylebox_override("panel", _panel(Color("#2e1e17"), GOLD, 9, 2))
	# Keep the operation band reserved for live movement/effect feedback. The
	# antique die already communicates the idle action, so no duplicate
	# "サイコロを振ろう" prompt is painted beneath the map.
	status_label = _label("", 18, Color("#f5e5bd"), HORIZONTAL_ALIGNMENT_CENTER)
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_panel.add_child(status_label)
	vertical.add_child(status_panel)
	controls_box = VBoxContainer.new()
	controls_box.name = "ControlsBox"
	controls_box.custom_minimum_size.y = 335 if is_kyoto_ui else 326
	controls_box.add_theme_constant_override("separation", 7)
	vertical.add_child(controls_box)
	idle_timer = Timer.new()
	idle_timer.wait_time = 0.18
	idle_timer.timeout.connect(_advance_idle_frame)
	add_child(idle_timer)
	idle_timer.start()
	dice_se_player = AudioStreamPlayer.new()
	dice_se_player.name = "JourneyDiceSE"
	add_child(dice_se_player)


func _start_journey() -> void:
	if stage_id == StageCatalog.STAGE_KYOTO:
		journey = KyotoJourney.new()
	else:
		stage_id = StageCatalog.STAGE_AMAZON
		journey = AmazonJourney.new()
	var title := stage_band.find_child("StageTitle", true, false) as Label
	title.text = journey.stage_name
	_render_map()
	_refresh_all()
	if show_stage_intro:
		call_deferred("_show_stage_intro")


func _render_map() -> void:
	if is_instance_valid(top_hud):
		top_hud.modulate = Color.WHITE
	if is_instance_valid(stage_band):
		stage_band.modulate = Color.WHITE
	if is_instance_valid(mission_band):
		mission_band.modulate = Color.WHITE
	if is_instance_valid(kyoto_boss_scene):
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
	if is_instance_valid(kyoto_chase_scene):
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
	amazon_boss = null
	map_roll_active = false
	map_roll_elapsed = 0.0
	map_roll_face = 1
	map_movement_active = false
	roll_animation_active = false
	amazon_boss_roll_active = false
	amazon_boss_roll_elapsed = 0.0
	amazon_boss_roll_face = 1
	amazon_boss_move_active = false
	aquafall_visual_lane = -1
	aquafall_visual_height = -1
	aquafall_visual_obstacles.clear()
	aquafall_animation_step = 0
	aquafall_animation_total = 0
	if map_camera_tween != null:
		map_camera_tween.kill()
		map_camera_tween = null
	map_camera_follow_origin = 0.0
	_clear_content()
	_clear_controls()
	roll_slots.clear()
	_play_stage_map_bgm()
	map_background = TextureRect.new()
	map_background.texture = KYOTO_MAP if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_MAP
	map_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_host.add_child(map_background)
	var shade := ColorRect.new()
	shade.color = Color(0.16, 0.10, 0.045, 0.18) if stage_id == StageCatalog.STAGE_KYOTO else Color(0.03, 0.05, 0.04, 0.14)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_host.add_child(shade)
	map_node_layer = Control.new()
	map_node_layer.clip_contents = true
	map_node_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_node_layer.z_index = 8
	content_host.add_child(map_node_layer)
	var map_frame := PanelContainer.new()
	map_frame.name = "AtlasFrame"
	map_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_frame.add_theme_stylebox_override("panel", _panel(Color(0, 0, 0, 0), GOLD, 8, 2))
	content_host.add_child(map_frame)
	# The Cairo-style Kyoto horizon makes the seven cards authoritative in
	# normal play. Route-line legend and the full 99-node topology belong to the
	# dedicated 全体マップ, where both remain available.
	if stage_id != StageCatalog.STAGE_KYOTO:
		_add_route_legend(content_host)
	var route_preview := PanelContainer.new()
	route_preview.name = "LocalRoutePreview"
	if stage_id == StageCatalog.STAGE_KYOTO:
		# Kyoto's normal-play map uses a Cairo-style card horizon as the primary
		# route readout. It is laid out from the content size below so the same
		# design coordinates scale cleanly to the 360x640 capture.
		route_preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
		route_preview.z_index = 12
		route_preview.custom_minimum_size = Vector2(0.0, KYOTO_HORIZON_CARD_HEIGHT)
	else:
		route_preview.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		route_preview.offset_left = 10
		route_preview.offset_top = -116
		route_preview.offset_right = -10
		route_preview.offset_bottom = -8
		route_preview.add_theme_stylebox_override("panel", _panel(Color(0.96, 0.90, 0.75, 0.93), GOLD, 12, 2))
	if stage_id == StageCatalog.STAGE_KYOTO:
		var horizon_style := _panel(Color(0.96, 0.90, 0.75, 0.97), GOLD, 14, 3)
		horizon_style.content_margin_left = 5
		horizon_style.content_margin_right = 5
		horizon_style.content_margin_top = 8
		horizon_style.content_margin_bottom = 8
		route_preview.add_theme_stylebox_override("panel", horizon_style)
	route_preview_row = HBoxContainer.new()
	route_preview_row.name = "RoutePreviewRow"
	route_preview_row.add_theme_constant_override("separation", 4)
	route_preview.add_child(route_preview_row)
	content_host.add_child(route_preview)
	if stage_id == StageCatalog.STAGE_KYOTO:
		var layout_callable := Callable(self, "_layout_kyoto_card_horizon")
		if not content_host.resized.is_connected(layout_callable):
			content_host.resized.connect(layout_callable)
	_refresh_route_preview_for_space(journey.current_space_id)
	map_dice = DICE_PRESENTATION.new()
	map_dice.name = "MapDicePresentation"
	map_dice.overlay_compact = true
	map_dice.compact_single = true
	map_dice.tray_surface_visible = false
	map_dice.high_contrast_pips = true
	content_host.add_child(map_dice)
	if stage_id == StageCatalog.STAGE_KYOTO:
		map_dice.set_anchors_preset(Control.PRESET_TOP_LEFT)
		map_dice.custom_minimum_size = Vector2(KYOTO_HORIZON_DIE_SIZE, KYOTO_HORIZON_DIE_SIZE)
		map_dice.size = Vector2(KYOTO_HORIZON_DIE_SIZE, KYOTO_HORIZON_DIE_SIZE)
		map_dice.z_index = 16
	else:
		map_dice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		# Keep the primary die in the same lower-right dock on the Amazon map. The
		# route strip remains the authoritative forecast there.
		var dice_x_offset := 188.0
		map_dice.offset_left = -80 + dice_x_offset
		map_dice.offset_top = -284
		map_dice.offset_right = 80 + dice_x_offset
		map_dice.offset_bottom = -124
	map_dice.present([1], false, 1)
	if stage_id == StageCatalog.STAGE_KYOTO:
		call_deferred("_layout_kyoto_card_horizon")
	_update_local_view_window()
	call_deferred("_apply_background_camera")
	call_deferred("_populate_map_nodes")
	_build_travel_tray()


func _layout_kyoto_card_horizon() -> void:
	if stage_id != StageCatalog.STAGE_KYOTO:
		return
	if not is_instance_valid(content_host) or not is_instance_valid(route_preview_row) or not is_instance_valid(map_dice):
		return
	if content_host.size.x <= 0.0 or content_host.size.y <= 0.0:
		call_deferred("_layout_kyoto_card_horizon")
		return
	var route_preview := route_preview_row.get_parent() as PanelContainer
	if route_preview == null:
		return
	var content_size := content_host.size
	var horizon_width := clampf(content_size.x - 16.0, 300.0, minf(696.0, content_size.x - 8.0))
	var die_size := clampf(content_size.y * 0.31, KYOTO_HORIZON_DIE_MIN_SIZE, KYOTO_HORIZON_DIE_SIZE)
	var card_height := clampf(content_size.y * 0.48, KYOTO_HORIZON_CARD_MIN_HEIGHT, KYOTO_HORIZON_CARD_HEIGHT)
	var panel_height := card_height + 16.0
	var total_height := panel_height + KYOTO_HORIZON_GAP + die_size
	var row_y := clampf(
		content_size.y * 0.40,
		12.0,
		maxf(12.0, content_size.y - total_height - 12.0)
	)
	route_preview.custom_minimum_size = Vector2(horizon_width, panel_height)
	route_preview.position = Vector2((content_size.x - horizon_width) * 0.5, row_y)
	route_preview.size = Vector2(horizon_width, panel_height)
	route_preview_row.custom_minimum_size = Vector2(0.0, card_height)
	for child: Node in route_preview_row.get_children():
		var tile := child as Control
		if tile == null:
			continue
		tile.custom_minimum_size.y = card_height
		var tile_content := tile.get_node_or_null("TileContent") as Control
		if tile_content != null:
			tile_content.custom_minimum_size.y = card_height
			var motion_player := tile_content.get_node_or_null("MotionPlayer") as TextureRect
			if motion_player != null:
				motion_player.size = Vector2(KYOTO_HORIZON_CAT_SIZE, KYOTO_HORIZON_CAT_SIZE)
				motion_player.position = Vector2(4.0, maxf(4.0, card_height - KYOTO_HORIZON_CAT_SIZE - 5.0))
	route_preview_row.queue_sort()
	map_dice.custom_minimum_size = Vector2(die_size, die_size)
	map_dice.size = Vector2(die_size, die_size)
	map_dice.position = Vector2(
		(content_size.x - die_size) * 0.5,
		row_y + panel_height + KYOTO_HORIZON_GAP
	)
	call_deferred("_sync_kyoto_horizon_anchors")


func _show_stage_intro() -> void:
	if journey == null or not show_stage_intro:
		return
	_show_overview_map(true)


func _show_overview_map(initial: bool = false) -> void:
	if journey == null:
		return
	if is_instance_valid(overview_overlay):
		return
	overview_overlay = Control.new()
	overview_overlay.name = "OverviewOverlay"
	overview_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overview_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root_layer.add_child(overview_overlay)
	var viewport_size := get_viewport_rect().size
	var overview_width := minf(680.0, maxf(viewport_size.x - 24.0, 300.0))
	var overview_height := minf(1000.0, maxf(viewport_size.y - 24.0, 560.0))
	var overview_map_height := clampf(overview_height - 176.0, 420.0, 736.0)
	var overview_map_width := overview_map_height * 9.0 / 16.0
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.03, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overview_overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.name = "OverviewPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -overview_width * 0.5
	panel.offset_top = -overview_height * 0.5
	panel.offset_right = overview_width * 0.5
	panel.offset_bottom = overview_height * 0.5
	panel.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 22, 4))
	overview_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := _label(("アマゾン" if stage_id == StageCatalog.STAGE_AMAZON else "京都") + "の旅路を見渡そう", 24, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 40
	box.add_child(title)
	var hint := _label("全体マップ" + ("　滝へ続く森の道" if stage_id == StageCatalog.STAGE_AMAZON else "　本線・2つの近道・4つの御朱印"), 13, _stage_accent(), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(hint)
	var map_view := Control.new()
	map_view.name = "OverviewMapView"
	# Both stage sources are 9:16 portrait routes. Give the overview a matching
	# viewport so the Amazon waterfall and Kyoto torii-to-bamboo route remain
	# aligned with their authored map coordinates instead of being cropped by a
	# wide KEEP_ASPECT_COVERED rectangle.
	# Both supplied stage paintings are portrait sources (9:16). Keep the
	# overview viewport portrait too; the old Amazon layout expanded to a wide
	# box and KEEP_ASPECT_COVERED cropped away the actual route geometry.
	map_view.custom_minimum_size = Vector2(overview_map_width, overview_map_height)
	map_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	map_view.clip_contents = true
	overview_sweep_layer = Control.new()
	overview_sweep_layer.name = "OverviewSweepLayer"
	overview_sweep_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.add_child(overview_sweep_layer)
	var map_background := TextureRect.new()
	map_background.texture = KYOTO_MAP if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_MAP
	map_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overview_sweep_layer.add_child(map_background)
	var map_shade := ColorRect.new()
	map_shade.color = Color(0.04, 0.04, 0.03, 0.08)
	map_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overview_sweep_layer.add_child(map_shade)
	overview_node_layer = Control.new()
	overview_node_layer.name = "OverviewNodeLayer"
	overview_node_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overview_sweep_layer.add_child(overview_node_layer)
	_add_route_legend(map_view, true)
	box.add_child(map_view)
	var close_text := "コースを確認したら旅を始める" if initial else "全体マップを閉じる"
	var close_button := _button(close_text, _close_overview_map, true)
	close_button.name = "MapCloseButton"
	close_button.custom_minimum_size.y = 54
	box.add_child(close_button)
	panel.add_child(box)
	call_deferred("_populate_overview_nodes")


func _close_overview_map() -> void:
	if is_instance_valid(overview_overlay):
		overview_overlay.queue_free()
	overview_overlay = null
	overview_node_layer = null
	overview_sweep_layer = null
	if show_stage_intro:
		show_stage_intro = false
		status_label.text = ("アマゾンの旅を始めよう" if stage_id == StageCatalog.STAGE_AMAZON else "京都の旅を始めよう")
		if stage_id == StageCatalog.STAGE_KYOTO and not bool(journey.stage_flags.get("kyoto_goshuin_tutorial_seen", false)):
			call_deferred("_show_kyoto_goshuin_tutorial")


func _populate_overview_nodes() -> void:
	if not is_instance_valid(overview_node_layer) or journey == null:
		return
	var size := overview_node_layer.size
	if size.x <= 0.0 or size.y <= 0.0:
		call_deferred("_populate_overview_nodes")
		return
	for child: Node in overview_node_layer.get_children():
		child.queue_free()
	overview_marker_occupancy.clear()
	if stage_id == StageCatalog.STAGE_AMAZON:
		var amazon := journey as AmazonJourney
		_add_amazon_overview_route_lines(amazon, size)
		for value: Variant in amazon.course.spaces.values():
			if value is Dictionary:
				var space := value as Dictionary
				var pos: Array = space.get("map_pos", [])
				if pos.size() == 2:
					_add_overview_node(str(space.get("kind", "NORMAL")), Vector2(float(pos[0]) / 1000.0, 1.0 - float(pos[1]) / 3600.0), size, str(space.get("number", "")))
	else:
		var kyoto := journey as KyotoJourney
		_add_kyoto_overview_route_lines(kyoto, size)
		for value: Variant in kyoto.course.spaces.values():
			if not value is Dictionary:
				continue
			var space := value as Dictionary
			var space_id := str(space.get("id", ""))
			if space_id.is_empty():
				continue
			# Branch spaces do not have numeric labels in the course JSON. Keep their
			# route id as the tooltip/name so every detour remains inspectable in the
			# full-map view instead of becoming an anonymous duplicate marker.
			_add_overview_node(str(space.get("kind", "NORMAL")), _kyoto_overview_normalized_for_space(space_id), size, str(space.get("number", space_id)), 22.0)
	var cat := TextureRect.new()
	cat.texture = _cat_frame(0)
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat.size = Vector2(46, 46)
	cat.z_index = 5
	var cat_space := journey.current_space_id
	var cat_normalized := _map_normalized_for_space(cat_space) if stage_id == StageCatalog.STAGE_AMAZON else _kyoto_overview_normalized_for_space(cat_space)
	cat.position = Vector2(cat_normalized.x * size.x - 23, cat_normalized.y * size.y - 32)
	cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overview_node_layer.add_child(cat)
	_play_overview_sweep()


func _play_overview_sweep() -> void:
	if not is_instance_valid(overview_sweep_layer):
		return
	var layer_size := overview_sweep_layer.size
	overview_sweep_layer.pivot_offset = layer_size * 0.5
	overview_sweep_layer.scale = Vector2(1.14, 1.14)
	overview_sweep_layer.position = Vector2(0, 34)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overview_sweep_layer, "position", Vector2(0, -24), 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(overview_sweep_layer, "scale", Vector2(1.06, 1.06), 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)
	tween.tween_property(overview_sweep_layer, "position", Vector2.ZERO, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(overview_sweep_layer, "scale", Vector2.ONE, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _add_overview_node(kind: String, normalized: Vector2, layer_size: Vector2, number: String, marker_size_value: float = 30.0) -> void:
	var medal := PanelContainer.new()
	medal.name = "OverviewNode_%s" % number
	var is_boss := kind == "BOSS"
	# The full route contains many ordinary spaces. Keep those footprints tiny so
	# the semantic checkpoints (ITEM/EVENT/RISK/GOSHUIN and junctions) remain
	# individually readable instead of forming one solid column of medals.
	var actual_marker_size := marker_size_value
	if is_boss:
		actual_marker_size = maxf(marker_size_value, 64.0)
	elif kind == "NORMAL":
		actual_marker_size = minf(marker_size_value, 8.0)
	elif kind == "START":
		actual_marker_size = maxf(minf(marker_size_value, 22.0), 18.0)
	elif kind == "GOSHUIN":
		actual_marker_size = maxf(marker_size_value + 8.0, 28.0)
	else:
		actual_marker_size = clampf(marker_size_value, 17.0, 24.0)
	var half_size := actual_marker_size * 0.5
	medal.size = Vector2.ONE * actual_marker_size
	var desired_center := Vector2(clampf(normalized.x, 0.03, 0.97) * layer_size.x, clampf(normalized.y, 0.03, 0.97) * layer_size.y)
	var resolved_center := _resolve_overview_marker_center(desired_center, actual_marker_size, kind, layer_size)
	medal.position = resolved_center - Vector2.ONE * half_size
	var medal_style := _panel(Color("#351c27") if is_boss else TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL), Color("#f7d36c") if is_boss else Color("#fff0bc"), int(half_size), 4 if is_boss else 2)
	medal_style.content_margin_left = 3
	medal_style.content_margin_right = 3
	medal_style.content_margin_top = 3
	medal_style.content_margin_bottom = 3
	medal.add_theme_stylebox_override("panel", medal_style)
	if is_boss:
		medal.z_index = 3
	medal.tooltip_text = "BOSS" if is_boss else number
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_boss:
		var emblem := BOSS_MAP_EMBLEM_SCRIPT.new() as Control
		emblem.custom_minimum_size = Vector2(actual_marker_size - 6.0, actual_marker_size - 6.0)
		emblem.size = Vector2(actual_marker_size - 6.0, actual_marker_size - 6.0)
		medal.add_child(emblem)
	else:
		var marker := TextureRect.new()
		marker.texture = _icon_for_kind(kind)
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.modulate = _icon_modulate_for_kind(kind)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.add_child(marker)
	overview_node_layer.add_child(medal)


func _resolve_overview_marker_center(desired: Vector2, marker_size: float, kind: String, layer_size: Vector2) -> Vector2:
	# Only semantic markers need a nudge. Ordinary footprints are deliberately
	# dense route texture; moving them would make the plotted spine look wavy.
	if kind == "NORMAL":
		return desired
	var offsets: Array[Vector2] = [
		Vector2.ZERO, Vector2(0, -18), Vector2(0, 18), Vector2(-20, 0), Vector2(20, 0),
		Vector2(-18, -18), Vector2(18, -18), Vector2(-18, 18), Vector2(18, 18),
		Vector2(-30, 0), Vector2(30, 0), Vector2(0, -30), Vector2(0, 30),
		Vector2(-34, -20), Vector2(34, -20), Vector2(-34, 20), Vector2(34, 20),
	]
	var chosen := desired
	for offset: Vector2 in offsets:
		var candidate := Vector2(
			clampf(desired.x + offset.x, marker_size * 0.5 + 2.0, layer_size.x - marker_size * 0.5 - 2.0),
			clampf(desired.y + offset.y, marker_size * 0.5 + 2.0, layer_size.y - marker_size * 0.5 - 2.0)
		)
		var clear := true
		for occupied: Dictionary in overview_marker_occupancy:
			var other_center := occupied.get("center", Vector2.ZERO) as Vector2
			var other_size := float(occupied.get("size", 0.0))
			if candidate.distance_to(other_center) < (marker_size + other_size) * 0.5 + 2.0:
				clear = false
				break
		if clear:
			chosen = candidate
			break
	overview_marker_occupancy.append({"center": chosen, "size": marker_size})
	return chosen


func _add_kyoto_overview_route_lines(kyoto: KyotoJourney, layer_size: Vector2) -> void:
	var main_points: PackedVector2Array = []
	for number: int in range(1, 91):
		main_points.append(_kyoto_overview_normalized_for_space("main:%d" % number) * layer_size)
	_add_overview_route_line(main_points, Color("#f2c968"), 3.0)
	var routes: Dictionary = {}
	for value: Variant in kyoto.course.spaces.values():
		if value is Dictionary:
			var space := value as Dictionary
			var route_id := str(space.get("route", "main"))
			if route_id != "main":
				if not routes.has(route_id):
					routes[route_id] = []
				(routes[route_id] as Array).append(space)
	for route_id: String in routes:
		var route_spaces: Array = routes[route_id]
		route_spaces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("route_order", 0)) < int(b.get("route_order", 0))
		)
		var points: PackedVector2Array = []
		var anchor := _kyoto_route_anchor(kyoto, route_id)
		if not anchor.is_empty():
			points.append(_kyoto_overview_normalized_for_space("main:%d" % int(anchor.get("entry", 1))) * layer_size)
		for space: Dictionary in route_spaces:
			points.append(_kyoto_overview_normalized_for_space(str(space.get("id", ""))) * layer_size)
		if not anchor.is_empty():
			points.append(_kyoto_overview_normalized_for_space("main:%d" % int(anchor.get("rejoin", 90))) * layer_size)
		_add_overview_route_line(points, _stage_accent().lightened(0.12), 2.0)


func _add_overview_route_line(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() < 2 or not is_instance_valid(overview_node_layer):
		return
	var line := Line2D.new()
	line.name = "OverviewRouteLine"
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	# Keep the route stroke above the painted background but below semantic
	# medals. A negative z-index would put it behind the sibling TextureRect,
	# making the legend visible while the actual branch connector disappears.
	line.z_index = 0
	overview_node_layer.add_child(line)


func _kyoto_overview_normalized_for_space(space_id_value: String) -> Vector2:
	if space_id_value.begins_with("main:"):
		var number := clampi(int(space_id_value.get_slice(":", 1)), 1, 90)
		var waypoint_numbers: Array[int] = [1, 22, 23, 45, 46, 68, 69, 89, 90]
		var x := 0.5
		for index: int in range(waypoint_numbers.size() - 1):
			var from_number := waypoint_numbers[index]
			var to_number := waypoint_numbers[index + 1]
			if number <= to_number:
				var t := float(number - from_number) / float(maxi(to_number - from_number, 1))
				x = lerpf(float(KYOTO_MAIN_WAYPOINTS[from_number]), float(KYOTO_MAIN_WAYPOINTS[to_number]), clampf(t, 0.0, 1.0))
				break
		var y := lerpf(0.94, 0.055, float(number - 1) / 89.0)
		return Vector2(x + sin(float(number) * 0.42) * 0.012, y)
	var kyoto := journey as KyotoJourney
	if kyoto == null:
		return Vector2(0.5, 0.5)
	var space := kyoto.course.space(space_id_value)
	var route_id := str(space.get("route", ""))
	var route_order := int(space.get("route_order", 0))
	var route_count := maxi(int(space.get("route_count", 1)), 1)
	var anchor := _kyoto_route_anchor(kyoto, route_id)
	if anchor.is_empty():
		return Vector2(0.5, 0.5)
	var entry_position := _kyoto_overview_normalized_for_space("main:%d" % int(anchor.get("entry", 1)))
	var rejoin_position := _kyoto_overview_normalized_for_space("main:%d" % int(anchor.get("rejoin", 90)))
	var t := float(route_order + 1) / float(route_count + 1)
	var side := float(anchor.get("side", -1.0))
	var base := entry_position.lerp(rejoin_position, clampf(t, 0.0, 1.0))
	# A four-space loop sits between adjacent main spaces (for example
	# Gion 38→39 and the night stone garden 61→62). A straight interpolation
	# puts every detour icon on top of the same y-coordinate. Short loops
	# therefore keep their gentle arc spacing. Longer pilgrimages and shortcuts
	# must, however, continue in the same upward direction as the main route:
	# the previous centered offset was larger than the entry/rejoin delta, so a
	# six-space detour visibly ran backwards and a three-space shortcut collapsed
	# into nearly one y-coordinate. Expand the interpolated lane around its
	# midpoint instead; this preserves direction while giving every marker
	# enough vertical separation in the close local camera.
	var main_gap := absf(float(anchor.get("rejoin", 90)) - float(anchor.get("entry", 1)))
	var route_y := base.y
	if main_gap <= 2.0:
		var centered_order := float(route_order) - float(route_count - 1) * 0.5
		var route_center_y := (entry_position.y + rejoin_position.y) * 0.5
		# Kyoto advances upward (smaller normalized y). Keep the compact loop in
		# that same reading direction and use a fixed gap large enough for 42px
		# medals in the 12%-high local camera. The old positive offset sent the
		# right-hand loop downward and pushed its middle checkpoints off-screen.
		route_y = route_center_y - centered_order * 0.018
	else:
		var route_center_y := (entry_position.y + rejoin_position.y) * 0.5
		route_y = route_center_y + (base.y - route_center_y) * 1.22
	var route_depth := 0.09 + sin(t * PI) * 0.045
	return Vector2(
		clampf(base.x + side * route_depth, 0.035, 0.965),
		clampf(route_y, 0.025, 0.975)
	)


func _kyoto_route_anchor(kyoto: KyotoJourney, route_id: String) -> Dictionary:
	if route_id.is_empty() or route_id == "main":
		return {}
	var first_route_space := ""
	for value: Variant in kyoto.course.spaces.values():
		if value is Dictionary:
			var candidate := value as Dictionary
			if str(candidate.get("route", "")) == route_id and int(candidate.get("route_order", -1)) == 0:
				first_route_space = str(candidate.get("id", ""))
				break
	if first_route_space.is_empty():
		return {}
	var rejoin := 90
	for value: Variant in kyoto.course.definition.get("routes", []):
		if value is Dictionary and str((value as Dictionary).get("id", "")) == route_id:
			var rejoin_id := str((value as Dictionary).get("rejoin", "main:90"))
			if rejoin_id.begins_with("main:"):
				rejoin = int(rejoin_id.get_slice(":", 1))
			break
	for value: Variant in kyoto.course.spaces.values():
		if not value is Dictionary:
			continue
		var main_space := value as Dictionary
		var main_id := str(main_space.get("id", ""))
		if not main_id.begins_with("main:") or str(main_space.get("branch_id", "")).is_empty():
			continue
		var branch := kyoto.course.branch(str(main_space.get("branch_id", "")))
		var choices: Array = branch.get("choices", [])
		for choice_index: int in range(choices.size()):
			if choices[choice_index] is Dictionary and str((choices[choice_index] as Dictionary).get("target", "")) == first_route_space:
				return {"entry": int(main_id.get_slice(":", 1)), "rejoin": rejoin, "side": float(KYOTO_ROUTE_SIDES.get(route_id, -1.0))}
	return {}


func _build_travel_tray() -> void:
	_build_roll_tray(_roll_map, true)


func _build_boss_roll_tray() -> void:
	_build_roll_tray(_aquafall_roll, false)


func _build_roll_tray(roll_callback: Callable, include_tools: bool) -> void:
	var is_kyoto_ui := stage_id == StageCatalog.STAGE_KYOTO and include_tools
	var tray := PanelContainer.new()
	tray.name = "TravelRollTray"
	tray.custom_minimum_size.y = 220 if is_kyoto_ui else 248
	tray.add_theme_stylebox_override("panel", _panel(Color("#f2dfb6"), GOLD, 14, 2))
	var tray_root := Control.new()
	tray_root.custom_minimum_size.y = 212 if is_kyoto_ui else 240
	travel_tray_root = tray_root
	primary_roll_controls = Control.new()
	primary_roll_controls.name = "PrimaryRollControls"
	primary_roll_controls.size = SLOT_DESIGN_SIZE
	tray_root.add_child(primary_roll_controls)
	var tray_art := TextureRect.new()
	tray_art.texture = SLOT_TRAY_ART
	tray_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# The source is exactly 2:1. A 448x224 rect removes invisible letterboxing,
	# letting slot values share the artwork's own window centers pixel-for-pixel.
	tray_art.position = Vector2.ZERO
	tray_art.size = Vector2(448, 224)
	tray_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary_roll_controls.add_child(tray_art)
	roll_slot_labels.clear()
	roll_slot_panels.clear()
	for index: int in range(3):
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % index
		slot.position = Vector2(42.0 + float(index) * 126.0, 58.0)
		slot.size = Vector2(112.0, 112.0)
		slot.add_theme_stylebox_override("panel", _panel(Color(0.08, 0.07, 0.06, 0.34), Color(0, 0, 0, 0), 9, 0))
		var value := _label("—", 48, Color("#f7edca"), HORIZONTAL_ALIGNMENT_CENTER)
		value.name = "Value"
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_child(value)
		primary_roll_controls.add_child(slot)
		roll_slot_panels.append(slot)
		roll_slot_labels.append(value)
	var roll_texture := TextureButton.new()
	roll_texture.name = "RollButton"
	roll_texture.texture_normal = ROLL_BUTTON_ART
	roll_texture.ignore_texture_size = true
	roll_texture.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	roll_texture.position = Vector2(456, 16)
	roll_texture.size = Vector2(192, 192)
	# The antique die artwork is self-explanatory. Avoid Godot's translucent
	# hover tooltip covering the tray on touch devices.
	roll_texture.tooltip_text = ""
	roll_texture.pressed.connect(roll_callback)
	primary_roll_controls.add_child(roll_texture)
	var roll_die_art := TextureRect.new()
	roll_die_art.texture = DICE_ART
	roll_die_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	roll_die_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	roll_die_art.position = Vector2(490, 34)
	roll_die_art.size = Vector2(124, 124)
	roll_die_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary_roll_controls.add_child(roll_die_art)
	# The antique die illustration is the idle affordance. Keep the duplicate
	# caption hidden until a roll is actually in progress, so no translucent
	# "サイコロを振る" copy floats over the primary control.
	roll_caption_label = _label("", 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	roll_caption_label.position = Vector2(502, 162)
	roll_caption_label.size = Vector2(100, 34)
	roll_caption_label.visible = false
	roll_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary_roll_controls.add_child(roll_caption_label)
	roll_button = roll_texture
	tray.add_child(tray_root)
	controls_box.add_child(tray)
	tray_root.resized.connect(_layout_travel_controls)
	call_deferred("_layout_travel_controls")
	if include_tools:
		_build_tool_dock()


func _layout_travel_controls() -> void:
	if not is_instance_valid(travel_tray_root) or not is_instance_valid(primary_roll_controls):
		return
	var available_width := maxf(travel_tray_root.size.x, 1.0)
	var available_height := maxf(travel_tray_root.size.y, 1.0)
	var scale_factor := minf(1.0, minf(available_width / SLOT_DESIGN_SIZE.x, available_height / SLOT_DESIGN_SIZE.y)) if stage_id == StageCatalog.STAGE_KYOTO else minf(1.0, available_width / SLOT_DESIGN_SIZE.x)
	primary_roll_controls.scale = Vector2.ONE * scale_factor
	primary_roll_controls.position = Vector2(
		maxf((available_width - SLOT_DESIGN_SIZE.x * scale_factor) * 0.5, 0.0),
		maxf((travel_tray_root.size.y - SLOT_DESIGN_SIZE.y * scale_factor) * 0.5, 0.0)
	)


func _build_tool_dock() -> void:
	var dock := PanelContainer.new()
	dock.name = "ToolDock"
	dock.custom_minimum_size.y = 108 if stage_id == StageCatalog.STAGE_KYOTO else 72
	dock.add_theme_stylebox_override("panel", _panel(Color("#f1dfb8") if stage_id == StageCatalog.STAGE_KYOTO else Color("#ead4a5"), GOLD, 12, 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	item_card_button = _tool_button("アイテム\n0/3", ITEM_CARD_ICON, _show_item_card)
	item_card_button.name = "ItemCardButton"
	row.add_child(item_card_button)
	coin_tool_button = _tool_button("コイン\n0", ICON_COIN, _show_coin_tool)
	coin_tool_button.name = "CoinToolButton"
	row.add_child(coin_tool_button)
	skill_tool_button = _tool_button("スキル\n0/3", SKILL_CARD_ICON, _show_skill_tool)
	skill_tool_button.name = "SkillToolButton"
	row.add_child(skill_tool_button)
	row.add_child(_tool_button("メニュー", MENU_ICON, _show_menu_tool))
	dock.add_child(row)
	controls_box.add_child(dock)


func _tool_button(text_value: String, icon: Texture2D, callback: Callable) -> Button:
	var button := _button(text_value, callback, false)
	button.custom_minimum_size = Vector2(0, 100 if stage_id == StageCatalog.STAGE_KYOTO else 68)
	button.add_theme_font_size_override("font_size", 16 if stage_id == StageCatalog.STAGE_KYOTO else 14)
	if stage_id == StageCatalog.STAGE_KYOTO:
		button.add_theme_color_override("font_color", INK)
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
		button.add_theme_stylebox_override("normal", _panel(Color("#fbefd2"), Color("#b89559"), 11, 2))
		button.add_theme_stylebox_override("hover", _panel(Color("#fff7e3"), GOLD, 11, 3))
		button.add_theme_stylebox_override("pressed", _panel(Color("#e8d3a7"), GOLD, 11, 3))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_view := TextureRect.new()
	icon_view.texture = icon
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tool_icon_size := 36.0 if stage_id == StageCatalog.STAGE_KYOTO else 30.0
	icon_view.position = Vector2(9, 13) if stage_id == StageCatalog.STAGE_KYOTO else Vector2(10, 10)
	icon_view.size = Vector2.ONE * tool_icon_size
	icon_view.custom_minimum_size = Vector2.ONE * tool_icon_size
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_view)
	return button


func _route_tile(text_value: String, kind: String, current: bool, space_id_value: String = "") -> PanelContainer:
	var tile := PanelContainer.new()
	tile.set_meta("space_id", space_id_value)
	tile.set_meta("kind", kind)
	tile.set_meta("current", current)
	var is_kyoto_horizon := stage_id == StageCatalog.STAGE_KYOTO
	var tile_height := KYOTO_HORIZON_CARD_HEIGHT if is_kyoto_horizon else 66.0
	tile.custom_minimum_size = Vector2(0, tile_height)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tile_fill := Color("#e8d8b4") if not current else _stage_accent()
	if is_kyoto_horizon and not current:
		tile_fill = Color("#f3e5c4")
	tile.add_theme_stylebox_override("panel", _panel(tile_fill, GOLD, 12 if is_kyoto_horizon else 9, 3 if is_kyoto_horizon else 2))
	var tile_content := Control.new()
	tile_content.name = "TileContent"
	tile_content.custom_minimum_size = Vector2(0, tile_height)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var horizon_caption_size := 24 if current else 36
	var caption := _label(text_value, horizon_caption_size if is_kyoto_horizon else 14, Color.WHITE if current else INK, HORIZONTAL_ALIGNMENT_CENTER)
	if is_kyoto_horizon:
		caption.custom_minimum_size.y = 60
	caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(caption)
	var is_boss := kind == "BOSS"
	var medal := PanelContainer.new()
	var medal_height := 44.0 if is_boss else (142.0 if is_kyoto_horizon else 34.0)
	medal.custom_minimum_size = Vector2(0, medal_height)
	medal.add_theme_stylebox_override("panel", _panel(Color("#351c27") if is_boss else TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL), Color("#f7d36c") if is_boss else Color("#684c2f"), 9 if is_boss else (10 if is_kyoto_horizon else 7), 3 if is_boss else (2 if is_kyoto_horizon else 1)))
	if is_boss:
		var emblem := BOSS_MAP_EMBLEM_SCRIPT.new() as Control
		emblem.custom_minimum_size = Vector2(0, 42)
		emblem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		emblem.size_flags_vertical = Control.SIZE_EXPAND_FILL
		emblem.set("compact", true)
		medal.add_child(emblem)
	else:
		var icon_view := TextureRect.new()
		icon_view.texture = _icon_for_kind(kind)
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_view.custom_minimum_size = Vector2(0, 112 if is_kyoto_horizon else 26)
		icon_view.modulate = _icon_modulate_for_kind(kind)
		if is_kyoto_horizon and current:
			# The large explorer owns the lower half of the current card. Hide the
			# centered copy and surface the same semantic icon in the clear space
			# between the caption and the explorer instead.
			icon_view.modulate.a = 0.0
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.add_child(icon_view)
	box.add_child(medal)
	tile_content.add_child(box)
	if is_kyoto_horizon and current and not is_boss:
		var kind_badge := PanelContainer.new()
		kind_badge.name = "CurrentKindBadge"
		kind_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		kind_badge.offset_left = -50.0
		kind_badge.offset_top = 64.0
		kind_badge.offset_right = -4.0
		kind_badge.offset_bottom = 110.0
		kind_badge.z_index = 36
		kind_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kind_badge.add_theme_stylebox_override("panel", _panel(TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL), Color("#684c2f"), 9, 2))
		var badge_icon := TextureRect.new()
		badge_icon.name = "KindIcon"
		badge_icon.texture = _icon_for_kind(kind)
		badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_icon.modulate = _icon_modulate_for_kind(kind)
		badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kind_badge.add_child(badge_icon)
		tile_content.add_child(kind_badge)
	var motion_player := TextureRect.new()
	motion_player.name = "MotionPlayer"
	motion_player.texture = _cat_frame(0)
	motion_player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	motion_player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	motion_player.position = Vector2(4, KYOTO_HORIZON_CARD_HEIGHT - KYOTO_HORIZON_CAT_SIZE - 5.0) if is_kyoto_horizon else Vector2(4, 1)
	motion_player.size = Vector2(KYOTO_HORIZON_CAT_SIZE, KYOTO_HORIZON_CAT_SIZE) if is_kyoto_horizon else Vector2(30, 30)
	motion_player.modulate = Color.WHITE
	motion_player.visible = false
	motion_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_content.add_child(motion_player)
	tile.set_meta("motion_player", motion_player)
	tile.add_child(tile_content)
	return tile


func _current_space_kind() -> String:
	return _space_kind(journey.current_space_id)


func _future_space_kind(step: int) -> String:
	var preview_space := journey.current_space_id
	for _index: int in range(step):
		var next_space := _next_preview_space_id(preview_space)
		if next_space.is_empty():
			break
		preview_space = next_space
	return _space_kind(preview_space)


func _refresh_route_preview_for_space(space_id_value: String) -> void:
	if not is_instance_valid(route_preview_row) or journey == null:
		return
	for child: Node in route_preview_row.get_children():
		route_preview_row.remove_child(child)
		child.queue_free()
	var preview_space := space_id_value
	route_preview_row.add_child(_route_tile("現在地", _space_kind(preview_space), true, preview_space))
	for step: int in range(1, 7):
		var next_space := _next_preview_space_id(preview_space)
		if not next_space.is_empty():
			preview_space = next_space
		route_preview_row.add_child(_route_tile("+%d" % step, _space_kind(preview_space), false, preview_space))
	_set_route_preview_motion_marker(space_id_value)
	if stage_id == StageCatalog.STAGE_KYOTO:
		call_deferred("_layout_kyoto_card_horizon")
		call_deferred("_sync_kyoto_horizon_anchors")


func _set_route_preview_motion_marker(space_id_value: String) -> void:
	if not is_instance_valid(route_preview_row):
		return
	var is_kyoto_horizon := stage_id == StageCatalog.STAGE_KYOTO
	for child: Node in route_preview_row.get_children():
		var tile := child as PanelContainer
		if tile == null:
			continue
		var is_active := str(tile.get_meta("space_id", "")) == space_id_value
		var kind := str(tile.get_meta("kind", "NORMAL"))
		var is_current := bool(tile.get_meta("current", false))
		var base_color := _stage_accent() if is_current else (Color("#f3e5c4") if is_kyoto_horizon else Color("#e8d8b4"))
		var border := GOLD
		var width := 3 if is_kyoto_horizon else 2
		if is_active:
			base_color = _stage_accent().lightened(0.16)
			border = Color("#fff0a6")
			width = 3
		tile.add_theme_stylebox_override("panel", _panel(base_color, border, 12 if is_kyoto_horizon else 9, width))
		var motion_player := tile.get_meta("motion_player") as TextureRect
		if motion_player != null:
			motion_player.visible = is_active
			if is_active:
				motion_player.texture = _cat_frame((idle_frame + 1) % 4)
				# The Kyoto horizon uses the larger map-layer cat as its single visible
				# traveler. Keep the legacy per-card marker alive for callers/tests, but
				# transparent so it never creates a duplicate cat silhouette.
				motion_player.modulate = Color(1.0, 1.0, 1.0, 0.0) if is_kyoto_horizon else Color.WHITE
	if is_kyoto_horizon and is_instance_valid(map_player) and not map_movement_active:
		map_player.visible = true
		_position_map_player()


func _next_preview_space_id(space_id_value: String) -> String:
	if space_id_value.is_empty() or journey == null:
		return ""
	if stage_id == StageCatalog.STAGE_AMAZON:
		var amazon_space := (journey as AmazonJourney).course.space(space_id_value)
		var next_values: Array = amazon_space.get("next", [])
		if next_values.size() > 1:
			var branch_data := amazon_space.get("branch", {}) as Dictionary
			var choices: Array = branch_data.get("choices", [])
			if not choices.is_empty():
				return str((choices[0] as Dictionary).get("target", ""))
		if not next_values.is_empty():
			return str(next_values[0])
		return ""
	var kyoto_space := (journey as KyotoJourney).course.space(space_id_value)
	var branch_id := str(kyoto_space.get("branch_id", ""))
	if not branch_id.is_empty():
		var branch_data := (journey as KyotoJourney).course.branch(branch_id)
		var choices: Array = branch_data.get("choices", [])
		if not choices.is_empty():
			return str((choices[0] as Dictionary).get("target", ""))
	return str(kyoto_space.get("next_id", ""))


func _space_kind(space_id_value: String) -> String:
	if stage_id == StageCatalog.STAGE_AMAZON:
		return str((journey as AmazonJourney).course.space(space_id_value).get("kind", "NORMAL"))
	return str((journey as KyotoJourney).course.space(space_id_value).get("kind", "NORMAL"))


func _mission_cell(title_text: String, value_text: String, icon: Texture2D) -> Control:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _panel(Color("#f6e7c5"), Color("#c0a66f"), 7, 1))
	var row := HBoxContainer.new()
	var icon_view := TextureRect.new()
	icon_view.texture = icon
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.custom_minimum_size = Vector2(32, 32)
	row.add_child(icon_view)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(title_text, 14, INK))
	var value_label := _label(value_text, 13, _stage_accent())
	mission_value_labels[title_text] = value_label
	if title_text == "御朱印":
		goshuin_mission_label = value_label
	copy.add_child(value_label)
	row.add_child(copy)
	cell.add_child(row)
	return cell


func _journey_mission_cell() -> Control:
	var mission := journey.journey_mission_state() if journey != null else {}
	var cell := PanelContainer.new()
	cell.name = "JourneyMissionCell"
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", _panel(Color("#f6e7c5"), Color("#c0a66f"), 9, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	mission_icon_view = TextureRect.new()
	mission_icon_view.name = "MissionIcon"
	mission_icon_view.texture = _journey_mission_icon(str(mission.get("icon_kind", "dice")))
	mission_icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mission_icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mission_icon_view.custom_minimum_size = Vector2(56, 56)
	mission_icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mission_icon_view)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	mission_caption_label = _label(str(mission.get("short_text", "旅の目標")), 20, INK)
	mission_caption_label.name = "MissionCaption"
	mission_progress_label = _label("進捗 0/1　報酬 COIN ×12", 20, _stage_accent())
	mission_progress_label.name = "MissionProgress"
	copy.add_child(mission_caption_label)
	copy.add_child(mission_progress_label)
	row.add_child(copy)
	cell.add_child(row)
	return cell


func _journey_mission_icon(icon_kind: String) -> Texture2D:
	match icon_kind:
		"coin": return ICON_COIN
		"trip": return ICON_NORMAL
		"slot": return SKILL_CARD_ICON
		_: return DICE_ART


func _populate_map_nodes() -> void:
	if not is_instance_valid(map_node_layer):
		return
	map_node_layer.position = Vector2.ZERO
	for child: Node in map_node_layer.get_children():
		map_node_layer.remove_child(child)
		child.queue_free()
	if stage_id == StageCatalog.STAGE_KYOTO:
		_build_kyoto_map_nodes()
	else:
		_build_amazon_map_nodes()
	map_player = TextureRect.new()
	map_player.name = "ExplorerCat"
	map_player.texture = _cat_frame(0)
	map_player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var player_size := Vector2(KYOTO_HORIZON_CAT_SIZE, KYOTO_HORIZON_CAT_SIZE) if stage_id == StageCatalog.STAGE_KYOTO else Vector2(60, 60)
	map_player.custom_minimum_size = player_size
	map_player.size = player_size
	map_player.z_index = 20 if stage_id == StageCatalog.STAGE_KYOTO else 5
	map_player.visible = true
	map_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_node_layer.add_child(map_player)
	_position_map_player()
	if stage_id == StageCatalog.STAGE_KYOTO:
		call_deferred("_sync_kyoto_horizon_anchors")


func _build_amazon_map_nodes() -> void:
	var amazon := journey as AmazonJourney
	var layer_size := map_node_layer.size
	_add_amazon_local_route_lines(amazon, layer_size)
	for space_value: Variant in amazon.course.spaces.values():
		if not space_value is Dictionary:
			continue
		var space := space_value as Dictionary
		var pos_values: Array = space.get("map_pos", [])
		if pos_values.size() != 2:
			continue
		var world_y := 1.0 - float(pos_values[1]) / 3600.0
		var normalized := Vector2(float(pos_values[0]) / 1000.0, _local_y(world_y))
		_add_map_node(str(space.get("id", "")), str(space.get("kind", "NORMAL")), normalized, int(space.get("number", 0)), layer_size)


func _build_kyoto_map_nodes() -> void:
	# Normal play is deliberately uncluttered: the background supplies place,
	# while current through +6 supplies navigation. Invisible card anchors are
	# created below for the explorer hop animation. The full route, shortcuts,
	# goshuin and boss markers are still drawn in 全体マップ.
	_sync_kyoto_horizon_anchors()


func _sync_kyoto_horizon_anchors() -> void:
	if stage_id != StageCatalog.STAGE_KYOTO or not is_instance_valid(map_node_layer) or not is_instance_valid(route_preview_row):
		return
	for child: Node in map_node_layer.get_children():
		if child.name.begins_with("space_") and bool(child.get_meta("kyoto_horizon_anchor", false)):
			map_node_layer.remove_child(child)
			child.queue_free()
	var layer_transform := map_node_layer.get_global_transform_with_canvas().affine_inverse()
	var anchor_ids: Dictionary = {}
	var anchor_count := 0
	for child: Node in route_preview_row.get_children():
		var tile := child as Control
		if tile == null:
			continue
		var space_id_value := str(tile.get_meta("space_id", ""))
		if space_id_value.is_empty() or anchor_ids.has(space_id_value):
			continue
		var tile_rect := tile.get_global_rect()
		if tile_rect.size.x <= 0.0 or tile_rect.size.y <= 0.0:
			continue
		var anchor_name := "space_%s" % space_id_value.replace(":", "_")
		var anchor := map_node_layer.get_node_or_null(anchor_name) as Control
		var existing_marker := anchor != null and not bool(anchor.get_meta("kyoto_horizon_anchor", false))
		if anchor == null:
			anchor = Control.new()
			anchor.name = anchor_name
			anchor.set_meta("kyoto_horizon_anchor", true)
		elif existing_marker:
			# Boss/semantic markers keep their authored emblem and size, but follow
			# the current horizon card when that space is in the visible seven.
			anchor.set_meta("kyoto_horizon_anchor", false)
		var tile_local_position := layer_transform * tile_rect.position
		if not existing_marker:
			# A compact hidden anchor keeps the public foot-offset contract while
			# placing the 112px visible cat on the lower half of the card with a
			# five-pixel bottom inset.
			anchor.size = Vector2(KYOTO_HORIZON_ANCHOR_SIZE, KYOTO_HORIZON_ANCHOR_SIZE)
			anchor.position = tile_local_position + Vector2(
				(tile_rect.size.x - KYOTO_HORIZON_ANCHOR_SIZE) * 0.5,
				tile_rect.size.y - KYOTO_HORIZON_ANCHOR_SIZE
			)
		else:
			anchor.position = tile_local_position
		anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not existing_marker:
			anchor.visible = false
			map_node_layer.add_child(anchor)
		else:
			anchor.position += (tile_rect.size - anchor.size) * 0.5
		anchor_ids[space_id_value] = true
		anchor_count += 1
	if anchor_count == 0 and route_preview_row.get_child_count() > 0:
		call_deferred("_sync_kyoto_horizon_anchors")
	elif is_instance_valid(map_player) and not map_movement_active:
		_position_map_player()


func _add_amazon_overview_route_lines(amazon: AmazonJourney, layer_size: Vector2) -> void:
	if amazon == null or not is_instance_valid(overview_node_layer):
		return
	for value: Variant in amazon.course.spaces.values():
		if not value is Dictionary:
			continue
		var space := value as Dictionary
		var from_id := str(space.get("id", ""))
		var from_point := _amazon_overview_normalized_for_space(space)
		if from_id.is_empty() or from_point.x < 0.0:
			continue
		var from_route := str(space.get("route", "main"))
		for target_value: Variant in space.get("next", []):
			var target_id := str(target_value)
			var target := amazon.course.space(target_id)
			var target_point := _amazon_overview_normalized_for_space(target)
			if target.is_empty() or target_point.x < 0.0:
				continue
			var side_route := _amazon_edge_is_side(amazon, from_route, str(target.get("route", "main")))
			_add_overview_route_line(PackedVector2Array([from_point * layer_size, target_point * layer_size]), _route_line_color(side_route), 3.0 if not side_route else 2.5)


func _amazon_overview_normalized_for_space(space: Dictionary) -> Vector2:
	var pos_values: Array = space.get("map_pos", [])
	if pos_values.size() != 2:
		return Vector2(-1.0, -1.0)
	return Vector2(float(pos_values[0]) / 1000.0, 1.0 - float(pos_values[1]) / 3600.0)


func _add_amazon_local_route_lines(amazon: AmazonJourney, layer_size: Vector2) -> void:
	if amazon == null or not is_instance_valid(map_node_layer):
		return
	for value: Variant in amazon.course.spaces.values():
		if not value is Dictionary:
			continue
		var space := value as Dictionary
		var from_id := str(space.get("id", ""))
		if from_id.is_empty():
			continue
		var from_route := str(space.get("route", "main"))
		for target_value: Variant in space.get("next", []):
			var target_id := str(target_value)
			var target := amazon.course.space(target_id)
			if target.is_empty():
				continue
			var side_route := _amazon_edge_is_side(amazon, from_route, str(target.get("route", "main")))
			_add_local_route_edge(from_id, target_id, side_route, layer_size)


func _add_kyoto_local_route_lines(kyoto: KyotoJourney, layer_size: Vector2) -> void:
	if kyoto == null or not is_instance_valid(map_node_layer):
		return
	var seen_edges: Dictionary = {}
	for value: Variant in kyoto.course.spaces.values():
		if not value is Dictionary:
			continue
		var space := value as Dictionary
		var from_id := str(space.get("id", ""))
		if from_id.is_empty():
			continue
		var from_route := str(space.get("route", "main"))
		var targets: Array[String] = []
		var next_id := str(space.get("next_id", ""))
		if not next_id.is_empty():
			targets.append(next_id)
		var branch_id := str(space.get("branch_id", ""))
		if not branch_id.is_empty():
			var branch := kyoto.course.branch(branch_id)
			for choice_value: Variant in branch.get("choices", []):
				if choice_value is Dictionary:
					var choice_target := str((choice_value as Dictionary).get("target", ""))
					if not choice_target.is_empty():
						targets.append(choice_target)
		for target_id: String in targets:
			if target_id.is_empty() or not kyoto.course.spaces.has(target_id):
				continue
			var edge_key := "%s>%s" % [from_id, target_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			var target := kyoto.course.space(target_id)
			var side_route := from_route != "main" or str(target.get("route", "main")) != "main"
			_add_local_route_edge(from_id, target_id, side_route, layer_size)


func _add_local_route_edge(from_id: String, target_id: String, side_route: bool, layer_size: Vector2) -> void:
	if not is_instance_valid(map_node_layer):
		return
	var from_point := _map_normalized_for_space(from_id)
	var target_point := _map_normalized_for_space(target_id)
	var points := PackedVector2Array([
		Vector2(from_point.x * layer_size.x, from_point.y * layer_size.y),
		Vector2(target_point.x * layer_size.x, target_point.y * layer_size.y),
	])
	var line := Line2D.new()
	line.name = "LocalRouteSide" if side_route else "LocalRouteMain"
	line.points = points
	line.width = 5.0 if side_route else 7.0
	line.default_color = _route_line_color(side_route)
	line.antialiased = true
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	# map_node_layer is already above the scenic TextureRect. Keep connectors at
	# the layer's base z so markers/player (added afterwards at higher/tree-order
	# priority) remain readable while the branch strokes stay visible.
	line.z_index = 0
	map_node_layer.add_child(line)


func _route_line_color(side_route: bool) -> Color:
	return _stage_accent().lightened(0.14) if side_route else Color("#f2c968")


func _amazon_edge_is_side(amazon: AmazonJourney, from_route: String, target_route: String) -> bool:
	if from_route == "main" and target_route == "main":
		return false
	# Amazon's authored branch groups have no literal `main` target. The low-risk
	# route is the primary-side line (gold), while high/medium-risk routes remain
	# stage-accent detours; this matches the labels shown in the choice card.
	return not (_amazon_route_is_primary(amazon, from_route) and _amazon_route_is_primary(amazon, target_route))


func _amazon_route_is_primary(amazon: AmazonJourney, route_id: String) -> bool:
	if route_id == "main":
		return true
	if amazon == null:
		return false
	for group: Dictionary in amazon.course.route_groups():
		if str(group.get("id", "")) == route_id:
			return str(group.get("risk_level", "")) == "low"
	return false


func _add_route_legend(parent: Control, overview: bool = false) -> void:
	if parent == null:
		return
	var legend := PanelContainer.new()
	legend.name = "RouteLegend"
	legend.position = Vector2(10, 10)
	legend.custom_minimum_size = Vector2(132 if not overview else 124, 54)
	legend.z_index = 30
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_theme_stylebox_override("panel", _panel(Color(0.08, 0.07, 0.06, 0.84), Color("#c9a65a"), 9, 1))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	var title := _label("道しるべ", 11 if overview else 12, Color("#f5dfae"), HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 17
	stack.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var main_swatch := ColorRect.new()
	main_swatch.color = _route_line_color(false)
	main_swatch.custom_minimum_size = Vector2(20, 5)
	main_swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(main_swatch)
	row.add_child(_label("本線", 12 if overview else 13, Color("#fff0c1")))
	var side_swatch := ColorRect.new()
	side_swatch.color = _route_line_color(true)
	side_swatch.custom_minimum_size = Vector2(20, 5)
	side_swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(side_swatch)
	row.add_child(_label("脇道", 12 if overview else 13, Color("#fff0c1")))
	stack.add_child(row)
	legend.add_child(stack)
	parent.add_child(legend)


func _add_map_node(space_id_value: String, kind: String, normalized: Vector2, number: int, layer_size: Vector2) -> void:
	# The normal map is a close camera around the traveler. Do not keep the
	# neighboring off-camera markers alive: their 42px medals used to stack at
	# the top and bottom edges and made the route unreadable.
	if normalized.y < 0.06 or normalized.y > 0.94:
		return
	var marker := PanelContainer.new()
	marker.name = "space_%s" % space_id_value.replace(":", "_")
	var is_boss := kind == "BOSS"
	var is_goshuin := kind == "GOSHUIN"
	var marker_size := 70.0 if is_boss else (52.0 if is_goshuin else (36.0 if stage_id == StageCatalog.STAGE_AMAZON else 42.0))
	var marker_radius := int(marker_size * 0.5)
	marker.custom_minimum_size = Vector2(marker_size, marker_size)
	marker.size = Vector2(marker_size, marker_size)
	marker.pivot_offset = Vector2.ONE * marker_size * 0.5
	marker.position = Vector2(clampf(normalized.x, 0.05, 0.95) * layer_size.x - marker_size * 0.5, clampf(normalized.y, 0.03, 0.97) * layer_size.y - marker_size * 0.5)
	var marker_style := _panel(Color("#351c27") if is_boss else TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL), Color("#f7d36c") if is_boss else (Color("#ffe0a1") if is_goshuin else Color("#4d3827")), marker_radius, 4 if is_boss else (3 if is_goshuin else 2))
	marker_style.content_margin_left = 4
	marker_style.content_margin_right = 4
	marker_style.content_margin_top = 4
	marker_style.content_margin_bottom = 4
	marker.add_theme_stylebox_override("panel", marker_style)
	if is_boss:
		marker.z_index = 3
	if is_boss:
		var emblem := BOSS_MAP_EMBLEM_SCRIPT.new() as Control
		emblem.custom_minimum_size = Vector2(marker_size - 8.0, marker_size - 8.0)
		emblem.size = Vector2(marker_size - 8.0, marker_size - 8.0)
		marker.add_child(emblem)
	else:
		var icon := TextureRect.new()
		icon.texture = _icon_for_kind(kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(marker_size - 8.0, marker_size - 8.0)
		icon.modulate = _icon_modulate_for_kind(kind)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_child(icon)
	marker.tooltip_text = "BOSS" if is_boss else ("御朱印・%s" % str(number) if is_goshuin else "%d・%s" % [number, kind])
	# Keep the boss crest at full contrast even before the final square is
	# discovered; the destination itself should remain legible as a goal.
	marker.modulate = Color.WHITE if is_boss or journey.discovered.has(space_id_value) else Color(0.76, 0.78, 0.72, 0.82)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_node_layer.add_child(marker)


func _icon_for_kind(kind: String) -> Texture2D:
	match kind:
		"COIN": return ICON_COIN
		"EVENT": return ICON_EVENT
		"REST": return ICON_REST
		"RISK": return ICON_RISK
		"SPECIAL", "JUNCTION", "GOSHUIN", "ITEM", "BOSS": return ICON_SPECIAL
	return ICON_NORMAL


func _icon_modulate_for_kind(kind: String) -> Color:
	# The generated Cairo footprints are white line art. A dark earth-brown
	# tint keeps NORMAL readable on the cream route tile and the pale map medals,
	# while leaving the stage-specific icons in their original colors.
	return Color("#604a35") if kind == "NORMAL" else Color.WHITE


func _position_map_player() -> void:
	if not is_instance_valid(map_player) or not is_instance_valid(map_node_layer):
		return
	var previous_min := local_view_y_min
	_update_local_view_window()
	if not is_equal_approx(previous_min, local_view_y_min):
		_apply_background_camera()
		_populate_map_nodes()
		return
	map_player.position = _map_player_position_for_space(journey.current_space_id)
	map_player.move_to_front()


func _update_local_view_window() -> void:
	# Show roughly 10–12% of the portrait course instead of 36–40%. This is the
	# normal-play camera; the opening presentation and 全体マップ retain the
	# complete route. The closer crop gives every semantic medal breathing room.
	local_view_y_min = _local_view_min_for_space(journey.current_space_id)
	local_view_y_max = local_view_y_min + _map_window_size()
	if is_instance_valid(map_background):
		map_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _map_window_size() -> float:
	return LOCAL_MAP_WINDOW_AMAZON if stage_id == StageCatalog.STAGE_AMAZON else LOCAL_MAP_WINDOW_KYOTO


func _local_view_min_for_space(space_id_value: String) -> float:
	var space_y := _world_y_for_space(space_id_value)
	var window_size := _map_window_size()
	var player_view_y := 0.5
	if stage_id == StageCatalog.STAGE_AMAZON:
		# Keep the traveler near the upper quarter so the next ten spaces remain
		# visible before the post-landing camera follow catches up.
		player_view_y = 0.20
	elif stage_id == StageCatalog.STAGE_KYOTO:
		# Kyoto advances upward through the portrait route. Docking the traveler
		# below center gives roughly twice as much room to upcoming checkpoints as
		# to already-passed spaces without crowding the route-preview strip.
		player_view_y = 0.66
	return clampf(space_y - window_size * player_view_y, 0.0, 1.0 - window_size)


func _apply_background_camera() -> void:
	if not is_instance_valid(map_background) or not is_instance_valid(content_host):
		return
	if content_host.size.x <= 0.0 or content_host.size.y <= 0.0:
		call_deferred("_apply_background_camera")
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = KYOTO_MAP if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_MAP
	var texture_size := Vector2(atlas.atlas.get_width(), atlas.atlas.get_height())
	var region_y := local_view_y_min * texture_size.y
	var region_height := (local_view_y_max - local_view_y_min) * texture_size.y
	atlas.region = Rect2(0.0, region_y, texture_size.x, region_height)
	map_background.texture = atlas
	map_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _current_world_y() -> float:
	return _world_y_for_space(journey.current_space_id)


func _world_y_for_space(space_id_value: String) -> float:
	if stage_id == StageCatalog.STAGE_AMAZON:
		var space := (journey as AmazonJourney).course.space(space_id_value)
		var pos_values: Array = space.get("map_pos", [])
		if pos_values.size() == 2:
			return 1.0 - float(pos_values[1]) / 3600.0
	if stage_id == StageCatalog.STAGE_KYOTO:
		# The Kyoto portrait is a continuous Fushimi → Gion → Kiyomizu →
		# Arashiyama road, not a ten-column board. Reuse the annotated overview
		# waypoints for the local camera so main and detour markers stay on the
		# painted path too.
		return _kyoto_overview_normalized_for_space(space_id_value).y
	if space_id_value.begins_with("main:"):
		var number := clampi(int(space_id_value.get_slice(":", 1)), 1, 90)
		var row := int(floor(float(number - 1) / 10.0))
		return 0.93 - float(row) * 0.103
	return 0.5


func _map_normalized_for_space(space_id_value: String) -> Vector2:
	if stage_id == StageCatalog.STAGE_AMAZON:
		var amazon_space := (journey as AmazonJourney).course.space(space_id_value)
		var pos_values: Array = amazon_space.get("map_pos", [])
		if pos_values.size() == 2:
			return Vector2(float(pos_values[0]) / 1000.0, _local_y(1.0 - float(pos_values[1]) / 3600.0))
		return Vector2(0.5, 0.5)
	if stage_id == StageCatalog.STAGE_KYOTO:
		var kyoto_point := _kyoto_overview_normalized_for_space(space_id_value)
		return Vector2(kyoto_point.x, _local_y(kyoto_point.y))
	if space_id_value.begins_with("main:"):
		var number := clampi(int(space_id_value.get_slice(":", 1)), 1, 90)
		var row := int(floor(float(number - 1) / 10.0))
		var column := (number - 1) % 10
		var x := (0.12 + float(column) * 0.084) if row % 2 == 0 else (0.88 - float(column) * 0.084)
		return Vector2(x, _local_y(0.93 - float(row) * 0.103))
	return Vector2(0.5, 0.5)


func _map_player_position_for_space(space_id_value: String) -> Vector2:
	if not is_instance_valid(map_player) or not is_instance_valid(map_node_layer):
		return Vector2.ZERO
	var target := map_node_layer.get_node_or_null("space_%s" % space_id_value.replace(":", "_")) as Control
	if target != null:
		if stage_id == StageCatalog.STAGE_KYOTO and bool(target.get_meta("kyoto_horizon_anchor", false)):
			# Keep the card label clear and plant the explorer over the semantic
			# medal, matching Cairo's current-card silhouette.
			return target.position + Vector2(
				(target.size.x - map_player.size.x) * 0.5,
				target.size.y - map_player.size.y - 6.0
			)
		return target.position + target.size * 0.5 - map_player.size * 0.5 + MAP_PLAYER_FOOT_OFFSET
	var normalized := _map_normalized_for_space(space_id_value)
	return Vector2(normalized.x * map_node_layer.size.x, normalized.y * map_node_layer.size.y) - map_player.size * 0.5 + MAP_PLAYER_FOOT_OFFSET


func _local_y(world_y: float) -> float:
	return (world_y - local_view_y_min) / maxf(local_view_y_max - local_view_y_min, 0.001)


func _roll_map() -> void:
	if journey == null:
		return
	# Cairo's tactile rhythm is a two-tap interaction: first tap starts the
	# carousel, second tap locks the visible face. Keep the button live while
	# rolling, then disable it only during the hop/effect/camera sequence.
	if map_roll_active:
		_stop_map_roll()
		return
	if map_movement_active or roll_animation_active or not journey.can_roll():
		return
	_begin_map_roll()


func _begin_map_roll() -> void:
	_prepare_next_slot_cycle()
	map_roll_active = true
	map_roll_elapsed = 0.0
	map_roll_face = 1
	roll_animation_active = false
	if is_instance_valid(roll_button):
		roll_button.disabled = false
		roll_button.tooltip_text = "タップで止める"
	if is_instance_valid(roll_caption_label):
		roll_caption_label.text = "止める"
		roll_caption_label.visible = true
	if is_instance_valid(map_dice):
		map_dice.present([map_roll_face], true, 0)
		map_dice.sync_rolling_elapsed(map_roll_elapsed)
	_play_dice_se(DICE_ROLL_SE)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.text = "ダイス回転中　—　タップで止める"
	_refresh_all()


func _stop_map_roll() -> void:
	if not map_roll_active or journey == null:
		return
	map_roll_active = false
	map_movement_active = true
	roll_animation_active = true
	var skill_face := journey.peek_skill_face()
	var face := skill_face if skill_face > 0 else clampi(map_roll_face, 1, 6)
	if is_instance_valid(roll_button):
		roll_button.tooltip_text = ""
	if is_instance_valid(roll_caption_label):
		roll_caption_label.text = ""
		roll_caption_label.visible = false
	if is_instance_valid(map_dice):
		map_dice.present([face], false, 1)
	_play_dice_se(DICE_LAND_SE)
	roll_slots.append(face)
	_refresh_roll_slots()
	var hp_before := journey.hp
	var life_before := journey.life
	var start_space := journey.current_space_id
	# Lock the input surface as soon as STOP is tapped; the logical roll below
	# still resolves before the first hop so the HUD can reveal its effect only
	# after the landing presentation completes.
	_refresh_all()
	var result: Dictionary = journey.roll(face)
	if not bool(result.get("ok", false)):
		map_movement_active = false
		roll_animation_active = false
		status_label.text = _journey_result_text(result)
		_refresh_all()
		return
	if stage_id == StageCatalog.STAGE_KYOTO:
		journey.record_journey_mission_roll(face, (result.get("path", []) as Array).size())
	if skill_face > 0:
		journey.consume_skill_face()
	status_label.text = "出目 %d！　%dマス進む…" % [face, face]
	_refresh_roll_slots()
	if _should_show_amazon_flow_tutorial(result):
		_show_amazon_flow_tutorial(start_space, result, hp_before, life_before, face)
		return
	await _finish_map_roll_transition(start_space, result, hp_before, life_before, face)


func _should_show_amazon_flow_tutorial(result: Dictionary) -> bool:
	return stage_id == StageCatalog.STAGE_AMAZON and int(result.get("flow_chain", 0)) > 0 and not bool(journey.stage_flags.get("amazon_flow_tutorial_seen", false))


func _show_amazon_flow_tutorial(start_space: String, result: Dictionary, hp_before: int, life_before: int, face: int) -> void:
	_open_choice_modal("青い急流マス", "青いマスに止まると、流れに乗って先のマスへ移動します。\n読んだらタップして、急流の移動を見てみよう。", [{"id": "continue", "label": "わかった。流れを見る"}], func(_choice_id: String) -> void:
		journey.stage_flags["amazon_flow_tutorial_seen"] = true
		await _finish_map_roll_transition(start_space, result, hp_before, life_before, face)
	, AMAZON_FLOW_TUTORIAL)


func _show_amazon_flow_event_tutorial(start_space: String, result: Dictionary) -> void:
	_open_choice_modal("青い急流マス", "青いマスに止まると、流れに乗って先のマスへ移動します。\n読んだらタップして、急流の移動を見てみよう。", [{"id": "continue", "label": "わかった。流れを見る"}], func(_choice_id: String) -> void:
		journey.stage_flags["amazon_flow_tutorial_seen"] = true
		await _animate_journey_movement(start_space, result)
		if not is_inside_tree():
			return
		map_movement_active = false
		roll_animation_active = false
		status_label.text = _journey_result_text(result)
		_refresh_all()
		_after_journey_action()
	, AMAZON_FLOW_TUTORIAL)


func _finish_map_roll_transition(start_space: String, result: Dictionary, hp_before: int, life_before: int, face: int) -> void:
	await get_tree().create_timer(0.18).timeout
	if not is_inside_tree():
		return
	await _animate_journey_movement(start_space, result)
	if not is_inside_tree():
		return
	status_label.text = _survival_result_text(hp_before, life_before, result, "ダイス %d　—　%s" % [face, _journey_result_text(result)])
	map_movement_active = false
	roll_animation_active = false
	_refresh_all()
	_show_slot_result_or_reach()
	_after_journey_action()


func _prepare_next_slot_cycle() -> void:
	# Cairo starts a fresh three-throw hand before the fourth throw. Clearing at
	# START (not after the third result) lets the completed hand remain readable.
	if roll_slots.size() >= 3:
		roll_slots.clear()
		pending_slot_role = ""
		slot_reach_signature = ""
		_refresh_roll_slots()


func _show_slot_result_or_reach() -> void:
	if roll_slots.size() == 2:
		var reach := _normal_slot_reach(roll_slots)
		if reach.is_empty():
			return
		var role := str(reach.get("role", ""))
		var signature := "%s:%s" % [role, str(reach.get("targets", []))]
		status_label.text = "%sリーチ！　%s" % [role, str(reach.get("hint", ""))]
		status_label.add_theme_font_size_override("font_size", 27)
		if signature == slot_reach_signature:
			return
		slot_reach_signature = signature
		_flash_roll_slots(2, Color("#ffd96a") if role == "TRIPLE" else Color("#76e0d0"))
		return
	if roll_slots.size() == 3:
		pending_slot_role = _completed_slot_role(roll_slots)
		if not pending_slot_role.is_empty():
			status_label.text = "%s！　3投の役がそろった" % pending_slot_role
			status_label.add_theme_font_size_override("font_size", 27)
			_flash_roll_slots(3, Color("#ffd96a"))
			var charge := journey.charge_skill_for_role(pending_slot_role, journey.roll_count)
			if stage_id == StageCatalog.STAGE_KYOTO:
				journey.record_journey_mission_role(pending_slot_role)
			status_label.text += "　スキル %d/%d" % [journey.skill_gauge(), StageJourneyBase.SKILL_GAUGE_MAX]
			if bool(charge.get("first_ready", false)) and not bool(journey.stage_flags.get("skill_ready_seen", false)):
				journey.stage_flags["skill_ready_seen"] = true
				_show_skill_ready_discovery()


func _show_skill_ready_discovery() -> void:
	_open_choice_modal("SKILL READY!", "次のサイコロの\n出目を選べる！\n\n今すぐ使わず、好きなタイミングで\n下のスキルボタンから選べます。", [{"id": "close", "label": "わかった（あとで使う）"}], func(_choice_id: String) -> void:
		# Cairo keeps the discovery card separate from the actual skill picker:
		# dismissing the explanation must not spend or arm the skill. The player
		# can continue rolling and open the READY button whenever it is useful.
		status_label.text = "スキルREADY！　好きなタイミングで使えます。"
		_refresh_all()
	, SKILL_CARD_ICON)


func _normal_slot_reach(values: Array[int]) -> Dictionary:
	if values.size() != 2:
		return {}
	var first := values[0]
	var second := values[1]
	if first == second:
		return {"role": "TRIPLE", "targets": [first], "hint": "同じ %d でTRIPLE！" % first}
	var step := second - first
	if absi(step) != 1:
		return {}
	var target := second + step
	if target < 1 or target > 6:
		return {}
	return {"role": "STRAIGHT", "targets": [target], "hint": "%d でSTRAIGHT！" % target}


func _completed_slot_role(values: Array[int]) -> String:
	if values.size() != 3:
		return ""
	if values[0] == values[1] and values[1] == values[2]:
		return "TRIPLE"
	# Cairo's STRAIGHT is order-sensitive: the dice must continue in one
	# direction. A shuffled set such as [1, 3, 2] remains a MIX.
	var first_step := values[1] - values[0]
	var second_step := values[2] - values[1]
	if absi(first_step) == 1 and second_step == first_step:
		return "STRAIGHT"
	return ""


func _flash_roll_slots(count: int, glow: Color) -> void:
	for index: int in range(mini(count, roll_slot_panels.size())):
		var panel := roll_slot_panels[index]
		if not is_instance_valid(panel):
			continue
		panel.modulate = glow
		var flash := create_tween()
		flash.tween_property(panel, "modulate", Color.WHITE, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_journey_movement(start_space: String, result: Dictionary) -> void:
	if not is_instance_valid(map_player) or not is_instance_valid(map_node_layer):
		return
	var path: Array[String] = []
	for value: Variant in result.get("path", []):
		var space_id_value := str(value)
		if not space_id_value.is_empty():
			path.append(space_id_value)
	# Flow tiles can resolve to one extra target after the dice path. Show that
	# target as the final hop, while a branch prompt correctly stops at the fork.
	var final_space := journey.current_space_id
	if str(result.get("status", "")) != "CHOICE_REQUIRED" and not final_space.is_empty() and (path.is_empty() or path.back() != final_space):
		path.append(final_space)
	var visual_position := _map_player_position_for_space(start_space)
	map_player.position = visual_position
	map_player.move_to_front()
	# Keep the settled seven-space horizon stable while the cat hops. Only the
	# lightweight marker moves during the animation; labels and semantic icons
	# are rebuilt after landing and camera follow.
	_set_route_preview_motion_marker(start_space)
	if path.is_empty():
		await _play_map_landing_effect(result)
		await _animate_map_camera_follow(final_space)
		return
	for step_index: int in range(path.size()):
		var target_position := _map_player_position_for_space(path[step_index])
		await _animate_map_hop(visual_position, target_position)
		if not is_inside_tree():
			return
		visual_position = target_position
		_set_route_preview_motion_marker(path[step_index])
		status_label.text = "%d / %d マス　%s" % [step_index + 1, path.size(), _space_kind(path[step_index])]
		var passed_stamp := _goshuin_event_for_space(result, path[step_index])
		if not passed_stamp.is_empty():
			await _play_goshuin_stamp(passed_stamp)
	await _play_map_landing_effect(result)
	await _animate_map_camera_follow(final_space)
	_refresh_route_preview_for_space(final_space)


func _animate_map_hop(from_position: Vector2, to_position: Vector2) -> void:
	if not is_instance_valid(map_player):
		return
	if _reduced_motion_enabled():
		map_player.position = to_position
		map_player.scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.tween_method(_apply_map_hop.bind(from_position, to_position), 0.0, 1.0, MAP_HOP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if is_instance_valid(map_player):
		map_player.position = to_position
		map_player.scale = Vector2.ONE


func _apply_map_hop(progress: float, from_position: Vector2, to_position: Vector2) -> void:
	if not is_instance_valid(map_player):
		return
	var t := clampf(progress, 0.0, 1.0)
	var arc := sin(t * PI) * 28.0
	map_player.position = from_position.lerp(to_position, t) + Vector2(0.0, -arc)
	map_player.scale = Vector2.ONE * (1.0 + sin(t * PI) * 0.08)


func _goshuin_event_for_space(result: Dictionary, space_id: String) -> Dictionary:
	var raw_events: Variant = result.get("goshuin_passed", [])
	if not raw_events is Array:
		return {}
	for value: Variant in raw_events:
		if value is Dictionary and str((value as Dictionary).get("space_id", "")) == space_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _play_goshuin_stamp(stamp: Dictionary) -> void:
	if not is_instance_valid(map_node_layer) or not is_instance_valid(map_player):
		return
	var title := str(stamp.get("title", "寺社"))
	status_label.text = "%s 御朱印をいただいた！" % title
	var popup := PanelContainer.new()
	popup.name = "GoshuinStampPopup"
	popup.custom_minimum_size = Vector2(300, 78)
	popup.size = Vector2(300, 78)
	popup.z_index = 24
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_stylebox_override("panel", _panel(Color("#fbefd9"), Color("#b54845"), 15, 3))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var seal := PanelContainer.new()
	seal.custom_minimum_size = Vector2(56, 56)
	seal.size = Vector2(56, 56)
	seal.add_theme_stylebox_override("panel", _panel(Color("#f8d9cf"), Color("#b54845"), 28, 3))
	var seal_copy := _label("朱印", 19, Color("#a4383c"), HORIZONTAL_ALIGNMENT_CENTER)
	seal_copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal.add_child(seal_copy)
	row.add_child(seal)
	var copy := _label("%s\n御朱印をいただいた！" % title, 17, Color("#5f3a32"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	popup.add_child(row)
	map_node_layer.add_child(popup)
	popup.position = Vector2(
		clampf(map_player.position.x - 112.0, 8.0, maxf(map_node_layer.size.x - 308.0, 8.0)),
		clampf(map_player.position.y - 104.0, 8.0, maxf(map_node_layer.size.y - 86.0, 8.0))
	)
	popup.pivot_offset = popup.size * 0.5
	popup.scale = Vector2(0.72, 0.72)
	popup.modulate.a = 0.0
	var appear := create_tween()
	appear.set_parallel(true)
	appear.tween_property(popup, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.tween_property(popup, "modulate:a", 1.0, 0.10)
	await get_tree().create_timer(0.48).timeout
	if not is_instance_valid(popup):
		return
	var disappear := create_tween()
	disappear.tween_property(popup, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await disappear.finished
	if is_instance_valid(popup):
		popup.queue_free()


func _play_map_landing_effect(result: Dictionary) -> void:
	var goshuin_passed: Array = result.get("goshuin_passed", []) as Array
	if stage_id == StageCatalog.STAGE_KYOTO and not goshuin_passed.is_empty() and _current_space_kind() == "GOSHUIN":
		# The checkpoint stamp already owns the landing pause and copy. Do not
		# stack a generic special-tile card over the seal animation.
		status_label.text = _landing_effect_text(result)
		return
	var landing_kind := "FLOW" if int(result.get("flow_chain", 0)) > 0 else _current_space_kind()
	status_label.text = _landing_effect_text(result)
	var effect_card: PanelContainer
	if is_instance_valid(map_node_layer) and is_instance_valid(map_player):
		effect_card = _landing_effect_card(landing_kind)
		map_node_layer.add_child(effect_card)
		effect_card.position = Vector2(
			clampf(map_player.position.x - 74.0, 8.0, maxf(map_node_layer.size.x - 236.0, 8.0)),
			clampf(map_player.position.y - 76.0, 8.0, maxf(map_node_layer.size.y - 56.0, 8.0))
		)
		effect_card.scale = Vector2(0.84, 0.84)
		effect_card.modulate.a = 0.0
	if not is_instance_valid(map_player):
		await get_tree().create_timer(MAP_LANDING_SECONDS).timeout
		if is_instance_valid(effect_card):
			effect_card.queue_free()
		return
	var player_tween := create_tween()
	player_tween.tween_property(map_player, "scale", Vector2(1.28, 1.28), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	player_tween.tween_property(map_player, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	player_tween.tween_property(map_player, "modulate", Color(1.0, 1.0, 1.0, 0.78), 0.08)
	player_tween.tween_property(map_player, "modulate", Color.WHITE, 0.18)
	if is_instance_valid(effect_card):
		var effect_tween := create_tween()
		effect_tween.tween_property(effect_card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		effect_tween.tween_property(effect_card, "modulate:a", 1.0, 0.12)
		effect_tween.tween_interval(0.18)
		effect_tween.tween_property(effect_card, "modulate:a", 0.0, 0.18)
	await get_tree().create_timer(MAP_LANDING_SECONDS).timeout
	if is_instance_valid(effect_card):
		effect_card.queue_free()


func _landing_effect_card(kind: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "LandingEffect"
	card.custom_minimum_size = Vector2(228, 50)
	card.size = Vector2(228, 50)
	card.z_index = 20
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_boss := kind == "BOSS"
	card.add_theme_stylebox_override("panel", _panel(Color("#351c27") if is_boss else TYPE_COLORS.get(kind, TYPE_COLORS.NORMAL), Color("#f7d36c") if is_boss else Color("#ffe7a2"), 14, 3 if is_boss else 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if is_boss:
		var emblem := BOSS_MAP_EMBLEM_SCRIPT.new() as Control
		emblem.custom_minimum_size = Vector2(42, 42)
		emblem.size = Vector2(42, 42)
		emblem.set("compact", true)
		row.add_child(emblem)
	else:
		var icon := TextureRect.new()
		icon.texture = _icon_for_kind(kind)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(34, 34)
		icon.modulate = _icon_modulate_for_kind(kind)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var copy := _label(_landing_effect_label(kind), 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	card.add_child(row)
	return card


func _landing_effect_label(kind: String) -> String:
	match kind:
		"COIN": return "コイン"
		"REST": return "休憩"
		"RISK": return "RISK"
		"EVENT": return "イベント"
		"ITEM": return "アイテム"
		"GOSHUIN": return "御朱印"
		"BOSS": return "ボス"
		"FLOW": return "急流"
		"SPECIAL", "JUNCTION": return "特別マス"
	return "通常マス"


func _landing_effect_text(result: Dictionary) -> String:
	if str(result.get("status", "")) == "CHOICE_REQUIRED":
		return "分岐点！　進む道をタップ"
	var goshuin_passed: Array = result.get("goshuin_passed", []) as Array
	if stage_id == StageCatalog.STAGE_KYOTO and not goshuin_passed.is_empty():
		var stamp: Dictionary = goshuin_passed[-1] as Dictionary
		return "%s 御朱印をいただいた！" % str(stamp.get("title", "寺社"))
	if int(result.get("flow_chain", 0)) > 0:
		return "急流マス！　青い流れに乗って先へ進む"
	var kind := _current_space_kind()
	match kind:
		"COIN": return "COINマス！　コインを見つけた"
		"REST":
			if int(result.get("skill_bonus", 0)) > 0:
				return "RESTマス！　HP満タンでSKILL +1"
			if int(result.get("coin_bonus", 0)) > 0:
				return "RESTマス！　HP満タンボーナス COIN +1"
			return "RESTマス！　ハートを整えた"
		"RISK": return "RISKマス！　足元に注意"
		"EVENT": return "EVENTマス！　旅のカードをめくろう"
		"ITEM":
			if bool(result.get("full", false)):
				return "ITEMマス！　バッグ満杯。コイン +2"
			var item_name := str(result.get("item_name", "アイテム"))
			return "ITEMマス！　%sを手に入れた" % item_name
		"GOSHUIN": return "寺社チェックポイント"
		"BOSS": return "BOSSマス！　守護者の試練へ"
		"FLOW": return "流れに乗った！　景色が切り替わる"
	return "マス効果！　%s" % _journey_result_text(result)


func _animate_map_camera_follow(space_id: String) -> void:
	if not is_instance_valid(map_background) or not is_instance_valid(map_node_layer):
		return
	var target_min := _local_view_min_for_space(space_id)
	if is_equal_approx(local_view_y_min, target_min):
		_populate_map_nodes()
		await _rebuild_kyoto_horizon_after_camera(space_id)
		return
	if map_camera_tween != null:
		map_camera_tween.kill()
	map_camera_follow_origin = local_view_y_min
	map_node_layer.position = Vector2.ZERO
	map_camera_tween = create_tween()
	map_camera_tween.tween_method(_set_map_camera_min, local_view_y_min, target_min, MAP_CAMERA_FOLLOW_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await map_camera_tween.finished
	if not is_inside_tree() or not is_instance_valid(map_node_layer):
		return
	local_view_y_min = target_min
	local_view_y_max = target_min + _map_window_size()
	map_camera_tween = null
	map_node_layer.position = Vector2.ZERO
	_populate_map_nodes()
	await _rebuild_kyoto_horizon_after_camera(space_id)


func _rebuild_kyoto_horizon_after_camera(space_id: String) -> void:
	if stage_id != StageCatalog.STAGE_KYOTO or not is_instance_valid(route_preview_row):
		_refresh_route_preview_for_space(space_id)
		return
	var route_preview := route_preview_row.get_parent() as Control
	if _reduced_motion_enabled() or route_preview == null:
		_refresh_route_preview_for_space(space_id)
		return
	var fade_out := create_tween()
	fade_out.tween_property(route_preview, "modulate:a", 0.72, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	if not is_inside_tree() or not is_instance_valid(route_preview):
		return
	_refresh_route_preview_for_space(space_id)
	_layout_kyoto_card_horizon()
	var fade_in := create_tween()
	fade_in.tween_property(route_preview, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished


func _reduced_motion_enabled() -> bool:
	return OS.get_environment("DICE_REDUCED_MOTION") == "1"


func _set_map_camera_min(value: float) -> void:
	local_view_y_min = clampf(value, 0.0, 1.0 - _map_window_size())
	local_view_y_max = local_view_y_min + _map_window_size()
	_apply_background_camera()
	if is_instance_valid(map_node_layer):
		if stage_id == StageCatalog.STAGE_KYOTO:
			# The Kyoto card horizon is a stable UI layer. Let the scenic portrait
			# crop follow the landing, while the single visible cat stays anchored to
			# the corresponding card instead of drifting beneath the row.
			map_node_layer.position = Vector2.ZERO
		else:
			# Keep the route medals and Explorer Cat glued to the same portrait
			# texture while the AtlasTexture crop eases to the new window.
			var y_offset := -(local_view_y_min - map_camera_follow_origin) / maxf(_map_window_size(), 0.001) * map_node_layer.size.y
			map_node_layer.position = Vector2(0.0, y_offset)


func _play_dice_se(stream: AudioStream) -> void:
	if not is_instance_valid(dice_se_player):
		return
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null and bool(game_state.get("dice_se_muted")):
		return
	var volume := float(game_state.get("se_volume")) if game_state != null else 1.0
	dice_se_player.volume_db = -80.0 if volume <= 0.0 else linear_to_db(volume)
	dice_se_player.stream = stream
	dice_se_player.play()


func _after_journey_action() -> void:
	_refresh_all()
	if journey.phase == StageJourneyBase.PHASE_BRANCH:
		if stage_id == StageCatalog.STAGE_KYOTO and not bool(journey.stage_flags.get("kyoto_route_tutorial_seen", false)):
			_show_kyoto_route_tutorial()
		else:
			_show_branch_modal()
	elif journey.phase == StageJourneyBase.PHASE_BOSS_CHOICE:
		_show_kyoto_boss_choice_modal()
	elif journey.phase == StageJourneyBase.PHASE_EVENT:
		_show_event_modal()
	elif journey.phase == StageJourneyBase.PHASE_SECRET:
		_show_secret_modal()
	elif journey.phase == StageJourneyBase.PHASE_BOSS:
		# The four-page Amazon rules are onboarding for the first two laps. From
		# lap three onward the player already knows the loop, so go straight to
		# the playable waterfall board (including saves made before this flag was
		# introduced).
		if stage_id == StageCatalog.STAGE_AMAZON and journey.lap >= 3:
			_start_aquafall_boss()
		else:
			_show_boss_intro()
	elif journey.phase == StageJourneyBase.PHASE_RUN_OVER:
		_show_run_over()
	else:
		_position_map_player()


func _show_branch_modal() -> void:
	var prompt := str(journey.pending_event.get("prompt", "どちらの道を進む？")) if stage_id == StageCatalog.STAGE_KYOTO else str(((journey as AmazonJourney).course.space(journey.current_space_id).get("branch", {}) as Dictionary).get("prompt", "どちらの道を進む？"))
	var choices: Array = []
	var preview_lines: Array[String] = []
	var main_candidate_index := _branch_main_candidate_index(journey.pending_choices)
	for choice_index: int in range(journey.pending_choices.size()):
		var value: Variant = journey.pending_choices[choice_index]
		if not value is Dictionary:
			continue
		var choice := (value as Dictionary).duplicate(true)
		var projection := _project_branch_choice(choice)
		var route_label := str(projection.get("route_label", "脇道"))
		# Amazon's course intentionally offers two named route groups at its
		# junctions rather than a literal `main` target. Treat the safer/longer
		# first-class option as the main-side choice so players can still read the
		# decision as 本線 vs 脇道; Kyoto keeps the data-driven main/side labels.
		if str(projection.get("route", "main")) != "main" and choice_index == main_candidate_index:
			route_label = "本線"
		elif str(projection.get("route", "main")) != "main":
			route_label = "脇道"
		var destination := str(projection.get("destination", "次のマス"))
		var destination_kind := str(projection.get("kind_label", "通常"))
		var moved_steps := int(projection.get("moved_steps", 0))
		var original_label := str(choice.get("label", choice.get("id", "道")))
		var stop_copy := "%s・%s" % [destination_kind, destination]
		choice["label"] = "%s　%s　→ %s" % [route_label, original_label, stop_copy]
		choices.append(choice)
		var detail := "%s　%s → %s・%s（%dマス後）" % [route_label, original_label, destination_kind, destination, maxi(moved_steps, 1)]
		preview_lines.append(detail)
	var remaining_steps := maxi(int(journey.pending_steps), 1)
	var body := "%s\n今回の残り%dマス。止まる予定を見て道を選べます。" % [prompt, remaining_steps]
	if not preview_lines.is_empty():
		body += "\n\n" + "\n".join(preview_lines)
	_open_choice_modal("分岐・近道" if stage_id == StageCatalog.STAGE_KYOTO else "道の分岐", body, choices, func(choice_id: String) -> void:
		var start_space := journey.current_space_id
		var result: Dictionary = journey.choose_branch(choice_id)
		if bool(result.get("ok", false)):
			map_movement_active = true
			roll_animation_active = true
			if is_instance_valid(roll_button):
				roll_button.disabled = true
			await _animate_journey_movement(start_space, result)
			map_movement_active = false
			roll_animation_active = false
		status_label.text = _journey_result_text(result)
		_after_journey_action()
	)


func _branch_main_candidate_index(raw_choices: Array) -> int:
	var first_main := -1
	for choice_index: int in range(raw_choices.size()):
		if not raw_choices[choice_index] is Dictionary:
			continue
		var choice := raw_choices[choice_index] as Dictionary
		var target_space := _journey_space(str(choice.get("target", "")))
		if str(target_space.get("route", "main")) == "main":
			first_main = choice_index
			break
	if first_main >= 0:
		return first_main
	# When both Amazon targets are alternate route groups, prefer the low-risk
	# route as the visually designated main-side option. This keeps the copy
	# stable even if the JSON order changes later.
	for choice_index: int in range(raw_choices.size()):
		if not raw_choices[choice_index] is Dictionary:
			continue
		var choice := raw_choices[choice_index] as Dictionary
		if str(choice.get("risk_level", "")) == "low":
			return choice_index
	return 0 if not raw_choices.is_empty() else -1


func _project_branch_choice(choice: Dictionary) -> Dictionary:
	var target_id := str(choice.get("target", ""))
	var route_id := "main"
	var destination := target_id
	var result: Dictionary = {}
	var distance := maxi(int(journey.pending_steps), 1)
	if stage_id == StageCatalog.STAGE_AMAZON:
		var amazon := journey as AmazonJourney
		var target_space := amazon.course.space(target_id) if amazon != null else {}
		route_id = str(target_space.get("route", "main"))
		result = amazon.course.advance(journey.current_space_id, distance, target_id) if amazon != null else {}
	else:
		var kyoto := journey as KyotoJourney
		var target_space := kyoto.course.space(target_id) if kyoto != null else {}
		route_id = str(target_space.get("route", "main"))
		result = kyoto.course.advance(journey.current_space_id, distance, target_id) if kyoto != null else {}
	if bool(result.get("ok", false)) or str(result.get("status", "")) == "CHOICE_REQUIRED":
		destination = str(result.get("position", target_id))
	var destination_space := _journey_space(destination)
	var destination_name := str(destination_space.get("name", ""))
	if destination_name.is_empty():
		# Never leak route IDs such as `stream:43` into the player-facing choice
		# card. Authored spaces normally have a name; malformed/legacy data gets a
		# harmless numbered fallback (or a generic stop) instead.
		if destination.begins_with("main:"):
			destination_name = "%sマス" % destination.get_slice(":", 1)
		else:
			destination_name = "次のマス"
	var destination_kind := str(destination_space.get("kind", "NORMAL"))
	var moved_steps := distance - int(result.get("remaining_steps", 0))
	return {
		"route_label": "本線" if route_id == "main" else "脇道",
		"route": route_id,
		"position": destination,
		"destination": destination_name,
		"kind": destination_kind,
		"kind_label": _space_kind_label(destination_kind),
		"moved_steps": maxi(moved_steps, 1),
	}


func _journey_space(space_id_value: String) -> Dictionary:
	if journey == null or space_id_value.is_empty():
		return {}
	if stage_id == StageCatalog.STAGE_AMAZON:
		return (journey as AmazonJourney).course.space(space_id_value)
	return (journey as KyotoJourney).course.space(space_id_value)


func _space_kind_label(kind: String) -> String:
	return {
		"START": "スタート",
		"NORMAL": "通常",
		"COIN": "コイン",
		"EVENT": "イベント",
		"REST": "回復",
		"RISK": "ダメージ",
		"FLOW": "急流",
		"ITEM": "アイテム",
		"GOSHUIN": "御朱印",
		"BYPASS_FORK": "分岐",
		"BOSS_FORK": "ボス選択",
		"BOSS_APPROACH": "ボス前",
		"JUNCTION": "分岐",
		"SPECIAL": "特殊",
		"BOSS": "ボス",
	}.get(kind, kind)


func _show_kyoto_route_tutorial() -> void:
	_open_choice_modal("京都の近道", "京都の分岐は2か所だけ。\n本線の報酬を取るか、ダメージマスの多い近道で4〜6マス縮めるかを選べます。", [{"id": "continue", "label": "道を選ぶ"}], func(_choice_id: String) -> void:
		journey.stage_flags["kyoto_route_tutorial_seen"] = true
		_show_branch_modal()
	, KYOTO_ROUTE_TUTORIAL)


func _show_kyoto_goshuin_tutorial() -> void:
	if stage_id != StageCatalog.STAGE_KYOTO or journey == null or bool(journey.stage_flags.get("kyoto_goshuin_tutorial_seen", false)):
		return
	_open_choice_modal("京都の御朱印めぐり", "京都には4つの御朱印所があります。\n御朱印マスを通過すると、御朱印帳に自動で記録されます。\n4つすべて集めると、白狐戦で『満願の護り』が一度発動します。", [{"id": "continue", "label": "御朱印めぐりを始める"}], func(_choice_id: String) -> void:
		journey.stage_flags["kyoto_goshuin_tutorial_seen"] = true
		status_label.text = "御朱印めぐりを始めよう。"
		_refresh_all()
	, KYOTO_GOSHUIN_TUTORIAL)


func _show_event_modal() -> void:
	var event: Dictionary = journey.pending_event
	var title := str(event.get("title", event.get("name", "旅の出会い")))
	var body := str(event.get("text", "旅の途中で小さな選択が訪れた。"))
	var choices: Array = event.get("choices", [])
	if choices.is_empty():
		choices = [{"id": "", "label": "旅の記憶に刻む"}]
	var card_art: Texture2D = AMAZON_EVENT_CARD if stage_id == StageCatalog.STAGE_AMAZON else KYOTO_EVENT_CARD
	_open_choice_modal(title, body, choices, func(choice_id: String) -> void:
		var start_space := journey.current_space_id
		var result: Dictionary = journey.resolve_event(choice_id)
		var end_space := str(result.get("position", journey.current_space_id))
		if bool(result.get("ok", false)) and end_space != start_space:
			map_movement_active = true
			roll_animation_active = true
			if is_instance_valid(roll_button):
				roll_button.disabled = true
			if _should_show_amazon_flow_tutorial(result):
				_show_amazon_flow_event_tutorial(start_space, result)
				return
			await _animate_journey_movement(start_space, result)
			map_movement_active = false
			roll_animation_active = false
		status_label.text = _journey_result_text(result)
		_after_journey_action()
	, card_art)


func _show_item_card() -> void:
	var title := "アマゾン・アイテムカード" if stage_id == StageCatalog.STAGE_AMAZON else "京都・アイテムカード"
	var entries := journey.inventory_entries()
	var body_lines: Array[String] = ["所持 %d/%d" % [journey.item_count(), StageJourneyBase.ITEM_CAPACITY]]
	var choices: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var item_id := str(entry.get("id", ""))
		var item_name := str(entry.get("name", item_id))
		var amount := int(entry.get("amount", 0))
		body_lines.append("%s ×%d　%s　%s" % [item_name, amount, str(entry.get("effect_text", "")), str(entry.get("description", ""))])
		choices.append({"id": item_id, "label": "%s ×%d　使う" % [item_name, amount]})
	if choices.is_empty():
		body_lines.append("まだアイテムを持っていません。")
		choices.append({"id": "close", "label": "閉じる"})
	else:
		choices.append({"id": "close", "label": "閉じる"})
	var body := "\n".join(body_lines)
	var art := AMAZON_ITEM_CARD if stage_id == StageCatalog.STAGE_AMAZON else KYOTO_ITEM_CARD
	_open_choice_modal(title, body, choices, func(choice_id: String) -> void:
		if choice_id == "close":
			return
		var result := journey.use_item(choice_id)
		if bool(result.get("ok", false)):
			status_label.text = str(result.get("text", "アイテムを使った。"))
		else:
			status_label.text = "今は使えない：%s" % _item_error_text(str(result.get("error", "UNKNOWN")))
		_refresh_all()
	, art)


func _item_error_text(error: String) -> String:
	match error:
		"HP_FULL": return "HPは満タン"
		"COMPASS_ALREADY_ACTIVE": return "コンパス効果中"
		"SCARAB_ALREADY_ACTIVE": return "護符効果中"
		"ITEM_NOT_OWNED": return "所持していない"
		"ITEM_NOT_AVAILABLE": return "ダイス移動中"
	return error


func _show_event_card_preview() -> void:
	if stage_id == StageCatalog.STAGE_AMAZON and journey.phase == StageJourneyBase.PHASE_EVENT:
		_show_event_modal()
		return
	var title := "アマゾン・イベントカード" if stage_id == StageCatalog.STAGE_AMAZON else "京都・イベントカード"
	var body := "イベントマスでめくる旅の出会い。\n森の精、川の案内人、滝の気配が次の一手を変える。" if stage_id == StageCatalog.STAGE_AMAZON else "イベントマスでめくる旅の出会い。\n狐、灯籠、社の気配が次の一手を変える。"
	var art := AMAZON_EVENT_CARD if stage_id == StageCatalog.STAGE_AMAZON else KYOTO_EVENT_CARD
	_open_choice_modal(title, body, [{"id": "close", "label": "カードを閉じる"}], func(_choice_id: String) -> void: return, art)


func _show_coin_tool() -> void:
	_open_choice_modal("コインポーチ", "旅で集めたコイン\n現在 %d 枚。イベントや分岐で使い道が変わります。" % journey.coins, [{"id": "close", "label": "閉じる"}], func(_choice_id: String) -> void: return, ICON_COIN)


func _show_skill_tool() -> void:
	if journey.skill_ready():
		var choices: Array[Dictionary] = []
		for face: int in range(1, 7):
			choices.append({"id": str(face), "label": "%d　次のサイコロ → %d" % [face, face]})
		choices.append({"id": "close", "label": "あとで使う"})
		_open_choice_modal("スキル READY", "次の出目を選ぶ", choices, func(choice_id: String) -> void:
			if choice_id == "close":
				return
			var result := journey.arm_skill_face(int(choice_id))
			status_label.text = str(result.get("text", "スキルを準備した")) if bool(result.get("ok", false)) else _journey_result_text(result)
			_refresh_all()
		, SKILL_CARD_ICON)
		return
	_open_choice_modal("旅のスキル", "役でチャージされます。\nPAIR +1　／　STRAIGHT +2　／　TRIPLE → MAX\n現在 %d/%d" % [journey.skill_gauge(), StageJourneyBase.SKILL_GAUGE_MAX], [{"id": "close", "label": "閉じる"}], func(_choice_id: String) -> void: return, SKILL_CARD_ICON)


func _show_menu_tool() -> void:
	_close_modal()
	active_modal = ColorRect.new()
	active_modal.name = "JourneyMenuOverlay"
	active_modal.color = Color(0.02, 0.03, 0.03, 0.86)
	active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(active_modal)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -410
	panel.offset_right = 300
	panel.offset_bottom = 410
	panel.add_theme_stylebox_override("panel", _panel(_stage_ink(0.98), GOLD, 22, 4))
	active_modal.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	box.add_child(_label("旅のメニュー", 34, Color("#f5d27b"), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label("旅を中断しています", 21, Color("#e1e8d8"), HORIZONTAL_ALIGNMENT_CENTER))
	var game_state := get_node_or_null("/root/GameState")
	var bgm_value := float(game_state.get("master_volume")) * 100.0 if game_state != null else 100.0
	var bgm_label := _label("BGM音量　%d%%" % roundi(bgm_value), 21, Color("#f5d27b"))
	box.add_child(bgm_label)
	var bgm_slider := HSlider.new()
	bgm_slider.name = "BgmSlider"
	bgm_slider.custom_minimum_size.y = 64
	bgm_slider.max_value = 100.0
	bgm_slider.step = 1.0
	bgm_slider.value = bgm_value
	bgm_slider.value_changed.connect(func(value: float) -> void:
		if game_state != null: game_state.set("master_volume", value / 100.0)
		bgm_label.text = "BGM音量　%d%%" % roundi(value)
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null: bgm.call("set_master_volume", value / 100.0)
	)
	box.add_child(bgm_slider)
	var se_value := float(game_state.get("se_volume")) * 100.0 if game_state != null else 100.0
	var se_label := _label("SE音量　%d%%" % roundi(se_value), 21, Color("#f5d27b"))
	box.add_child(se_label)
	var se_slider := HSlider.new()
	se_slider.name = "SeSlider"
	se_slider.custom_minimum_size.y = 64
	se_slider.max_value = 100.0
	se_slider.step = 1.0
	se_slider.value = se_value
	se_slider.value_changed.connect(func(value: float) -> void:
		if game_state != null: game_state.set("se_volume", value / 100.0)
		se_label.text = "SE音量　%d%%" % roundi(value)
	)
	box.add_child(se_slider)
	var encyclopedia := _button("旅の図鑑を見る", func() -> void:
		_persist_global_settings()
		_save_now()
		_close_modal()
		encyclopedia_requested.emit()
	, false)
	encyclopedia.custom_minimum_size.y = 82
	box.add_child(encyclopedia)
	var continue_button := _button("旅を続ける", func() -> void:
		_persist_global_settings()
		_close_modal()
	, true)
	continue_button.custom_minimum_size.y = 82
	box.add_child(continue_button)
	var exit_button := _button("ステージ選択へ戻る", func() -> void:
		_persist_global_settings()
		_save_now()
		_close_modal()
		_request_back()
	, false)
	exit_button.custom_minimum_size.y = 82
	box.add_child(exit_button)
	panel.add_child(box)


func _persist_global_settings() -> void:
	var global_save := get_node_or_null("/root/SaveManager")
	if global_save != null and global_save.has_method("save_now"):
		global_save.call("save_now")


func _show_secret_modal() -> void:
	var secret := journey.pending_event
	var choices := [{"id": "yes", "label": str(secret.get("accept_label", "入る"))}, {"id": "no", "label": str(secret.get("decline_label", "入らない"))}]
	_open_choice_modal("滝裏の入口", str(secret.get("prompt", "洞窟へ入る？")), choices, func(choice_id: String) -> void:
		var result := (journey as AmazonJourney).resolve_secret(choice_id == "yes")
		status_label.text = _journey_result_text(result)
		_after_journey_action()
	)


func _show_boss_intro() -> void:
	if stage_id == StageCatalog.STAGE_AMAZON:
		_show_aquafall_rules_modal()
		return
	var route := str(journey.stage_flags.get("kyoto_boss_route", ""))
	if route == "direct":
		_open_choice_modal("狐火追陣", "6×6の盤面外周を走り、逃げる白狐に追いつこう。", [{"id": "start", "label": "狐火追陣を始める"}], func(_choice: String) -> void:
			_start_fox_fire_chase_boss()
		)
	else:
		_open_choice_modal("狐火六路陣", "6×6の路地を3つの出目で進み、白狐より先に3つの鳥居を封じる。", [{"id": "start", "label": "狐火六路陣を始める"}], func(_choice: String) -> void:
			_start_fox_fire_six_routes_boss()
		)


func _show_kyoto_boss_choice_modal() -> void:
	if stage_id != StageCatalog.STAGE_KYOTO:
		return
	var choices: Array = []
	for value: Variant in journey.pending_choices:
		if not value is Dictionary:
			continue
		var choice := (value as Dictionary).duplicate(true)
		choice["label"] = "%s　%s" % [str(choice.get("name", "最後の試練")), str(choice.get("description", ""))]
		choices.append(choice)
	_open_choice_modal("最後の試練を選ぶ", "報酬は同じ。好きな遊び方を選べます。\n\n狐火追陣：短時間・追走型\n狐火六路陣：じっくり・パズル型", choices, func(choice_id: String) -> void:
		var start_space := journey.current_space_id
		var result := (journey as KyotoJourney).choose_boss_route(choice_id)
		if bool(result.get("ok", false)) and not (result.get("path", []) as Array).is_empty():
			map_movement_active = true
			await _animate_journey_movement(start_space, result)
			map_movement_active = false
		status_label.text = _journey_result_text(result)
		_refresh_all()
		_after_journey_action()
	)


func _show_aquafall_rules_modal() -> void:
	_close_modal()
	aquafall_rules_slide = 0
	aquafall_rules_slide_count = 4
	aquafall_rules_content = null
	aquafall_rules_prev_button = null
	aquafall_rules_next_button = null
	aquafall_rules_start_button = null
	aquafall_rules_slide_index = null
	active_modal = ColorRect.new()
	active_modal.name = "AquafallRulesModal"
	active_modal.color = Color(0.02, 0.03, 0.03, 0.84)
	active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	# Route emblems can use their own z-index on the map. Keep every tutorial
	# element above them so decorative boss icons never cover explanation copy.
	active_modal.z_index = 200
	add_child(active_modal)

	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var panel_width := minf(632.0, maxf(viewport_size.x - 24.0, 260.0))
	var panel_height := minf(700.0, maxf(viewport_size.y - 28.0, 420.0))
	aquafall_rules_compact = panel_width < 500.0 or panel_height < 580.0
	var panel := PanelContainer.new()
	panel.name = "AquafallRulesPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5
	panel.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 24, 4))
	active_modal.add_child(panel)

	var panel_content := VBoxContainer.new()
	panel_content.name = "AquafallRulesPanelContent"
	panel_content.add_theme_constant_override("separation", 8 if aquafall_rules_compact else 10)
	panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(panel_content)

	var scroll := ScrollContainer.new()
	scroll.name = "AquafallRulesScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Every rule page is intentionally composed to fit the fixed modal. A
	# visible scrollbar makes the final page feel like a document instead of a
	# short onboarding lesson, so keep the viewport fixed and non-scrolling.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_content.add_child(scroll)
	var box := VBoxContainer.new()
	box.name = "AquafallRulesContent"
	box.add_theme_constant_override("separation", 8 if aquafall_rules_compact else 12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	aquafall_rules_content = box

	var navigation := HBoxContainer.new()
	navigation.name = "AquafallRulesNavigation"
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 8)
	navigation.custom_minimum_size.y = 58 if aquafall_rules_compact else 64
	panel_content.add_child(navigation)

	var previous_button := _button("‹ 前へ", func() -> void:
		_set_aquafall_rules_slide(aquafall_rules_slide - 1)
	, false)
	previous_button.name = "AquafallRulesPrevButton"
	previous_button.custom_minimum_size = Vector2(72, 54) if aquafall_rules_compact else Vector2(116, 56)
	previous_button.add_theme_font_size_override("font_size", 16 if aquafall_rules_compact else 19)
	previous_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(previous_button)
	aquafall_rules_prev_button = previous_button

	var slide_index := _label("", 16 if aquafall_rules_compact else 18, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	slide_index.name = "AquafallRulesSlideIndex"
	slide_index.custom_minimum_size.x = 64 if aquafall_rules_compact else 116
	slide_index.mouse_filter = Control.MOUSE_FILTER_IGNORE
	navigation.add_child(slide_index)
	aquafall_rules_slide_index = slide_index

	var next_button := _button("次へ ›", func() -> void:
		_set_aquafall_rules_slide(aquafall_rules_slide + 1)
	, true)
	next_button.name = "AquafallRulesNextButton"
	next_button.custom_minimum_size = Vector2(72, 54) if aquafall_rules_compact else Vector2(116, 56)
	next_button.add_theme_font_size_override("font_size", 16 if aquafall_rules_compact else 19)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(next_button)
	aquafall_rules_next_button = next_button

	var start_button := _button("わかった！ 挑戦する", func() -> void:
		_close_modal()
		if journey != null and not bool(journey.stage_flags.get("aquafall_practice_seen", false)):
			_show_aquafall_practice_modal()
		else:
			_start_aquafall_boss()
	, true)
	start_button.name = "AquafallRulesStartButton"
	start_button.custom_minimum_size = Vector2(0, 54 if aquafall_rules_compact else 58)
	start_button.add_theme_font_size_override("font_size", 16 if aquafall_rules_compact else 19)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(start_button)
	aquafall_rules_start_button = start_button

	_set_aquafall_rules_slide(0)


func _set_aquafall_rules_slide(slide_index: int) -> void:
	if not is_instance_valid(aquafall_rules_content):
		return
	aquafall_rules_slide = clampi(slide_index, 0, aquafall_rules_slide_count - 1)
	for child: Node in aquafall_rules_content.get_children():
		child.free()
	aquafall_rules_content.add_child(_aquafall_rules_slide_view(aquafall_rules_slide, aquafall_rules_compact))
	if is_instance_valid(aquafall_rules_prev_button):
		aquafall_rules_prev_button.disabled = aquafall_rules_slide == 0
	if is_instance_valid(aquafall_rules_next_button):
		aquafall_rules_next_button.visible = aquafall_rules_slide < aquafall_rules_slide_count - 1
	if is_instance_valid(aquafall_rules_start_button):
		aquafall_rules_start_button.visible = aquafall_rules_slide == aquafall_rules_slide_count - 1
	if is_instance_valid(aquafall_rules_slide_index):
		aquafall_rules_slide_index.visible = aquafall_rules_slide < aquafall_rules_slide_count - 1 or not aquafall_rules_compact
		var dots := ""
		for dot_index: int in range(aquafall_rules_slide_count):
			dots += "●" if dot_index == aquafall_rules_slide else "○"
			dots += " " if dot_index < aquafall_rules_slide_count - 1 else ""
		aquafall_rules_slide_index.text = "%s  %d / %d" % [dots, aquafall_rules_slide + 1, aquafall_rules_slide_count]


func _aquafall_rules_slide_view(slide_index: int, compact: bool) -> Control:
	var slide := VBoxContainer.new()
	slide.name = "AquafallRulesSlide_%d" % (slide_index + 1)
	slide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dense_final := slide_index == 3
	slide.add_theme_constant_override("separation", 5 if dense_final else 8 if compact else 12)
	var kicker := _label("BOSS RULES  •  %d / %d" % [slide_index + 1, aquafall_rules_slide_count], 12 if compact else 14, _stage_accent(), HORIZONTAL_ALIGNMENT_CENTER)
	kicker.custom_minimum_size.y = 22 if compact else 26
	slide.add_child(kicker)
	var title_text := ""
	var subtitle_text := ""
	match slide_index:
		0:
			title_text = "① 頂上まで登れば勝ち！"
			subtitle_text = "頂上の高さ24に着けば勝ち！　／　丸太に3回ぶつかるとゲームオーバー"
			slide.add_child(_aquafall_rules_goal_illustration(compact))
		1:
			title_text = "② 出目を見て「左」か「右」を選ぶ"
			subtitle_text = "出目3なら、選んだ方向へ3歩進む"
			slide.add_child(_aquafall_rules_direction_illustration(compact))
			slide.add_child(_aquafall_rules_emphasis("途中で方向は変えられない！", compact, true))
		2:
			title_text = "③ 端まで行ったら折り返す"
			subtitle_text = "出目3 ／ 右を選択"
			slide.add_child(_aquafall_rules_turn_illustration(compact))
			slide.add_child(_aquafall_rules_emphasis("4 → 5 → 4 → 3", compact))
		3:
			title_text = "④ 1歩動くたび、丸太も1段下がる"
			subtitle_text = "出目3なら：猫3歩 ／ 丸太3段下降"
			slide.add_child(_aquafall_rules_log_illustration(compact, dense_final))
			slide.add_child(_aquafall_rules_log_comparison(compact, dense_final))
			slide.add_child(_aquafall_rules_emphasis("丸太に3回ぶつかるとゲームオーバー", compact, true, dense_final))
	var title := _label(title_text, 19 if dense_final and compact else 24 if dense_final else 21 if compact else 29, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "AquafallRulesTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	title.custom_minimum_size.y = 38 if dense_final and compact else 48 if dense_final else 52 if compact else 62
	slide.add_child(title)
	slide.move_child(title, 1)
	var subtitle := _label(subtitle_text, 13 if dense_final and compact else 15 if compact else 18, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.name = "AquafallRulesSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	subtitle.custom_minimum_size.y = 28 if dense_final and compact else 34 if dense_final else 42 if compact else 48
	slide.add_child(subtitle)
	slide.move_child(subtitle, 2)
	return slide


func _aquafall_rules_emphasis(text_value: String, compact: bool, danger: bool = false, dense: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesEmphasis"
	card.custom_minimum_size.y = 42 if dense and compact else 50 if dense else 56 if compact else 68
	card.add_theme_stylebox_override("panel", _panel(Color("#f8ddd0") if danger else Color("#d9f0e7"), Color("#c6644d") if danger else Color("#53a997"), 14, 3 if danger else 2))
	var copy := _label(text_value, 14 if dense and compact else 17 if compact else 21, Color("#8f3e32") if danger else AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	copy.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	card.add_child(copy)
	return card


func _aquafall_rules_texture(texture: Texture2D, texture_size: Vector2, node_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.custom_minimum_size = texture_size
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _aquafall_rules_goal_illustration(compact: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesGoalIllustration"
	card.custom_minimum_size.y = 252 if compact else 322
	card.add_theme_stylebox_override("panel", _panel(Color("#103c39"), Color("#e6c65b"), 18, 3))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10 if compact else 28)
	var climb := VBoxContainer.new()
	climb.name = "AquafallRulesVictoryTrack"
	climb.alignment = BoxContainer.ALIGNMENT_CENTER
	climb.add_child(_aquafall_rules_texture(AQUAFALL_GOAL_ICON, Vector2(104, 94) if compact else Vector2(150, 132), "RulesGoalArt"))
	var goal_copy := _label("高さ 24　WIN!", 20 if compact else 27, Color("#fff0a5"), HORIZONTAL_ALIGNMENT_CENTER)
	climb.add_child(goal_copy)
	var climb_arrow := _label("↑　↑　↑", 24 if compact else 34, Color("#8de1cf"), HORIZONTAL_ALIGNMENT_CENTER)
	climb.add_child(climb_arrow)
	climb.add_child(_aquafall_rules_texture(_cat_frame(0), Vector2(58, 66) if compact else Vector2(86, 94), "RulesGoalCat"))
	row.add_child(climb)
	var danger := PanelContainer.new()
	danger.name = "AquafallRulesThreeHits"
	danger.custom_minimum_size = Vector2(118, 176) if compact else Vector2(190, 230)
	danger.add_theme_stylebox_override("panel", _panel(Color("#4a2520"), Color("#ee805d"), 14, 3))
	var danger_stack := VBoxContainer.new()
	danger_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	danger_stack.add_child(_aquafall_rules_texture(AQUAFALL_LARGE_LOG, Vector2(104, 62) if compact else Vector2(164, 92), "RulesGoalDangerLog"))
	danger_stack.add_child(_label("♥ ♥ ♥", 24 if compact else 34, Color("#ffb092"), HORIZONTAL_ALIGNMENT_CENTER))
	var lose := _label("3回衝突で\nGAME OVER", 16 if compact else 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	lose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	danger_stack.add_child(lose)
	danger.add_child(danger_stack)
	row.add_child(danger)
	card.add_child(row)
	return card


func _aquafall_rules_direction_illustration(compact: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesDirectionIllustration"
	card.custom_minimum_size.y = 244 if compact else 300
	card.add_theme_stylebox_override("panel", _panel(Color("#123f3d"), Color("#70cfba"), 16, 2))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 5 if compact else 9)
	var roll_row := HBoxContainer.new()
	roll_row.alignment = BoxContainer.ALIGNMENT_CENTER
	roll_row.add_child(_aquafall_rules_texture(DICE_ART, Vector2(52, 52) if compact else Vector2(76, 76), "RulesDirectionDice"))
	roll_row.add_child(_label("3", 31 if compact else 42, Color("#fff1b0"), HORIZONTAL_ALIGNMENT_CENTER))
	stack.add_child(roll_row)
	var lanes := HBoxContainer.new()
	lanes.name = "AquafallRulesFiveLanes"
	lanes.alignment = BoxContainer.ALIGNMENT_CENTER
	lanes.add_theme_constant_override("separation", 4 if compact else 8)
	for lane_value: int in range(1, 6):
		var lane := PanelContainer.new()
		lane.name = "RulesDirectionLane_%d" % lane_value
		lane.custom_minimum_size = Vector2(42, 62) if compact else Vector2(64, 84)
		lane.add_theme_stylebox_override("panel", _panel(Color("#8fd0bd") if lane_value == 3 else Color("#f5edcf"), Color("#e4bd50") if lane_value == 3 else Color("#5e9c8d"), 9, 2))
		var lane_stack := VBoxContainer.new()
		lane_stack.add_child(_label(str(lane_value), 14 if compact else 18, INK, HORIZONTAL_ALIGNMENT_CENTER))
		if lane_value == 3:
			lane_stack.add_child(_aquafall_rules_texture(_cat_frame(0), Vector2(34, 36) if compact else Vector2(48, 52), "RulesDirectionCat"))
		lane.add_child(lane_stack)
		lanes.add_child(lane)
	stack.add_child(lanes)
	stack.add_child(_label("左なら　← ← ←", 18 if compact else 24, Color("#a8f0df"), HORIZONTAL_ALIGNMENT_CENTER))
	stack.add_child(_label("右なら　→ → →", 18 if compact else 24, Color("#fff0a5"), HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(stack)
	return card


func _aquafall_rules_move_illustration(compact: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesMoveIllustration"
	card.custom_minimum_size.y = 146 if compact else 178
	card.add_theme_stylebox_override("panel", _panel(Color("#123f3d"), Color("#70cfba"), 16, 2))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2 if compact else 10)
	var dice_stack := VBoxContainer.new()
	dice_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_stack.add_child(_aquafall_rules_texture(DICE_ART, Vector2(60, 60) if compact else Vector2(92, 92), "RulesDiceArt"))
	var face := _label("3", 28 if compact else 36, Color("#fff1b0"), HORIZONTAL_ALIGNMENT_CENTER)
	face.custom_minimum_size.y = 36 if compact else 44
	dice_stack.add_child(face)
	row.add_child(dice_stack)
	row.add_child(_aquafall_rules_arrow("→", compact))
	for hop_index: int in range(3):
		var hop := PanelContainer.new()
		hop.name = "AquafallRulesHop_%d" % (hop_index + 1)
		hop.custom_minimum_size = Vector2(46, 94) if compact else Vector2(70, 124)
		var hop_style := _panel(Color("#e7f4dc"), Color("#d9b54b"), 11, 2)
		hop_style.content_margin_left = 2
		hop_style.content_margin_right = 2
		hop_style.content_margin_top = 4
		hop_style.content_margin_bottom = 4
		hop.add_theme_stylebox_override("panel", hop_style)
		var hop_stack := VBoxContainer.new()
		hop_stack.add_child(_aquafall_rules_texture(_cat_frame(hop_index), Vector2(38, 54) if compact else Vector2(58, 76), "RulesHopCat_%d" % (hop_index + 1)))
		var hop_number := _label(str(hop_index + 1), 18 if compact else 23, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
		hop_number.custom_minimum_size.y = 24 if compact else 30
		hop_stack.add_child(hop_number)
		hop.add_child(hop_stack)
		row.add_child(hop)
		if hop_index < 2:
			row.add_child(_aquafall_rules_arrow("→", compact))
	card.add_child(row)
	return card


func _aquafall_rules_arrow(text_value: String, compact: bool) -> Label:
	var arrow := _label(text_value, 16 if compact else 24, Color("#f9e4a2"), HORIZONTAL_ALIGNMENT_CENTER)
	arrow.custom_minimum_size.x = 10 if compact else 24
	return arrow


func _aquafall_rules_turn_illustration(compact: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesTurnIllustration"
	card.custom_minimum_size.y = 132 if compact else 160
	card.add_theme_stylebox_override("panel", _panel(Color("#d9eee4"), Color("#4d9b87"), 16, 2))
	var row := HBoxContainer.new()
	row.name = "AquafallRulesReflectionPath"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4 if compact else 8)
	var lane_path: Array[int] = [4, 5, 4, 3]
	for path_index: int in range(lane_path.size()):
		row.add_child(_aquafall_rules_turn_step(lane_path[path_index], path_index, compact))
		if path_index < lane_path.size() - 1:
			row.add_child(_aquafall_rules_turn_back_badge(compact) if path_index == 1 else _aquafall_rules_arrow("→", compact))
	card.add_child(row)
	return card


func _aquafall_rules_turn_back_badge(compact: bool) -> Control:
	var badge := PanelContainer.new()
	badge.name = "AquafallRulesTurnBackBadge"
	badge.custom_minimum_size = Vector2(54, 38) if compact else Vector2(82, 48)
	badge.add_theme_stylebox_override("panel", _panel(Color("#f7d785"), Color("#b55d2c"), 10, 2))
	var copy := _label("折返し", 12 if compact else 17, Color("#7b3e25"), HORIZONTAL_ALIGNMENT_CENTER)
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(copy)
	return badge


func _aquafall_rules_turn_step(lane_value: int, path_index: int, compact: bool) -> Control:
	var step := PanelContainer.new()
	step.name = "AquafallRulesTurnStep_%d" % path_index
	step.custom_minimum_size = Vector2(50, 98) if compact else Vector2(70, 122)
	var fill := Color("#f2e5bd") if lane_value != 5 else Color("#f7d785")
	var style := _panel(fill, Color("#4d9b87") if lane_value != 5 else Color("#c6782e"), 11, 2 if lane_value != 5 else 3)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	step.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.add_child(_aquafall_rules_texture(_cat_frame(path_index), Vector2(40, 54) if compact else Vector2(56, 72), "RulesTurnCat_%d" % path_index))
	var lane_label := _label("滝筋 %d" % lane_value, 12 if compact else 16, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	lane_label.custom_minimum_size.y = 26 if compact else 32
	stack.add_child(lane_label)
	step.add_child(stack)
	return step


func _aquafall_rules_log_illustration(compact: bool, dense: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesLogIllustration"
	card.custom_minimum_size.y = 122 if dense and compact else 142 if dense else 174 if compact else 214
	card.add_theme_stylebox_override("panel", _panel(Color("#153c35"), Color("#d8ad4a"), 16, 2))
	var row := HBoxContainer.new()
	row.name = "AquafallRulesStepStoryboard"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4 if compact else 8)
	var lanes: Array[int] = [3, 2, 1]
	for frame_index: int in range(3):
		row.add_child(_aquafall_rules_motion_frame(frame_index, lanes[frame_index], compact, dense))
		if frame_index < 2:
			row.add_child(_aquafall_rules_arrow("→", compact))
	card.add_child(row)
	return card


func _aquafall_rules_motion_frame(frame_index: int, lane_value: int, compact: bool, dense: bool = false) -> Control:
	var frame := PanelContainer.new()
	frame.name = "AquafallRulesMotionFrame_%d" % frame_index
	frame.custom_minimum_size = Vector2(62, 98) if dense and compact else Vector2(86, 118) if dense else Vector2(76, 142) if compact else Vector2(116, 176)
	var style := _panel(Color("#e4f0dd"), Color("#7cb49b"), 10, 2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	frame.add_theme_stylebox_override("panel", style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	var caption := _label("START" if frame_index == 0 else "%d歩" % frame_index, 10 if dense and compact else 11 if compact else 14, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	caption.custom_minimum_size.y = 16 if dense and compact else 22 if compact else 26
	stack.add_child(caption)
	var scene := Control.new()
	scene.name = "AquafallRulesMotionScene"
	scene.custom_minimum_size.y = 66 if dense and compact else 84 if dense else 108 if compact else 140
	for grid_index: int in range(1, 3):
		var lane_line := ColorRect.new()
		lane_line.color = Color(0.18, 0.46, 0.42, 0.30)
		lane_line.anchor_left = float(grid_index) / 3.0
		lane_line.anchor_right = lane_line.anchor_left
		lane_line.anchor_top = 0.0
		lane_line.anchor_bottom = 1.0
		lane_line.offset_left = -1.0
		lane_line.offset_right = 1.0
		lane_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scene.add_child(lane_line)
	var log := _aquafall_rules_texture(AQUAFALL_SMALL_LOG, Vector2.ZERO, "RulesMotionLog_%d" % frame_index)
	log.anchor_left = 0.08
	log.anchor_right = 0.92
	log.anchor_top = 0.0
	log.anchor_bottom = 0.0
	log.offset_top = 3.0 + frame_index * (14.0 if dense and compact else 18.0 if dense else 21.0 if compact else 28.0)
	log.offset_bottom = log.offset_top + (18.0 if dense and compact else 24.0 if dense else 28.0 if compact else 36.0)
	scene.add_child(log)
	var cat := _aquafall_rules_texture(_cat_frame(frame_index), Vector2.ZERO, "RulesMotionCat_%d" % frame_index)
	var cat_center := (float(lane_value) - 0.5) / 3.0
	cat.anchor_left = cat_center
	cat.anchor_right = cat_center
	cat.anchor_top = 1.0
	cat.anchor_bottom = 1.0
	cat.offset_left = -11.0 if dense and compact else -15.0 if compact else -21.0
	cat.offset_right = 11.0 if dense and compact else 15.0 if compact else 21.0
	cat.offset_top = -28.0 if dense and compact else -38.0 if compact else -52.0
	cat.offset_bottom = 0.0
	scene.add_child(cat)
	stack.add_child(scene)
	frame.add_child(stack)
	return frame


func _aquafall_rules_damage_illustration(compact: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRulesDamageIllustration"
	card.custom_minimum_size.y = 112 if compact else 142
	card.add_theme_stylebox_override("panel", _panel(Color("#4b2520"), Color("#f0835e"), 16, 3))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6 if compact else 18)
	row.add_child(_aquafall_rules_texture(_cat_frame(2), Vector2(56, 72) if compact else Vector2(88, 108), "RulesDangerCatArt"))
	var warning := _label("⚠  丸太に注意\n♥♥♥", 18 if compact else 23, Color("#ffe4b0"), HORIZONTAL_ALIGNMENT_CENTER)
	warning.custom_minimum_size.x = 90 if compact else 180
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(warning)
	row.add_child(_aquafall_rules_texture(AQUAFALL_LARGE_LOG, Vector2(90, 58) if compact else Vector2(156, 88), "RulesDangerLogArt"))
	card.add_child(row)
	return card


func _aquafall_rules_log_comparison(compact: bool, dense: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.name = "AquafallRulesLogComparison"
	row.add_theme_constant_override("separation", 8 if compact else 12)
	row.add_child(_aquafall_rules_log_rule_visual(false, compact, dense))
	row.add_child(_aquafall_rules_log_rule_visual(true, compact, dense))
	return row


func _aquafall_rules_log_rule_visual(is_large: bool, compact: bool, dense: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "LargeLogRule" if is_large else "SmallLogRule"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 112 if dense and compact else 132 if dense else 188 if compact else 220
	var accent := Color("#b55439") if is_large else Color("#6f9d5a")
	card.add_theme_stylebox_override("panel", _panel(Color("#f8dfd2") if is_large else Color("#f7eed8"), accent, 12, 3 if is_large else 2))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3 if compact else 5)
	var title := _label("大きい丸太" if is_large else "小さい丸太", 12 if dense and compact else 15 if compact else 19, Color("#7e3026") if is_large else Color("#355d31"), HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 20 if dense and compact else 28 if compact else 34
	stack.add_child(title)
	var log_size := Vector2(86, 38) if is_large and dense and compact else Vector2(62, 24) if dense and compact else Vector2(126, 62) if is_large and dense else Vector2(92, 38) if dense else Vector2(116, 70) if is_large and compact else Vector2(74, 38) if compact else Vector2(176, 102) if is_large else Vector2(108, 52)
	stack.add_child(_aquafall_rules_texture(AQUAFALL_LARGE_LOG if is_large else AQUAFALL_SMALL_LOG, log_size, "RulesLargeLogArt" if is_large else "RulesSmallLogArt"))
	stack.add_child(_aquafall_rules_contact_row("横切る", not is_large, compact, dense))
	stack.add_child(_aquafall_rules_contact_row("止まる", false, compact, dense))
	card.add_child(stack)
	return card


func _aquafall_rules_contact_row(action_text: String, safe: bool, compact: bool, dense: bool = false) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3 if compact else 6)
	row.add_child(_aquafall_rules_texture(_cat_frame(0), Vector2(18, 22) if dense and compact else Vector2(24, 30) if compact else Vector2(32, 40), "RulesContactCat"))
	var action := _label(action_text, 10 if dense and compact else 12 if compact else 15, INK, HORIZONTAL_ALIGNMENT_CENTER)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(action)
	var result := _label("○" if safe else "×", 22 if dense and compact else 28 if compact else 34, Color("#2f8a61") if safe else Color("#c34d3c"), HORIZONTAL_ALIGNMENT_CENTER)
	result.custom_minimum_size.x = 22 if dense and compact else 28 if compact else 36
	row.add_child(result)
	return row


func _aquafall_lane_diagram(compact: bool = false) -> Control:
	var panel := PanelContainer.new()
	panel.name = "AquafallLaneDiagram"
	panel.custom_minimum_size.y = 82 if compact else 128
	panel.add_theme_stylebox_override("panel", _panel(Color("#d8eee5"), Color("#75bfae"), 14, 2))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.name = "AquafallLaneDiagramRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2 if compact else 5)
	var left := _label("←3", 15 if compact else 18, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	left.custom_minimum_size.x = 30 if compact else 70
	row.add_child(left)
	var lane_strip := HBoxContainer.new()
	lane_strip.name = "AquafallLaneStrip"
	lane_strip.add_theme_constant_override("separation", 3)
	for lane_value: int in range(1, 6):
		var lane := PanelContainer.new()
		lane.custom_minimum_size = Vector2(20 if compact else 38, 34 if compact else 54)
		lane.add_theme_stylebox_override("panel", _panel(Color("#f5edcf") if lane_value != 3 else Color("#8fd0bd"), Color("#5e9c8d"), 8, 1))
		var lane_label := _label(str(lane_value), 15 if compact else 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
		lane_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lane.add_child(lane_label)
		lane_strip.add_child(lane)
	row.add_child(lane_strip)
	var right := _label("3→", 15 if compact else 18, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	right.custom_minimum_size.x = 30 if compact else 70
	row.add_child(right)
	content.add_child(row)
	var hint := _label("滝筋1・5の先は反対側へ折り返し", 11 if compact else 13, Color("#456c61"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.custom_minimum_size.y = 18 if compact else 25
	content.add_child(hint)
	panel.add_child(content)
	return panel


func _aquafall_rule_card(title_text: String, body_text: String, icon: Texture2D, accent: Color, compact: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallRuleCard"
	card.custom_minimum_size.y = 48 if compact else 64
	card.add_theme_stylebox_override("panel", _panel(Color("#f6e8c9"), accent, 11, 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	if icon != null:
		var icon_view := TextureRect.new()
		icon_view.name = "RuleIcon"
		icon_view.texture = icon
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_view.custom_minimum_size = Vector2(28, 28) if compact else Vector2(44, 44)
		icon_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_view)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(_label(title_text, 14 if compact else 16, accent))
	var body := _label(body_text, 12 if compact else 14, INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 18 if compact else 28
	copy.add_child(body)
	row.add_child(copy)
	card.add_child(row)
	return card


func _aquafall_log_rules(compact: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallLogRules"
	card.add_theme_stylebox_override("panel", _panel(Color("#edf4e5"), Color("#8aa65b"), 11, 2))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	var heading := _label("丸太の当たり方", 14 if compact else 16, Color("#476329"), HORIZONTAL_ALIGNMENT_CENTER)
	heading.custom_minimum_size.y = 18 if compact else 0
	content.add_child(heading)
	var row: Container = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var small := _aquafall_log_rule_item("小さい丸太", "横切るだけ：無傷\n止まった場所：1ダメージ" if not compact else "横切り：無傷\n停止：1ダメージ", Color("#56752e"), compact)
	var large := _aquafall_log_rule_item("大きい丸太", "横切る：1ダメージ\n止まっても：1ダメージ" if not compact else "横切り／停止：1ダメージ", Color("#9a542f"), compact)
	row.add_child(small)
	row.add_child(large)
	content.add_child(row)
	card.add_child(content)
	return card


func _aquafall_log_rule_item(title_text: String, body_text: String, accent: Color, compact: bool = false) -> Control:
	var item := PanelContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.custom_minimum_size.y = 30 if compact else 0
	item.add_theme_stylebox_override("panel", _panel(Color("#fff9e9"), accent, 8, 1))
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 1)
	copy.add_child(_label(title_text, 13 if compact else 14, accent, HORIZONTAL_ALIGNMENT_CENTER))
	var body := _label(body_text, 11 if compact else 13, INK, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 20 if compact else 42
	copy.add_child(body)
	item.add_child(copy)
	return item


func _aquafall_game_over_rule(compact: bool = false) -> Control:
	var card := PanelContainer.new()
	card.name = "AquafallGameOverRule"
	card.custom_minimum_size.y = 44 if compact else 52
	card.add_theme_stylebox_override("panel", _panel(Color("#f8ddd0"), Color("#c6644d"), 11, 2))
	var label := _label("♥ ♥ ♥　3回当たるとゲームオーバー", 15 if compact else 17, Color("#8f3e32"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(label)
	return card


func _show_aquafall_practice_modal() -> void:
	_close_modal()
	aquafall_practice_active = false
	aquafall_practice_cat = null
	aquafall_practice_logs.clear()
	active_modal = ColorRect.new()
	active_modal.name = "AquafallPracticeModal"
	active_modal.color = Color(0.015, 0.035, 0.035, 0.94)
	active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	active_modal.z_index = 200
	add_child(active_modal)

	var viewport_size := size if size.x > 0.0 and size.y > 0.0 else get_viewport_rect().size
	var panel_width := minf(620.0, maxf(viewport_size.x - 24.0, 292.0))
	var panel_height := minf(680.0, maxf(viewport_size.y - 28.0, 500.0))
	var compact := panel_width < 500.0 or panel_height < 580.0
	var panel := PanelContainer.new()
	panel.name = "AquafallPracticePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5
	panel.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 22, 4))
	active_modal.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8 if compact else 12)
	panel.add_child(stack)
	stack.add_child(_label("5秒練習　出目 3", 25 if compact else 32, INK, HORIZONTAL_ALIGNMENT_CENTER))
	var hint := _label("左か右を一度だけ選ぼう", 16 if compact else 20, AMAZON_INK, HORIZONTAL_ALIGNMENT_CENTER)
	hint.name = "AquafallPracticeHint"
	stack.add_child(hint)

	var field := Control.new()
	field.name = "AquafallPracticeField"
	field.custom_minimum_size.y = 270 if compact else 330
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.set_meta("lane_count", 5)
	field.set_meta("start_lane", 4)
	var practice_row_step := 42.0 if compact else 52.0
	field.set_meta("row_step", practice_row_step)
	stack.add_child(field)
	var field_bg := Panel.new()
	field_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_bg.add_theme_stylebox_override("panel", _panel(Color("#123f3d"), Color("#70cfba"), 16, 2))
	field.add_child(field_bg)
	for lane_value: int in range(1, 6):
		var lane_line := ColorRect.new()
		lane_line.name = "AquafallPracticeLane_%d" % lane_value
		lane_line.color = Color(0.84, 0.97, 0.92, 0.32)
		var lane_x := (float(lane_value) - 0.5) / 5.0
		lane_line.anchor_left = lane_x
		lane_line.anchor_right = lane_x
		lane_line.anchor_top = 0.08
		lane_line.anchor_bottom = 0.96
		lane_line.offset_left = -2.0
		lane_line.offset_right = 2.0
		field.add_child(lane_line)
		var lane_label := _label(str(lane_value), 15 if compact else 18, Color("#fff1b0"), HORIZONTAL_ALIGNMENT_CENTER)
		lane_label.anchor_left = lane_x
		lane_label.anchor_right = lane_x
		lane_label.offset_left = -20.0
		lane_label.offset_right = 20.0
		lane_label.offset_top = 7.0
		lane_label.offset_bottom = 33.0
		field.add_child(lane_label)
	var practice_log_specs: Array[Dictionary] = [
		{"lane": 2, "row": 1, "large": false},
		{"lane": 4, "row": 2, "large": true},
	]
	for log_index: int in range(practice_log_specs.size()):
		var spec := practice_log_specs[log_index]
		var practice_log := TextureRect.new()
		practice_log.name = "AquafallPracticeLog_%d" % log_index
		practice_log.texture = AQUAFALL_LARGE_LOG if bool(spec.large) else AQUAFALL_SMALL_LOG
		practice_log.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		practice_log.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var log_width := 114.0 if bool(spec.large) else 72.0
		var log_height := 66.0 if bool(spec.large) else 38.0
		var log_lane_x := (float(int(spec.lane)) - 0.5) / 5.0
		practice_log.anchor_left = log_lane_x
		practice_log.anchor_right = log_lane_x
		practice_log.offset_left = -log_width * 0.5
		practice_log.offset_right = log_width * 0.5
		practice_log.offset_top = 42.0 + float(int(spec.row)) * practice_row_step
		practice_log.offset_bottom = practice_log.offset_top + log_height
		practice_log.set_meta("start_top", practice_log.offset_top)
		field.add_child(practice_log)
		aquafall_practice_logs.append(practice_log)
	var cat := _aquafall_rules_texture(_cat_frame(0), Vector2.ZERO, "AquafallPracticeCat")
	cat.anchor_left = 0.7
	cat.anchor_right = 0.7
	cat.anchor_top = 1.0
	cat.anchor_bottom = 1.0
	cat.offset_left = -36.0 if compact else -46.0
	cat.offset_right = 36.0 if compact else 46.0
	cat.offset_top = -86.0 if compact else -106.0
	cat.offset_bottom = -10.0
	cat.set_meta("base_top", cat.offset_top)
	cat.set_meta("base_bottom", cat.offset_bottom)
	field.add_child(cat)
	aquafall_practice_cat = cat

	var direction_row := HBoxContainer.new()
	direction_row.name = "AquafallPracticeDirectionRow"
	direction_row.add_theme_constant_override("separation", 10)
	stack.add_child(direction_row)
	for direction: int in [-1, 1]:
		var button_text := "← 左へ3歩" if direction < 0 else "右へ3歩 →"
		var direction_button := _button(button_text, _run_aquafall_practice.bind(direction), true)
		direction_button.name = "AquafallPracticeLeftButton" if direction < 0 else "AquafallPracticeRightButton"
		direction_button.custom_minimum_size.y = 62 if compact else 72
		direction_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		direction_button.add_theme_font_size_override("font_size", 18 if compact else 22)
		direction_row.add_child(direction_button)


func _run_aquafall_practice(direction: int) -> void:
	if aquafall_practice_active or not is_instance_valid(active_modal):
		return
	aquafall_practice_active = true
	for button_name: String in ["AquafallPracticeLeftButton", "AquafallPracticeRightButton"]:
		var button := active_modal.find_child(button_name, true, false) as BaseButton
		if button != null:
			button.visible = false
	var hint := active_modal.find_child("AquafallPracticeHint", true, false) as Label
	if hint != null:
		hint.text = ("LEFT ×3" if direction < 0 else "RIGHT ×3") + "　方向固定！"
		hint.add_theme_color_override("font_color", Color("#b26443"))
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(aquafall_practice_cat):
		return
	var path := AquafallBattle.reflect_path(4, direction, 3, 5)
	var practice_field := active_modal.find_child("AquafallPracticeField", true, false) as Control
	var row_step := float(practice_field.get_meta("row_step", 42.0)) if practice_field != null else 42.0
	for step_index: int in range(path.size()):
		var from_position := aquafall_practice_cat.position
		var to_position := from_position
		to_position.x = practice_field.size.x * ((float(path[step_index]) - 0.5) / 5.0) - aquafall_practice_cat.size.x * 0.5 if practice_field != null else from_position.x
		var log_positions: Array[Vector2] = []
		for practice_log: Control in aquafall_practice_logs:
			log_positions.append(practice_log.position)
		var tween := create_tween()
		tween.tween_method(_apply_aquafall_practice_motion.bind(aquafall_practice_cat, from_position, to_position, aquafall_practice_logs, log_positions, row_step), 0.0, 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if hint != null:
			hint.text = "%s ×3　　%d / 3" % ["LEFT" if direction < 0 else "RIGHT", step_index + 1]
		await tween.finished
		if not is_inside_tree():
			return
		await get_tree().create_timer(0.08).timeout
	if hint != null:
		hint.text = "OK！ 3歩のあいだ方向は固定"
	if journey != null:
		journey.stage_flags["aquafall_practice_seen"] = true
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	aquafall_practice_active = false
	_close_modal()
	_start_aquafall_boss()


func _apply_aquafall_practice_motion(progress: float, cat: Control, from_position: Vector2, to_position: Vector2, logs: Array[Control], log_positions: Array[Vector2], row_step: float) -> void:
	var t := clampf(progress, 0.0, 1.0)
	if is_instance_valid(cat):
		cat.position = from_position.lerp(to_position, t) + Vector2(0.0, -sin(t * PI) * 24.0)
	for log_index: int in range(mini(logs.size(), log_positions.size())):
		if is_instance_valid(logs[log_index]):
			logs[log_index].position = log_positions[log_index] + Vector2(0.0, row_step * t)


func _start_aquafall_boss() -> void:
	map_roll_active = false
	map_roll_elapsed = 0.0
	map_movement_active = false
	roll_animation_active = false
	amazon_boss_roll_active = false
	amazon_boss_roll_elapsed = 0.0
	amazon_boss_roll_face = 1
	amazon_boss_move_active = false
	aquafall_visual_lane = -1
	aquafall_visual_height = -1
	aquafall_visual_obstacles.clear()
	aquafall_animation_step = 0
	aquafall_animation_total = 0
	roll_slots.clear()
	if is_instance_valid(top_hud):
		top_hud.modulate = Color(1.0, 1.0, 1.0, 0.46)
	if is_instance_valid(stage_band):
		stage_band.modulate = Color(1.0, 1.0, 1.0, 0.68)
	if is_instance_valid(mission_band):
		mission_band.modulate = Color(1.0, 1.0, 1.0, 0.52)
	amazon_boss = AquafallBattle.new()
	amazon_boss.configure(journey.lap, journey.hp, journey.max_hp, rng.randi())
	var previous_waterfall_level := int(journey.stage_flags.get("aquafall_last_waterfall_level", 0))
	journey.stage_flags["aquafall_last_waterfall_level"] = amazon_boss.waterfall_level
	if previous_waterfall_level > 0 and amazon_boss.waterfall_level > previous_waterfall_level:
		status_label.text = "瀑流 LEVEL UP　Lv.%d → Lv.%d" % [previous_waterfall_level, amazon_boss.waterfall_level]
	else:
		status_label.text = "瀑流 Lv.%d　頂上を目指そう！ ダイスを振る" % amazon_boss.waterfall_level
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm != null:
		bgm.call("play_amazon_boss")
	_render_aquafall_boss()


func _render_aquafall_boss() -> void:
	_clear_content()
	_clear_controls()
	var bg := _boss_background(AMAZON_BOSS_BG)
	content_host.add_child(bg)
	var lane_area := Control.new()
	lane_area.name = "AquafallLanes"
	lane_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host.add_child(lane_area)
	aquafall_lane_layer = lane_area
	var arena_size := content_host.size
	if arena_size.x <= 0.0 or arena_size.y <= 0.0:
		arena_size = content_host.custom_minimum_size
	var side_margin := clampf(arena_size.x * 0.08, 24.0, 58.0)
	var lane_count := maxi(amazon_boss.lane_count, 2)
	var lane_width := (arena_size.x - side_margin * 2.0) / float(lane_count)
	var info_height := clampf(arena_size.y * 0.16, 66.0, 84.0)
	var info_top := clampf(arena_size.y * 0.04, 12.0, 30.0)
	var player_size := clampf(lane_width * 1.02, 76.0, 124.0)
	# Keep the explorer on a distinct bottom rail. The die now lives in its own
	# compact lower-right dock, so the hop animation never hides the player.
	var player_bottom := arena_size.y - 2.0
	var player_top := player_bottom - player_size
	var collision_row_y := player_top + player_size * 0.20
	var row_step := clampf((collision_row_y - (info_top + info_height + 16.0)) / 6.0, 32.0, 58.0)
	var display_lane := amazon_boss.lane
	var display_height := amazon_boss.height
	var display_obstacles: Array[Dictionary] = amazon_boss.obstacles
	if amazon_boss_move_active:
		display_lane = aquafall_visual_lane
		display_height = aquafall_visual_height
		display_obstacles = aquafall_visual_obstacles
	lane_area.set_meta("side_margin", side_margin)
	lane_area.set_meta("lane_width", lane_width)
	lane_area.set_meta("row_step", row_step)
	for lane_index: int in range(lane_count):
		var lane_line := ColorRect.new()
		lane_line.color = Color(0.82, 0.95, 1.0, 0.36)
		lane_line.position = Vector2(side_margin + lane_width * (lane_index + 0.5) - 2.0, info_top + info_height + 10.0)
		lane_line.size = Vector2(4, player_bottom - (info_top + info_height + 10.0))
		lane_area.add_child(lane_line)
	_add_aquafall_height_guide(lane_area, side_margin, info_top, info_height, collision_row_y, player_bottom, row_step, display_height, amazon_boss.goal_height, lane_count, lane_width)
	for obstacle_index: int in range(display_obstacles.size()):
		var obstacle: Dictionary = display_obstacles[obstacle_index]
		var is_large_log := str(obstacle.get("type", "")) == "large_log"
		var obstacle_lanes: Array = obstacle.get("lanes", []) as Array
		for segment_index: int in range(obstacle_lanes.size()):
			var lane_value: Variant = obstacle_lanes[segment_index]
			var log := Panel.new()
			log.name = "AquafallLog_%d_%d" % [obstacle_index, segment_index]
			log.set_meta("aquafall_log_segment", true)
			log.set_meta("obstacle_index", obstacle_index)
			log.set_meta("log_type", str(obstacle.get("type", "small_log")))
			log.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Each occupied lane gets one segment. Keep even the large frame inside
			# its lane so adjacent segments read as one wall without overlapping.
			var log_width := lane_width * (0.88 if is_large_log else 0.72)
			var log_height := clampf(row_step * (0.86 if is_large_log else 0.58), 24.0, 56.0)
			var log_inset := 3.0 if is_large_log else 2.0
			var frame_size := Vector2(log_width + log_inset * 2.0, log_height + log_inset * 2.0)
			log.position = Vector2(side_margin + (int(lane_value) - 1) * lane_width + (lane_width - frame_size.x) * 0.5, collision_row_y - int(obstacle.get("relative_height", 0)) * row_step - frame_size.y * 0.5)
			log.size = frame_size
			log.add_theme_stylebox_override("panel", _aquafall_log_style(is_large_log))
			var log_texture := TextureRect.new()
			log_texture.name = "AquafallLogTexture"
			log_texture.texture = AQUAFALL_LARGE_LOG if is_large_log else AQUAFALL_SMALL_LOG
			log_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			log_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			log_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			log_texture.offset_left = log_inset
			log_texture.offset_top = log_inset
			log_texture.offset_right = -log_inset
			log_texture.offset_bottom = -log_inset
			log_texture.modulate = Color(1.08, 1.08, 1.02, 1.0) if not is_large_log else Color(1.12, 1.02, 0.92, 1.0)
			log_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			log.add_child(log_texture)
			lane_area.add_child(log)
	var cat := TextureRect.new()
	cat.name = "AquafallPlayer"
	cat.texture = _cat_frame(idle_frame)
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat.position = Vector2(side_margin + (display_lane - 1) * lane_width + (lane_width - player_size) * 0.5, player_top)
	cat.size = Vector2(player_size, player_size)
	cat.set_meta("base_y", player_top)
	lane_area.add_child(cat)
	aquafall_player_sprite = cat
	var info := _label(_aquafall_info_text(display_height, display_lane, -1, amazon_boss.pending_face), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	info.name = "AquafallInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.position = Vector2(side_margin, info_top)
	info.size = Vector2(arena_size.x - side_margin * 2.0, info_height)
	info.add_theme_stylebox_override("normal", _panel(Color(0.03, 0.18, 0.19, 0.86), Color("#75e1d0"), 14, 2))
	lane_area.add_child(info)
	var step_counter := _label("", 22, Color("#fff1b0"), HORIZONTAL_ALIGNMENT_CENTER)
	step_counter.name = "AquafallStepCounter"
	step_counter.position = Vector2((arena_size.x - 176.0) * 0.5, info_top + info_height + 8.0)
	step_counter.size = Vector2(176.0, 42.0)
	step_counter.visible = false
	step_counter.z_index = 4
	step_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	step_counter.add_theme_stylebox_override("normal", _panel(Color(0.02, 0.14, 0.13, 0.92), Color("#f0cc62"), 12, 2))
	lane_area.add_child(step_counter)
	map_dice = DICE_PRESENTATION.new()
	map_dice.name = "AquafallDicePresentation"
	map_dice.overlay_compact = true
	map_dice.compact_single = true
	map_dice.tray_surface_visible = false
	map_dice.high_contrast_pips = true
	content_host.add_child(map_dice)
	# A compact die dock keeps the live roll visible in the lower-right corner
	# without sitting on top of the explorer. It is intentionally separate from
	# the three-slot tray below the waterfall.
	map_dice.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	map_dice.offset_left = -124
	map_dice.offset_top = -224
	map_dice.offset_right = -16
	map_dice.offset_bottom = -116
	map_dice.z_index = 2
	var settled_face := 1
	if amazon_boss_roll_active:
		settled_face = amazon_boss_roll_face
	elif amazon_boss.pending_face > 0:
		settled_face = amazon_boss.pending_face
	elif not roll_slots.is_empty():
		settled_face = roll_slots.back()
	map_dice.present([settled_face], amazon_boss_roll_active, 0 if amazon_boss_roll_active else 1)
	_build_boss_roll_tray()
	if amazon_boss.phase == AquafallBattle.PHASE_WAIT_DIRECTION and not amazon_boss_move_active:
		var row := HBoxContainer.new()
		row.name = "AquafallDirectionRow"
		row.add_theme_constant_override("separation", 10)
		var left_preview := amazon_boss.preview_direction(-1)
		var right_preview := amazon_boss.preview_direction(1)
		var left := _button("← 左へ%d歩\n着地：レーン%d" % [amazon_boss.pending_face, int(left_preview.destination_lane)], _aquafall_direction.bind(-1), true)
		var right := _button("右へ%d歩 →\n着地：レーン%d" % [amazon_boss.pending_face, int(right_preview.destination_lane)], _aquafall_direction.bind(1), true)
		left.name = "AquafallLeftButton"
		right.name = "AquafallRightButton"
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.custom_minimum_size.y = 82
		right.custom_minimum_size.y = 82
		left.add_theme_font_size_override("font_size", 20)
		right.add_theme_font_size_override("font_size", 20)
		row.add_child(left)
		row.add_child(right)
		controls_box.add_child(row)
	_refresh_all()


func _aquafall_info_text(height_value: int, lane_value: int, remaining_jumps: int = -1, face_value: int = 0, hp_value: int = -1) -> String:
	var goal_remaining := maxi(amazon_boss.goal_height - height_value, 0) if amazon_boss != null else 0
	var display_hp := amazon_boss.hp if hp_value < 0 else hp_value
	var action_text := ""
	if remaining_jumps >= 0:
		action_text = "残り %dジャンプ" % remaining_jumps
	elif face_value > 0:
		action_text = "出目 %d" % face_value
	else:
		action_text = "ROLL待ち"
	if amazon_boss != null and amazon_boss.water_guard_charges > 0:
		action_text += "・ガード%d" % amazon_boss.water_guard_charges
	if amazon_boss != null and amazon_boss.water_run_rolls > 0:
		action_text += "・無傷%d投" % amazon_boss.water_run_rolls
	return "GOALまで あと%d段　｜　%s　｜　%s\n高さ %d/%d　｜　現在レーン %d" % [goal_remaining, _heart_text(display_hp), action_text, height_value, amazon_boss.goal_height, lane_value]


func _add_aquafall_height_guide(lane_area: Control, side_margin: float, info_top: float, info_height: float, collision_row_y: float, player_bottom: float, row_step: float, current_height: int, goal_height: int, lane_count: int, lane_width: float) -> void:
	var track_top := info_top + info_height + 10.0
	var visible_rows := clampi(int(floor((collision_row_y - track_top) / row_step)), 0, 8)
	# Horizontal guides make the one-step fall of every log readable even when
	# the waterfall spray is bright. The collision row is the strongest guide.
	for row_index: int in range(visible_rows + 1):
		var guide := ColorRect.new()
		guide.name = "AquafallHeightTick_%d" % row_index
		guide.color = Color(0.92, 0.96, 0.82, 0.42 if row_index == 0 else 0.20)
		guide.position = Vector2(side_margin, collision_row_y - row_index * row_step - 1.0)
		guide.size = Vector2(lane_width * lane_count, 2.0)
		guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lane_area.add_child(guide)

	var gauge_width := maxf(side_margin - 8.0, 28.0)
	var gauge := Panel.new()
	gauge.name = "AquafallHeightGauge"
	gauge.position = Vector2(4.0, track_top)
	gauge.size = Vector2(gauge_width, maxf(player_bottom - track_top, 120.0))
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.z_index = 1
	gauge.add_theme_stylebox_override("panel", _panel(Color(0.015, 0.08, 0.08, 0.72), Color("#75e1d0"), 10, 1))
	lane_area.add_child(gauge)
	var goal_icon := TextureRect.new()
	goal_icon.name = "AquafallGoalIcon"
	goal_icon.texture = AQUAFALL_GOAL_ICON
	goal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	goal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	goal_icon.position = Vector2(1.0, 2.0)
	goal_icon.size = Vector2(gauge_width - 2.0, 40.0)
	goal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_child(goal_icon)
	var meter_top := 48.0
	var meter_bottom := gauge.size.y - 16.0
	gauge.set_meta("meter_top", meter_top)
	gauge.set_meta("meter_bottom", meter_bottom)
	gauge.set_meta("goal_height", goal_height)
	var meter_line := ColorRect.new()
	meter_line.color = Color(0.73, 0.91, 0.82, 0.56)
	meter_line.position = Vector2(gauge_width * 0.5 - 1.0, meter_top)
	meter_line.size = Vector2(2.0, maxf(meter_bottom - meter_top, 1.0))
	meter_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_child(meter_line)
	var current_ratio := clampf(float(current_height) / float(maxi(goal_height, 1)), 0.0, 1.0)
	var current_marker := TextureRect.new()
	current_marker.name = "AquafallHeightCurrent"
	current_marker.texture = _cat_frame(0)
	current_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	current_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	current_marker.position = Vector2(1.0, lerpf(meter_bottom, meter_top, current_ratio) - 14.0)
	current_marker.size = Vector2(gauge_width - 2.0, 28.0)
	current_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_marker.z_index = 2
	gauge.add_child(current_marker)
	for marker: int in range(7):
		var ratio := float(marker) / 6.0
		var y := lerpf(meter_bottom, meter_top, ratio)
		var tick := ColorRect.new()
		tick.color = Color("#f5d27b")
		tick.position = Vector2(gauge_width * 0.22, y - 1.0)
		tick.size = Vector2(gauge_width * 0.56, 2.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gauge.add_child(tick)
		var value := roundi(lerpf(0.0, float(goal_height), ratio))
		var value_label := _label(str(value), 9, Color("#f4ead0"), HORIZONTAL_ALIGNMENT_CENTER)
		value_label.position = Vector2(0.0, y - 8.0)
		value_label.size = Vector2(gauge_width, 16.0)
		gauge.add_child(value_label)


func _aquafall_roll() -> void:
	if amazon_boss == null or amazon_boss_move_active:
		return
	if amazon_boss_roll_active:
		amazon_boss_roll_active = false
		var face := clampi(amazon_boss_roll_face, 1, 6)
		var result := amazon_boss.request_roll(face)
		if not bool(result.get("ok", false)):
			status_label.text = str(result.get("error", ""))
			_refresh_all()
			return
		roll_slots.append(face)
		if is_instance_valid(roll_caption_label):
			roll_caption_label.text = ""
			roll_caption_label.visible = false
		if is_instance_valid(roll_button):
			roll_button.tooltip_text = ""
		if is_instance_valid(map_dice):
			map_dice.present([face], false, 1)
		_play_dice_se(DICE_LAND_SE)
		status_label.text = "出目 %d。左右どちらへ進む？" % face
		_render_aquafall_boss()
		return
	if amazon_boss.phase != AquafallBattle.PHASE_WAIT_ROLL:
		return
	_prepare_next_slot_cycle()
	amazon_boss_roll_active = true
	amazon_boss_roll_elapsed = 0.0
	amazon_boss_roll_face = 1
	if is_instance_valid(roll_caption_label):
		roll_caption_label.text = "止める"
		roll_caption_label.visible = true
	if is_instance_valid(roll_button):
		roll_button.disabled = false
		roll_button.tooltip_text = "タップで止める"
	if is_instance_valid(map_dice):
		map_dice.present([amazon_boss_roll_face], true, 0)
		map_dice.sync_rolling_elapsed(amazon_boss_roll_elapsed)
	_play_dice_se(DICE_ROLL_SE)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.text = "ダイス回転中　—　タップで止める"
	_refresh_roll_slots()


func _aquafall_direction(direction: int) -> void:
	if amazon_boss == null or amazon_boss_move_active or amazon_boss.phase != AquafallBattle.PHASE_WAIT_DIRECTION:
		return
	var path := AquafallBattle.reflect_path(amazon_boss.lane, direction, amazon_boss.pending_face, amazon_boss.lane_count)
	if path.is_empty():
		return
	var collision_preview := amazon_boss.preview_direction(direction)
	var contact_details: Array = collision_preview.get("contact_details", []) as Array
	amazon_boss_move_active = true
	amazon_boss_roll_active = false
	aquafall_animation_step = 0
	aquafall_animation_total = path.size()
	aquafall_visual_lane = amazon_boss.lane
	aquafall_visual_height = amazon_boss.height
	aquafall_visual_obstacles = amazon_boss.obstacles.duplicate(true)
	_set_aquafall_direction_buttons_disabled(true)
	if is_instance_valid(roll_button):
		roll_button.disabled = true
	var lane_area := aquafall_lane_layer
	var step_counter := lane_area.get_node_or_null("AquafallStepCounter") as Label if is_instance_valid(lane_area) else null
	if step_counter != null:
		step_counter.text = ("LEFT ×%d" if direction < 0 else "RIGHT ×%d") % path.size()
		step_counter.visible = true
	status_label.text = ("左へ%d歩　方向固定！" if direction < 0 else "右へ%d歩　方向固定！") % path.size()
	await get_tree().create_timer(0.28).timeout
	if not is_inside_tree():
		return
	await _animate_aquafall_direction(path, contact_details)
	if not is_inside_tree():
		return
	var result := amazon_boss.choose_direction(direction)
	journey.hp = amazon_boss.hp
	amazon_boss_move_active = false
	aquafall_visual_lane = -1
	aquafall_visual_height = -1
	aquafall_visual_obstacles.clear()
	var role := str(result.get("role", amazon_boss.last_role))
	var role_effect := str(result.get("role_effect", amazon_boss.last_role_effect))
	if amazon_boss.hp > 0 and not role.is_empty() and role != "NONE":
		status_label.text = "%s！　%s" % [role, role_effect]
		await _play_aquafall_role_effect(role, role_effect)
		if not is_inside_tree():
			return
	if amazon_boss.phase == AquafallBattle.PHASE_VICTORY:
		status_label.text = "高さ %d。流れを制した！" % amazon_boss.height
		_show_boss_recovery_or_perfect()
	elif amazon_boss.phase == AquafallBattle.PHASE_DEFEAT:
		_resolve_boss_defeat("瀑竜の激流に押し戻された。")
	elif bool(result.get("ok", false)):
		status_label.text = "高さ %d。%s%s" % [amazon_boss.height, ("%s！　" % role) if not role.is_empty() and role != "NONE" else "", role_effect]
		_render_aquafall_boss()


func _play_aquafall_role_effect(role: String, role_effect: String) -> void:
	if not is_instance_valid(content_host):
		return
	var presentation := _aquafall_role_presentation(role)
	var accent: Color = presentation.get("accent", Color("#76e0d0")) as Color
	var deep: Color = presentation.get("deep", Color("#063c42")) as Color
	_flash_roll_slots(3, accent)

	var overlay := Control.new()
	overlay.name = "AquafallRoleBurst"
	overlay.set_meta("role", role)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 120
	overlay.modulate = Color(1, 1, 1, 0)
	content_host.add_child(overlay)

	var veil := ColorRect.new()
	veil.name = "AquafallRoleVeil"
	veil.color = Color(deep.r, deep.g, deep.b, 0.34)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(veil)

	var arena_size := content_host.size
	if arena_size.x <= 0.0 or arena_size.y <= 0.0:
		arena_size = content_host.custom_minimum_size
	var card_width := minf(maxf(arena_size.x - 34.0, 280.0), 520.0)
	var card_height := 176.0
	var card := PanelContainer.new()
	card.name = "AquafallRoleCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -card_width * 0.5
	card.offset_right = card_width * 0.5
	card.offset_top = -card_height * 0.62
	card.offset_bottom = card.offset_top + card_height
	card.pivot_offset = Vector2(card_width * 0.5, card_height * 0.5)
	card.scale = Vector2(0.72, 0.72)
	card.z_index = 10
	var card_style := _panel(Color(deep.r, deep.g, deep.b, 0.96), accent, 22, 4)
	card_style.shadow_color = Color(0, 0, 0, 0.72)
	card_style.shadow_size = 14
	card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(card)

	var stack := VBoxContainer.new()
	stack.name = "AquafallRoleCopy"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 2)
	var eyebrow := _label("SLOT SKILL  •  %s" % role, 16, accent, HORIZONTAL_ALIGNMENT_CENTER)
	eyebrow.name = "AquafallRoleName"
	stack.add_child(eyebrow)
	var skill := _label(str(presentation.get("skill", role)), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	skill.name = "AquafallRoleSkill"
	skill.add_theme_color_override("font_outline_color", deep.darkened(0.35))
	skill.add_theme_constant_override("outline_size", 7)
	stack.add_child(skill)
	var effect_copy := _label(str(presentation.get("copy", role_effect)), 17, Color("#fff1bd"), HORIZONTAL_ALIGNMENT_CENTER)
	effect_copy.name = "AquafallRoleEffectCopy"
	effect_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_copy.custom_minimum_size.y = 42
	stack.add_child(effect_copy)
	card.add_child(stack)

	_add_aquafall_role_world_effect(overlay, role, accent, deep)
	var intro := create_tween().set_parallel(true)
	intro.tween_property(overlay, "modulate:a", 1.0, 0.14)
	intro.tween_property(card, "scale", Vector2(1.04, 1.04), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro.finished
	if not is_instance_valid(overlay):
		return
	var settle := create_tween()
	settle.tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	settle.tween_interval(0.48)
	settle.tween_property(overlay, "modulate:a", 0.0, 0.22)
	await settle.finished
	if is_instance_valid(overlay):
		overlay.queue_free()


func _aquafall_role_presentation(role: String) -> Dictionary:
	match role:
		"PAIR":
			return {"skill": "水流ガード", "copy": "次の衝突を1回防ぐ", "accent": Color("#72ead2"), "deep": Color("#063c42")}
		"STRAIGHT":
			return {"skill": "水走り", "copy": "次の1投は丸太ダメージ無効", "accent": Color("#78cfff"), "deep": Color("#073c64")}
		"TRIPLE":
			return {"skill": "激流突破", "copy": "丸太を一掃・高さ＋2", "accent": Color("#ffd86b"), "deep": Color("#6b2f12")}
	return {"skill": role, "copy": "スキル発動", "accent": Color("#76e0d0"), "deep": Color("#063c42")}


func _add_aquafall_role_world_effect(overlay: Control, role: String, accent: Color, deep: Color) -> void:
	var effect_size := overlay.size
	if (effect_size.x <= 0.0 or effect_size.y <= 0.0) and overlay.get_parent() is Control:
		effect_size = (overlay.get_parent() as Control).size
	if role == "PAIR" and is_instance_valid(aquafall_player_sprite):
		var shield := Panel.new()
		shield.name = "AquafallGuardRing"
		shield.position = aquafall_player_sprite.position - Vector2(12, 12)
		shield.size = aquafall_player_sprite.size + Vector2(24, 24)
		shield.pivot_offset = shield.size * 0.5
		shield.scale = Vector2(0.55, 0.55)
		shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shield_style := _panel(Color(0.15, 0.95, 0.82, 0.12), accent, 40, 5)
		shield_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.55)
		shield_style.shadow_size = 12
		shield.add_theme_stylebox_override("panel", shield_style)
		overlay.add_child(shield)
		var shield_tween := create_tween().set_parallel(true)
		shield_tween.tween_property(shield, "scale", Vector2(1.16, 1.16), 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		shield_tween.tween_property(shield, "modulate:a", 0.18, 0.82).set_delay(0.18)
	elif role == "STRAIGHT":
		for line_index: int in range(5):
			var stream := ColorRect.new()
			stream.name = "AquafallWaterRunLine_%d" % line_index
			stream.color = Color(accent.r, accent.g, accent.b, 0.62)
			stream.position = Vector2(54.0 + line_index * maxf((effect_size.x - 108.0) / 4.0, 44.0), effect_size.y * 0.70 + line_index % 2 * 28.0)
			stream.size = Vector2(6, 112)
			stream.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(stream)
			var stream_tween := create_tween().set_parallel(true)
			stream_tween.tween_property(stream, "position:y", effect_size.y * 0.12, 0.82 + line_index * 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			stream_tween.tween_property(stream, "modulate:a", 0.0, 0.72).set_delay(0.18)
	elif role == "TRIPLE":
		for value: Node in find_children("AquafallLog_*", "Panel", true, false):
			var log := value as Control
			if log == null:
				continue
			var clear_tween := create_tween().set_parallel(true)
			clear_tween.tween_property(log, "position:y", log.position.y + 84.0, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			clear_tween.tween_property(log, "modulate:a", 0.0, 0.42)
		var burst := Panel.new()
		burst.name = "AquafallTripleBurst"
		burst.set_anchors_preset(Control.PRESET_CENTER)
		burst.offset_left = -54
		burst.offset_top = -54
		burst.offset_right = 54
		burst.offset_bottom = 54
		burst.pivot_offset = Vector2(54, 54)
		burst.scale = Vector2(0.2, 0.2)
		var burst_style := _panel(Color(accent.r, accent.g, accent.b, 0.18), accent, 54, 6)
		burst_style.shadow_color = Color(deep.r, deep.g, deep.b, 0.65)
		burst_style.shadow_size = 18
		burst.add_theme_stylebox_override("panel", burst_style)
		overlay.add_child(burst)
		var burst_tween := create_tween().set_parallel(true)
		burst_tween.tween_property(burst, "scale", Vector2(3.4, 3.4), 0.68).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		burst_tween.tween_property(burst, "modulate:a", 0.0, 0.58).set_delay(0.10)


func _set_aquafall_direction_buttons_disabled(disabled: bool) -> void:
	for button_name: String in ["AquafallLeftButton", "AquafallRightButton"]:
		var button := controls_box.find_child(button_name, true, false) as BaseButton
		if button != null:
			button.disabled = disabled
			button.visible = not disabled


func _animate_aquafall_direction(path: Array[int], contact_details: Array = []) -> void:
	var projected_hp := amazon_boss.hp
	var projected_guard := amazon_boss.water_guard_charges
	var immune := amazon_boss.water_run_rolls > 0
	for step_index: int in range(path.size()):
		await _animate_aquafall_step(path[step_index], step_index, path.size())
		if not is_inside_tree():
			return
		var step_contacts: Array[Dictionary] = []
		for raw_contact: Variant in contact_details:
			if raw_contact is Dictionary and int((raw_contact as Dictionary).get("step", -1)) == step_index + 1:
				step_contacts.append(raw_contact as Dictionary)
		if step_contacts.is_empty():
			continue
		var damage_count := 0
		var blocked_count := 0
		for _contact: Dictionary in step_contacts:
			if immune:
				blocked_count += 1
			elif projected_guard > 0:
				projected_guard -= 1
				blocked_count += 1
			else:
				projected_hp = maxi(projected_hp - 1, 0)
				damage_count += 1
		_show_aquafall_contact_feedback(step_contacts, damage_count, blocked_count, projected_hp, path.size() - step_index - 1)
		# Hold the contact state long enough to read before the turn-result copy
		# replaces it. This also makes the damage land on the exact hop where the
		# log and explorer meet instead of appearing only after every hop ends.
		await get_tree().create_timer(0.32).timeout
		if not is_inside_tree():
			return
		if projected_hp <= 0:
			break


func _show_aquafall_contact_feedback(contacts: Array[Dictionary], damage_count: int, blocked_count: int, projected_hp: int, remaining_jumps: int) -> void:
	var contact_types: Array[String] = []
	for contact: Dictionary in contacts:
		var label := "大丸太" if str(contact.get("type", "")) == "large_log" else "小丸太"
		if label not in contact_types:
			contact_types.append(label)
	if damage_count > 0:
		status_label.text = "%sに衝突！　♥−%d" % ["・".join(contact_types), damage_count]
	elif blocked_count > 0:
		status_label.text = "%sを防いだ！" % "・".join(contact_types)
	var info := aquafall_lane_layer.get_node_or_null("AquafallInfo") as Label if is_instance_valid(aquafall_lane_layer) else null
	if info != null:
		info.text = _aquafall_info_text(aquafall_visual_height, aquafall_visual_lane, remaining_jumps, amazon_boss.pending_face, projected_hp)
	if is_instance_valid(aquafall_player_sprite):
		aquafall_player_sprite.modulate = Color("#ff7466") if damage_count > 0 else Color("#78f4df")
		var hit_tween := create_tween()
		hit_tween.tween_property(aquafall_player_sprite, "modulate", Color.WHITE, 0.24)


func _animate_aquafall_step(target_lane: int, step_index: int, total_steps: int) -> void:
	var lane_area := aquafall_lane_layer
	if not is_instance_valid(lane_area):
		lane_area = content_host.get_node_or_null("AquafallLanes") as Control
	if lane_area == null:
		return
	var cat := aquafall_player_sprite
	if not is_instance_valid(cat):
		cat = lane_area.get_node_or_null("AquafallPlayer") as Control
	if cat == null:
		return
	var side_margin := float(lane_area.get_meta("side_margin", 24.0))
	var lane_width := float(lane_area.get_meta("lane_width", 80.0))
	var row_step := float(lane_area.get_meta("row_step", 40.0))
	var from_position := cat.position
	var base_y := float(cat.get_meta("base_y", from_position.y))
	var to_position := Vector2(side_margin + (target_lane - 1) * lane_width + (lane_width - cat.size.x) * 0.5, base_y)
	# Announce each hop before the tween starts so the player can follow the
	# die count instead of only seeing the settled destination.
	status_label.text = "%d / %d歩　探検猫がぴょん！" % [step_index + 1, total_steps]
	var info := lane_area.get_node_or_null("AquafallInfo") as Label
	if info != null:
		info.text = _aquafall_info_text(mini(amazon_boss.height + step_index, amazon_boss.goal_height), target_lane, total_steps - step_index, amazon_boss.pending_face)
	var target_height := mini(amazon_boss.height + step_index + 1, amazon_boss.goal_height)
	var step_counter := lane_area.get_node_or_null("AquafallStepCounter") as Label
	if step_counter != null:
		step_counter.text = "STEP  %d / %d" % [step_index + 1, total_steps]
		step_counter.visible = true
	var gauge := lane_area.get_node_or_null("AquafallHeightGauge") as Control
	var current_line := gauge.get_node_or_null("AquafallHeightCurrent") as Control if gauge != null else null
	var gauge_from_y := current_line.position.y if current_line != null else 0.0
	var gauge_to_y := gauge_from_y
	if gauge != null and current_line != null:
		var meter_top := float(gauge.get_meta("meter_top", 24.0))
		var meter_bottom := float(gauge.get_meta("meter_bottom", gauge.size.y - 16.0))
		var goal_height := maxi(int(gauge.get_meta("goal_height", amazon_boss.goal_height)), 1)
		var target_ratio := clampf(float(target_height) / float(goal_height), 0.0, 1.0)
		gauge_to_y = lerpf(meter_bottom, meter_top, target_ratio) - 14.0
	var moving_logs: Array[Control] = []
	var log_start_positions: Array[Vector2] = []
	for child: Node in lane_area.get_children():
		if child is Control and bool(child.get_meta("aquafall_log_segment", false)):
			moving_logs.append(child as Control)
			log_start_positions.append((child as Control).position)
	# One master progress value drives the explorer, every log segment, and the
	# height gauge. Multi-lane logs can no longer drift because their individual
	# tweens happened to begin on different scheduler ticks.
	var step_tween := create_tween()
	step_tween.tween_method(
		_apply_aquafall_step_motion.bind(cat, from_position, to_position, moving_logs, log_start_positions, row_step, current_line, gauge_from_y, gauge_to_y),
		0.0,
		1.0,
		AQUAFALL_STEP_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await step_tween.finished
	if not is_inside_tree():
		return
	aquafall_visual_lane = target_lane
	aquafall_visual_height = mini(amazon_boss.height + step_index + 1, amazon_boss.goal_height)
	aquafall_animation_step = step_index + 1
	cat.position = to_position
	cat.scale = Vector2.ONE
	for log_index: int in range(moving_logs.size()):
		if is_instance_valid(moving_logs[log_index]):
			moving_logs[log_index].position = log_start_positions[log_index] + Vector2(0.0, row_step)
	if is_instance_valid(current_line):
		current_line.position.y = gauge_to_y
	for obstacle: Dictionary in aquafall_visual_obstacles:
		obstacle["relative_height"] = int(obstacle.get("relative_height", 0)) - 1
	info = lane_area.get_node_or_null("AquafallInfo") as Label
	if info != null:
		info.text = _aquafall_info_text(aquafall_visual_height, aquafall_visual_lane, total_steps - step_index - 1, amazon_boss.pending_face)
	status_label.text = "%d / %d歩　探検猫がぴょん！" % [step_index + 1, total_steps]
	if AQUAFALL_STEP_PAUSE_SECONDS > 0.0 and is_inside_tree():
		await get_tree().create_timer(AQUAFALL_STEP_PAUSE_SECONDS).timeout


func _apply_aquafall_step_motion(progress: float, cat: Control, from_position: Vector2, to_position: Vector2, moving_logs: Array[Control], log_start_positions: Array[Vector2], row_step: float, current_line: Control, gauge_from_y: float, gauge_to_y: float) -> void:
	var t := clampf(progress, 0.0, 1.0)
	if is_instance_valid(cat):
		cat.position = from_position.lerp(to_position, t) + Vector2(0.0, -sin(t * PI) * AQUAFALL_HOP_ARC)
		cat.scale = Vector2.ONE * (1.0 + sin(t * PI) * AQUAFALL_HOP_SCALE)
	for log_index: int in range(mini(moving_logs.size(), log_start_positions.size())):
		if is_instance_valid(moving_logs[log_index]):
			moving_logs[log_index].position = log_start_positions[log_index] + Vector2(0.0, row_step * t)
	if is_instance_valid(current_line):
		current_line.position.y = lerpf(gauge_from_y, gauge_to_y, t)


func _start_white_fox_boss(qa_mode: bool = false, restore_snapshot: Dictionary = {}) -> void:
	# Kept as the legacy visual-QA entry point for 狐火六路陣. New
	# `direct` selections are dispatched explicitly to 狐火追陣 below.
	_start_fox_fire_six_routes_boss(qa_mode, restore_snapshot)


func _start_direct_white_fox_boss(restore_snapshot: Dictionary = {}) -> void:
	# Schema-v1 `direct` saves used the seal board. Only restoration calls this
	# compatibility path; a fresh `direct` battle starts 狐火追陣.
	var kyoto := journey as KyotoJourney
	if kyoto == null:
		return
	if is_instance_valid(kyoto_chase_scene):
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
	if is_instance_valid(kyoto_boss_scene):
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
	kyoto_boss = WhiteFoxBattle.new()
	if not kyoto_boss.configure(kyoto.goshuin_state(), journey.coins, false, rng.randi()):
		push_error("Unable to configure direct WhiteFoxBattle")
		kyoto_boss = null
		return
	if not restore_snapshot.is_empty():
		kyoto_boss.restore(restore_snapshot)
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm != null:
		bgm.call("play_kyoto_boss")
	_render_white_fox_boss()


func _start_fox_fire_chase_boss(qa_mode: bool = false, restore_snapshot: Dictionary = {}) -> void:
	var kyoto := journey as KyotoJourney
	if kyoto == null or root_layer == null:
		return
	if is_instance_valid(kyoto_chase_scene):
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
	if is_instance_valid(kyoto_boss_scene):
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
	kyoto_boss = null
	var chase_scene := load(FOX_FIRE_CHASE_BATTLE_PATH) as PackedScene
	if chase_scene == null:
		push_error("FoxFireChaseBattle scene is not available: %s" % FOX_FIRE_CHASE_BATTLE_PATH)
		return
	var chase := chase_scene.instantiate() as Control
	if chase == null:
		push_error("Unable to instantiate FoxFireChaseBattle")
		return
	kyoto_chase_scene = chase
	kyoto_chase_scene.name = "FoxFireChaseBattle"
	kyoto_chase_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kyoto_chase_scene.z_index = 50
	root_layer.add_child(kyoto_chase_scene)
	if kyoto_chase_scene.has_signal("battle_finished"):
		kyoto_chase_scene.connect("battle_finished", Callable(self, "_on_fox_fire_chase_finished"))
	else:
		push_error("FoxFireChaseBattle must expose battle_finished")
	if kyoto_chase_scene.has_signal("coins_spent"):
		kyoto_chase_scene.connect("coins_spent", Callable(self, "_on_fox_fire_chase_coins_spent"))
	var configured := bool(kyoto_chase_scene.call(
		"configure_battle",
		journey.lap,
		kyoto.goshuin_count(),
		journey.coins,
		journey.hp,
		journey.max_hp,
		rng.randi(),
		restore_snapshot
	))
	if not configured:
		push_error("FoxFireChaseBattle configuration failed")
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
		return
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm != null:
		bgm.call("play_kyoto_fox_fire_chase")
	if qa_mode and kyoto_chase_scene.has_method("show_for_qa"):
		kyoto_chase_scene.call("show_for_qa")
	else:
		kyoto_chase_scene.call("start_battle")


func _on_fox_fire_chase_coins_spent(amount: int) -> void:
	if journey == null or amount <= 0:
		return
	journey.coins = maxi(journey.coins - amount, 0)
	_refresh_all()
	# Persist the journey and the purchased head start together. Otherwise an
	# app restart between purchase and the first roll could refund the coins.
	if is_instance_valid(kyoto_chase_scene):
		var chase_snapshot: Variant = kyoto_chase_scene.call("snapshot")
		if chase_snapshot is Dictionary:
			save_manager.save(stage_id, journey.snapshot(), chase_snapshot as Dictionary)


func _on_fox_fire_chase_finished(result: Variant) -> void:
	if not is_instance_valid(kyoto_chase_scene):
		return
	kyoto_chase_scene.visible = false
	kyoto_chase_scene.queue_free()
	kyoto_chase_scene = null
	if _boss_result_victory(result):
		status_label.text = "外周を駆け、白狐に追いついた。"
		_show_boss_recovery_or_perfect()
	else:
		_resolve_boss_defeat("白狐に一周先を取られた。")


func _boss_result_victory(result: Variant) -> bool:
	if result is Dictionary:
		return bool((result as Dictionary).get("victory", false))
	if result is Object:
		var object_result := result as Object
		for property: Dictionary in object_result.get_property_list():
			if str(property.get("name", "")) == "victory":
				return bool(object_result.get("victory"))
	return false


func _start_fox_fire_six_routes_boss(qa_mode: bool = false, restore_snapshot: Dictionary = {}) -> void:
	if is_instance_valid(kyoto_chase_scene):
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
	if is_instance_valid(kyoto_boss_scene):
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
	var kyoto := journey as KyotoJourney
	if kyoto == null or root_layer == null:
		return
	kyoto_boss = null
	kyoto_boss_scene = FOX_FIRE_BATTLE_SCENE.instantiate() as FoxFireSixRoutesBattle
	if kyoto_boss_scene == null:
		push_error("Unable to instantiate FoxFireSixRoutesBattle")
		return
	kyoto_boss_scene.name = "FoxFireSixRoutesBattle"
	kyoto_boss_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kyoto_boss_scene.z_index = 50
	root_layer.add_child(kyoto_boss_scene)
	kyoto_boss_scene.battle_finished.connect(_on_fox_fire_battle_finished)
	kyoto_boss_scene.slot_role_completed.connect(_on_fox_fire_slot_role_completed)
	var configured := kyoto_boss_scene.configure_battle(
		journey.lap,
		kyoto.goshuin_state(),
		journey.coins,
		journey.hp,
		journey.max_hp,
		rng.randi(),
		restore_snapshot
	)
	if not configured:
		push_error("FoxFireSixRoutesBattle configuration failed")
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
		return
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm != null:
		bgm.call("play_kyoto_boss")
	if qa_mode:
		kyoto_boss_scene.show_for_qa()
	else:
		kyoto_boss_scene.start_battle()


func _on_fox_fire_slot_role_completed(role: String) -> void:
	# Kyoto uses the same role reward as the normal map: PAIR +1,
	# STRAIGHT +2, TRIPLE → MAX. The boss owns presentation while the journey
	# remains the authority for the persistent skill gauge.
	if journey == null or role not in ["PAIR", "STRAIGHT", "TRIPLE"]:
		return
	journey.charge_skill_for_role(role)


func _on_fox_fire_battle_finished(result: Variant) -> void:
	if not is_instance_valid(kyoto_boss_scene):
		return
	kyoto_boss_scene.visible = false
	kyoto_boss_scene.queue_free()
	kyoto_boss_scene = null
	if _fox_fire_result_victory(result):
		status_label.text = "三つの鳥居が灯った。白狐は道を譲った。"
		_show_boss_recovery_or_perfect()
	else:
		_resolve_boss_defeat("狐火が六路を塞いだ。")


func _fox_fire_result_victory(result: Variant) -> bool:
	if result is FoxFireBattleResult:
		return (result as FoxFireBattleResult).victory
	if result is Dictionary:
		return bool((result as Dictionary).get("victory", false))
	return false


func _render_white_fox_boss() -> void:
	_clear_content()
	_clear_controls()
	content_host.add_child(_boss_background(KYOTO_BOSS_BG))
	var board := Control.new()
	board.name = "WhiteFoxBoard"
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host.add_child(board)
	var fox := TextureRect.new()
	fox.texture = WHITE_FOX
	fox.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fox.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fox.position = Vector2(230, 260)
	fox.size = Vector2(230, 230)
	fox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(fox)
	var positions := [Vector2(166, 230), Vector2(292, 186), Vector2(420, 230), Vector2(464, 358), Vector2(420, 486), Vector2(292, 530), Vector2(166, 486), Vector2(122, 358)]
	for index: int in range(kyoto_boss.seals.size()):
		var seal: Dictionary = kyoto_boss.seals[index]
		var state := str(seal.get("state", "EMPTY"))
		var label := "%s\n%d" % [str(seal.get("id", "")), int(seal.get("required", 0))]
		if state == "NORMAL": label += " ✓"
		if state == "CRACKED": label += " ひび"
		var button := _button(label, _fox_seal_pressed.bind(str(seal.get("id", ""))), false)
		button.name = "Seal_%s" % str(seal.get("id", ""))
		button.position = positions[index]
		button.size = Vector2(112, 88)
		button.add_theme_stylebox_override("normal", _panel(_seal_color(state), Color("#f5d674") if index == kyoto_boss.attack_cursor else Color("#784b32"), 18, 3 if index == kyoto_boss.attack_cursor else 2))
		button.disabled = selected_fox_die < 0 or not str(seal.get("id", "")) in kyoto_boss.available_targets(selected_fox_die)
		board.add_child(button)
	var info := _label("封印 %d/8　｜　ターン %d/%d\n狐火 今:%s → 次:%s　｜　祈り %d　供物 %d" % [kyoto_boss.completed_seals(), kyoto_boss.turn_number, kyoto_boss.max_turns, kyoto_boss.current_attack_id(), kyoto_boss.next_attack_id(), kyoto_boss.prayer_count, kyoto_boss.offering_count], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	info.position = Vector2(26, 82)
	info.size = Vector2(642, 88)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_stylebox_override("normal", _panel(Color(0.22, 0.05, 0.05, 0.86), Color("#f2b74d"), 14, 2))
	board.add_child(info)
	if kyoto_boss.phase == WhiteFoxBattle.PHASE_PRE_BONUS:
		status_label.text = "稲荷の御朱印：好きな封印へ旅石を先置きできる。"
		selected_fox_die = 0
		for child: Node in board.get_children():
			if child is Button and child.name.begins_with("Seal_"):
				(child as Button).disabled = false
	elif kyoto_boss.phase == WhiteFoxBattle.PHASE_WAIT_ROLL:
		var roll := _button("白狐のダイスを振る", _fox_roll, true)
		roll.name = "BossRollButton"
		roll.custom_minimum_size.y = 82
		controls_box.add_child(roll)
	elif kyoto_boss.phase == WhiteFoxBattle.PHASE_ACTION:
		_build_fox_dice_controls()
	_refresh_all()


func _build_fox_dice_controls() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for index: int in range(kyoto_boss.dice.size()):
		var die := _button("出目 %d" % kyoto_boss.dice[index], _select_fox_die.bind(index), true)
		die.name = "FoxDie%d" % index
		die.button_pressed = index == selected_fox_die
		die.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		die.custom_minimum_size.y = 64
		row.add_child(die)
	controls_box.add_child(row)
	var helpers := HBoxContainer.new()
	helpers.add_theme_constant_override("separation", 6)
	var reroll := _button("選択を3 COINで振り直す", _fox_coin_reroll, false)
	reroll.disabled = selected_fox_die < 0 or kyoto_boss.coins < kyoto_boss.reroll_cost or kyoto_boss.rerolls_used >= kyoto_boss.reroll_limit
	var kiyomizu := _button("清水・全振り直し", _fox_kiyomizu, false)
	kiyomizu.disabled = not kyoto_boss.kiyomizu_reroll_available
	var prayer := _button("祈りで出目変更", _fox_prayer, false)
	prayer.disabled = selected_fox_die < 0 or kyoto_boss.prayer_count <= 0
	var luck_shift := _button("勝運で出目 ±1", _fox_luck_shift, false)
	luck_shift.disabled = selected_fox_die < 0 or not kyoto_boss.tenryuji_shift_available
	for helper: Button in [reroll, kiyomizu, prayer]:
		helper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		helper.custom_minimum_size.y = 48
		helpers.add_child(helper)
	controls_box.add_child(helpers)
	var final_row := HBoxContainer.new()
	final_row.add_theme_constant_override("separation", 6)
	luck_shift.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	luck_shift.custom_minimum_size.y = 48
	final_row.add_child(luck_shift)
	var offer := _button("供物にする", _fox_offer, false)
	offer.disabled = selected_fox_die < 0 or not kyoto_boss.can_offer(selected_fox_die)
	offer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer.custom_minimum_size.y = 48
	final_row.add_child(offer)
	controls_box.add_child(final_row)


func _fox_roll() -> void:
	selected_fox_die = -1
	kyoto_boss.roll()
	status_label.text = "使うダイスを1つ選び、置く封印を決めよう。6はワイルド。"
	_render_white_fox_boss()


func _select_fox_die(index: int) -> void:
	selected_fox_die = index
	status_label.text = "出目 %d を選択。光る封印へ置くか、補助行動を使える。" % kyoto_boss.dice[index]
	_render_white_fox_boss()


func _fox_seal_pressed(seal_id: String) -> void:
	if kyoto_boss.phase == WhiteFoxBattle.PHASE_PRE_BONUS:
		kyoto_boss.apply_fushimi_preplacement(seal_id)
		selected_fox_die = -1
		status_label.text = "稲荷の旅石を %s へ先置きした。" % seal_id
		_render_white_fox_boss()
		return
	var result := kyoto_boss.commit_die(selected_fox_die, seal_id)
	selected_fox_die = -1
	_resolve_white_fox_action(result)


func _fox_offer() -> void:
	var result := kyoto_boss.commit_die(selected_fox_die)
	selected_fox_die = -1
	_resolve_white_fox_action(result)


func _resolve_white_fox_action(result: Dictionary) -> void:
	journey.coins = kyoto_boss.coins
	if kyoto_boss.phase == WhiteFoxBattle.PHASE_VICTORY:
		status_label.text = "八封成立。白狐が尾を伏せた。"
		_show_boss_recovery_or_perfect()
	elif kyoto_boss.phase == WhiteFoxBattle.PHASE_DEFEAT:
		_resolve_boss_defeat("夜が明け、封陣はあと一歩でほどけた。")
	else:
		status_label.text = _fox_result_text(result)
		_render_white_fox_boss()


func _fox_coin_reroll() -> void:
	kyoto_boss.coin_reroll(selected_fox_die)
	journey.coins = kyoto_boss.coins
	status_label.text = "旅銭で選んだダイスを振り直した。"
	_render_white_fox_boss()


func _fox_kiyomizu() -> void:
	kyoto_boss.kiyomizu_reroll()
	selected_fox_die = -1
	status_label.text = "清水の御朱印で3個すべて振り直した。"
	_render_white_fox_boss()


func _fox_prayer() -> void:
	var die_index := selected_fox_die
	var choices: Array = []
	for value: int in range(1, 6):
		choices.append({"id": str(value), "label": "出目を %d にする" % value})
	_open_choice_modal("祈り", "選択中のダイスを1〜5へ変える。", choices, func(choice_id: String) -> void:
		kyoto_boss.use_prayer(die_index, int(choice_id))
		selected_fox_die = die_index
		status_label.text = "祈りで出目を %s に変えた。" % choice_id
		_render_white_fox_boss()
	)


func _fox_luck_shift() -> void:
	var die_index := selected_fox_die
	_open_choice_modal("勝運の水", "選択中のダイスを1だけ上下させる。", [{"id": "-1", "label": "出目 -1"}, {"id": "1", "label": "出目 +1"}], func(choice_id: String) -> void:
		var result := kyoto_boss.use_luck_shift(die_index, int(choice_id))
		selected_fox_die = die_index
		status_label.text = "勝運の水で出目を%sした。" % choice_id if bool(result.get("ok", false)) else "この出目は%sできない。" % choice_id
		_render_white_fox_boss()
	)


func _show_heart_roulette() -> void:
	if is_instance_valid(kyoto_chase_scene):
		kyoto_chase_scene.visible = false
		kyoto_chase_scene.queue_free()
		kyoto_chase_scene = null
	if is_instance_valid(kyoto_boss_scene):
		kyoto_boss_scene.visible = false
		kyoto_boss_scene.queue_free()
		kyoto_boss_scene = null
	if is_instance_valid(map_player):
		map_player.hide()
	_clear_controls()
	heart_roulette_spinning = false
	heart_roulette_resolved = false
	heart_roulette_elapsed = 0.0
	heart_roulette_display_index = -1
	heart_roulette_segments.clear()
	var modal := _modal_shell("旅のハートルーレット", "守護者を越えた。タップで回して、もう一度タップで止めよう。")
	var wheel_holder := CenterContainer.new()
	wheel_holder.name = "HeartRouletteWheelHolder"
	wheel_holder.custom_minimum_size = Vector2(0, 320)
	wheel_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wheel_stage := Control.new()
	wheel_stage.name = "HeartRouletteWheelStage"
	wheel_stage.custom_minimum_size = Vector2(320, 320)
	wheel_stage.size = Vector2(320, 320)
	wheel_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := TextureRect.new()
	image.name = "HeartRouletteWheel"
	image.texture = HEART_WHEEL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.pivot_offset = Vector2(160, 160)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_roulette_wheel_image = image
	wheel_stage.add_child(image)
	var roulette_values: Array[int] = HeartRouletteModel.VALUES.duplicate()
	for segment_index: int in range(roulette_values.size()):
		var segment := _heart_roulette_segment(roulette_values[segment_index], segment_index)
		heart_roulette_segments.append(segment)
		wheel_stage.add_child(segment)
	wheel_holder.add_child(wheel_stage)
	modal.box.add_child(wheel_holder)
	heart_roulette_result_label = _label("結果：—　現在 %s" % _heart_text(journey.hp), 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	heart_roulette_result_label.name = "HeartRouletteResult"
	heart_roulette_result_label.custom_minimum_size.y = 34
	modal.box.add_child(heart_roulette_result_label)
	heart_roulette_action_button = _button("回転スタート", _on_heart_roulette_action, true)
	heart_roulette_action_button.name = "HeartRouletteActionButton"
	heart_roulette_action_button.custom_minimum_size.y = 74
	modal.box.add_child(heart_roulette_action_button)


func _on_heart_roulette_action() -> void:
	if heart_roulette_resolved:
		_close_modal()
		journey.start_next_lap()
		amazon_boss = null
		kyoto_boss = null
		_render_map()
		_refresh_all()
		return
	if not heart_roulette_spinning:
		heart_roulette_spinning = true
		heart_roulette_elapsed = 0.0
		heart_roulette_display_index = 0
		_set_heart_roulette_selection(0)
		if is_instance_valid(heart_roulette_action_button):
			heart_roulette_action_button.text = "ストップ"
		return
	heart_roulette_spinning = false
	heart_roulette_resolved = true
	var selected_index := clampi(heart_roulette_display_index, 0, HeartRouletteModel.VALUES.size() - 1)
	var result := journey.apply_heart_roulette(selected_index)
	_refresh_all()
	if is_instance_valid(heart_roulette_result_label):
		heart_roulette_result_label.text = "結果：%s　%s → %s" % [str(result.get("label", "")), _heart_text(int(result.get("before_hp", journey.hp))), _heart_text(journey.hp)]
	if is_instance_valid(heart_roulette_action_button):
		heart_roulette_action_button.text = "通常マップへ"
	status_label.text = "ハートルーレット %s。通常マップのハートに反映！" % str(result.get("label", ""))


func _heart_roulette_segment(value: int, segment_index: int) -> PanelContainer:
	var segment := PanelContainer.new()
	segment.name = "HeartRouletteSegment%d" % segment_index
	segment.z_index = 2
	var positions: Array[Vector2] = [
		Vector2(72, 44), Vector2(176, 44), Vector2(220, 132),
		Vector2(176, 224), Vector2(72, 224), Vector2(22, 132),
	]
	var widths: Array[float] = [70.0, 70.0, 70.0, 82.0, 70.0, 70.0]
	segment.position = positions[clampi(segment_index, 0, positions.size() - 1)]
	segment.size = Vector2(widths[clampi(segment_index, 0, widths.size() - 1)], 42.0)
	segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	segment.add_theme_stylebox_override("panel", _panel(Color(0.015, 0.10, 0.105, 0.78), Color("#d8aa48"), 10, 2))
	var label := _label(_heart_roulette_value_text(value), 20 if value < 3 else 17, Color("#fff0c5"), HORIZONTAL_ALIGNMENT_CENTER)
	label.name = "HeartRouletteSegmentLabel%d" % segment_index
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#071b1e"))
	label.add_theme_constant_override("outline_size", 5)
	segment.add_child(label)
	return segment


func _set_heart_roulette_selection(selected_index: int) -> void:
	for index: int in range(heart_roulette_segments.size()):
		var segment := heart_roulette_segments[index]
		if not is_instance_valid(segment):
			continue
		var selected := index == selected_index
		segment.add_theme_stylebox_override("panel", _panel(
			Color("#fff1bd") if selected else Color(0.015, 0.10, 0.105, 0.78),
			Color("#ff6b55") if selected else Color("#d8aa48"),
			10,
			4 if selected else 2
		))
		var label := segment.get_node_or_null("HeartRouletteSegmentLabel%d" % index) as Label
		if label != null:
			label.add_theme_color_override("font_color", Color("#6f261d") if selected else Color("#fff0c5"))
		segment.scale = Vector2(1.08, 1.08) if selected else Vector2.ONE


func _heart_roulette_value_text(value: int) -> String:
	if value >= 3:
		return "Full"
	if value == 0:
		return "0"
	return "+%d" % value


func _show_boss_recovery_or_perfect() -> void:
	# A clean HP3 boss win is Cairo's PERFECT state; wounded wins alone get the
	# recovery roulette. Keeping this decision in the host avoids a no-op STOP.
	if stage_id == StageCatalog.STAGE_AMAZON:
		_show_aquafall_victory_modal()
		return
	if journey != null and journey.hp >= StageJourneyBase.MAX_HEARTS:
		_clear_controls()
		var modal := _modal_shell("PERFECT!", "HP FULL\nハート3つで次の周回へ進める。")
		var next := _button("次の周回へ", func() -> void:
			_close_modal()
			journey.start_next_lap()
			amazon_boss = null
			kyoto_boss = null
			_render_map()
			_refresh_all()
		, true)
		next.custom_minimum_size.y = 74
		modal.box.add_child(next)
		return
	_show_heart_roulette()


func _show_aquafall_victory_modal() -> void:
	_clear_controls()
	_close_modal()
	active_modal = ColorRect.new()
	active_modal.name = "AquafallVictoryModal"
	active_modal.color = Color(0.02, 0.03, 0.03, 0.86)
	active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(active_modal)

	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = get_viewport_rect().size
	var panel_width := minf(632.0, maxf(viewport_size.x - 24.0, 260.0))
	var panel_height := minf(720.0, maxf(viewport_size.y - 28.0, 440.0))
	var compact := panel_width < 500.0 or panel_height < 580.0
	var panel := PanelContainer.new()
	panel.name = "AquafallVictoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_width * 0.5
	panel.offset_top = -panel_height * 0.5
	panel.offset_right = panel_width * 0.5
	panel.offset_bottom = panel_height * 0.5
	panel.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 24, 4))
	active_modal.add_child(panel)

	var box := VBoxContainer.new()
	box.name = "AquafallVictoryContent"
	box.add_theme_constant_override("separation", 8 if compact else 12)
	var perfect := journey != null and journey.hp >= StageJourneyBase.MAX_HEARTS
	var title := _label("PERFECT!" if perfect else "瀑竜アクアフォール制覇", 25 if compact else 30, INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "AquafallVictoryTitle"
	title.custom_minimum_size.y = 40 if compact else 48
	box.add_child(title)
	var kicker := _label("滝筋の頂へ到達" if not perfect else "ハート3つのまま瀑竜を越えた", 14 if compact else 16, _stage_accent(), HORIZONTAL_ALIGNMENT_CENTER)
	kicker.name = "AquafallVictoryKicker"
	kicker.custom_minimum_size.y = 24
	box.add_child(kicker)
	var art := TextureRect.new()
	art.name = "AquafallVictoryIllustration"
	art.texture = AQUAFALL_VICTORY
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0.0, 210.0 if compact else 300.0)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	var body := _label(
		"水流の守護者は静かに霧へ戻った。\n次の旅へ進もう。" if perfect else "丸太をかわし、滝の頂を越えた。\nハートルーレットで次の旅へ。",
		16 if compact else 20,
		Color("#554434"),
		HORIZONTAL_ALIGNMENT_CENTER
	)
	body.name = "AquafallVictoryBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 52 if compact else 62
	box.add_child(body)
	var next := _button("次の周回へ" if perfect else "ハートルーレットへ", func() -> void:
		_close_modal()
		if perfect:
			journey.start_next_lap()
			amazon_boss = null
			kyoto_boss = null
			_render_map()
			_refresh_all()
		else:
			_show_heart_roulette()
	, true)
	next.name = "AquafallVictoryContinueButton"
	next.custom_minimum_size.y = 56 if compact else 68
	box.add_child(next)
	panel.add_child(box)


func _resolve_boss_defeat(message: String) -> void:
	if stage_id == StageCatalog.STAGE_KYOTO:
		journey.hp = maxi(journey.hp - 2, 0)
	var life_result := journey.resolve_life_if_needed()
	if bool(life_result.get("run_over", false)):
		journey.phase = StageJourneyBase.PHASE_RUN_OVER
		_show_run_over()
		return
	journey.phase = StageJourneyBase.PHASE_BOSS
	if bool(life_result.get("revived", false)):
		status_label.text = "%s 復活を1回使って、ハート3つで再挑戦。" % message
	else:
		status_label.text = "%s ハートを整えて、もう一度挑戦。" % message
	if stage_id == StageCatalog.STAGE_AMAZON:
		_start_aquafall_boss()
	else:
		var boss_route := str(journey.stage_flags.get("kyoto_boss_route", ""))
		if boss_route == "foxfire":
			_start_fox_fire_six_routes_boss()
		else:
			_start_fox_fire_chase_boss()


func _show_run_over() -> void:
	_open_choice_modal("旅はここまで", "累計 %d 点。荷造りを整えて、また旅に出よう。" % (journey.cumulative_score + journey.score), [{"id": "retry", "label": "同じ旅先でもう一度"}, {"id": "back", "label": "旅先選択へ"}], func(choice_id: String) -> void:
		if choice_id == "retry":
			_start_journey()
		else:
			_request_back()
	)


func _open_choice_modal(title_text: String, body_text: String, choices: Array, callback: Callable, card_art: Texture2D = null) -> void:
	var modal := _modal_shell(title_text, body_text, card_art)
	var compact_choices := choices.size() > 3
	if compact_choices:
		# Item and READY skill cards can expose several touch targets. Keep the
		# generated art visible, but reclaim vertical space so every action stays
		# inside the parchment modal on a 720x1280 phone layout.
		for child: Node in modal.box.get_children():
			if child is TextureRect:
				(child as TextureRect).custom_minimum_size.y = 150.0
	for value: Variant in choices:
		if not value is Dictionary:
			continue
		var choice := value as Dictionary
		var choice_id := str(choice.get("id", choice.get("target", "")))
		var button := _button(str(choice.get("label", choice_id)), func() -> void:
			_close_modal()
			callback.call(choice_id)
		, true)
		var choice_icon := choice.get("icon") as Texture2D
		if choice_icon != null:
			button.icon = choice_icon
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 34)
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var requirements := choice.get("requires", {}) as Dictionary
		if not requirements.is_empty():
			button.disabled = journey == null or journey.coins < int(requirements.get("coin_gte", 0))
		var route_cost := int(choice.get("cost", 0))
		if route_cost > 0 and (journey == null or journey.coins < route_cost):
			button.disabled = true
		button.custom_minimum_size.y = 52 if compact_choices else 66
		modal.box.add_child(button)


func _modal_shell(title_text: String, body_text: String, card_art: Texture2D = null) -> Dictionary:
	_close_modal()
	active_modal = ColorRect.new()
	active_modal.color = Color(0.02, 0.03, 0.03, 0.82)
	active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_modal.name = "JourneyModal"
	# Route/player sprites can carry their own z-index during a boss finish.
	# Keep the recovery wheel and its labels above those decorative layers.
	active_modal.z_index = 200
	add_child(active_modal)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -316
	panel.offset_top = -300
	panel.offset_right = 316
	panel.offset_bottom = 300
	panel.add_theme_stylebox_override("panel", _panel(PAPER, GOLD, 24, 4))
	active_modal.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_label(title_text, 30, INK, HORIZONTAL_ALIGNMENT_CENTER))
	if card_art != null:
		var art := TextureRect.new()
		art.texture = card_art
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(0, 286)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
	var body := _label(body_text, 20, Color("#554434"), HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 62
	box.add_child(body)
	panel.add_child(box)
	return {"layer": active_modal, "box": box}


func _close_modal() -> void:
	heart_roulette_spinning = false
	heart_roulette_resolved = false
	heart_roulette_display_index = -1
	heart_roulette_wheel_image = null
	heart_roulette_segments.clear()
	heart_roulette_action_button = null
	heart_roulette_result_label = null
	if is_instance_valid(active_modal):
		active_modal.queue_free()
	active_modal = null


func _refresh_all() -> void:
	if journey == null:
		return
	coins_label.text = str(journey.coins)
	life_label.text = "復活 ×%d" % journey.life
	hp_label.text = _heart_text(journey.hp)
	lap_label.text = str(journey.lap)
	var traveled := int(journey.cumulative_score) + int(journey.score)
	score_label.text = str(traveled)
	best_label.text = str(maxi(traveled, int(best_label.text)))
	if stage_id == StageCatalog.STAGE_KYOTO:
		var mission := journey.sync_journey_mission()
		if is_instance_valid(mission_caption_label):
			mission_caption_label.text = str(mission.get("short_text", "旅の目標"))
		if is_instance_valid(mission_progress_label):
			var mission_target := maxi(int(mission.get("target", 1)), 1)
			var mission_progress := clampi(int(mission.get("progress", 0)), 0, mission_target)
			var mission_reward := maxi(int(mission.get("reward_coins", StageJourneyBase.MISSION_STANDARD_REWARD)), 0)
			mission_progress_label.text = "✓ CLEAR!　獲得 COIN +%d" % mission_reward if bool(mission.get("completed", false)) else "進捗 %d/%d　報酬 COIN ×%d" % [mission_progress, mission_target, mission_reward]
		if is_instance_valid(mission_icon_view):
			mission_icon_view.texture = _journey_mission_icon(str(mission.get("icon_kind", "dice")))
		progress_label.text = _space_number_text()
		var boss_route := str(journey.stage_flags.get("kyoto_boss_route", ""))
		var goshuin_copy := "御朱印 %d/4" % (journey as KyotoJourney).goshuin_count()
		stage_route_label.text = ("追陣" if boss_route == "direct" else ("六路陣" if boss_route == "foxfire" else "本線")) + "　" + goshuin_copy
	else:
		progress_label.text = _space_number_text()
		stage_route_label.text = "本線　滝の支流"
		_set_mission_value("発見", "%d/5" % mini(int(journey.stage_flags.get("mission_event_count", 0)), 5))
	if is_instance_valid(roll_button):
		# A rolling die must remain tappable so the player can lock the face. The
		# control is disabled only after the stop tap, while hops/effect/camera are
		# being presented.
		if amazon_boss != null:
			roll_button.disabled = amazon_boss_move_active or (not amazon_boss_roll_active and amazon_boss.phase != AquafallBattle.PHASE_WAIT_ROLL)
		else:
			roll_button.disabled = not journey.can_roll() or map_movement_active
	if is_instance_valid(item_card_button):
		item_card_button.text = "アイテム\n%d/%d" % [journey.item_count(), StageJourneyBase.ITEM_CAPACITY]
		item_card_button.disabled = map_movement_active
	if is_instance_valid(coin_tool_button):
		coin_tool_button.text = "コイン\n%d" % journey.coins
		coin_tool_button.disabled = map_movement_active
	if is_instance_valid(skill_tool_button):
		var skill_value := "READY" if journey.skill_ready() else "%d/%d" % [journey.skill_gauge(), StageJourneyBase.SKILL_GAUGE_MAX]
		skill_tool_button.text = "スキル\n%s" % skill_value
		# Like Cairo, the picker is a pre-roll utility: it stays available while
		# the player is READY, but cannot interrupt a die carousel, hop, branch,
		# event, or boss resolution.
		skill_tool_button.disabled = map_movement_active or map_roll_active or roll_animation_active or not journey.can_roll()
	if is_instance_valid(event_card_button):
		event_card_button.disabled = false
	_refresh_roll_slots()
	_position_map_player()


func _set_mission_value(title_text: String, value_text: String) -> void:
	var value := mission_value_labels.get(title_text, null) as Label
	if is_instance_valid(value):
		value.text = value_text


func _refresh_roll_slots() -> void:
	for index: int in range(roll_slot_labels.size()):
		var label := roll_slot_labels[index]
		if not is_instance_valid(label):
			continue
		if (map_roll_active or amazon_boss_roll_active) and index == roll_slots.size() and index < 3:
			label.text = str(map_roll_face if map_roll_active else amazon_boss_roll_face)
			label.modulate = Color(1.0, 1.0, 1.0, 0.72)
		else:
			label.text = str(roll_slots[index]) if index < roll_slots.size() else "—"
			label.modulate = Color.WHITE


func _play_stage_map_bgm() -> void:
	var bgm := get_node_or_null("/root/BgmManager")
	if bgm == null:
		return
	if stage_id == StageCatalog.STAGE_AMAZON:
		bgm.call("play_amazon_normal")
	else:
		bgm.call("play_kyoto_normal")


func _space_number_text() -> String:
	var total := 90 if stage_id == StageCatalog.STAGE_KYOTO else 120
	var number := _progress_index_for_space(journey.current_space_id)
	return "%d/%d" % [number, total] if number > 0 else "—/%d" % total


func _progress_index_for_space(space_id_value: String) -> int:
	if space_id_value.begins_with("main:"):
		return maxi(int(space_id_value.get_slice(":", 1)), 0)
	if stage_id == StageCatalog.STAGE_AMAZON:
		var amazon_space := (journey as AmazonJourney).course.space(space_id_value)
		var amazon_number := int(amazon_space.get("number", 0))
		if amazon_number > 0:
			return amazon_number
		return _numeric_suffix(space_id_value)
	var kyoto := journey as KyotoJourney
	if kyoto == null:
		return _numeric_suffix(space_id_value)
	var route_space := kyoto.course.space(space_id_value)
	var route_order := int(route_space.get("route_order", -1))
	if route_order < 0:
		return _numeric_suffix(space_id_value)
	var route_name := str(route_space.get("route", ""))
	var first_route_space := ""
	for value: Variant in kyoto.course.spaces.values():
		if value is Dictionary:
			var candidate := value as Dictionary
			if str(candidate.get("route", "")) == route_name and int(candidate.get("route_order", -1)) == 0:
				first_route_space = str(candidate.get("id", ""))
				break
	var entry_number := route_order
	if not first_route_space.is_empty():
		for value: Variant in kyoto.course.spaces.values():
			if not value is Dictionary:
				continue
			var main_space := value as Dictionary
			var main_id := str(main_space.get("id", ""))
			if not main_id.begins_with("main:"):
				continue
			var branch_id := str(main_space.get("branch_id", ""))
			if branch_id.is_empty():
				continue
			var branch_data := kyoto.course.branch(branch_id)
			for choice: Variant in branch_data.get("choices", []):
				if choice is Dictionary and str((choice as Dictionary).get("target", "")) == first_route_space:
					entry_number = int(main_id.get_slice(":", 1)) + route_order + 1
					return entry_number
	return entry_number + 1


func _numeric_suffix(space_id_value: String) -> int:
	var pieces := space_id_value.split(":")
	if pieces.is_empty():
		return 0
	var suffix: String = pieces[pieces.size() - 1]
	var digits := ""
	for character: String in suffix:
		if character >= "0" and character <= "9":
			digits += character
		elif not digits.is_empty():
			break
	return int(digits) if not digits.is_empty() else 0


func _journey_result_text(result: Dictionary) -> String:
	if not bool(result.get("ok", false)):
		return "進めない：%s" % str(result.get("error", "UNKNOWN"))
	match str(result.get("status", "")):
		"CHOICE_REQUIRED": return "辻に到着。残り歩数を保ったまま進路を選ぶ。"
		"EVENT_REQUIRED": return "旅の出会いが待っている。"
		"AUTO_EVENT_RESOLVED": return str(result.get("text", "旅の出来事がすぐに解決した。"))
		"BOSS_CHOICE_REQUIRED": return "最後の試練を選ぼう。"
		"BOSS_CHOICE_RESOLVED": return "選んだ試練の鳥居へ進む。"
		"SECRET_REQUIRED": return "滝裏にひそかな入口を見つけた。"
		"BOSS_READY": return "守護者の試練へ。"
		"EVENT_RESOLVED": return "選択が旅の続きを変えた。"
		"BRANCH_RESOLVED": return "選んだ道を進んだ。"
	return "次の景色へ進んだ。"


func _survival_result_text(hp_before: int, life_before: int, result: Dictionary, fallback: String) -> String:
	if journey == null or not bool(result.get("ok", false)):
		return fallback
	var goshuin_passed: Array = result.get("goshuin_passed", []) as Array
	if stage_id == StageCatalog.STAGE_KYOTO and not goshuin_passed.is_empty():
		var stamp: Dictionary = goshuin_passed[-1] as Dictionary
		return "%s 御朱印をいただいた！" % str(stamp.get("title", "寺社"))
	if int(result.get("coin_bonus", 0)) > 0:
		return "REST！ HP満タンボーナス。COIN +1"
	if int(result.get("skill_bonus", 0)) > 0:
		return "REST！ HP満タンボーナス。SKILL +1"
	if bool(result.get("item_acquired", false)):
		return "ITEM！ %sを手に入れた。" % str(result.get("item_name", "アイテム"))
	if bool(result.get("full", false)):
		return "ITEM満杯。コイン +2。"
	if bool(result.get("item_guarded", false)):
		return "護符がRISKを無効化した。"
	if journey.life < life_before:
		return "復活！ 探検猫を1匹使って、ハートが3つに戻った。"
	if journey.hp < hp_before:
		return "RISK！ ハートが1つ空になった。　%s" % _heart_text(journey.hp)
	return fallback


func _fox_result_text(result: Dictionary) -> String:
	var attack: Dictionary = result.get("fox_attack", {}) as Dictionary
	match str(attack.get("status", "")):
		"WATCHING": return "白狐はまだ様子を見ている。次の狐火は %s。" % kyoto_boss.current_attack_id()
		"MANGAN_GUARD": return "満願の護りが %s への狐火を退けた。" % str(attack.get("target", ""))
		"FOX_FIRE": return "狐火が %s を焦がした。次は %s。" % [str(attack.get("target", "")), kyoto_boss.current_attack_id()]
	return "封印を一手進めた。"


func _save_now() -> void:
	var boss_snapshot: Dictionary = {}
	if amazon_boss != null:
		boss_snapshot = amazon_boss.snapshot()
	elif is_instance_valid(kyoto_chase_scene):
		var chase_snapshot: Variant = kyoto_chase_scene.call("snapshot")
		if chase_snapshot is Dictionary:
			boss_snapshot = (chase_snapshot as Dictionary).duplicate(true)
	elif is_instance_valid(kyoto_boss_scene):
		boss_snapshot = kyoto_boss_scene.snapshot()
	elif kyoto_boss != null:
		boss_snapshot = kyoto_boss.snapshot()
	status_label.text = "旅の途中を保存した。" if save_manager.save(stage_id, journey.snapshot(), boss_snapshot) else "保存に失敗した。"


func _restore_saved_state() -> void:
	var payload := save_manager.load_for_stage(stage_id)
	if payload.is_empty() or journey == null:
		return
	if journey.restore(payload.get("journey", {}) as Dictionary):
		status_label.text = "保存した旅を再開した。"
		var boss_snapshot := payload.get("boss", {}) as Dictionary
		if journey.phase == StageJourneyBase.PHASE_BOSS and not boss_snapshot.is_empty():
			if stage_id == StageCatalog.STAGE_AMAZON:
				amazon_boss = AquafallBattle.new()
				amazon_boss.configure(journey.lap, journey.hp, journey.max_hp)
				amazon_boss.restore(boss_snapshot)
				roll_slots = amazon_boss.roll_faces.duplicate()
				var bgm := get_node_or_null("/root/BgmManager")
				if bgm != null:
					bgm.call("play_amazon_boss")
				if is_instance_valid(top_hud):
					top_hud.modulate = Color(1.0, 1.0, 1.0, 0.46)
				if is_instance_valid(stage_band):
					stage_band.modulate = Color(1.0, 1.0, 1.0, 0.68)
				if is_instance_valid(mission_band):
					mission_band.modulate = Color(1.0, 1.0, 1.0, 0.52)
				_render_aquafall_boss()
			else:
				var kyoto := journey as KyotoJourney
				if kyoto != null:
					var route := str(kyoto.stage_flags.get("kyoto_boss_route", ""))
					match _kyoto_boss_restore_target(route, boss_snapshot):
						"chase": _start_fox_fire_chase_boss(false, boss_snapshot)
						"legacy_direct": _start_direct_white_fox_boss(boss_snapshot)
						_: _start_fox_fire_six_routes_boss(false, boss_snapshot)
		else:
			_render_map()
			_refresh_all()


func _kyoto_boss_restore_target(route: String, boss_snapshot: Dictionary) -> String:
	if str(boss_snapshot.get("battle_id", "")) == "fox_fire_chase":
		return "chase"
	if route == "direct":
		return "legacy_direct" if boss_snapshot.has("seals") else "chase"
	return "six_routes"


func _advance_idle_frame() -> void:
	idle_frame = (idle_frame + 1) % 4
	if is_instance_valid(map_player):
		map_player.texture = _cat_frame(idle_frame)
	if is_instance_valid(life_icon):
		life_icon.texture = _cat_frame(idle_frame)


func _cat_frame(frame: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = EXPLORER_IDLE_STRIP
	var frame_width := float(EXPLORER_IDLE_STRIP.get_width()) / 4.0
	atlas.region = Rect2(frame_width * clampi(frame, 0, 3), 0, frame_width, EXPLORER_IDLE_STRIP.get_height())
	return atlas


func _boss_background(texture: Texture2D) -> TextureRect:
	var background := TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return background


func _seal_color(state: String) -> Color:
	match state:
		"NORMAL": return Color(0.90, 0.82, 0.54, 0.96)
		"CRACKED": return Color(0.80, 0.47, 0.30, 0.96)
	return Color(0.16, 0.10, 0.08, 0.88)


func _clear_content() -> void:
	for child: Node in content_host.get_children():
		child.queue_free()
	map_node_layer = null
	map_player = null
	aquafall_lane_layer = null
	aquafall_player_sprite = null
	route_preview_row = null


func _clear_controls() -> void:
	for child: Node in controls_box.get_children():
		child.queue_free()
	roll_button = null
	travel_tray_root = null
	primary_roll_controls = null


func _request_back() -> void:
	back_requested.emit()


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _stat_chip(text_value: String) -> Label:
	var label := _label(text_value, 17, Color("#f5dfae"), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size.y = 38
	label.add_theme_stylebox_override("normal", _panel(Color(0.18, 0.15, 0.11, 0.94), Color("#796b50"), 10, 1))
	return label


func _hud_stat(caption: String, value: String) -> Label:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2 if stage_id == StageCatalog.STAGE_KYOTO else 0)
	var title := _label(caption, 16 if stage_id == StageCatalog.STAGE_KYOTO else 13, Color("#d9c6a0") if stage_id == StageCatalog.STAGE_KYOTO else Color("#e4d5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	var number := _label(value, 40 if stage_id == StageCatalog.STAGE_KYOTO else 25, Color("#f9df8d"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	box.add_child(number)
	return number


func _info_chip(text_value: String) -> Label:
	var label := _label(text_value, 17, Color("#fff0c1"), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size.y = 42
	label.add_theme_stylebox_override("normal", _panel(Color(0.14, 0.13, 0.11, 0.92), Color("#796b50"), 8, 1))
	return label


func _info_value_chip(caption_text: String, value_text: String) -> Dictionary:
	var chip := PanelContainer.new()
	chip.custom_minimum_size.y = 54
	chip.add_theme_stylebox_override("panel", _panel(Color(0.14, 0.13, 0.11, 0.92), Color("#796b50"), 8, 1))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -2)
	var caption := _label(caption_text, 13, Color("#e4d5b8"), HORIZONTAL_ALIGNMENT_CENTER)
	caption.custom_minimum_size.y = 20
	var value := _label(value_text, 24, Color("#fff0c1"), HORIZONTAL_ALIGNMENT_CENTER)
	value.custom_minimum_size.y = 31
	stack.add_child(caption)
	stack.add_child(value)
	chip.add_child(stack)
	return {"chip": chip, "value": value}


func _cairo_coin_hud() -> Dictionary:
	var chip := PanelContainer.new()
	chip.name = "CoinStack"
	chip.custom_minimum_size = Vector2(104, 96)
	chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	var icon_view := TextureRect.new()
	icon_view.texture = ICON_COIN
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.custom_minimum_size = Vector2(36, 36)
	icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_view)
	var value := _label("0", 26, Color("#f0d69f"), HORIZONTAL_ALIGNMENT_CENTER)
	value.custom_minimum_size = Vector2(54, 44)
	row.add_child(value)
	chip.add_child(row)
	return {"chip": chip, "value": value}


func _cairo_progress_hud() -> Dictionary:
	var chip := PanelContainer.new()
	chip.name = "ProgressStack"
	chip.custom_minimum_size = Vector2(148, 96)
	chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var value := _label("1/90", 46, Color("#fff0c1"), HORIZONTAL_ALIGNMENT_CENTER)
	value.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.09, 0.92))
	value.add_theme_constant_override("outline_size", 4)
	chip.add_child(value)
	return {"chip": chip, "value": value}


func _survival_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "SurvivalStack"
	chip.custom_minimum_size = Vector2(124, 96) if stage_id == StageCatalog.STAGE_KYOTO else Vector2(0, 54)
	if stage_id == StageCatalog.STAGE_KYOTO:
		chip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		chip.add_theme_stylebox_override("panel", _panel(Color(0.14, 0.13, 0.11, 0.92), Color("#796b50"), 8, 1))
	var stack := VBoxContainer.new()
	stack.name = "SurvivalStackContent"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.name = "LifeBox"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	life_icon = TextureRect.new()
	life_icon.name = "LifeIcon"
	life_icon.texture = _cat_frame(0)
	life_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	life_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	life_icon.custom_minimum_size = Vector2(32, 32)
	life_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(life_icon)
	life_label = _label("復活 ×3", 18, Color("#80dbd1"), HORIZONTAL_ALIGNMENT_CENTER)
	life_label.name = "LifeLabel"
	life_label.custom_minimum_size = Vector2(76, 28)
	row.add_child(life_label)
	stack.add_child(row)
	hp_label = _label("♥♥♥", 23, Color("#f5ab80"), HORIZONTAL_ALIGNMENT_CENTER)
	hp_label.name = "HPLabel"
	hp_label.custom_minimum_size = Vector2(112, 26)
	stack.add_child(hp_label)
	chip.add_child(stack)
	return chip


func _heart_text(current: int) -> String:
	var result := ""
	for index: int in range(StageJourneyBase.MAX_HEARTS):
		result += "♥" if index < clampi(current, 0, StageJourneyBase.MAX_HEARTS) else "♡"
	return result


func _stage_accent() -> Color:
	return KYOTO_RED if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_TEAL


func _stage_ink(alpha: float = 1.0) -> Color:
	var base := KYOTO_INK if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_INK
	return Color(base.r, base.g, base.b, alpha)


func _button(text_value: String, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color.WHITE if primary else Color("#f4e4bb"))
	button.add_theme_color_override("font_disabled_color", Color("#8d8579"))
	var accent := KYOTO_RED if stage_id == StageCatalog.STAGE_KYOTO else AMAZON_TEAL
	button.add_theme_stylebox_override("normal", _panel(accent if primary else Color(0.16, 0.15, 0.13, 0.96), GOLD if primary else Color("#75654c"), 14, 2))
	button.add_theme_stylebox_override("hover", _panel(accent.lightened(0.12) if primary else Color(0.23, 0.21, 0.18, 0.98), Color("#ffe08a"), 14, 3))
	button.add_theme_stylebox_override("pressed", _panel(accent.darkened(0.12), Color("#ffe08a"), 14, 3))
	button.add_theme_stylebox_override("disabled", _panel(Color(0.18, 0.18, 0.17, 0.82), Color("#54514b"), 14, 1))
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _aquafall_log_style(is_large: bool) -> StyleBoxFlat:
	var style := _panel(
		Color(1.0, 0.975, 0.88, 0.96) if not is_large else Color(0.10, 0.045, 0.025, 0.90),
		Color("#2b8f80") if not is_large else Color("#ff7652"),
		10 if not is_large else 12,
		2 if not is_large else 3
	)
	# Small logs sit on ivory, while impassable large logs keep a dark warning
	# plate. The silhouette and the plate colour now communicate different rules.
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0.0, 0.015, 0.01, 0.66 if not is_large else 0.78)
	style.shadow_size = 5 if not is_large else 7
	style.shadow_offset = Vector2(0.0, 3.0)
	return style
