class_name FoxFireSixRoutesBattle
extends Control

## Integration wrapper for the Kyoto "Fox Fire Six Routes" boss.
##
## The wrapper owns presentation flow and forwards input to the controller. The
## view only reads controller state; neither this script nor the view mutates it.

signal battle_finished(result)
signal slot_role_completed(role: String)

const ControllerScript = preload("res://boss/kyoto/fox_fire_six_routes/fox_fire_six_routes_controller.gd")
const MAX_HEARTS: int = 3

var _configured: bool = false
var _restored: bool = false
var _tutorial_seen: bool = false
var _resolving_turn: bool = false
var _pending_result: Variant = null
var _context: Dictionary = {
	"lap": 1,
	"coins": 0,
	"hp": MAX_HEARTS,
	"max_hp": MAX_HEARTS,
}


func _ready() -> void:
	var controller := _controller()
	var view := _view()
	if controller == null or view == null:
		push_error("FoxFireSixRoutesBattle requires Controller and View children.")
		return
	view.bind_controller(controller)
	view.cell_pressed.connect(_on_cell_pressed)
	view.roll_requested.connect(_on_roll_requested)
	view.undo_requested.connect(_on_undo_requested)
	view.path_confirm_requested.connect(_on_path_confirm_requested)
	view.miss_requested.connect(_on_miss_requested)
	view.tutorial_finished.connect(_on_tutorial_finished)
	view.start_torii_selected.connect(_on_start_torii_selected)
	view.result_continue_requested.connect(_on_result_continue_requested)
	view.mangan_requested.connect(_on_mangan_requested)
	view.kiyomizu_requested.connect(_on_kiyomizu_requested)
	view.tenryuji_shift_requested.connect(_on_tenryuji_shift_requested)
	view.special_cell_selected.connect(_on_special_cell_selected)
	view.special_skip_requested.connect(_on_special_skip_requested)
	controller.phase_changed.connect(_on_controller_changed)
	controller.move_steps_changed.connect(_on_controller_changed)
	controller.remaining_steps_changed.connect(_on_controller_changed)
	controller.reachable_endpoints_changed.connect(_on_controller_changed)
	controller.fox_preview_changed.connect(_on_controller_changed)
	controller.seal_completed.connect(_on_seal_completed)
	controller.white_fire_changed.connect(_on_controller_changed)
	controller.line_cut_changed.connect(_on_line_cut_changed)
	controller.special_requested.connect(_on_special_requested)
	controller.battle_finished.connect(_on_controller_battle_finished)
	view.set_player_context(_context)
	if _configured:
		view.refresh()


## Main product integration entry point. External HP/coins remain host-owned and
## are display context only; battle rules never write them.
func configure_battle(
		lap: int,
		goshuin: Dictionary,
		coins: int,
		hp: int,
		max_hp: int,
		seed: int = 0,
		restore_snapshot: Dictionary = {}
	) -> bool:
	var controller := _controller()
	if controller == null:
		return false
	var safe_max_hp := clampi(max_hp, 1, MAX_HEARTS)
	_context = {
		"lap": maxi(lap, 1),
		"coins": maxi(coins, 0),
		"hp": clampi(hp, 0, safe_max_hp),
		"max_hp": safe_max_hp,
	}
	_pending_result = null
	_resolving_turn = false
	_restored = not restore_snapshot.is_empty()
	var configured_ok: bool = controller.configure(maxi(lap, 1), goshuin, seed)
	if not configured_ok:
		_configured = false
		return false
	if _restored and not controller.restore_snapshot(restore_snapshot):
		_configured = false
		return false
	_configured = true
	if is_node_ready():
		var view := _view()
		view.set_player_context(_context)
		view.reset_presentation()
		view.refresh()
	return true


## Starts the configured battle. A restored in-progress snapshot resumes in
## place. A fresh battle shows the concise three-step tutorial once.
func start_battle() -> void:
	if not is_node_ready():
		call_deferred("start_battle")
		return
	if not _configured:
		push_warning("FoxFireSixRoutesBattle.start_battle called before configure_battle.")
		return
	var controller := _controller()
	var view := _view()
	if _restored and controller.state.phase not in [
		ControllerScript.BattlePhase.INTRO,
		ControllerScript.BattlePhase.PRE_BATTLE,
	]:
		view.refresh()
		return
	if not _tutorial_seen:
		view.show_tutorial()
		return
	_begin_configured_battle()


## Returns the controller-owned deterministic snapshot. Host HP and coins are
## deliberately supplied again through configure_battle on restore.
func snapshot() -> Dictionary:
	var controller := _controller()
	return {} if controller == null else controller.snapshot()


