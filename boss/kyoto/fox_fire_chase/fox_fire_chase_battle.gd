class_name FoxFireChaseBattle
extends Control

## Host-facing wrapper for 狐火追陣.  The deterministic controller owns rules;
## this node owns touch flow, tutorial presentation, and result signalling.

signal battle_finished(result)
signal coins_spent(amount: int)

const ControllerScript = preload("res://boss/kyoto/fox_fire_chase/fox_fire_chase_controller.gd")
const MAX_HEARTS: int = 3

var _configured := false
var _tutorial_seen := false
var _restored := false
var _pending_result: Variant = null
var _resolving_turn := false
var _rng := RandomNumberGenerator.new()
var _context: Dictionary = {"lap": 1, "coins": 0, "hp": 3, "max_hp": 3}


func _ready() -> void:
	var view := _view()
	var controller := _controller()
	if view == null or controller == null:
		push_error("FoxFireChaseBattle requires Controller and View children.")
		return
	view.bind_controller(controller)
	view.roll_requested.connect(_on_roll_requested)
	view.tutorial_finished.connect(_on_tutorial_finished)
	view.head_start_requested.connect(_on_head_start_requested)
	view.fire_choice_requested.connect(_on_fire_choice_requested)
	view.result_continue_requested.connect(_on_result_continue_requested)
	controller.state_changed.connect(_on_controller_changed)
	controller.phase_changed.connect(_on_controller_changed)
	controller.fire_choice_requested.connect(_on_fire_choice_requested_from_controller)
	controller.battle_finished.connect(_on_controller_battle_finished)
	view.set_player_context(_context)


## Public host contract.  goshuin may be the integer used by the chase rules or
## the Kyoto journey dictionary used by older callers.
func configure_battle(
	lap: int,
	goshuin_count_or_dict: Variant,
	coins: int,
	hp: int,
	max_hp: int,
	seed: int = 0,
	restore_snapshot: Dictionary = {}
) -> bool:
	var controller := _controller()
	if controller == null:
		return false
	var goshuin_count := _goshuin_count(goshuin_count_or_dict)
	var safe_max_hp := clampi(max_hp, 1, MAX_HEARTS)
	_context = {
		"lap": maxi(lap, 1),
		"coins": maxi(coins, 0),
		"hp": clampi(hp, 0, safe_max_hp),
		"max_hp": safe_max_hp,
		"goshuin": goshuin_count,
	}
	_pending_result = null
	_restored = not restore_snapshot.is_empty()
	_rng.seed = seed if seed != 0 else 0xF0CF1E
	var configured_ok := _configure_controller(controller, maxi(lap, 1), goshuin_count, maxi(coins, 0), seed, restore_snapshot)
	if not configured_ok:
		_configured = false
		return false
	_configured = true
	if is_node_ready():
		var view := _view()
		view.set_player_context(_context)
		view.hide_fire_choice()
		view.hide_tutorial()
		view.refresh()
	return true


func start_battle() -> void:
	if not is_node_ready():
		call_deferred("start_battle")
		return
	if not _configured:
		push_warning("FoxFireChaseBattle.start_battle called before configure_battle.")
		return
	var controller := _controller()
	var view := _view()
	var restored_state := controller.get("state") as Object
	if _restored and restored_state != null and int(_state_get(restored_state, "phase", 0)) != ControllerScript.Phase.PRE_BATTLE:
		view.refresh()
		return
	if not _tutorial_seen:
		view.show_tutorial()
		return
	_begin_battle()


func show_for_qa() -> bool:
	if not _configured:
		if not configure_battle(1, 0, 12, MAX_HEARTS, MAX_HEARTS, 0xF0CF1E):
			return false
	_tutorial_seen = true
	_restored = false
	var controller := _controller()
	var state := controller.get("state") as Object
	if state != null and int(_state_get(state, "phase", 0)) == ControllerScript.Phase.PRE_BATTLE:
		var started: Dictionary = controller.call("start_battle")
		if not bool(started.get("ok", false)):
			return false
	_view().refresh()
	return true


func snapshot() -> Dictionary:
	var controller := _controller()
	return {} if controller == null else controller.snapshot()


func set_reduced_motion(enabled: bool) -> void:
	var view := _view()
	if view != null:
		view.set_reduced_motion(enabled)


func _begin_battle() -> void:
	var event: Dictionary = _controller().start_battle()
	if not bool(event.get("ok", false)):
		_view().status_label.text = "追陣を開始できません"
		return
	_view().refresh()


func _on_tutorial_finished() -> void:
	_tutorial_seen = true
	_begin_battle()


func _on_head_start_requested() -> void:
	var event: Dictionary = _controller().buy_head_start()
	if not bool(event.get("ok", false)):
		_view().status_label.text = "先行には3 coin必要"
		return
	coins_spent.emit(3)
	_context["coins"] = maxi(int(_context.get("coins", 0)) - 3, 0)
	_view().set_player_context(_context)
	_view().refresh()


