extends Node

const DEFAULT_STAGE: StringName = &"cairo_hourglass"
const DEFAULT_CHARACTER: StringName = &"relaxed"
const DEFAULT_LANDMARK_LEVELS: Dictionary = {
	"CAI_LANDMARK_01": 0,
	"CAI_LANDMARK_02": 0,
	"CAI_LANDMARK_03": 0,
}
const BossSystemScript = preload("res://scripts/game/boss_system.gd")
const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")

var selected_stage_id: StringName = DEFAULT_STAGE
var selected_character_id: StringName = DEFAULT_CHARACTER
var current_tile_index: int = 0
var lap_count: int = 0
var rolls_used: int = 0
var coins: int = 12
var souvenirs: int = 0
var boss_presence: int = 0
var boss_bond: float = 0.0
var boss_relief: int = 0
var current_boss: Dictionary = {}
var encyclopedia: Array[Dictionary] = []
var boss_sequence: int = 1
var debug_force_encounter: bool = false
var fixed_rolls: Array[int] = []
var travel_memos: Array[String] = []
var lap_stamps: Array[String] = []
var inventory: Dictionary = {"pinpoint": 2, "fever": 2}
var event_history: Array[Dictionary] = []
var seen_event_ids: Array[String] = []
var recent_event_ids: Array[String] = []
var events_seen_this_loop: Array[String] = []
var rare_event_used_this_loop: bool = false
var events_since_rare: int = 99
var active_event_state: Dictionary = {}
var pending_event_rewards: Array[Dictionary] = []
var pending_boss_handoff: bool = false
var registered_travel_notes: Array[String] = []
var registered_postcards: Array[String] = []
var applied_resolution_ids: Array[String] = []
var next_interaction_bonus: int = 0
var next_move_bonus: int = 0
var skill_recovery: int = 0
var map_highlight: String = ""
var character_skill_charge: int = 1
var debug_forced_event_id: String = ""
var debug_fixed_extra_rolls: Array[int] = []
var debug_boss_handoff_enabled: bool = true
var reward_apply_log: Array = []
## Temporary base dice state. Event-only 1/3/5 rolls never mutate this value.
var current_dice_count: int = 1
var dice_keep_active: bool = false
var dice_double_retry_active: bool = false
var dice_slot_retry_active: bool = false
var pending_dice_rewards: Array[Dictionary] = []
var temporary_roll_dice_count: int = 0
var dice_slot_chain_count: int = 0
var last_roll_dice_count: int = 0
var master_volume: float = 1.0
var se_volume: float = 1.0
var dice_se_muted: bool = false

## TOURMAP-03B durable roll transaction.  Visual positions are intentionally
## omitted; only gameplay facts needed to resume after an app restart persist.
var roll_transaction: Dictionary = {}

# LAP/CLEAN state remains in save v6; FLOW fields stay neutral until its own
# implementation slice.
var total_lap_points: int = 0
var current_lap_bonus: int = 0
var current_lap_roll_count: int = 0
var current_lap_clean: bool = true
var current_lap_penalty_count: int = 0
var clean_streak: int = 0
var flow_level: int = 0
var flow_triggered_this_turn: bool = false
var flow_reward_3_claimed_this_lap: bool = false
var flow_reward_5_claimed_this_lap: bool = false
var even_guard_active: bool = false
var best_lap_score: int = 0
var best_clean_streak: int = 0
var best_flow_level: int = 0
var total_laps: int = 0
var highest_laps_in_one_journey: int = 0
var pending_lap_rewards: Array[Dictionary] = []
var lap_resolution_id: String = ""
var lap_reward_committed: bool = false
var last_lap_result: Dictionary = {}

# LANDMARK-01. Collection/revisit behavior is intentionally deferred, but the
# v6 neutral fields keep later additions backward compatible.
var landmark_levels: Dictionary = DEFAULT_LANDMARK_LEVELS.duplicate(true)
var landmark_revisit_stamps: Dictionary = {}
var landmark_collection_flags: Dictionary = {}
var landmark_completion_flags: Dictionary = {}
var stage_development: int = 0
var stage_development_milestones_claimed: Array[int] = []
var stage_collection_count: int = 0
var stage_collection_completed: bool = false
var pending_landmark_rewards: Array[Dictionary] = []
var landmark_resolution_id: String = ""
var landmark_reward_committed: bool = false