## Deterministic scene harness. Skips tutorial and can enter PATH_INPUT with an
## exact move value without reaching into controller state.
func show_for_qa(move_steps: int = 0) -> bool:
	if not _configured:
		if not configure_battle(1, {}, 0, MAX_HEARTS, MAX_HEARTS, 0xF06F1E):
			return false
	_tutorial_seen = true
	_restored = false
	var controller := _controller()
	if controller.state.phase in [
		ControllerScript.BattlePhase.INTRO,
		ControllerScript.BattlePhase.PRE_BATTLE,
	]:
		var start_event: Dictionary = controller.start_battle()
		if not bool(start_event.get("ok", false)):
			return false
	if move_steps > 0 and controller.state.phase == ControllerScript.BattlePhase.ROLL_SLOT:
		var roll_event: Dictionary = controller.set_move_steps_for_test(clampi(move_steps, 1, 6))
		if not bool(roll_event.get("ok", false)):
			return false
		_view().present_roll(roll_event)
	_view().dismiss_all_modals()
	_view().refresh()
	return true


## QA/readability helpers. They do not alter battle state.
func board_cell_center(position: Vector2i) -> Vector2:
	var view := _view()
	return Vector2.ZERO if view == null else view.board_cell_center(position)


func cell_touch_rect(position: Vector2i) -> Rect2:
	var view := _view()
	return Rect2() if view == null else view.cell_touch_rect(position)


func set_reduced_motion(enabled: bool) -> void:
	var view := _view()
	if view != null:
		view.set_reduced_motion(enabled)


func _begin_configured_battle() -> void:
	var controller := _controller()
	var view := _view()
	var yasaka_activates := false
	if controller.state.phase == ControllerScript.BattlePhase.PRE_BATTLE:
		if controller.state.fushimi_start_choice_available:
			view.show_start_choice()
			return
		view.set_white_fire_guide_deferred(true)
		yasaka_activates = controller.state.yasaka_delay_available
		var event: Dictionary = controller.start_battle()
		if not bool(event.get("ok", false)):
			view.set_white_fire_guide_deferred(false)
			view.show_banner("戦闘を開始できません", true)
	if controller.state.phase == ControllerScript.BattlePhase.ROLL_SLOT:
		view.show_torii_rule_guide()
		view.set_white_fire_guide_deferred(false)
		if yasaka_activates:
			view.play_blessing_activation("yasaka", "八坂のご加護", "最初の狐火を1回遅らせた")
	else:
		view.set_white_fire_guide_deferred(false)
		view.refresh()


func _on_tutorial_finished() -> void:
	_tutorial_seen = true
	_begin_configured_battle()


func _on_start_torii_selected(torii_id: int) -> void:
	var controller := _controller()
	if controller.choose_start_torii(torii_id):
		var torii_labels: Array[String] = ["A", "B", "C", "D"]
		var selected_label := torii_labels[clampi(torii_id, 0, torii_labels.size() - 1)]
		_view().hide_start_choice()
		_view().set_white_fire_guide_deferred(true)
		var yasaka_activates := controller.state.yasaka_delay_available
		var event: Dictionary = controller.start_battle()
		if not bool(event.get("ok", false)):
			_view().set_white_fire_guide_deferred(false)
			_view().show_banner("戦闘を開始できません", true)
		if _controller().state.phase == ControllerScript.BattlePhase.ROLL_SLOT:
			_view().show_torii_rule_guide()
			_view().set_white_fire_guide_deferred(false)
			_view().play_blessing_activation("fushimi", "伏見稲荷のご加護", "%sの鳥居から開始" % selected_label)
			if yasaka_activates:
				_view().play_blessing_activation("yasaka", "八坂のご加護", "最初の狐火を1回遅らせた")
		else:
			_view().set_white_fire_guide_deferred(false)
			_view().refresh()
			_view().play_blessing_activation("fushimi", "伏見稲荷のご加護", "%sの鳥居から開始" % selected_label)
			if yasaka_activates:
				_view().play_blessing_activation("yasaka", "八坂のご加護", "最初の狐火を1回遅らせた")


func _on_roll_requested() -> void:
	if _resolving_turn:
		return
	var view := _view()
	if view.is_die_rolling():
		view.finish_die_roll()
	else:
		if view.begin_die_roll():
			view.show_banner("サイコロ回転中　もう一度タップで止める", false)
		return
	var event: Dictionary = _controller().roll_move()
	if not bool(event.get("ok", false)):
		view.show_banner("今は出目を決められません", true)
		return
	view.present_roll(event)
	var completed_role := str(event.get("slot_role", ""))
	if completed_role in ["PAIR", "STRAIGHT", "TRIPLE"] and (event.get("slot_faces", []) as Array).size() == 3:
		slot_role_completed.emit(completed_role)
	view.refresh()
	if str(event.get("status", "")) == "NO_ROUTE":
		view.show_banner("この出目では道を引けない！", true)


func _on_cell_pressed(position: Vector2i) -> void:
	if _resolving_turn:
		return
	var event: Dictionary = _controller().press_cell(position)
	if bool(event.get("ok", false)):
		_view().refresh()


func _on_undo_requested() -> void:
	if _resolving_turn:
		return
	var event: Dictionary = _controller().undo_path()
	if bool(event.get("ok", false)):
		_view().refresh()


