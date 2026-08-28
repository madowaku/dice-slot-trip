extends RefCounted
class_name VaultBreakModel

## Pure VAULT BREAK game state. It never touches UI, SaveData, or chip storage;
## the caller charges the wager before `start()` and credits `reward` once.

const RulesScript = preload("res://scripts/game/vault_break/vault_break_rules.gd")

signal roll_started()
signal die_rolled(face: int)
signal placement_required(face: int, valid_indices: Array)
signal die_placed(lock_index: int, face: int)
signal die_discarded(face: int, automatic: bool)
signal game_succeeded()
signal game_failed()
signal state_changed(new_state: int)

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
	"SETUP",
	"READY",
	"ROLLING",
	"WAITING_FOR_PLACEMENT",
	"RESOLVING_PLACEMENT",
	"SUCCESS",
	"FAILURE",
	"RESULT",
	"EXITING",
]
const ACTIVE_GAME_SNAPSHOT_SCHEMA_VERSION := 1
const ACTIVE_GAME_SNAPSHOT_TYPE := "vault_break_active_game"
const RESTORABLE_STATES: Array[int] = [
	State.READY,
	State.ROLLING,
	State.WAITING_FOR_PLACEMENT,
	State.SUCCESS,
	State.FAILURE,
	State.RESULT,
]

var state: int = State.SETUP
var rolls_used := 0
var max_rolls := 0
var current_face := 0
var bet := 0
var payout_multiplier := 0.0
var reward := 0
var result := ""
var discard_count := 0
var last_discard_was_automatic := false

var _template: Dictionary = {}
var _locks: Array[Dictionary] = []
var _placed_faces: Array[int] = []
var _lock_rules: Dictionary = RulesScript.DEFAULT_LOCK_RULES.duplicate(true)
var _rng := RandomNumberGenerator.new()
var _roll_provider := Callable()

func _init() -> void:
	_rng.randomize()

func set_rng(custom_rng: RandomNumberGenerator) -> void:
	if custom_rng != null:
		_rng = custom_rng

func set_roll_provider(provider: Callable) -> void:
	_roll_provider = provider

func set_lock_rules(custom_lock_rules: Dictionary) -> void:
	if custom_lock_rules.is_empty():
		_lock_rules = RulesScript.DEFAULT_LOCK_RULES.duplicate(true)
	else:
		_lock_rules = custom_lock_rules.duplicate(true)

func start(template_data: Dictionary, bet_amount: int = 10, multiplier: float = 1.0) -> bool:
	if state not in [State.SETUP, State.RESULT]:
		return false
	if not RulesScript.is_valid_bet(bet_amount) or multiplier <= 0.0:
		return false
	if not template_data.get("locks") is Array:
		return false
	var template_locks: Array = template_data.get("locks", []) as Array
	var authored_max_rolls := int(template_data.get("max_rolls", 0))
	if template_locks.is_empty() or authored_max_rolls < template_locks.size():
		return false
	for lock_value: Variant in template_locks:
		if not lock_value is Dictionary:
			return false

	_template = template_data.duplicate(true)
	_locks.clear()
	_placed_faces.clear()
	for lock_value: Variant in template_locks:
		_locks.append((lock_value as Dictionary).duplicate(true))
		_placed_faces.append(0)
	rolls_used = 0
	max_rolls = authored_max_rolls
	current_face = 0
	bet = bet_amount
	payout_multiplier = multiplier
	reward = 0
	result = ""
	discard_count = 0
	last_discard_was_automatic = false
	_change_state(State.READY)
	return true

func start_with_tier_config(template_data: Dictionary, bet_amount: int, tier_config: Dictionary) -> bool:
	return start(template_data, bet_amount, float(tier_config.get("payout_multiplier", 0.0)))

## Starts a roll but deliberately remains in ROLLING. The presentation layer
## calls `resolve_rolled_die()` after its animation; tests can call it directly.
func begin_roll(explicit_face: Variant = null) -> int:
	if state != State.READY:
		return 0
	var face := _resolve_roll_face(explicit_face)
	if not RulesScript.is_valid_face(face):
		return 0
	_change_state(State.ROLLING)
	roll_started.emit()
	rolls_used += 1
	current_face = face
	die_rolled.emit(face)
	return face