## Transitional code compatibility; v5 saves only current_dice_count.
var unlocked_dice_count: int:
	get: return current_dice_count
	set(value): current_dice_count = clampi(value, 1, 3)

func start_new_game() -> void:
	reset_run()

func unlock_dice(step: int = 1) -> int:
	# Compatibility method for v4 call sites. New code should use add_dice().
	return add_dice(step)

func add_dice(step: int = 1) -> int:
	var before := clampi(current_dice_count, 1, 3)
	var gained := maxi(0, step)
	current_dice_count = mini(3, before + gained)
	var overflow := maxi(0, before + gained - 3)
	if overflow > 0:
		coins = mini(99999, coins + 12 * overflow)
	return current_dice_count

func apply_dice_roll_transition(rolled_dice_count: int, roles: Dictionary) -> Dictionary:
	last_roll_dice_count = rolled_dice_count
	var transition: Dictionary = DiceLogicScript.next_dice_state(rolled_dice_count, roles, dice_keep_active, dice_double_retry_active, dice_slot_retry_active)
	# A temporary roll is deliberately a no-op for the base state.
	if rolled_dice_count in [1, 2, 3]:
		current_dice_count = clampi(int(transition.get("count", current_dice_count)), 1, 3)
	if bool(transition.get("consume_keep", false)): dice_keep_active = false
	if bool(transition.get("consume_double_retry", false)): dice_double_retry_active = false
	if bool(transition.get("consume_slot_retry", false)): dice_slot_retry_active = false
	dice_slot_chain_count = dice_slot_chain_count + 1 if bool(transition.get("slot_continues", false)) else 0
	return transition

func reset_run() -> void:
	current_tile_index = 0
	lap_count = 0
	rolls_used = 0
	coins = 12
	souvenirs = 0
	boss_presence = 0
	boss_relief = 0
	travel_memos.clear()
	lap_stamps.clear()
	inventory = {"pinpoint": 2, "fever": 2}
	events_seen_this_loop.clear()
	rare_event_used_this_loop = false
	events_since_rare = 99
	active_event_state.clear()
	pending_event_rewards.clear()
	pending_boss_handoff = false
	next_move_bonus = 0
	character_skill_charge = 1
	current_dice_count = 1
	dice_keep_active = false
	dice_double_retry_active = false
	dice_slot_retry_active = false
	pending_dice_rewards.clear()
	temporary_roll_dice_count = 0
	dice_slot_chain_count = 0
	last_roll_dice_count = 0
	current_lap_bonus = 0
	current_lap_roll_count = 0
	current_lap_clean = true
	current_lap_penalty_count = 0
	even_guard_active = false
	flow_triggered_this_turn = false
	flow_reward_3_claimed_this_lap = false
	flow_reward_5_claimed_this_lap = false
	last_lap_result.clear()
	roll_transaction.clear()
	ensure_boss_data()

func begin_roll_transaction(values: Array, dice_count: int, start_tile: int) -> bool:
	if not roll_transaction.is_empty():
		return false
	var transaction_id := "roll:%08d:%d" % [rolls_used, Time.get_ticks_msec()]
	var normalized_start := posmod(start_tile, 90)
	roll_transaction = {
		"phase": "PRE_ROLL",
		"roll_phase": "PRE_ROLL",
		"transaction_id": transaction_id,
		"roll_id": transaction_id,
		"roll_transaction_id": transaction_id,
		"values": values.duplicate(),
		"final_dice_values": [],
		"dice_count": clampi(dice_count, 1, 5),
		"start_tile_index": normalized_start,
		"start_tile": normalized_start,
		"target_tile_index": -1,
		"result_committed": false,
		"movement_committed": false,
		"space_effect_committed": false,
		"landing_roles_committed": false,
		"landing_core_committed": false,
		"early_stopped": false,
		"encounter_phase": "NONE",
		# These are gameplay inputs, not presentation state. They make an
		# interrupted PRE_ROLL/ROLLING rollback future-proof if consumption is
		# ever moved earlier in the animation pipeline.
		"pre_roll_current_dice_count": current_dice_count,
		"pre_roll_temporary_roll_dice_count": temporary_roll_dice_count,
	}
	return true

func mark_roll_started(values: Array) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "PRE_ROLL":
		return false
	roll_transaction["phase"] = "ROLLING"
	roll_transaction["roll_phase"] = "ROLLING"
	roll_transaction["values"] = values.duplicate()
	return true

