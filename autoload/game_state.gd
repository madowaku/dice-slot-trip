extends Node

const DEFAULT_STAGE: StringName = &"cairo_hourglass"
const DEFAULT_CHARACTER: StringName = &"relaxed"
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
	ensure_boss_data()

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
		"version": 5,
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
	# v1 saves had only boss_bond. Their first individual is safely migrated here.
	if current_boss.is_empty():
		current_boss = BossSystemScript.initial_individual(boss_sequence)
		current_boss["gauge"] = clampi(roundi(boss_bond), 0, 100)
		current_boss["stage"] = BossSystemScript.stage_for_gauge(int(current_boss["gauge"]))
		boss_sequence += 1
	ensure_boss_data()
