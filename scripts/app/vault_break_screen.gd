class_name VaultBreakScreen
extends Control

signal back_requested

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const VisualFeedback = preload("res://scripts/ui/casino_visual_feedback.gd")
const CasinoBackButton = preload("res://scripts/ui/casino_back_button.gd")
const CasinoHowTo3StepsScript = preload("res://scripts/ui/casino_how_to_3_steps.gd")
const RepositoryScript = preload("res://scripts/game/vault_break/vault_break_template_repository.gd")
const SelectorScript = preload("res://scripts/game/vault_break/vault_break_selector.gd")
const ProgressScript = preload("res://scripts/game/vault_break/vault_break_progress.gd")
const ModelScript = preload("res://scripts/game/vault_break/vault_break_model.gd")
const LockViewScript = preload("res://scripts/app/vault_break_lock_view.gd")
const DicePresentationScript = preload("res://scripts/game/dice_presentation_3d.gd")
const FONT: Font = preload("res://assets/fonts/noto_sans_jp/NotoSansJP-Regular.ttf")
const VAULT_DOOR_TEXTURE: Texture2D = preload("res://assets/casino/vault_break/ui/vault-door-brass-v1.png")
const BET_CHIP_TEXTURES: Dictionary = {
	10: preload("res://assets/casino/vault_break/ui/chip-10-black-v1.png"),
	20: preload("res://assets/casino/vault_break/ui/chip-20-red-v1.png"),
	50: preload("res://assets/casino/vault_break/ui/chip-50-gold-v1.png"),
}

const FACILITY_ID := "vault_break"
const META_KEY := "vault_break"
const META_SCHEMA_VERSION := 1
const BET_AMOUNTS: Array[int] = [10, 20, 50]
const TIERS: Array[String] = ["bronze", "silver", "gold", "black"]
const NORMAL_TIERS: Array[String] = ["bronze", "silver", "gold"]
const TIER_NAMES := {
	"bronze": "BRONZE",
	"silver": "SILVER",
	"gold": "GOLD",
	"black": "BLACK",
}
const TIER_NAMES_JA := {
	"bronze": "ブロンズ金庫",
	"silver": "シルバー金庫",
	"gold": "ゴールド金庫",
	"black": "ブラック金庫",
}

const ROLL_SECONDS := 0.30
const SETTLE_SECONDS := 0.12
const ACTION_SECONDS := 0.14
const RESULT_HOLD_SECONDS := 0.22

const NAVY := Color("#171932")
const NAVY_2 := Color("#25234a")
const PLUM := Color("#36213e")
const OXBLOOD := Color("#7e2929")
const OXBLOOD_LIGHT := Color("#a7463e")
const BRASS := Color("#c9963d")
const BRASS_LIGHT := Color("#f2d27b")
const PARCHMENT := Color("#f4dfb0")
const PARCHMENT_LIGHT := Color("#fff0cf")
const INK := Color("#302116")
const GREEN := Color("#3f7d58")
const FAILURE_RED := Color("#b34a44")
const VELVET_RED := Color("#761f1c")
const VELVET_RED_LIGHT := Color("#a63b2d")
const BRONZE_SURFACE := Color("#5c3422")
const SILVER_SURFACE := Color("#343843")
const GOLD_SURFACE := Color("#5b421d")
const BLACK_SURFACE := Color("#20172b")

enum State {
	SETUP,
	READY,
	ROLLING,
	WAITING_FOR_PLACEMENT,
	RESOLVING_PLACEMENT,
	SUCCESS,
	FAILURE,
	RESULT,
	EXITING,
}

const STATE_NAMES: Array[String] = [
	"setup",
	"ready",
	"rolling",
	"waiting_for_placement",
	"resolving_placement",
	"success",
	"failure",
	"result",
	"exiting",
]

## Runtime leaves this false. Isolated tests set it before instancing so they
## do not start BGM or emit SFX while exercising persistence.
static var suppress_audio_for_tests := false

var repository: RefCounted
var selector: RefCounted
var progress: RefCounted
var model: RefCounted

var state: int = State.SETUP
var view_state := "setup"
var selected_bet := 20
var selected_tier := "bronze"
var active_tier := ""
var active_template: Dictionary = {}
var game_id := ""
var pending_rolls: Array = []
var pending_roll: Dictionary = {}
var result_data: Dictionary = {}
var settlement_receipt: Dictionary = {}
var settled := false
var rolling := false
var resume_error := false
var displayed_face := 0
var settlement_attempt_count := 0
var spawned_black_template_id := ""

## Deterministic test/debug hooks. A queued value is consumed once.
var rng_seed := 0
var queued_roll_value := 0
var queued_template_random_value: Variant = null
var queued_spawn_random_value: Variant = null
var queued_black_template_random_value: Variant = null
var template_random_provider := Callable()
var spawn_random_provider := Callable()
var black_template_random_provider := Callable()
var forced_template_id := ""
var animation_duration_scale := 1.0

var _rng := RandomNumberGenerator.new()
var _terminal_handling := false
var _repository_loaded := false

var chip_label: Label
var status_label: Label
var setup_view: VBoxContainer
var active_view: VBoxContainer
var result_view: VBoxContainer
var bet_buttons: Dictionary = {}
var bet_state_labels: Dictionary = {}
var bet_value_labels: Dictionary = {}
var bet_unit_labels: Dictionary = {}
var tier_buttons: Dictionary = {}
var start_button: Button
var setup_reward_label: Label
var back_button: Button
var roll_button: Button
var discard_button: Button
var again_button: Button
var tier_label: Label
var multiplier_label: Label
var roll_counter: Label
var reward_label: Label
var template_label: Label
var instruction_label: Label
var die_face_label: Label
var result_label: Label
var result_payout_label: Label
var result_detail_label: Label
var result_vault_door_panel: PanelContainer
var result_vault_door: TextureRect
var lock_container: HBoxContainer
var lock_views: Array[VaultBreakLockView] = []
var dice_presentation: DicePresentation3D
var vault_panel: PanelContainer
var effect_layer: Control
var setup_vault_door: TextureRect
var active_vault_door: TextureRect
var vault_handle_tween: Tween
var chip_balance_tween: Tween
var last_chip_balance: int = -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	_rng.randomize()
	if not suppress_audio_for_tests:
		var bgm := get_node_or_null("/root/BgmManager")
		if bgm != null:
			bgm.call("play_vault_break")
		var ui_sfx := get_node_or_null("/root/UiSfxManager")
		if ui_sfx != null:
			ui_sfx.call("set_stage", &"las_vegas")

	repository = RepositoryScript.new()
	_repository_loaded = bool(repository.call("load_default"))
	selector = SelectorScript.new(repository)
	var meta := _load_meta()
	var raw_progress: Variant = meta.get("progress", {})
	# Tolerate the early pure-model shape where the progress dictionary itself
	# occupied the namespace, while always writing the canonical nested shape.
	if (not raw_progress is Dictionary or (raw_progress as Dictionary).is_empty()) and meta.has("tiers"):
		raw_progress = meta
	progress = ProgressScript.new(raw_progress)
	_restore_preferences(meta)
	_new_model()
	_build_ui()
	_resume_or_show_setup()

func _new_model() -> void:
	model = ModelScript.new()
	if repository != null:
		model.call("set_lock_rules", repository.get("lock_rules") as Dictionary)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "VaultBreakBackdrop"
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var upper_glow := ColorRect.new()
	upper_glow.name = "OxbloodGlow"
	upper_glow.color = Color("#3f1f31")
	upper_glow.anchor_right = 1.0
	upper_glow.anchor_bottom = 0.36
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_glow)

	var margin := MarginContainer.new()
	margin.name = "SafeMargins"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.name = "VaultBreakRoot"
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_theme_constant_override("separation", 7)
	margin.add_child(root_box)
	_build_header(root_box)

	status_label = _label("ベットと金庫ランクを選ぼう", 19, Color.WHITE)
	status_label.name = "StatusLabel"
	status_label.custom_minimum_size.y = 42
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(status_label)

	setup_view = VBoxContainer.new()
	setup_view.name = "VaultBreakSetupView"
	setup_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	setup_view.add_theme_constant_override("separation", 7)
	root_box.add_child(setup_view)
	_build_setup(setup_view)

	active_view = VBoxContainer.new()
	active_view.name = "VaultBreakActiveView"
	active_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_view.add_theme_constant_override("separation", 6)
	root_box.add_child(active_view)
	_build_active(active_view)

	result_view = VBoxContainer.new()
	result_view.name = "VaultBreakResultView"
	result_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_view.add_theme_constant_override("separation", 8)
	root_box.add_child(result_view)
	_build_result(result_view)

	back_button = _button("カジノへ戻る", false)
	back_button.name = "CasinoBackButton"
	back_button.custom_minimum_size.y = 96
	back_button.pressed.connect(_on_back_pressed)
	CasinoBackButton.configure(back_button)
	root_box.add_child(back_button)

	effect_layer = Control.new()
	effect_layer.name = "VaultBreakEffectLayer"
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.z_index = 40
	add_child(effect_layer)