func roll_die(explicit_face: Variant = null) -> int:
	return begin_roll(explicit_face)

## Returns the valid empty targets. A zero face means the currently rolled die.
func get_valid_empty_lock_indices(face: int = 0) -> Array[int]:
	var checked_face := current_face if face == 0 else face
	var result_indices: Array[int] = []
	if not RulesScript.is_valid_face(checked_face):
		return result_indices
	for index: int in _locks.size():
		if _placed_faces[index] != 0:
			continue
		if RulesScript.accepts_face(_locks[index], checked_face, _lock_rules):
			result_indices.append(index)
	return result_indices

## Resolves target discovery after ROLLING. A no-fit face is automatically
## discarded in the same call; a fitting final roll remains placeable.
func resolve_rolled_die() -> Array[int]:
	if state != State.ROLLING:
		return []
	var valid_indices := get_valid_empty_lock_indices(current_face)
	if not valid_indices.is_empty():
		_change_state(State.WAITING_FOR_PLACEMENT)
		placement_required.emit(current_face, valid_indices.duplicate())
		return valid_indices
	_change_state(State.RESOLVING_PLACEMENT)
	_discard_current(true)
	return []

func finish_roll() -> Array[int]:
	return resolve_rolled_die()

func place_current_die(lock_index: int) -> bool:
	if state != State.WAITING_FOR_PLACEMENT:
		return false
	if lock_index < 0 or lock_index >= _locks.size():
		return false
	if _placed_faces[lock_index] != 0:
		return false
	if not RulesScript.accepts_face(_locks[lock_index], current_face, _lock_rules):
		return false
	_change_state(State.RESOLVING_PLACEMENT)
	var placed_face := current_face
	_placed_faces[lock_index] = placed_face
	current_face = 0
	die_placed.emit(lock_index, placed_face)
	_resolve_turn()
	return true

func discard_current_die() -> bool:
	if state != State.WAITING_FOR_PLACEMENT:
		return false
	_change_state(State.RESOLVING_PLACEMENT)
	_discard_current(false)
	return true

func accepts_face(lock_data: Dictionary, face: int) -> bool:
	return RulesScript.accepts_face(lock_data, face, _lock_rules)

func all_locks_filled() -> bool:
	return not _placed_faces.is_empty() and 0 not in _placed_faces

func filled_lock_count() -> int:
	var count := 0
	for face: int in _placed_faces:
		if face != 0:
			count += 1
	return count

func get_placed_faces() -> Array[int]:
	return _placed_faces.duplicate()

func get_locks() -> Array[Dictionary]:
	return _locks.duplicate(true)

func get_template() -> Dictionary:
	return _template.duplicate(true)

func get_lock_face(lock_index: int) -> int:
	if lock_index < 0 or lock_index >= _placed_faces.size():
		return 0
	return _placed_faces[lock_index]

func get_state_name() -> String:
	return state_name(state)

static func state_name(state_value: int) -> String:
	if state_value < 0 or state_value >= STATE_NAMES.size():
		return "UNKNOWN"
	return STATE_NAMES[state_value]