func commit_roll_result(values: Array, dice_count: int, roles: Dictionary, distance: int, destination: int, crossed_laps: int, early_stopped: bool) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) not in ["PRE_ROLL", "ROLLING"]:
		return false
	roll_transaction["phase"] = "RESULT_COMMITTED"
	roll_transaction["roll_phase"] = "RESULT_COMMITTED"
	roll_transaction["values"] = values.duplicate()
	roll_transaction["final_dice_values"] = values.duplicate()
	roll_transaction["dice_count"] = clampi(dice_count, 1, 5)
	roll_transaction["roles"] = roles.duplicate(true)
	roll_transaction["role_result"] = roles.duplicate(true)
	roll_transaction["distance"] = maxi(0, distance)
	roll_transaction["destination"] = posmod(destination, 90)
	roll_transaction["target_tile_index"] = posmod(destination, 90)
	roll_transaction["crossed_laps"] = maxi(0, crossed_laps)
	roll_transaction["result_committed"] = true
	roll_transaction["early_stopped"] = early_stopped
	return true

func commit_roll_movement(destination: int) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "RESULT_COMMITTED":
		return false
	roll_transaction["phase"] = "MOVEMENT_COMMITTED"
	roll_transaction["roll_phase"] = "MOVEMENT_COMMITTED"
	roll_transaction["destination"] = posmod(destination, 90)
	roll_transaction["target_tile_index"] = posmod(destination, 90)
	roll_transaction["movement_committed"] = true
	return true

func commit_roll_space_effect() -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	roll_transaction["phase"] = "SPACE_EFFECT_COMMITTED"
	roll_transaction["roll_phase"] = "SPACE_EFFECT_COMMITTED"
	roll_transaction["space_effect_committed"] = true
	return true

func commit_roll_landing_roles() -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if bool(roll_transaction.get("landing_roles_committed", false)):
		return false
	roll_transaction["landing_roles_committed"] = true
	return true

func commit_roll_landing_core(tile_type: StringName, memo: String) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if bool(roll_transaction.get("landing_core_committed", false)):
		return false
	roll_transaction["landing_core_committed"] = true
	roll_transaction["landing_tile_type"] = String(tile_type)
	roll_transaction["landing_memo"] = memo
	return true

func mark_roll_turn_resolved() -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "SPACE_EFFECT_COMMITTED":
		return false
	roll_transaction["phase"] = "TURN_RESOLVED"
	roll_transaction["roll_phase"] = "TURN_RESOLVED"
	return true

func mark_roll_encounter_handoff(pair_bonus: bool, double_bonus: int) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if str(roll_transaction.get("encounter_phase", "NONE")) != "NONE":
		return false
	roll_transaction["encounter_phase"] = "HANDOFF_PENDING"
	roll_transaction["encounter_pair_bonus"] = pair_bonus
	roll_transaction["encounter_double_bonus"] = maxi(0, double_bonus)
	return true

func mark_roll_encounter_open(pair_bonus: bool, double_bonus: int) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	var encounter_phase := str(roll_transaction.get("encounter_phase", "NONE"))
	if encounter_phase not in ["NONE", "HANDOFF_PENDING"]:
		return false
	roll_transaction["encounter_phase"] = "MODAL_OPEN"
	roll_transaction["encounter_pair_bonus"] = pair_bonus
	roll_transaction["encounter_double_bonus"] = maxi(0, double_bonus)
	return true

func commit_roll_encounter_interaction(joined_now: bool, definition_id: String) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if str(roll_transaction.get("encounter_phase", "NONE")) != "MODAL_OPEN":
		return false
	roll_transaction["encounter_phase"] = "INTERACTION_COMMITTED"
	roll_transaction["encounter_joined_now"] = joined_now
	roll_transaction["encounter_definition_id"] = definition_id
	return true

func commit_roll_encounter_registration(obtained: Dictionary) -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if str(roll_transaction.get("encounter_phase", "NONE")) != "INTERACTION_COMMITTED" or not bool(roll_transaction.get("encounter_joined_now", false)):
		return false
	roll_transaction["encounter_phase"] = "REGISTRATION_COMMITTED"
	roll_transaction["encounter_obtained"] = obtained.duplicate(true)
	return true

func complete_roll_encounter() -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) != "MOVEMENT_COMMITTED":
		return false
	if str(roll_transaction.get("encounter_phase", "NONE")) not in ["INTERACTION_COMMITTED", "REGISTRATION_COMMITTED"]:
		return false
	roll_transaction["encounter_phase"] = "COMPLETE"
	return true