func _build_header(root_box: VBoxContainer) -> void:
	var header := PanelContainer.new()
	header.name = "VaultBreakHeader"
	header.custom_minimum_size.y = 72
	header.add_theme_stylebox_override("panel", _panel(OXBLOOD, BRASS, 20, 3))
	root_box.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	var title := _label("VAULT BREAK", 32, BRASS_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#3f1519"))
	title.add_theme_constant_override("outline_size", 5)
	row.add_child(title)
	var chip_panel := PanelContainer.new()
	chip_panel.name = "ChipBalancePanel"
	chip_panel.custom_minimum_size.x = 142
	chip_panel.add_theme_stylebox_override("panel", _panel(Color("#211c20"), BRASS, 14, 2))
	chip_label = _label("CASINO CHIP\n0", 17, PARCHMENT_LIGHT)
	chip_label.name = "ChipBalanceLabel"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_panel.add_child(chip_label)
	row.add_child(chip_panel)

func _build_setup(root_box: VBoxContainer) -> void:
	var rules_panel := PanelContainer.new()
	rules_panel.name = "VaultBreakHero"
	rules_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rules_panel.custom_minimum_size.y = 300
	rules_panel.add_theme_stylebox_override("panel", _metal_panel(Color("#160f15f2"), BRASS, 20, 3))
	root_box.add_child(rules_panel)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 8)
	rules_panel.add_child(hero_row)
	var rules_box := VBoxContainer.new()
	rules_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_box.size_flags_stretch_ratio = 0.92
	rules_box.alignment = BoxContainer.ALIGNMENT_CENTER
	rules_box.add_theme_constant_override("separation", 8)
	hero_row.add_child(rules_box)
	var rules_title := _label("出た目を置いて\n金庫を開けよう", 27, BRASS_LIGHT)
	rules_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rules_box.add_child(rules_title)
	var rules_copy := _label("1  サイコロを振る\n2  光るロックを選ぶ\n3  すべて埋めると開錠", 15, PARCHMENT)
	rules_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rules_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_box.add_child(rules_copy)
	var strategy_copy := _label("同じ出目でも、置く場所で\n結果が変わる！", 14, BRASS_LIGHT)
	strategy_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	strategy_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_box.add_child(strategy_copy)
	var discard_copy := _label("不要な目は捨てられます", 12, Color("#d7c5df"))
	discard_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	discard_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_box.add_child(discard_copy)
	var vault_center := CenterContainer.new()
	vault_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vault_center.size_flags_stretch_ratio = 1.25
	hero_row.add_child(vault_center)
	setup_vault_door = _vault_door_texture("SetupVaultDoor")
	setup_vault_door.custom_minimum_size = Vector2(380, 380)
	setup_vault_door.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_vault_door.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vault_center.add_child(setup_vault_door)

	CasinoHowTo3StepsScript.build(root_box, FACILITY_ID, _how_to_steps())

	var bet_caption := _label("STEP 1　ベットを選ぶ", 19, BRASS_LIGHT)
	bet_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(bet_caption)
	var bet_row := HBoxContainer.new()
	bet_row.name = "BetRow"
	bet_row.add_theme_constant_override("separation", 7)
	root_box.add_child(bet_row)
	for amount: int in BET_AMOUNTS:
		var button := _button("")
		button.name = "Bet_%d" % amount
		button.custom_minimum_size = Vector2(0, 104)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_bet.bind(amount))
		bet_buttons[amount] = button
		bet_row.add_child(button)
		_configure_bet_button(button, amount)

	var tier_caption := _label("STEP 2　金庫ランクを選ぶ", 19, BRASS_LIGHT)
	tier_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(tier_caption)
	var tier_grid := GridContainer.new()
	tier_grid.name = "TierGrid"
	tier_grid.columns = 2
	tier_grid.add_theme_constant_override("h_separation", 7)
	tier_grid.add_theme_constant_override("v_separation", 7)
	root_box.add_child(tier_grid)
	for tier: String in TIERS:
		var tier_button := _button(tier.to_upper())
		tier_button.name = "%sTierButton" % tier.capitalize()
		tier_button.custom_minimum_size = Vector2(0, 112)
		tier_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tier_button.add_theme_font_size_override("font_size", 17)
		tier_button.pressed.connect(_select_tier.bind(tier))
		tier_buttons[tier] = tier_button
		tier_grid.add_child(tier_button)

	setup_reward_label = _label("成功報酬  34 チップ", 17, BRASS_LIGHT)
	setup_reward_label.name = "SetupRewardLabel"
	setup_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(setup_reward_label)

	start_button = _button("金庫に挑戦！\nゲーム開始", true)
	start_button.name = "StartButton"
	start_button.custom_minimum_size.y = 112
	start_button.add_theme_font_size_override("font_size", 22)
	_apply_cta_style(start_button)
	start_button.pressed.connect(_start_game)
	root_box.add_child(start_button)

func _how_to_steps() -> Array[Dictionary]:
	return [
		{"action": "ベットと金庫を選ぶ", "copy": "挑戦するCHIPとランクを決めよう"},
		{"action": "サイコロを振って置く", "copy": "出た目に合うロックを選ぼう"},
		{"action": "6つのロックを埋める", "copy": "すべて埋まれば開錠成功"},
	]

func _configure_bet_button(button: Button, amount: int) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	margin.add_child(row)
	var chip := TextureRect.new()
	chip.texture = BET_CHIP_TEXTURES.get(amount) as Texture2D
	chip.custom_minimum_size = Vector2(62, 62)
	chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(chip)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", -3)
	row.add_child(copy)
	var state_copy := _label(" ", 11, BRASS_LIGHT)
	state_copy.custom_minimum_size.y = 16
	state_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(state_copy)
	var amount_copy := _label(str(amount), 27, PARCHMENT_LIGHT)
	amount_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(amount_copy)
	var unit_copy := _label("チップ", 12, PARCHMENT)
	unit_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(unit_copy)
	bet_state_labels[amount] = state_copy
	bet_value_labels[amount] = amount_copy
	bet_unit_labels[amount] = unit_copy