## Returns a compact JSON-safe snapshot of a started game. SETUP, the
## synchronous RESOLVING_PLACEMENT state, and EXITING are intentionally not
## persistable because none represents a resumable player decision.
func snapshot_active_game() -> Dictionary:
	if state not in RESTORABLE_STATES or _template.is_empty() or _locks.is_empty():
		return {}
	var snapshot_locks: Array[Dictionary] = []
	for lock_data: Dictionary in _locks:
		snapshot_locks.append(_snapshot_lock_config(lock_data))
	var snapshot_tier_config: Dictionary = {
		"lock_count": _locks.size(),
		"max_rolls": max_rolls,
		"payout_multiplier": payout_multiplier,
	}
	var active_snapshot: Dictionary = {
		"schema_version": ACTIVE_GAME_SNAPSHOT_SCHEMA_VERSION,
		"snapshot_type": ACTIVE_GAME_SNAPSHOT_TYPE,
		"game_id": "vault_break",
		"state": state,
		"state_name": state_name(state),
		"template_id": str(_template.get("id", "")),
		"template": {
			"id": str(_template.get("id", "")),
			"tier": str(_template.get("tier", "")),
			"structure_group": str(_template.get("structure_group", "")),
			"max_rolls": max_rolls,
			"locks": snapshot_locks,
		},
		"tier_config": snapshot_tier_config,
		"rolls_used": rolls_used,
		"max_rolls": max_rolls,
		"current_face": current_face,
		"bet": bet,
		"payout_multiplier": payout_multiplier,
		"reward": reward,
		"result": result,
		"discard_count": discard_count,
		"last_discard_was_automatic": last_discard_was_automatic,
		"placed_faces": _placed_faces.duplicate(),
	}
	if not bool(_validate_active_game_snapshot(active_snapshot, _template, snapshot_tier_config).get("valid", false)):
		return {}
	return active_snapshot

## Restores only after validating the complete snapshot against authored data.
## A fresh model should receive the repository template and tier config. A
## model already started with the same authored template may omit both; its
## current template and multiplier then form the validation authority.
func restore_active_game(snapshot: Dictionary, canonical_template: Dictionary = {}, canonical_tier_config: Dictionary = {}) -> bool:
	var validated: Dictionary = _validate_active_game_snapshot(snapshot, canonical_template, canonical_tier_config)
	if not bool(validated.get("valid", false)):
		return false

	var restored_template: Dictionary = validated.get("template", {}) as Dictionary
	var restored_locks: Array = restored_template.get("locks", []) as Array
	var restored_faces: Array[int] = validated.get("placed_faces", []) as Array[int]
	var restored_state: int = int(validated.get("state", State.SETUP))
	var previous_state: int = state
	_template = restored_template.duplicate(true)
	_locks.clear()
	for lock_value: Variant in restored_locks:
		_locks.append((lock_value as Dictionary).duplicate(true))
	_placed_faces = restored_faces.duplicate()
	rolls_used = int(validated.get("rolls_used", 0))
	max_rolls = int(validated.get("max_rolls", 0))
	current_face = int(validated.get("current_face", 0))
	bet = int(validated.get("bet", 0))
	payout_multiplier = float(validated.get("payout_multiplier", 0.0))
	reward = int(validated.get("reward", 0))
	result = str(validated.get("result", ""))
	discard_count = int(validated.get("discard_count", 0))
	last_discard_was_automatic = bool(validated.get("last_discard_was_automatic", false))
	state = restored_state
	if previous_state != state:
		state_changed.emit(state)
	return true

func advance_to_result() -> bool:
	if state not in [State.SUCCESS, State.FAILURE]:
		return false
	_change_state(State.RESULT)
	return true

func reset_to_setup() -> bool:
	if state != State.RESULT:
		return false
	_clear_game()
	_change_state(State.SETUP)
	return true

func exit_game() -> bool:
	if state not in [State.SETUP, State.RESULT]:
		return false
	_change_state(State.EXITING)
	return true

func _discard_current(automatic: bool) -> void:
	var discarded_face := current_face
	current_face = 0
	discard_count += 1
	last_discard_was_automatic = automatic
	die_discarded.emit(discarded_face, automatic)
	_resolve_turn()

func _resolve_turn() -> void:
	if all_locks_filled():
		result = "success"
		reward = RulesScript.reward_for_bet(bet, payout_multiplier)
		_change_state(State.SUCCESS)
		game_succeeded.emit()
		return
	if rolls_used >= max_rolls:
		result = "failure"
		reward = 0
		_change_state(State.FAILURE)
		game_failed.emit()
		return
	_change_state(State.READY)

func _resolve_roll_face(explicit_face: Variant) -> int:
	if typeof(explicit_face) == TYPE_INT or typeof(explicit_face) == TYPE_FLOAT:
		return int(explicit_face)
	if _roll_provider.is_valid():
		var provided: Variant = _roll_provider.call()
		if typeof(provided) == TYPE_INT or typeof(provided) == TYPE_FLOAT:
			return int(provided)
		return 0
	return _rng.randi_range(1, RulesScript.DIE_SIDES)