func rollback_uncommitted_roll() -> bool:
	if roll_transaction.is_empty() or str(roll_transaction.get("phase", "")) not in ["PRE_ROLL", "ROLLING"]:
		return false
	current_dice_count = clampi(int(roll_transaction.get("pre_roll_current_dice_count", current_dice_count)), 1, 3)
	temporary_roll_dice_count = maxi(0, int(roll_transaction.get("pre_roll_temporary_roll_dice_count", temporary_roll_dice_count)))
	roll_transaction.clear()
	return true

func clear_roll_transaction() -> void:
	roll_transaction.clear()

func ensure_boss_data() -> void:
	if current_boss.is_empty():
		current_boss = BossSystemScript.initial_individual(boss_sequence)
		boss_sequence += 1
	current_boss["gauge"] = clampi(int(current_boss.get("gauge", boss_bond)), 0, 100)
	current_boss["stage"] = BossSystemScript.stage_for_gauge(int(current_boss["gauge"]))
	boss_bond = float(current_boss["gauge"])

func register_current_boss() -> bool:
	ensure_boss_data()
	if bool(current_boss.get("got", false)):
		return false
	for entry: Dictionary in encyclopedia:
		if str(entry.get("individual_id", "")) == str(current_boss.get("individual_id", "")):
			current_boss["got"] = true
			return false
	current_boss["got"] = true
	current_boss["gauge"] = 100
	current_boss["stage"] = "joined"
	current_boss["registration_order"] = encyclopedia.size() + 1
	current_boss["registered_at"] = Time.get_datetime_string_from_system()
	encyclopedia.append(current_boss.duplicate(true))
	boss_bond = 100.0
	return true

func begin_next_boss() -> void:
	ensure_boss_data()
	var old_name := str(current_boss.get("name", ""))
	current_boss = BossSystemScript.next_individual(old_name, boss_sequence)
	boss_sequence += 1
	boss_bond = 0.0
	boss_presence = 0
	boss_relief = 0