func _build_active(root_box: VBoxContainer) -> void:
	var stats := HBoxContainer.new()
	stats.name = "VaultStats"
	stats.custom_minimum_size.y = 64
	stats.add_theme_constant_override("separation", 5)
	root_box.add_child(stats)
	var tier_stat := _stat_box("TIER")
	tier_label = tier_stat.get("label") as Label
	tier_label.name = "TierLabel"
	stats.add_child(tier_stat.get("panel") as PanelContainer)
	var multiplier_stat := _stat_box("PAYOUT")
	multiplier_label = multiplier_stat.get("label") as Label
	multiplier_label.name = "MultiplierLabel"
	stats.add_child(multiplier_stat.get("panel") as PanelContainer)
	var roll_stat := _stat_box("ROLLS LEFT")
	roll_counter = roll_stat.get("label") as Label
	roll_counter.name = "RollCounter"
	stats.add_child(roll_stat.get("panel") as PanelContainer)

	vault_panel = PanelContainer.new()
	vault_panel.name = "VaultDoorPanel"
	vault_panel.custom_minimum_size.y = 342
	vault_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vault_panel.add_theme_stylebox_override("panel", _metal_panel(Color("#160f15"), BRASS, 22, 3))
	root_box.add_child(vault_panel)
	var vault_canvas := Control.new()
	vault_canvas.custom_minimum_size.y = 320
	vault_panel.add_child(vault_canvas)
	active_vault_door = _vault_door_texture("ActiveVaultDoor")
	active_vault_door.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	active_vault_door.offset_left = 26.0
	active_vault_door.offset_top = 26.0
	active_vault_door.offset_right = -26.0
	active_vault_door.offset_bottom = -26.0
	active_vault_door.modulate = Color("#b9a688")
	active_vault_door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vault_canvas.add_child(active_vault_door)
	var vault_margin := MarginContainer.new()
	vault_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vault_margin.add_theme_constant_override("margin_left", 20)
	vault_margin.add_theme_constant_override("margin_right", 20)
	vault_margin.add_theme_constant_override("margin_top", 10)
	vault_margin.add_theme_constant_override("margin_bottom", 10)
	vault_canvas.add_child(vault_margin)
	var vault_box := VBoxContainer.new()
	vault_box.add_theme_constant_override("separation", 5)
	vault_margin.add_child(vault_box)
	template_label = _label("VAULT —", 17, BRASS_LIGHT)
	template_label.name = "TemplateLabel"
	template_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vault_box.add_child(template_label)
	lock_container = HBoxContainer.new()
	lock_container.name = "LockContainer"
	lock_container.custom_minimum_size.y = 156
	lock_container.size_flags_vertical = Control.SIZE_FILL
	lock_container.add_theme_constant_override("separation", 7)
	lock_container.modulate = Color("#fff5d4")
	vault_box.add_child(lock_container)
	instruction_label = _label("「サイコロを振る」でダイスを出す", 18, PARCHMENT)
	instruction_label.name = "InstructionLabel"
	instruction_label.custom_minimum_size.y = 42
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vault_box.add_child(instruction_label)

	var die_panel := PanelContainer.new()
	die_panel.name = "CurrentDiePanel"
	die_panel.custom_minimum_size.y = 208
	die_panel.add_theme_stylebox_override("panel", _panel(Color("#151324"), Color("#745832"), 18, 2))
	root_box.add_child(die_panel)
	var die_row := HBoxContainer.new()
	die_row.add_theme_constant_override("separation", 8)
	die_panel.add_child(die_row)
	var die_center := CenterContainer.new()
	die_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	die_center.size_flags_stretch_ratio = 1.2
	die_row.add_child(die_center)
	dice_presentation = DicePresentationScript.new()
	dice_presentation.name = "VaultBreakDie3D"
	dice_presentation.overlay_compact = true
	dice_presentation.compact_single = true
	dice_presentation.tray_surface_visible = false
	dice_presentation.high_contrast_pips = true
	dice_presentation.custom_minimum_size = Vector2(220, 176)
	die_center.add_child(dice_presentation)
	var die_copy := VBoxContainer.new()
	die_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	die_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	die_row.add_child(die_copy)
	var die_caption := _label("CURRENT DIE", 15, Color("#cfc4dc"))
	die_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_copy.add_child(die_caption)
	die_face_label = _label("—", 44, BRASS_LIGHT)
	die_face_label.name = "CurrentDieFaceLabel"
	die_face_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	die_copy.add_child(die_face_label)
	reward_label = _label("獲得チップ 0 CHIP", 15, PARCHMENT)
	reward_label.name = "RewardLabel"
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	die_copy.add_child(reward_label)

	var actions := HBoxContainer.new()
	actions.name = "VaultActions"
	actions.add_theme_constant_override("separation", 8)
	root_box.add_child(actions)
	discard_button = _button("捨てる\nこの目を捨てる", false)
	discard_button.name = "DiscardButton"
	discard_button.custom_minimum_size = Vector2(0, 104)
	discard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discard_button.pressed.connect(_on_discard_pressed)
	actions.add_child(discard_button)
	roll_button = _button("サイコロを振る\n1D6", true)
	roll_button.name = "RollButton"
	roll_button.custom_minimum_size = Vector2(0, 104)
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.add_theme_font_size_override("font_size", 21)
	roll_button.pressed.connect(_on_roll_pressed)
	actions.add_child(roll_button)

func _build_result(root_box: VBoxContainer) -> void:
	var result_card := PanelContainer.new()
	result_card.name = "ResultCard"
	result_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_card.add_theme_stylebox_override("panel", _panel(Color("#21162bf2"), BRASS, 20, 3))
	root_box.add_child(result_card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 13)
	result_card.add_child(box)
	var eyebrow := _label("VAULT BREAK RESULT", 17, Color("#cfc4dc"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	result_vault_door_panel = PanelContainer.new()
	result_vault_door_panel.name = "ResultVaultDoorPanel"
	result_vault_door_panel.custom_minimum_size = Vector2(0, 244)
	result_vault_door_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_vault_door_panel.add_theme_stylebox_override("panel", _metal_panel(Color("#130e17d8"), BRASS, 16, 2))
	box.add_child(result_vault_door_panel)
	result_vault_door = _vault_door_texture("ResultVaultDoor")
	result_vault_door.custom_minimum_size = Vector2(0, 234)
	result_vault_door.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_vault_door.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_vault_door_panel.add_child(result_vault_door)
	result_label = _label("RESULT", 37, BRASS_LIGHT)
	result_label.name = "ResultLabel"
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_label)
	result_payout_label = _label("0 CHIP", 46, PARCHMENT_LIGHT)
	result_payout_label.name = "ResultPayoutLabel"
	result_payout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(result_payout_label)
	result_detail_label = _label("", 19, Color.WHITE)
	result_detail_label.name = "ResultDetailLabel"
	result_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_detail_label)
	again_button = _button("次の金庫を選ぶ", true)
	again_button.name = "AgainButton"
	again_button.custom_minimum_size.y = 104
	again_button.add_theme_font_size_override("font_size", 23)
	again_button.pressed.connect(_on_again_pressed)
	root_box.add_child(again_button)

func _resume_or_show_setup() -> void:
	if not _repository_loaded:
		_show_setup()
		status_label.text = "VAULTデータを読み込めません。"
		start_button.disabled = true
		resume_error = true
		return
	var active: Dictionary = CasinoBankScript.active_game(FACILITY_ID)
	if active.is_empty():
		var pending_result := _load_pending_result()
		if not pending_result.is_empty():
			_show_saved_result(pending_result)
		else:
			_show_setup()
		return

	game_id = str(active.get("game_id", ""))
	var session: Dictionary = active.get("session", {}) as Dictionary
	active_tier = str(session.get("tier", session.get("active_tier", ""))).to_lower()
	var template_id := str(session.get("template_id", ""))
	active_template = repository.call("get_template", template_id) as Dictionary
	if active_tier not in TIERS or active_template.is_empty() or str(active_template.get("tier", "")) != active_tier:
		_show_resume_error("保存されたVAULTの識別情報が不正です。")
		return
	var tier_config: Dictionary = repository.call("get_tier_config", active_tier) as Dictionary
	var snapshot_value: Variant = session.get("model_snapshot", session.get("game_snapshot", {}))
	if not snapshot_value is Dictionary:
		_show_resume_error("保存されたVAULT状態を復元できません。")
		return
	_new_model()
	if not bool(model.call("restore_active_game", snapshot_value as Dictionary, active_template, tier_config)):
		_show_resume_error("保存されたVAULT状態を復元できません。")
		return
	selected_bet = int((snapshot_value as Dictionary).get("bet", active.get("bet", selected_bet)))
	selected_tier = active_tier
	pending_rolls = _extract_pending_rolls(session)
	if pending_rolls.is_empty():
		pending_rolls = _extract_pending_rolls(active)
	pending_roll = _first_pending_roll()
	settled = false
	resume_error = false
	result_data = {}
	displayed_face = int(model.get("current_face"))
	_rebuild_lock_views()
	_show_active_views()
	var model_state := int(model.get("state"))
	if not pending_roll.is_empty() and model_state in [ModelScript.State.READY, ModelScript.State.ROLLING]:
		rolling = true
		displayed_face = int(pending_roll.get("value", 0))
		_set_state(State.ROLLING)
		status_label.text = "保存済みのFACE %dを再開..." % displayed_face
		_refresh_all()
		call_deferred("_resume_pending_roll")
		return
	if not pending_rolls.is_empty():
		pending_rolls = []
		pending_roll = {}
		_persist_active_game()
	match model_state:
		ModelScript.State.READY:
			_set_state(State.READY)
			status_label.text = "ゲームを再開しました。サイコロを振ってください。"
		ModelScript.State.WAITING_FOR_PLACEMENT:
			_set_state(State.WAITING_FOR_PLACEMENT)
			displayed_face = int(model.get("current_face"))
			status_label.text = "FACE %dを光るLOCKへ配置。" % displayed_face
		ModelScript.State.SUCCESS:
			_set_state(State.SUCCESS)
			call_deferred("_complete_terminal_result")
		ModelScript.State.FAILURE:
			_set_state(State.FAILURE)
			call_deferred("_complete_terminal_result")
		ModelScript.State.RESULT:
			_set_state(State.RESULT)
			call_deferred("_complete_terminal_result")
		_:
			_show_resume_error("保存されたVAULT状態は再開対象ではありません。")
	_refresh_all()