func _clear_game() -> void:
	_template.clear()
	_locks.clear()
	_placed_faces.clear()
	rolls_used = 0
	max_rolls = 0
	current_face = 0
	bet = 0
	payout_multiplier = 0.0
	reward = 0
	result = ""
	discard_count = 0
	last_discard_was_automatic = false

func _validate_active_game_snapshot(snapshot: Dictionary, canonical_template: Dictionary, canonical_tier_config: Dictionary) -> Dictionary:
	var invalid: Dictionary = {"valid": false}
	if not _is_integer_number(snapshot.get("schema_version")) or int(snapshot.get("schema_version", 0)) != ACTIVE_GAME_SNAPSHOT_SCHEMA_VERSION:
		return invalid
	if str(snapshot.get("snapshot_type", "")) != ACTIVE_GAME_SNAPSHOT_TYPE or str(snapshot.get("game_id", "")) != "vault_break":
		return invalid
	if not _is_integer_number(snapshot.get("state")):
		return invalid
	var restored_state: int = int(snapshot.get("state", State.SETUP))
	if restored_state not in RESTORABLE_STATES or str(snapshot.get("state_name", "")) != state_name(restored_state):
		return invalid

	var authored_template: Dictionary = canonical_template.duplicate(true)
	var expected_multiplier: float = 0.0
	if authored_template.is_empty():
		if _template.is_empty() or payout_multiplier <= 0.0:
			return invalid
		authored_template = _template.duplicate(true)
		expected_multiplier = payout_multiplier
	elif not canonical_tier_config.is_empty():
		if not _is_number(canonical_tier_config.get("payout_multiplier")):
			return invalid
		expected_multiplier = float(canonical_tier_config.get("payout_multiplier", 0.0))
	elif not _template.is_empty() and _templates_match(authored_template, _template) and payout_multiplier > 0.0:
		expected_multiplier = payout_multiplier
	else:
		return invalid
	if expected_multiplier <= 0.0 or not _is_valid_authored_template(authored_template):
		return invalid

	var authored_locks: Array = authored_template.get("locks", []) as Array
	var authored_max_rolls: int = int(authored_template.get("max_rolls", 0))
	if not canonical_tier_config.is_empty():
		if not _is_integer_number(canonical_tier_config.get("lock_count")) or int(canonical_tier_config.get("lock_count", -1)) != authored_locks.size():
			return invalid
		if not _is_integer_number(canonical_tier_config.get("max_rolls")) or int(canonical_tier_config.get("max_rolls", -1)) != authored_max_rolls:
			return invalid

	if not snapshot.get("template") is Dictionary or str(snapshot.get("template_id", "")) != str(authored_template.get("id", "")):
		return invalid
	var snapshot_template: Dictionary = snapshot.get("template", {}) as Dictionary
	if not _snapshot_template_matches(snapshot_template, authored_template):
		return invalid
	if not snapshot.get("tier_config") is Dictionary:
		return invalid
	var snapshot_tier_config: Dictionary = snapshot.get("tier_config", {}) as Dictionary
	if not _is_integer_number(snapshot_tier_config.get("lock_count")) or int(snapshot_tier_config.get("lock_count", -1)) != authored_locks.size():
		return invalid
	if not _is_integer_number(snapshot_tier_config.get("max_rolls")) or int(snapshot_tier_config.get("max_rolls", -1)) != authored_max_rolls:
		return invalid
	if not _is_number(snapshot_tier_config.get("payout_multiplier")) or not is_equal_approx(float(snapshot_tier_config.get("payout_multiplier", 0.0)), expected_multiplier):
		return invalid

	for integer_key: String in ["rolls_used", "max_rolls", "current_face", "bet", "reward", "discard_count"]:
		if not _is_integer_number(snapshot.get(integer_key)):
			return invalid
	if not _is_number(snapshot.get("payout_multiplier")) or not snapshot.get("result") is String or not snapshot.get("last_discard_was_automatic") is bool:
		return invalid
	var restored_rolls_used: int = int(snapshot.get("rolls_used", -1))
	var restored_max_rolls: int = int(snapshot.get("max_rolls", -1))
	var restored_current_face: int = int(snapshot.get("current_face", -1))
	var restored_bet: int = int(snapshot.get("bet", 0))
	var restored_multiplier: float = float(snapshot.get("payout_multiplier", 0.0))
	var restored_reward: int = int(snapshot.get("reward", -1))
	var restored_result: String = str(snapshot.get("result", ""))
	var restored_discard_count: int = int(snapshot.get("discard_count", -1))
	var restored_last_discard_automatic: bool = bool(snapshot.get("last_discard_was_automatic", false))
	if restored_max_rolls != authored_max_rolls or restored_rolls_used < 0 or restored_rolls_used > restored_max_rolls:
		return invalid
	if not RulesScript.is_valid_bet(restored_bet) or not is_equal_approx(restored_multiplier, expected_multiplier):
		return invalid
	if restored_reward < 0 or restored_discard_count < 0 or restored_discard_count > restored_rolls_used:
		return invalid
	if restored_discard_count == 0 and restored_last_discard_automatic:
		return invalid

	if not snapshot.get("placed_faces") is Array:
		return invalid
	var snapshot_faces: Array = snapshot.get("placed_faces", []) as Array
	if snapshot_faces.size() != authored_locks.size():
		return invalid
	var restored_faces: Array[int] = []
	var filled_count: int = 0
	for lock_index: int in authored_locks.size():
		var face_value: Variant = snapshot_faces[lock_index]
		if not _is_integer_number(face_value):
			return invalid
		var placed_face: int = int(face_value)
		if placed_face < 0 or placed_face > RulesScript.DIE_SIDES:
			return invalid
		if placed_face != 0:
			if not RulesScript.accepts_face(authored_locks[lock_index] as Dictionary, placed_face, _lock_rules):
				return invalid
			filled_count += 1
		restored_faces.append(placed_face)

	var has_pending_face: bool = restored_state in [State.ROLLING, State.WAITING_FOR_PLACEMENT]
	var expected_resolved_rolls: int = filled_count + restored_discard_count + (1 if has_pending_face else 0)
	if restored_rolls_used != expected_resolved_rolls:
		return invalid
	var all_filled: bool = filled_count == authored_locks.size()
	var expected_reward: int = RulesScript.reward_for_bet(restored_bet, restored_multiplier)
	match restored_state:
		State.READY:
			if restored_current_face != 0 or restored_rolls_used >= restored_max_rolls or all_filled or restored_reward != 0 or not restored_result.is_empty():
				return invalid
		State.ROLLING:
			if not RulesScript.is_valid_face(restored_current_face) or restored_rolls_used == 0 or all_filled or restored_reward != 0 or not restored_result.is_empty():
				return invalid
		State.WAITING_FOR_PLACEMENT:
			if not RulesScript.is_valid_face(restored_current_face) or restored_rolls_used == 0 or all_filled or restored_reward != 0 or not restored_result.is_empty():
				return invalid
			if _valid_empty_indices_for(authored_locks, restored_faces, restored_current_face).is_empty():
				return invalid
		State.SUCCESS:
			if restored_current_face != 0 or not all_filled or restored_result != "success" or restored_reward != expected_reward:
				return invalid
		State.FAILURE:
			if restored_current_face != 0 or all_filled or restored_rolls_used != restored_max_rolls or restored_result != "failure" or restored_reward != 0:
				return invalid
		State.RESULT:
			if restored_current_face != 0:
				return invalid
			if restored_result == "success":
				if not all_filled or restored_reward != expected_reward:
					return invalid
			elif restored_result == "failure":
				if all_filled or restored_rolls_used != restored_max_rolls or restored_reward != 0:
					return invalid
			else:
				return invalid

	return {
		"valid": true,
		"template": authored_template,
		"state": restored_state,
		"rolls_used": restored_rolls_used,
		"max_rolls": restored_max_rolls,
		"current_face": restored_current_face,
		"bet": restored_bet,
		"payout_multiplier": restored_multiplier,
		"reward": restored_reward,
		"result": restored_result,
		"discard_count": restored_discard_count,
		"last_discard_was_automatic": restored_last_discard_automatic,
		"placed_faces": restored_faces,
	}