func _on_path_confirm_requested() -> void:
	if _resolving_turn:
		return
	var event: Dictionary = _controller().confirm_path()
	if not bool(event.get("ok", false)):
		_view().show_banner("出目ぶんの道を完成させよう", true)
		return
	_resolving_turn = true
	var view := _view()
	view.show_banner("猫が選んだ道を進んでいます", false)
	# Start the coroutine before refresh so it marks the cat as animating. The
	# controller has already committed the endpoint; refreshing first would snap
	# the sprite there, then teleport it back when the tween begins.
	view.animate_cat_path(event.get("path", []) as Array, _on_cat_animation_finished)
	view.refresh()


func _on_cat_animation_finished() -> void:
	var event: Dictionary = _controller().finish_cat_movement()
	_view().refresh()
	if bool(event.get("seal_completed", false)):
		_view().show_banner("封印！　結界が金色に変わった", false)
	if _controller().state.phase == ControllerScript.BattlePhase.SPECIAL_RESOLVE:
		_view().refresh()
	elif _controller().state.phase == ControllerScript.BattlePhase.FOX_ACTION:
		_resolve_fox_turn.call_deferred()
	else:
		_resolving_turn = false


func _on_miss_requested() -> void:
	if _resolving_turn:
		return
	var event: Dictionary = _controller().resolve_miss()
	if not bool(event.get("ok", false)):
		return
	_resolving_turn = true
	_view().show_banner("MISS　猫はその場にとどまった", true)
	_view().refresh()
	_resolve_fox_turn.call_deferred()


func _resolve_fox_turn() -> void:
	var view := _view()
	var delay: float = view.resolution_delay()
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self):
		return
	if _controller().state.phase != ControllerScript.BattlePhase.FOX_ACTION:
		_resolving_turn = false
		return
	var event: Dictionary = _controller().resolve_fox_action()
	view.refresh()
	if bool(event.get("mangan_skipped", false)):
		view.play_blessing_activation("mangan", "満願札 発動！", "白狐の狐火を完全に防いだ")
	elif bool(event.get("block_seal_bonus", false)):
		view.show_banner("街区封印！　白狐の一手を封じた", false)
	elif not str(event.get("line_cut_edge", "")).is_empty():
		view.show_banner("白狐が道を一筋、断ち切った", true)
	elif not (event.get("placed_cells", []) as Array).is_empty():
		view.show_banner("白狐の狐火が道を塞いだ", true)
	if _controller().state.phase == ControllerScript.BattlePhase.TURN_END:
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
		if is_instance_valid(self) and _controller().state.phase == ControllerScript.BattlePhase.TURN_END:
			_controller().finish_turn()
			view.refresh()
	_resolving_turn = false


func _on_mangan_requested() -> void:
	if _controller().arm_mangan():
		_view().play_blessing_activation("mangan", "満願札を構えた", "次の白狐行動を1回無効にする")
		_view().refresh()


func _on_kiyomizu_requested() -> void:
	if not _controller().use_kiyomizu_reroll():
		return
	_view().play_blessing_activation("kiyomizu", "清水寺のご加護", "3つのサイコロをすべて振り直す")
	_on_roll_requested()


func _on_tenryuji_shift_requested(delta: int) -> void:
	var before := _controller().state.move_steps
	var event: Dictionary = _controller().apply_tenryuji_shift(delta)
	if bool(event.get("ok", false)):
		_view().play_blessing_activation("tenryuji", "天龍寺のご加護", "出目 %d → %d" % [before, _controller().state.move_steps])
		_view().refresh()


func _on_special_cell_selected(position: Vector2i) -> void:
	if not _resolving_turn:
		return
	var event := _controller().purify_white_fire(position)
	if not bool(event.get("ok", false)):
		return
	_view().hide_special_choice()
	_view().show_banner("桜守　狐火をひとつ浄化した", false)
	_view().refresh()
	_resolve_fox_turn.call_deferred()


func _on_special_skip_requested() -> void:
	if not _resolving_turn:
		return
	var event := _controller().skip_special_resolution()
	if not bool(event.get("ok", false)):
		return
	_view().hide_special_choice()
	_view().refresh()
	_resolve_fox_turn.call_deferred()


func _on_controller_changed(_value: Variant = null) -> void:
	if is_node_ready() and _view() != null:
		_view().refresh()


func _on_special_requested(_kind: StringName, options: Array[Vector2i]) -> void:
	if is_node_ready() and _view() != null:
		_view().show_special_choice(options)


func _on_line_cut_changed(_edge_key: String) -> void:
	if is_node_ready() and _view() != null:
		_view().refresh()


func _on_seal_completed(_count: int) -> void:
	_on_controller_changed()


func _on_controller_battle_finished(result: Variant) -> void:
	_pending_result = result
	_resolving_turn = false
	_view().refresh()
	_view().show_result(result)


func _on_result_continue_requested() -> void:
	if _pending_result == null:
		return
	var result: Variant = _pending_result
	_pending_result = null
	battle_finished.emit(result)


func _controller() -> FoxFireSixRoutesController:
	return get_node_or_null("Controller") as FoxFireSixRoutesController


func _view() -> FoxFireSixRoutesView:
	return get_node_or_null("View") as FoxFireSixRoutesView