func _show_resume_error(message: String) -> void:
	resume_error = true
	settled = false
	rolling = false
	_set_state(State.SETUP)
	setup_view.visible = true
	active_view.visible = false
	result_view.visible = false
	status_label.text = message
	_refresh_all()
	start_button.disabled = true

func _show_setup() -> void:
	if CasinoBankScript.has_active_game(FACILITY_ID):
		_show_resume_error("進行中のVAULTを先に再開してください。")
		return
	_new_model()
	active_tier = ""
	active_template = {}
	game_id = ""
	pending_rolls = []
	pending_roll = {}
	result_data = {}
	settlement_receipt = {}
	settled = false
	rolling = false
	resume_error = false
	displayed_face = 0
	_terminal_handling = false
	_restore_valid_tier_selection()
	_set_state(State.SETUP)
	status_label.text = "ベットと金庫ランクを選ぼう"
	_refresh_all()

func _show_active_views() -> void:
	setup_view.visible = false
	active_view.visible = true
	result_view.visible = false

func _select_bet(amount: int) -> void:
	if state != State.SETUP or amount not in BET_AMOUNTS:
		return
	if CasinoBankScript.balance() < amount:
		status_label.text = "%d CHIPのBETには残高が足りません。" % amount
		_play_ui_sfx(&"blocked", false)
		return
	selected_bet = amount
	_save_preferences()
	_play_ui_sfx(&"select", false)
	_refresh_all()

func select_bet(amount: int) -> void:
	_select_bet(amount)

func _select_tier(tier: String) -> void:
	var normalized := tier.strip_edges().to_lower()
	if state != State.SETUP or normalized not in TIERS:
		return
	if not _is_tier_playable(normalized):
		status_label.text = _tier_lock_reason(normalized)
		_play_ui_sfx(&"blocked", false)
		return
	selected_tier = normalized
	_save_preferences()
	_play_ui_sfx(&"select", false)
	_refresh_all()

func select_tier(tier: String) -> void:
	_select_tier(tier)

func _start_game() -> void:
	if state != State.SETUP or resume_error or not _repository_loaded:
		return
	if selected_bet not in BET_AMOUNTS or CasinoBankScript.balance() < selected_bet:
		status_label.text = "選択中のBETに必要なCHIPがありません。"
		_play_ui_sfx(&"blocked", false)
		_refresh_all()
		return
	if not _is_tier_playable(selected_tier):
		status_label.text = _tier_lock_reason(selected_tier)
		_play_ui_sfx(&"blocked", false)
		_refresh_all()
		return

	var chosen: Dictionary = {}
	if selected_tier == "black":
		chosen = repository.call("get_template", str(progress.call("get_active_black_template_id"))) as Dictionary
	elif not forced_template_id.is_empty():
		var forced: Dictionary = repository.call("get_template", forced_template_id) as Dictionary
		if str(forced.get("tier", "")) == selected_tier:
			chosen = forced
		forced_template_id = ""
	if chosen.is_empty():
		chosen = selector.call("select_template", selected_tier, progress, _next_template_random_value()) as Dictionary
	if chosen.is_empty() or str(chosen.get("tier", "")) != selected_tier:
		status_label.text = "このTIERのVAULTを選べません。"
		_play_ui_sfx(&"blocked", false)
		return

	var tier_config: Dictionary = repository.call("get_tier_config", selected_tier) as Dictionary
	var candidate: RefCounted = ModelScript.new()
	candidate.call("set_lock_rules", repository.get("lock_rules") as Dictionary)
	if not bool(candidate.call("start_with_tier_config", chosen, selected_bet, tier_config)):
		status_label.text = "VAULTを開始できません。"
		return
	var initial_session := _make_session(candidate.call("snapshot_active_game") as Dictionary, [], chosen, selected_tier)
	var receipt: Dictionary = CasinoBankScript.begin_game(FACILITY_ID, selected_bet, initial_session)
	if not bool(receipt.get("ok", false)):
		if bool(receipt.get("already_active", false)):
			_resume_or_show_setup()
		else:
			status_label.text = "開始できません。CHIP残高を確認してください。"
			_refresh_all()
		return

	model = candidate
	active_template = chosen.duplicate(true)
	active_tier = selected_tier
	game_id = str(receipt.get("game_id", ""))
	pending_rolls = []
	pending_roll = {}
	settled = false
	rolling = false
	_terminal_handling = false
	result_data = {}
	spawned_black_template_id = ""
	displayed_face = 0
	_clear_pending_result()
	_save_preferences()
	_rebuild_lock_views()
	_show_active_views()
	_set_state(State.READY)
	status_label.text = "%s %s。「サイコロを振る」で最初のダイスを出す。" % [str(TIER_NAMES.get(active_tier, active_tier.to_upper())), str(active_template.get("id", ""))]
	_play_ui_sfx(&"start", false)
	_refresh_all()

func start_game() -> void:
	_start_game()

func _on_roll_pressed() -> void:
	if state != State.READY or rolling or model == null or not pending_rolls.is_empty():
		return
	var face := _next_roll_value()
	if face not in range(1, 7):
		return
	var pre_roll_snapshot: Dictionary = model.call("snapshot_active_game") as Dictionary
	pending_roll = {
		"kind": "roll",
		"value": face,
		"roll_index": int(model.get("rolls_used")) + 1,
		"template_id": str(active_template.get("id", "")),
	}
	pending_rolls = [pending_roll.duplicate(true)]
	# The pending face and the canonical pre-roll snapshot are persisted before
	# any visual motion. A scene exit can therefore replay this exact face.
	if not _persist_active_game(pre_roll_snapshot):
		pending_rolls = []
		pending_roll = {}
		status_label.text = "サイコロを保存できません。もう一度お試しください。"
		_refresh_all()
		return
	rolling = true
	displayed_face = face
	_set_state(State.ROLLING)
	status_label.text = "サイコロ %d / %d..." % [int(pending_roll.get("roll_index", 1)), int(model.get("max_rolls"))]
	_play_ui_sfx(&"roll", false)
	_refresh_all()
	await _animate_roll(face)
	if not is_inside_tree():
		return
	await _resolve_pending_roll(pending_roll)

func roll() -> void:
	_on_roll_pressed()

func _resume_pending_roll() -> void:
	if pending_roll.is_empty() or not is_inside_tree():
		return
	var face := clampi(int(pending_roll.get("value", 1)), 1, 6)
	await _animate_roll(face)
	if not is_inside_tree():
		return
	await _resolve_pending_roll(pending_roll)