func _snapshot_template_matches(snapshot_template: Dictionary, authored_template: Dictionary) -> bool:
	if str(snapshot_template.get("id", "")) != str(authored_template.get("id", "")):
		return false
	if str(snapshot_template.get("tier", "")) != str(authored_template.get("tier", "")):
		return false
	if str(snapshot_template.get("structure_group", "")) != str(authored_template.get("structure_group", "")):
		return false
	if not _is_integer_number(snapshot_template.get("max_rolls")) or int(snapshot_template.get("max_rolls", -1)) != int(authored_template.get("max_rolls", 0)):
		return false
	if not snapshot_template.get("locks") is Array:
		return false
	var snapshot_locks: Array = snapshot_template.get("locks", []) as Array
	var authored_locks: Array = authored_template.get("locks", []) as Array
	if snapshot_locks.size() != authored_locks.size():
		return false
	for lock_index: int in authored_locks.size():
		if not snapshot_locks[lock_index] is Dictionary:
			return false
		if not _lock_configs_match(snapshot_locks[lock_index] as Dictionary, authored_locks[lock_index] as Dictionary):
			return false
	return true

func _templates_match(left: Dictionary, right: Dictionary) -> bool:
	var compact_left: Dictionary = {
		"id": str(left.get("id", "")),
		"tier": str(left.get("tier", "")),
		"structure_group": str(left.get("structure_group", "")),
		"max_rolls": int(left.get("max_rolls", 0)),
		"locks": left.get("locks", []),
	}
	return _snapshot_template_matches(compact_left, right)