func _on_roll_requested() -> void:
	if _resolving_turn:
		return
	var view := _view()
	var state := _controller().get("state") as Object
	if view == null or state == null:
		return
	var phase := int(_state_get(state, "phase", ControllerScript.Phase.PRE_BATTLE))
	if phase == ControllerScript.Phase.TURN_RESOLVED:
		_controller().call("acknowledge_turn")
		view.refresh()
		return
	if phase != ControllerScript.Phase.ROLL_READY:
		return
	# Two taps mirror the reference artwork: the first starts a readable roll,
	# the second commits a seeded face.  Reduced-motion mode commits immediately.
	if not view.is_die_rolling() and not view.reduced_motion:
		view.begin_die_roll()
		return
	if view.is_die_rolling():
		view.finish_die_roll()
	var cat_start: Variant = state.get("cat_position")
	var fox_start: Variant = state.get("fox_position")
	var face := _rng.randi_range(1, 6)
	_resolving_turn = true
	var event: Dictionary = _controller().commit_face(face)
	if not bool(event.get("ok", false)):
		_resolving_turn = false
		view.status_label.text = "今は出目を決められません"
		return
	event["cat_start"] = cat_start
	event["fox_start"] = fox_start
	view.present_roll(event)
	await view.animate_turn(event)
	_resolving_turn = false
	if _pending_result != null:
		view.show_result(_pending_result as Dictionary if _pending_result is Dictionary else {})
		return
	if str(event.get("status", "")) == "FIRE_CHOICE":
		view.show_fire_choice(int(event.get("pending_fire_index", -1)), int(event.get("goshuin_count", 0)))
	elif str(event.get("status", "")) == "TURN_RESOLVED":
		# Keep the loop immediate for touch play while still showing the resolved
		# path for a frame.  The next roll button acknowledges it if needed.
		view.status_label.text = "白狐も1マス進んだ　次のROLLへ"


func _on_fire_choice_requested(choice: StringName) -> void:
	if _resolving_turn:
		return
	var state := _controller().get("state") as Object
	var cat_start: Variant = state.get("cat_position") if state != null else Vector2i.ZERO
	var fox_start: Variant = state.get("fox_position") if state != null else Vector2i.ZERO
	_resolving_turn = true
	var event: Dictionary = _controller().resolve_fire_choice(choice)
	if not bool(event.get("ok", false)):
		_resolving_turn = false
		_view().status_label.text = "その選択はできません"
		return
	event["cat_start"] = cat_start
	event["fox_start"] = fox_start
	_view().hide_fire_choice()
	_view().present_roll(event)
	await _view().animate_turn(event)
	_resolving_turn = false
	if _pending_result != null:
		_view().show_result(_pending_result as Dictionary if _pending_result is Dictionary else {})


func _on_fire_choice_requested_from_controller(outer_index: int, goshuin_count: int) -> void:
	if not _resolving_turn:
		_view().show_fire_choice(outer_index, goshuin_count)


func _on_controller_changed(_value: Variant = null) -> void:
	if is_node_ready() and _view() != null:
		_view().refresh()


func _on_controller_battle_finished(result: Variant) -> void:
	_pending_result = result
	# Keep the terminal board visible until the movement finishes, then let the
	# result card's explicit action hand control back to the journey host.
	if not _resolving_turn:
		var result_dict := result as Dictionary if result is Dictionary else {}
		_view().show_result(result_dict)


func _on_result_continue_requested() -> void:
	if _pending_result != null:
		var result: Variant = _pending_result
		_pending_result = null
		battle_finished.emit(result)


func _configure_controller(
	controller: Node,
	lap: int,
	goshuin_count: int,
	coins: int,
	seed: int,
	restore_snapshot: Dictionary
) -> bool:
	# Current controller API is kept as the first call for save compatibility.
	# When the rules agent lands the extended host signature, the fallback below
	# keeps this view wrapper usable without coupling UI to its exact arguments.
	var ok := bool(controller.call("configure_battle", lap, goshuin_count, coins, seed, restore_snapshot))
	if ok:
		return true
	return bool(controller.call("configure_battle", lap, goshuin_count, coins, 0, MAX_HEARTS, seed, restore_snapshot))


func _goshuin_count(value: Variant) -> int:
	if value is Dictionary:
		var dictionary := value as Dictionary
		if dictionary.has("count"):
			return maxi(int(dictionary.get("count", 0)), 0)
		var total := 0
		for key: Variant in ["fushimi", "yasaka", "kiyomizu", "tenryuji", "mangan"]:
			if bool(dictionary.get(key, false)):
				total += 1
		return total
	return maxi(int(value), 0)


func _state_get(state: Object, key: String, fallback: Variant) -> Variant:
	var value: Variant = state.get(key)
	return fallback if value == null else value


func _controller() -> Node:
	return get_node_or_null("Controller") as Node


func _view() -> FoxFireChaseView:
	return get_node_or_null("View") as FoxFireChaseView