func _resolve_pending_roll(pending: Dictionary) -> void:
	if pending.is_empty() or model == null:
		return
	var face := clampi(int(pending.get("value", 1)), 1, 6)
	var model_state := int(model.get("state"))
	if model_state == ModelScript.State.READY:
		if int(model.call("begin_roll", face)) != face:
			rolling = false
			status_label.text = "サイコロを解決できません。"
			return
	elif model_state == ModelScript.State.ROLLING:
		if int(model.get("current_face")) != face:
			rolling = false
			status_label.text = "保存された出目が一致しません。"
			return
	else:
		rolling = false
		return

	var valid_indices: Array = model.call("resolve_rolled_die") as Array
	pending_rolls = []
	pending_roll = {}
	rolling = false
	displayed_face = face
	if not valid_indices.is_empty():
		_set_state(State.WAITING_FOR_PLACEMENT)
		status_label.text = "目 %d。光るLOCKを選ぶか捨てる。" % face
		instruction_label.text = "%d個のLOCKが有効 · どこに使うか選択" % valid_indices.size()
		_persist_active_game()
		_play_ui_sfx(&"select", true)
		_refresh_all()
		return

	# The pure model has already performed the authored automatic discard. Keep
	# that outcome visible briefly, including on the final roll, before failure.
	_set_state(State.RESOLVING_PLACEMENT)
	status_label.text = "置けない目%dを自動で捨てました" % face
	instruction_label.text = "入るLOCKがないため自動で捨てました"
	_persist_active_game()
	_play_ui_sfx(&"blocked", true)
	_refresh_all()
	await _finish_turn_feedback(false)

func _on_lock_pressed(lock_index: int) -> void:
	if state != State.WAITING_FOR_PLACEMENT or model == null:
		return
	var face := int(model.get("current_face"))
	if not bool(model.call("place_current_die", lock_index)):
		status_label.text = "LOCK %dにはFACE %dを置けません。" % [lock_index + 1, face]
		_play_ui_sfx(&"blocked", false)
		_refresh_lock_views()
		return
	displayed_face = face
	_set_state(State.RESOLVING_PLACEMENT)
	status_label.text = "FACE %dをLOCK %dへ固定。" % [face, lock_index + 1]
	instruction_label.text = "LOCKED · 置いたダイスは動かせません"
	_persist_active_game()
	_play_ui_sfx(&"progress-step", true)
	_refresh_all()
	await _finish_turn_feedback(true)

func place_current_die(lock_index: int) -> void:
	_on_lock_pressed(lock_index)

func _on_discard_pressed() -> void:
	if state != State.WAITING_FOR_PLACEMENT or model == null:
		return
	var face := int(model.get("current_face"))
	if not bool(model.call("discard_current_die")):
		return
	displayed_face = face
	_set_state(State.RESOLVING_PLACEMENT)
	status_label.text = "目%dを捨てる。" % face
	instruction_label.text = "捨てました · 次のサイコロへ"
	_persist_active_game()
	_play_ui_sfx(&"back", false)
	_refresh_all()
	await _finish_turn_feedback(false)

func discard() -> void:
	_on_discard_pressed()

func _finish_turn_feedback(was_placement: bool) -> void:
	await _wait_seconds(ACTION_SECONDS)
	if not is_inside_tree():
		return
	var model_state := int(model.get("state"))
	if model_state in [ModelScript.State.SUCCESS, ModelScript.State.FAILURE]:
		await _complete_terminal_result()
		return
	if model_state != ModelScript.State.READY:
		return
	_set_state(State.READY)
	status_label.text = "LOCKを埋めた。次のサイコロ。" if was_placement else "次のサイコロへ。"
	instruction_label.text = "「サイコロを振る」で次のダイスを出す"
	_refresh_all()

func _complete_terminal_result() -> void:
	if _terminal_handling or model == null:
		return
	var model_state := int(model.get("state"))
	if model_state == ModelScript.State.RESULT:
		var restored_result := str(model.get("result"))
		model_state = ModelScript.State.SUCCESS if restored_result == "success" else ModelScript.State.FAILURE
	if model_state not in [ModelScript.State.SUCCESS, ModelScript.State.FAILURE]:
		return
	_terminal_handling = true
	var won := model_state == ModelScript.State.SUCCESS
	_set_state(State.SUCCESS if won else State.FAILURE)
	status_label.text = "金庫を開錠！" if won else "開錠失敗"
	instruction_label.text = "すべてのロックを解除" if won else "サイコロ回数終了"
	_refresh_all()
	# Persist the terminal model first, then atomically save progress/BLACK and a
	# game-id receipt before any Result UI becomes visible.
	pending_rolls = []
	pending_roll = {}
	if not _persist_active_game():
		status_label.text = "最終状態を保存できません。"
		_terminal_handling = false
		return
	if not _record_progress_before_result(won):
		status_label.text = "進行状況を保存できません。"
		_terminal_handling = false
		return

	var payout := int(model.get("reward")) if won else 0
	settlement_attempt_count += 1
	settlement_receipt = CasinoBankScript.settle_game(FACILITY_ID, payout, {
		"result": "success" if won else "failure",
		"tier": active_tier,
		"template_id": str(active_template.get("id", "")),
		"bet": selected_bet,
		"reward": payout,
	}, game_id)
	settled = bool(settlement_receipt.get("ok", false)) or bool(settlement_receipt.get("already_settled", false))
	if not settled:
		status_label.text = "CHIP決済を完了できません。"
		_terminal_handling = false
		return
	if bool(settlement_receipt.get("already_settled", false)):
		payout = int(settlement_receipt.get("payout", payout))
		result_data["reward"] = payout
	if won:
		_play_ui_sfx(&"complete", true)
		_play_success_feedback()
	else:
		_play_ui_sfx(&"error", true)
		_play_failure_feedback()
	await _wait_seconds(RESULT_HOLD_SECONDS)
	if not is_inside_tree():
		return
	if int(model.get("state")) in [ModelScript.State.SUCCESS, ModelScript.State.FAILURE]:
		model.call("advance_to_result")
	_set_state(State.RESULT)
	_show_result()
	_terminal_handling = false

func _record_progress_before_result(won: bool) -> bool:
	var bank_data: Dictionary = CasinoBankScript.load_data()
	var meta := _meta_from_data(bank_data)
	var recorded: Array = meta.get("recorded_game_ids", []) as Array if meta.get("recorded_game_ids", []) is Array else []
	if game_id not in recorded:
		spawned_black_template_id = str(progress.call(
			"complete_game",
			active_template,
			won,
			selector,
			_next_spawn_random_value(),
			_next_black_template_random_value()
		))
		recorded.append(game_id)
		while recorded.size() > 64:
			recorded.pop_front()
	else:
		var saved_progress: Variant = meta.get("progress", {})
		if saved_progress is Dictionary:
			progress.call("load_progress", saved_progress)
	meta["schema_version"] = META_SCHEMA_VERSION
	meta["progress"] = progress.call("serialize") as Dictionary
	meta["last_bet"] = selected_bet
	meta["last_tier"] = active_tier
	meta["recorded_game_ids"] = recorded
	result_data = {
		"schema_version": 1,
		"game_id": game_id,
		"tier": active_tier,
		"template_id": str(active_template.get("id", "")),
		"bet": selected_bet,
		"won": won,
		"result": "success" if won else "failure",
		"reward": int(model.get("reward")) if won else 0,
		"rolls_used": int(model.get("rolls_used")),
		"max_rolls": int(model.get("max_rolls")),
		"spawned_black_template_id": spawned_black_template_id,
	}
	meta["pending_result"] = result_data.duplicate(true)
	bank_data[META_KEY] = meta
	return CasinoBankScript.save_data(bank_data)

func _show_result() -> void:
	setup_view.visible = false
	active_view.visible = false
	result_view.visible = true
	var won := bool(result_data.get("won", str(result_data.get("result", "")) == "success"))
	var reward := int(result_data.get("reward", 0))
	var bet := int(result_data.get("bet", selected_bet))
	var tier := str(result_data.get("tier", active_tier))
	var template_id := str(result_data.get("template_id", active_template.get("id", "")))
	result_label.text = "金庫を開錠！" if won else "開錠失敗\nチップなし"
	result_label.add_theme_color_override("font_color", BRASS_LIGHT if won else Color("#f0a39a"))
	if result_vault_door != null:
		result_vault_door.modulate = Color("#f5d890") if won else Color("#75646b")
		result_vault_door.modulate.a = 0.96 if won else 0.64
	if result_vault_door_panel != null:
		result_vault_door_panel.add_theme_stylebox_override("panel", _metal_panel(Color("#130e17d8"), BRASS if won else FAILURE_RED, 16, 2))
	result_payout_label.text = "受け取り %d CHIP（BET込み）" % reward
	result_detail_label.text = "収支 %+d CHIP · BET %d\n%s %s · %d/%d回" % [
		reward - bet,
		bet,
		str(TIER_NAMES.get(tier, tier.to_upper())),
		template_id,
		int(result_data.get("rolls_used", 0)),
		int(result_data.get("max_rolls", 0)),
	]
	var spawned := str(result_data.get("spawned_black_template_id", ""))
	if not spawned.is_empty():
		result_detail_label.text += "\nBLACK VAULT %s APPEARED" % spawned
	status_label.text = "進行とCHIPを保存しました。次の行動を選択。"
	_refresh_all()
	call_deferred("_animate_result_reveal")