func _lock_configs_match(left: Dictionary, right: Dictionary) -> bool:
	var left_rule: String = str(left.get("rule", ""))
	var right_rule: String = str(right.get("rule", ""))
	if left_rule != right_rule or left_rule.is_empty():
		return false
	if left_rule == "exact":
		return _is_integer_number(left.get("value")) and _is_integer_number(right.get("value")) and int(left.get("value", 0)) == int(right.get("value", 0))
	return not left.has("value") and not right.has("value")

func _is_valid_authored_template(authored_template: Dictionary) -> bool:
	if str(authored_template.get("id", "")).is_empty() or not authored_template.get("locks") is Array:
		return false
	var authored_locks: Array = authored_template.get("locks", []) as Array
	var authored_max_rolls: int = int(authored_template.get("max_rolls", 0))
	if authored_locks.is_empty() or authored_max_rolls < authored_locks.size():
		return false
	for lock_value: Variant in authored_locks:
		if not lock_value is Dictionary:
			return false
		var lock_data: Dictionary = lock_value as Dictionary
		var rule_name: String = str(lock_data.get("rule", ""))
		if rule_name == "exact":
			if not _is_integer_number(lock_data.get("value")) or not RulesScript.is_valid_face(int(lock_data.get("value", 0))):
				return false
		elif not _lock_rules.has(rule_name):
			return false
	return true

func _valid_empty_indices_for(authored_locks: Array, restored_faces: Array[int], checked_face: int) -> Array[int]:
	var result_indices: Array[int] = []
	for lock_index: int in authored_locks.size():
		if restored_faces[lock_index] == 0 and RulesScript.accepts_face(authored_locks[lock_index] as Dictionary, checked_face, _lock_rules):
			result_indices.append(lock_index)
	return result_indices

func _snapshot_lock_config(lock_data: Dictionary) -> Dictionary:
	var compact: Dictionary = {"rule": str(lock_data.get("rule", ""))}
	if str(lock_data.get("rule", "")) == "exact":
		compact["value"] = int(lock_data.get("value", 0))
	return compact

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _is_integer_number(value: Variant) -> bool:
	if not _is_number(value):
		return false
	return is_equal_approx(float(value), float(int(value)))

func _change_state(next_state: int) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state)