func to_dictionary() -> Dictionary:
	ensure_boss_data()
	return {
		"version": 6,
		"stage_id": String(selected_stage_id),
		"character_id": String(selected_character_id),
		"tile": current_tile_index,
		"laps": lap_count,
		"rolls": rolls_used,
		"coins": coins,
		"souvenirs": souvenirs,
		"presence": boss_presence,
		"bond": boss_bond,
		"boss_relief": boss_relief,
		"current_boss": current_boss.duplicate(true),
		"encyclopedia": encyclopedia.duplicate(true),
		"boss_sequence": boss_sequence,
		"memos": travel_memos.duplicate(),
		"stamps": lap_stamps.duplicate(),
		"inventory": inventory.duplicate(true),
		"event_history": event_history.duplicate(true),
		"seen_event_ids": seen_event_ids.duplicate(),
		"recent_event_ids": recent_event_ids.duplicate(),
		"events_seen_this_loop": events_seen_this_loop.duplicate(),
		"rare_event_used_this_loop": rare_event_used_this_loop,
		"events_since_rare": events_since_rare,
		"active_event_state": active_event_state.duplicate(true),
		"pending_event_rewards": pending_event_rewards.duplicate(true),
		"pending_boss_handoff": pending_boss_handoff,
		"registered_travel_notes": registered_travel_notes.duplicate(),
		"registered_postcards": registered_postcards.duplicate(),
		"applied_resolution_ids": applied_resolution_ids.duplicate(),
		"next_interaction_bonus": next_interaction_bonus,
		"next_move_bonus": next_move_bonus,
		"skill_recovery": skill_recovery,
		"map_highlight": map_highlight,
		"character_skill_charge": character_skill_charge
		,"current_dice_count": clampi(current_dice_count, 1, 3)
		,"dice_keep_active": dice_keep_active
		,"dice_double_retry_active": dice_double_retry_active
		,"dice_slot_retry_active": dice_slot_retry_active
		,"pending_dice_rewards": pending_dice_rewards.duplicate(true)
		,"temporary_roll_dice_count": temporary_roll_dice_count
		,"dice_slot_chain_count": dice_slot_chain_count
		,"last_roll_dice_count": last_roll_dice_count
		,"master_volume": clampf(master_volume, 0.0, 1.0)
		,"se_volume": clampf(se_volume, 0.0, 1.0)
		,"dice_se_muted": dice_se_muted
		,"roll_transaction": roll_transaction.duplicate(true)
		,"total_lap_points": maxi(0, total_lap_points)
		,"current_lap_bonus": maxi(0, current_lap_bonus)
		,"current_lap_roll_count": maxi(0, current_lap_roll_count)
		,"current_lap_clean": current_lap_clean
		,"current_lap_penalty_count": maxi(0, current_lap_penalty_count)
		,"clean_streak": clampi(clean_streak, 0, 5)
		,"flow_level": clampi(flow_level, 0, 5)
		,"flow_triggered_this_turn": flow_triggered_this_turn
		,"flow_reward_3_claimed_this_lap": flow_reward_3_claimed_this_lap
		,"flow_reward_5_claimed_this_lap": flow_reward_5_claimed_this_lap
		,"even_guard_active": even_guard_active
		,"best_lap_score": maxi(0, best_lap_score)
		,"best_clean_streak": maxi(0, best_clean_streak)
		,"best_flow_level": maxi(0, best_flow_level)
		,"total_laps": maxi(0, total_laps)
		,"highest_laps_in_one_journey": maxi(0, highest_laps_in_one_journey)
		,"pending_lap_rewards": pending_lap_rewards.duplicate(true)
		,"lap_resolution_id": lap_resolution_id
		,"lap_reward_committed": lap_reward_committed
		,"last_lap_result": last_lap_result.duplicate(true)
		,"landmark_levels": landmark_levels.duplicate(true)
		,"landmark_revisit_stamps": landmark_revisit_stamps.duplicate(true)
		,"landmark_collection_flags": landmark_collection_flags.duplicate(true)
		,"landmark_completion_flags": landmark_completion_flags.duplicate(true)
		,"stage_development": clampi(stage_development, 0, 9)
		,"stage_development_milestones_claimed": stage_development_milestones_claimed.duplicate()
		,"stage_collection_count": maxi(0, stage_collection_count)
		,"stage_collection_completed": stage_collection_completed
		,"pending_landmark_rewards": pending_landmark_rewards.duplicate(true)
		,"landmark_resolution_id": landmark_resolution_id
		,"landmark_reward_committed": landmark_reward_committed
	}