func _animate_result_reveal() -> void:
	if result_view == null or not result_view.visible:
		return
	VisualFeedback.reveal(result_view, 0.28)

func _show_saved_result(saved_result: Dictionary) -> void:
	result_data = saved_result.duplicate(true)
	selected_bet = int(result_data.get("bet", selected_bet))
	active_tier = str(result_data.get("tier", "bronze"))
	selected_tier = active_tier
	active_template = repository.call("get_template", str(result_data.get("template_id", ""))) as Dictionary
	game_id = str(result_data.get("game_id", ""))
	settled = true
	rolling = false
	_set_state(State.RESULT)
	_show_result()

func _on_again_pressed() -> void:
	if state != State.RESULT:
		return
	var previous_tier := str(result_data.get("tier", selected_tier))
	var previous_bet := int(result_data.get("bet", selected_bet))
	_clear_pending_result()
	selected_bet = previous_bet if previous_bet in BET_AMOUNTS else 20
	selected_tier = previous_tier
	if not _is_tier_playable(selected_tier):
		selected_tier = "bronze"
	_save_preferences()
	_show_setup()

func _on_back_pressed() -> void:
	if state == State.EXITING:
		return
	if state in [State.SUCCESS, State.FAILURE, State.RESOLVING_PLACEMENT]:
		return
	if state == State.RESULT:
		_clear_pending_result()
	elif state in [State.READY, State.ROLLING, State.WAITING_FOR_PLACEMENT]:
		# READY/WAITING snapshots and pre-animation pending faces are canonical.
		# Save once more before yielding control to Casino Hub.
		_persist_active_game()
	_set_state(State.EXITING)
	_play_ui_sfx(&"back", false)
	back_requested.emit()

func exit_to_casino() -> void:
	_on_back_pressed()

func _make_session(snapshot: Dictionary, queued_rolls: Array, template: Dictionary = active_template, tier: String = active_tier) -> Dictionary:
	return {
		"schema_version": 1,
		"facility_id": FACILITY_ID,
		"tier": tier,
		"active_tier": tier,
		"template_id": str(template.get("id", "")),
		"bet": int(snapshot.get("bet", selected_bet)),
		"model_snapshot": snapshot.duplicate(true),
		"pending_rolls": queued_rolls.duplicate(true),
	}

func _persist_active_game(snapshot_override: Dictionary = {}) -> bool:
	if game_id.is_empty() or active_template.is_empty():
		return false
	var snapshot := snapshot_override.duplicate(true)
	if snapshot.is_empty():
		snapshot = model.call("snapshot_active_game") as Dictionary
	if snapshot.is_empty():
		return false
	var session := _make_session(snapshot, pending_rolls)
	var receipt: Dictionary = CasinoBankScript.update_game(FACILITY_ID, session, game_id)
	return bool(receipt.get("ok", false))

func _extract_pending_rolls(source: Dictionary) -> Array:
	var candidate: Variant = source.get("pending_rolls", [])
	return (candidate as Array).duplicate(true) if candidate is Array else []

func _first_pending_roll() -> Dictionary:
	if not pending_rolls.is_empty() and pending_rolls[0] is Dictionary:
		return (pending_rolls[0] as Dictionary).duplicate(true)
	return {}

func _load_meta() -> Dictionary:
	return _meta_from_data(CasinoBankScript.load_data())