func apply_dictionary(data: Dictionary) -> void:
	selected_stage_id = StringName(str(data.get("stage_id", DEFAULT_STAGE)))
	selected_character_id = StringName(str(data.get("character_id", DEFAULT_CHARACTER)))
	current_tile_index = int(data.get("tile", 0))
	lap_count = int(data.get("laps", 0))
	rolls_used = int(data.get("rolls", 0))
	coins = int(data.get("coins", 12))
	souvenirs = int(data.get("souvenirs", 0))
	boss_presence = int(data.get("presence", 0))
	boss_bond = float(data.get("bond", 0.0))
	boss_relief = int(data.get("boss_relief", 0))
	current_boss = (data.get("current_boss", {}) as Dictionary).duplicate(true)
	encyclopedia.clear()
	for entry: Variant in data.get("encyclopedia", []):
		if entry is Dictionary:
			encyclopedia.append((entry as Dictionary).duplicate(true))
	boss_sequence = maxi(1, int(data.get("boss_sequence", encyclopedia.size() + 1)))
	travel_memos.assign(data.get("memos", []))
	lap_stamps.assign(data.get("stamps", []))
	inventory = data.get("inventory", {"pinpoint": 2, "fever": 2})
	event_history.assign(data.get("event_history", []))
	seen_event_ids.assign(data.get("seen_event_ids", []))
	recent_event_ids.assign(data.get("recent_event_ids", []))
	events_seen_this_loop.assign(data.get("events_seen_this_loop", []))
	rare_event_used_this_loop = bool(data.get("rare_event_used_this_loop", false))
	events_since_rare = int(data.get("events_since_rare", 99))
	active_event_state = (data.get("active_event_state", {}) as Dictionary).duplicate(true)
	pending_event_rewards.assign(data.get("pending_event_rewards", []))
	pending_boss_handoff = bool(data.get("pending_boss_handoff", false))
	registered_travel_notes.assign(data.get("registered_travel_notes", []))
	registered_postcards.assign(data.get("registered_postcards", []))
	applied_resolution_ids.assign(data.get("applied_resolution_ids", []))
	next_interaction_bonus = int(data.get("next_interaction_bonus", 0))
	next_move_bonus = int(data.get("next_move_bonus", 0))
	skill_recovery = int(data.get("skill_recovery", 0))
	map_highlight = str(data.get("map_highlight", ""))
	character_skill_charge = clampi(int(data.get("character_skill_charge", 1)), 0, 1)
	var save_version := int(data.get("version", 1))
	if save_version >= 5 and data.has("current_dice_count"):
		current_dice_count = clampi(int(data.get("current_dice_count", 1)), 1, 3)
	else:
		# v4's permanent unlock loop kept three dice available indefinitely. It
		# migrates once to DOUBLE CHANCE, matching the old selected-3 rule while
		# preserving a small returning-player bonus. Explicit one-die saves stay 1.
		var old_count := int(data.get("unlocked_dice_count", data.get("dice_mode", 3)))
		current_dice_count = 1 if old_count <= 1 else (3 if old_count >= 5 else 2)
	dice_keep_active = bool(data.get("dice_keep_active", false)) if save_version >= 5 else false
	dice_double_retry_active = bool(data.get("dice_double_retry_active", false)) if save_version >= 5 else false
	dice_slot_retry_active = bool(data.get("dice_slot_retry_active", false)) if save_version >= 5 else false
	pending_dice_rewards.clear()
	if save_version >= 5:
		for reward: Variant in data.get("pending_dice_rewards", []):
			if reward is Dictionary: pending_dice_rewards.append((reward as Dictionary).duplicate(true))
	temporary_roll_dice_count = maxi(0, int(data.get("temporary_roll_dice_count", 0))) if save_version >= 5 else 0
	dice_slot_chain_count = maxi(0, int(data.get("dice_slot_chain_count", 0))) if save_version >= 5 else 0
	last_roll_dice_count = maxi(0, int(data.get("last_roll_dice_count", 0))) if save_version >= 5 else 0
	master_volume = clampf(float(data.get("master_volume", 1.0)), 0.0, 1.0)
	se_volume = clampf(float(data.get("se_volume", 1.0)), 0.0, 1.0)
	dice_se_muted = bool(data.get("dice_se_muted", false))
	roll_transaction = (data.get("roll_transaction", {}) as Dictionary).duplicate(true)
	if not roll_transaction.is_empty():
		var transaction_phase := str(roll_transaction.get("phase", roll_transaction.get("roll_phase", "")))
		if transaction_phase not in ["PRE_ROLL", "ROLLING", "RESULT_COMMITTED", "MOVEMENT_COMMITTED", "SPACE_EFFECT_COMMITTED", "TURN_RESOLVED"]:
			roll_transaction.clear()
		else:
			roll_transaction["phase"] = transaction_phase
			roll_transaction["roll_phase"] = transaction_phase
			var loaded_transaction_id := str(roll_transaction.get("transaction_id", roll_transaction.get("roll_transaction_id", roll_transaction.get("roll_id", ""))))
			if loaded_transaction_id.is_empty():
				loaded_transaction_id = "legacy:%08d:%d" % [rolls_used, Time.get_ticks_msec()]
			roll_transaction["transaction_id"] = loaded_transaction_id
			roll_transaction["roll_transaction_id"] = loaded_transaction_id
			roll_transaction["roll_id"] = loaded_transaction_id
			roll_transaction["dice_count"] = clampi(int(roll_transaction.get("dice_count", 1)), 1, 5)
			var loaded_start_tile := posmod(int(roll_transaction.get("start_tile_index", roll_transaction.get("start_tile", current_tile_index))), 90)
			roll_transaction["start_tile_index"] = loaded_start_tile
			roll_transaction["start_tile"] = loaded_start_tile
			roll_transaction["pre_roll_current_dice_count"] = clampi(int(roll_transaction.get("pre_roll_current_dice_count", current_dice_count)), 1, 3)
			roll_transaction["pre_roll_temporary_roll_dice_count"] = maxi(0, int(roll_transaction.get("pre_roll_temporary_roll_dice_count", temporary_roll_dice_count)))
			roll_transaction["landing_roles_committed"] = bool(roll_transaction.get("landing_roles_committed", false))
			roll_transaction["landing_core_committed"] = bool(roll_transaction.get("landing_core_committed", false))
			if transaction_phase in ["PRE_ROLL", "ROLLING"]:
				roll_transaction["final_dice_values"] = []
			var loaded_target := int(roll_transaction.get("target_tile_index", roll_transaction.get("destination", -1)))
			if loaded_target >= 0:
				loaded_target = posmod(loaded_target, 90)
			roll_transaction["target_tile_index"] = loaded_target
			roll_transaction["destination"] = loaded_target
			var encounter_phase := str(roll_transaction.get("encounter_phase", "NONE"))
			if encounter_phase not in ["NONE", "HANDOFF_PENDING", "MODAL_OPEN", "INTERACTION_COMMITTED", "REGISTRATION_COMMITTED", "COMPLETE"]:
				encounter_phase = "NONE"
			roll_transaction["encounter_phase"] = encounter_phase
	total_lap_points = maxi(0, int(data.get("total_lap_points", 0)))
	current_lap_bonus = maxi(0, int(data.get("current_lap_bonus", 0)))
	current_lap_roll_count = maxi(0, int(data.get("current_lap_roll_count", 0)))
	current_lap_clean = bool(data.get("current_lap_clean", true))
	current_lap_penalty_count = maxi(0, int(data.get("current_lap_penalty_count", 0)))
	clean_streak = clampi(int(data.get("clean_streak", 0)), 0, 5)
	flow_level = clampi(int(data.get("flow_level", 0)), 0, 5)
	flow_triggered_this_turn = bool(data.get("flow_triggered_this_turn", false))
	flow_reward_3_claimed_this_lap = bool(data.get("flow_reward_3_claimed_this_lap", false))
	flow_reward_5_claimed_this_lap = bool(data.get("flow_reward_5_claimed_this_lap", false))
	even_guard_active = bool(data.get("even_guard_active", false))
	best_lap_score = maxi(0, int(data.get("best_lap_score", 0)))
	best_clean_streak = maxi(0, int(data.get("best_clean_streak", 0)))
	best_flow_level = maxi(0, int(data.get("best_flow_level", 0)))
	total_laps = maxi(0, int(data.get("total_laps", data.get("laps", 0))))
	highest_laps_in_one_journey = maxi(0, int(data.get("highest_laps_in_one_journey", data.get("laps", 0))))
	pending_lap_rewards.clear()
	for reward: Variant in data.get("pending_lap_rewards", []):
		if reward is Dictionary: pending_lap_rewards.append((reward as Dictionary).duplicate(true))
	lap_resolution_id = str(data.get("lap_resolution_id", ""))
	lap_reward_committed = bool(data.get("lap_reward_committed", false))
	last_lap_result = (data.get("last_lap_result", {}) as Dictionary).duplicate(true)
	landmark_levels = DEFAULT_LANDMARK_LEVELS.duplicate(true)
	for landmark_id: Variant in (data.get("landmark_levels", {}) as Dictionary):
		landmark_levels[str(landmark_id)] = clampi(int((data.get("landmark_levels", {}) as Dictionary)[landmark_id]), 0, 3)
	landmark_revisit_stamps = (data.get("landmark_revisit_stamps", {}) as Dictionary).duplicate(true)
	landmark_collection_flags = (data.get("landmark_collection_flags", {}) as Dictionary).duplicate(true)
	landmark_completion_flags = (data.get("landmark_completion_flags", {}) as Dictionary).duplicate(true)
	stage_development = clampi(int(data.get("stage_development", 0)), 0, 9)
	stage_development_milestones_claimed.assign(data.get("stage_development_milestones_claimed", []))
	stage_collection_count = maxi(0, int(data.get("stage_collection_count", 0)))
	stage_collection_completed = bool(data.get("stage_collection_completed", false))
	pending_landmark_rewards.clear()
	for reward: Variant in data.get("pending_landmark_rewards", []):
		if reward is Dictionary: pending_landmark_rewards.append((reward as Dictionary).duplicate(true))
	landmark_resolution_id = str(data.get("landmark_resolution_id", ""))
	landmark_reward_committed = bool(data.get("landmark_reward_committed", false))
	# v1 saves had only boss_bond. Their first individual is safely migrated here.
	if current_boss.is_empty():
		current_boss = BossSystemScript.initial_individual(boss_sequence)
		current_boss["gauge"] = clampi(roundi(boss_bond), 0, 100)
		current_boss["stage"] = BossSystemScript.stage_for_gauge(int(current_boss["gauge"]))
		boss_sequence += 1
	ensure_boss_data()