func _meta_from_data(bank_data: Dictionary) -> Dictionary:
	var value: Variant = bank_data.get(META_KEY, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

func _save_preferences() -> bool:
	var bank_data := CasinoBankScript.load_data()
	var meta := _meta_from_data(bank_data)
	meta["schema_version"] = META_SCHEMA_VERSION
	meta["progress"] = progress.call("serialize") as Dictionary
	meta["last_bet"] = selected_bet
	meta["last_tier"] = selected_tier
	bank_data[META_KEY] = meta
	return CasinoBankScript.save_data(bank_data)

func _restore_preferences(meta: Dictionary) -> void:
	var remembered_bet := int(meta.get("last_bet", 20))
	selected_bet = remembered_bet if remembered_bet in BET_AMOUNTS else 20
	var remembered_tier := str(meta.get("last_tier", "bronze")).to_lower()
	selected_tier = remembered_tier if remembered_tier in TIERS else "bronze"
	_restore_valid_tier_selection()

func _restore_valid_tier_selection() -> void:
	if selected_tier not in TIERS or not _is_tier_playable(selected_tier):
		selected_tier = "bronze"

func _load_pending_result() -> Dictionary:
	var meta := _load_meta()
	var candidate: Variant = meta.get("pending_result", {})
	return (candidate as Dictionary).duplicate(true) if candidate is Dictionary else {}

func _clear_pending_result() -> void:
	var bank_data := CasinoBankScript.load_data()
	var meta := _meta_from_data(bank_data)
	if not meta.has("pending_result"):
		return
	meta.erase("pending_result")
	bank_data[META_KEY] = meta
	CasinoBankScript.save_data(bank_data)

func _is_tier_playable(tier: String) -> bool:
	if progress == null or tier not in TIERS:
		return false
	if tier == "black":
		return not str(progress.call("get_active_black_template_id")).is_empty()
	return bool(progress.call("is_tier_unlocked", tier))

func _tier_lock_reason(tier: String) -> String:
	match tier:
		"silver":
			return "シルバー金庫は、ブロンズを1回成功すると解放されます。"
		"gold":
			return "ゴールド金庫は、シルバーを2回成功すると解放されます。"
		"black":
			return "ブラック金庫はまだ出現していません。"
	return "この金庫ランクは選べません。"

func _rebuild_lock_views() -> void:
	if lock_container == null:
		return
	for child: Node in lock_container.get_children():
		lock_container.remove_child(child)
		child.queue_free()
	lock_views.clear()
	if active_template.is_empty():
		return
	var locks: Array = active_template.get("locks", []) as Array
	for index: int in locks.size():
		var lock_data: Dictionary = locks[index] as Dictionary
		var lock_view := LockViewScript.new() as VaultBreakLockView
		lock_view.name = "Lock_%d" % index
		lock_view.configure(index, lock_data, _display_faces_for_lock(lock_data))
		lock_view.lock_selected.connect(_on_lock_pressed)
		lock_views.append(lock_view)
		lock_container.add_child(lock_view)
	_refresh_lock_views()

func _display_faces_for_lock(lock_data: Dictionary) -> Array[int]:
	var result: Array[int] = []
	var rule := str(lock_data.get("rule", ""))
	if rule == "exact":
		var exact_face := int(lock_data.get("value", 0))
		if exact_face in range(1, 7):
			result.append(exact_face)
		return result
	var definitions: Dictionary = repository.get("lock_rules") as Dictionary
	var definition: Variant = definitions.get(rule, {})
	if definition is Dictionary:
		var authored_faces: Variant = (definition as Dictionary).get("accepted_faces", [])
		if authored_faces is Array:
			for face_value: Variant in authored_faces as Array:
				result.append(int(face_value))
	return result

func _refresh_all() -> void:
	if chip_label != null:
		var chip_balance: int = CasinoBankScript.balance()
		chip_label.text = "CASINO CHIP\n%d" % chip_balance
		if last_chip_balance >= 0 and chip_balance != last_chip_balance:
			_pop_chip_balance()
		last_chip_balance = chip_balance
	setup_view.visible = state == State.SETUP
	active_view.visible = state in [State.READY, State.ROLLING, State.WAITING_FOR_PLACEMENT, State.RESOLVING_PLACEMENT, State.SUCCESS, State.FAILURE]
	result_view.visible = state == State.RESULT
	_refresh_bet_buttons()
	_refresh_tier_buttons()
	if setup_reward_label != null and repository != null:
		var setup_config: Dictionary = repository.call("get_tier_config", selected_tier) as Dictionary
		var setup_reward := floori(float(selected_bet) * float(setup_config.get("payout_multiplier", 0.0)))
		setup_reward_label.text = "成功報酬  %d チップ" % setup_reward
	if start_button != null:
		start_button.disabled = state != State.SETUP or resume_error or CasinoBankScript.balance() < selected_bet or not _is_tier_playable(selected_tier) or not _repository_loaded
	if back_button != null:
		back_button.disabled = state in [State.ROLLING, State.RESOLVING_PLACEMENT, State.SUCCESS, State.FAILURE, State.EXITING]
		back_button.text = CasinoBackButton.LABEL
	if model == null or active_template.is_empty():
		return
	var config: Dictionary = repository.call("get_tier_config", active_tier) as Dictionary
	if tier_label != null:
		tier_label.text = str(TIER_NAMES.get(active_tier, active_tier.to_upper()))
	if multiplier_label != null:
		multiplier_label.text = "×%.1f" % float(config.get("payout_multiplier", 0.0))
	if roll_counter != null:
		roll_counter.text = "%d / %d" % [maxi(0, int(model.get("max_rolls")) - int(model.get("rolls_used"))), int(model.get("max_rolls"))]
	if reward_label != null:
		reward_label.text = "獲得チップ  %d CHIP" % floori(float(selected_bet) * float(config.get("payout_multiplier", 0.0)))
	if template_label != null:
		template_label.text = "%s VAULT · %s · %d LOCKS" % [str(TIER_NAMES.get(active_tier, active_tier.to_upper())), str(active_template.get("id", "")), lock_views.size()]
	if die_face_label != null:
		die_face_label.text = str(displayed_face) if displayed_face in range(1, 7) else "—"
	if roll_button != null:
		roll_button.disabled = state != State.READY
	if discard_button != null:
		discard_button.disabled = state != State.WAITING_FOR_PLACEMENT
	_refresh_lock_views()

func _refresh_bet_buttons() -> void:
	var chips := CasinoBankScript.balance()
	for amount_value: Variant in bet_buttons.keys():
		var amount := int(amount_value)
		var button := bet_buttons.get(amount) as Button
		if button == null:
			continue
		var selected := amount == selected_bet
		button.disabled = state != State.SETUP or chips < amount
		button.text = ""
		button.offset_transform_enabled = true
		button.offset_transform_position = Vector2(0, -2 if selected else 0)
		button.offset_transform_scale = Vector2(1.02, 1.02) if selected else Vector2.ONE
		var state_copy := bet_state_labels.get(amount) as Label
		var amount_copy := bet_value_labels.get(amount) as Label
		var unit_copy := bet_unit_labels.get(amount) as Label
		if state_copy != null:
			state_copy.text = "選択中" if selected else " "
			state_copy.modulate = Color.WHITE if chips >= amount else Color(1, 1, 1, 0.4)
		if amount_copy != null:
			amount_copy.modulate = Color.WHITE if chips >= amount else Color(1, 1, 1, 0.4)
		if unit_copy != null:
			unit_copy.modulate = Color.WHITE if chips >= amount else Color(1, 1, 1, 0.4)
		_apply_button_state(button, selected, chips >= amount)

func _refresh_tier_buttons() -> void:
	if progress == null or repository == null:
		return
	var active_black := str(progress.call("get_active_black_template_id"))
	for tier_value: Variant in tier_buttons.keys():
		var tier := str(tier_value)
		var button := tier_buttons.get(tier) as Button
		if button == null:
			continue
		if tier == "black":
			button.visible = not active_black.is_empty()
		var playable := _is_tier_playable(tier)
		var selected := tier == selected_tier
		var config: Dictionary = repository.call("get_tier_config", tier) as Dictionary
		var heading := ("選択中  " if selected else "") + str(TIER_NAMES_JA.get(tier, tier))
		var payout := "配当 ×%.1f" % float(config.get("payout_multiplier", 0.0))
		var detail := "挑戦可能"
		if tier == "black" and playable:
			detail = "特別金庫が出現中"
		elif not playable:
			match tier:
				"silver": detail = "ブロンズ成功 1回で解放"
				"gold": detail = "シルバー成功 2回で解放"
				"black": detail = "未出現"
		button.text = "%s\n%s\n%s" % [heading, payout, detail]
		button.disabled = state != State.SETUP or not playable
		button.offset_transform_enabled = true
		button.offset_transform_position = Vector2(0, -2 if selected else 0)
		button.offset_transform_scale = Vector2(1.02, 1.02) if selected else Vector2.ONE
		_apply_tier_state(button, tier, selected, playable)

func _refresh_lock_views() -> void:
	if model == null or active_template.is_empty():
		return
	var placed: Array = model.call("get_placed_faces") as Array
	var valid: Array = []
	if state == State.WAITING_FOR_PLACEMENT:
		valid = model.call("get_valid_empty_lock_indices") as Array
	var won := int(model.get("state")) in [ModelScript.State.SUCCESS, ModelScript.State.RESULT] and str(model.get("result")) == "success"
	var failed := int(model.get("state")) in [ModelScript.State.FAILURE, ModelScript.State.RESULT] and str(model.get("result")) == "failure"
	for index: int in lock_views.size():
		var lock_view := lock_views[index]
		var face := int(placed[index]) if index < placed.size() else 0
		if face != 0:
			lock_view.set_lock_state(VaultBreakLockView.State.SUCCESS if won else VaultBreakLockView.State.FILLED, face)
		elif failed:
			lock_view.set_lock_state(VaultBreakLockView.State.FAILED)
		elif state == State.WAITING_FOR_PLACEMENT:
			lock_view.set_lock_state(VaultBreakLockView.State.VALID_TARGET if index in valid else VaultBreakLockView.State.INVALID_TARGET)
		else:
			lock_view.set_lock_state(VaultBreakLockView.State.EMPTY)

func _set_state(next_state: int) -> void:
	state = clampi(next_state, State.SETUP, State.EXITING)
	view_state = STATE_NAMES[state]
	rolling = state == State.ROLLING

func _next_roll_value() -> int:
	if queued_roll_value in range(1, 7):
		var forced := queued_roll_value
		queued_roll_value = 0
		return forced
	if rng_seed != 0:
		_rng.seed = rng_seed
		rng_seed = 0
	return _rng.randi_range(1, 6)

func _next_template_random_value() -> Variant:
	if queued_template_random_value != null:
		var value: Variant = queued_template_random_value
		queued_template_random_value = null
		return value
	if template_random_provider.is_valid():
		return template_random_provider.call()
	return null

func _next_spawn_random_value() -> Variant:
	if queued_spawn_random_value != null:
		var value: Variant = queued_spawn_random_value
		queued_spawn_random_value = null
		return value
	if spawn_random_provider.is_valid():
		return spawn_random_provider.call()
	return null

func _next_black_template_random_value() -> Variant:
	if queued_black_template_random_value != null:
		var value: Variant = queued_black_template_random_value
		queued_black_template_random_value = null
		return value
	if black_template_random_provider.is_valid():
		return black_template_random_provider.call()
	return null

func set_template_random_provider(provider: Callable) -> void:
	template_random_provider = provider

func set_spawn_random_provider(provider: Callable) -> void:
	spawn_random_provider = provider

func set_black_template_random_provider(provider: Callable) -> void:
	black_template_random_provider = provider

func set_vault_break_seed(seed_value: int) -> void:
	rng_seed = seed_value

func force_next_roll(face: int) -> void:
	queued_roll_value = face if face in range(1, 7) else 0

func force_template(template_id: String) -> void:
	forced_template_id = template_id.strip_edges()

func force_black_spawn() -> void:
	queued_spawn_random_value = 0.0
	queued_black_template_random_value = 0.0

func _animate_roll(face: int) -> void:
	var start_face := displayed_face
	if start_face not in range(1, 7):
		start_face = 1
	if is_instance_valid(dice_presentation):
		dice_presentation.present([start_face], true, 1)
	await _wait_seconds(ROLL_SECONDS)
	if not is_inside_tree():
		return
	if is_instance_valid(dice_presentation):
		dice_presentation.flip_to_face(face)
	displayed_face = face
	if die_face_label != null:
		die_face_label.text = str(face)
	await _wait_seconds(SETTLE_SECONDS)

func _wait_seconds(base_seconds: float) -> void:
	var seconds := maxf(0.0, base_seconds * maxf(0.0, animation_duration_scale))
	if seconds <= 0.0:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(seconds).timeout

func _play_success_feedback() -> void:
	if vault_panel == null:
		return
	vault_panel.pivot_offset = vault_panel.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(vault_panel, "modulate", Color("#fff3c4"), 0.10 * maxf(animation_duration_scale, 0.01))
	pulse.tween_property(vault_panel, "modulate", Color.WHITE, 0.20 * maxf(animation_duration_scale, 0.01))
	_spin_vault_handle()
	_spawn_brass_sparks()

func _play_failure_feedback() -> void:
	if vault_panel == null:
		return
	var pulse := create_tween()
	pulse.tween_property(vault_panel, "modulate", Color("#d77b72"), 0.09 * maxf(animation_duration_scale, 0.01))
	pulse.tween_property(vault_panel, "modulate", Color.WHITE, 0.18 * maxf(animation_duration_scale, 0.01))
	_shake_vault_door()

func _spawn_brass_sparks() -> void:
	if effect_layer == null:
		return
	for index: int in 10:
		var spark := ColorRect.new()
		spark.name = "VaultSpark"
		spark.size = Vector2(5, 9)
		spark.color = BRASS_LIGHT if index % 2 == 0 else PARCHMENT_LIGHT
		spark.position = Vector2(effect_layer.size.x * 0.5 + randf_range(-90.0, 90.0), effect_layer.size.y * 0.40 + randf_range(-25.0, 25.0))
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		effect_layer.add_child(spark)
		var drift := create_tween().set_parallel(true)
		drift.tween_property(spark, "position", spark.position + Vector2(randf_range(-55.0, 55.0), randf_range(-85.0, -35.0)), 0.40 * maxf(animation_duration_scale, 0.01))
		drift.tween_property(spark, "modulate:a", 0.0, 0.34 * maxf(animation_duration_scale, 0.01))
		drift.chain().tween_callback(spark.queue_free)

func _play_ui_sfx(cue: StringName, world_specific: bool) -> void:
	if suppress_audio_for_tests:
		return
	var ui_sfx := get_node_or_null("/root/UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("play_ui_sfx", cue, world_specific)

func _stat_box(caption: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel(PARCHMENT, Color("#9d682d"), 12, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var cap := _label(caption, 12, Color("#70451d"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	var value := _label("—", 19, INK)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	return {"panel": panel, "label": value}

func _label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(copy: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = copy
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 17)
	button.custom_minimum_size = Vector2(96, 96)
	button.add_theme_color_override("font_color", INK if primary else PARCHMENT_LIGHT)
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#b8b1b4"))
	button.add_theme_stylebox_override("normal", _panel(BRASS if primary else Color("#403452"), Color("#9c6e31") if primary else Color("#705e84"), 13, 2))
	button.add_theme_stylebox_override("hover", _panel(BRASS_LIGHT if primary else Color("#51436a"), BRASS_LIGHT, 13, 3))
	button.add_theme_stylebox_override("pressed", _panel(Color("#ae792a") if primary else Color("#302641"), BRASS_LIGHT, 13, 3))
	button.add_theme_stylebox_override("disabled", _panel(Color("#3a3540"), Color("#67616b"), 13, 1))
	button.add_theme_stylebox_override("focus", _focus_panel(BRASS_LIGHT, 13))
	VisualFeedback.bind_button(button)
	return button

func _vault_door_texture(node_name: String) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = VAULT_DOOR_TEXTURE
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.pivot_offset = texture_rect.size * 0.5
	return texture_rect

func _apply_cta_style(button: Button) -> void:
	button.add_theme_color_override("font_color", PARCHMENT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _metal_panel(VELVET_RED, BRASS_LIGHT, 18, 4))
	button.add_theme_stylebox_override("hover", _metal_panel(VELVET_RED_LIGHT, Color("#ffe49a"), 18, 5))
	button.add_theme_stylebox_override("pressed", _metal_panel(Color("#571512"), BRASS, 18, 4))
	button.add_theme_stylebox_override("disabled", _metal_panel(Color("#322b30"), Color("#62585e"), 18, 2))
	button.add_theme_stylebox_override("focus", _focus_panel(Color("#ffe49a"), 18))

func _apply_tier_state(button: Button, tier: String, selected: bool, available: bool) -> void:
	var fill: Color = BRONZE_SURFACE
	var border: Color = Color("#b56f42")
	match tier:
		"silver":
			fill = SILVER_SURFACE
			border = Color("#aeb4c0")
		"gold":
			fill = GOLD_SURFACE
			border = Color("#e6b84f")
		"black":
			fill = BLACK_SURFACE
			border = Color("#a45dde")
	if not available:
		fill = fill.darkened(0.42)
		border = border.darkened(0.35)
	button.add_theme_stylebox_override("normal", _metal_panel(fill.lightened(0.10) if selected else fill, BRASS_LIGHT if selected else border, 14, 4 if selected else 2))
	button.add_theme_stylebox_override("hover", _metal_panel(fill.lightened(0.18), BRASS_LIGHT, 14, 3))
	button.add_theme_stylebox_override("pressed", _metal_panel(fill.darkened(0.12), BRASS_LIGHT, 14, 3))
	button.add_theme_color_override("font_color", PARCHMENT_LIGHT if available else Color("#aaa4ad"))
	button.add_theme_stylebox_override("focus", _focus_panel(BRASS_LIGHT if tier != "black" else Color("#c47aff"), 14))

func _metal_panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _panel(fill, border, radius, width)
	style.shadow_color = Color("#00000088")
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

func _focus_panel(border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_expand_margin_all(3)
	return style

func _pop_chip_balance() -> void:
	if chip_label == null:
		return
	if chip_balance_tween != null:
		chip_balance_tween.kill()
	chip_label.offset_transform_enabled = true
	chip_balance_tween = create_tween()
	chip_balance_tween.tween_property(chip_label, "offset_transform_scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chip_balance_tween.tween_property(chip_label, "offset_transform_scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _spin_vault_handle() -> void:
	if active_vault_door == null:
		return
	if vault_handle_tween != null:
		vault_handle_tween.kill()
	active_vault_door.pivot_offset = active_vault_door.size * 0.5
	vault_handle_tween = create_tween()
	vault_handle_tween.tween_property(active_vault_door, "rotation", 0.32, 0.34 * maxf(animation_duration_scale, 0.01)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	vault_handle_tween.tween_property(active_vault_door, "rotation", 0.0, 0.20 * maxf(animation_duration_scale, 0.01))

func _shake_vault_door() -> void:
	if active_vault_door == null:
		return
	if vault_handle_tween != null:
		vault_handle_tween.kill()
	vault_handle_tween = create_tween()
	vault_handle_tween.tween_property(active_vault_door, "position:x", 8.0, 0.05).as_relative()
	vault_handle_tween.tween_property(active_vault_door, "position:x", -16.0, 0.08).as_relative()
	vault_handle_tween.tween_property(active_vault_door, "position:x", 8.0, 0.05).as_relative()

func _apply_button_state(button: Button, selected: bool, available: bool) -> void:
	if not available:
		button.add_theme_stylebox_override("normal", _panel(Color("#34303a"), Color("#625d67"), 13, 1))
		button.add_theme_color_override("font_color", Color("#aaa4ad"))
	elif selected:
		button.add_theme_stylebox_override("normal", _panel(PARCHMENT, BRASS_LIGHT, 13, 3))
		button.add_theme_color_override("font_color", INK)
	else:
		button.add_theme_stylebox_override("normal", _panel(Color("#403452"), Color("#705e84"), 13, 2))
		button.add_theme_color_override("font_color", PARCHMENT_LIGHT)

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
