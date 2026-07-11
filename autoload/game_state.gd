extends Node

const DEFAULT_STAGE: StringName = &"cairo_hourglass"
const DEFAULT_CHARACTER: StringName = &"relaxed"
const BossSystemScript = preload("res://scripts/game/boss_system.gd")

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
		"version": 2,
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
		"inventory": inventory.duplicate(true)
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
	# v1 saves had only boss_bond. Their first individual is safely migrated here.
	if current_boss.is_empty():
		current_boss = BossSystemScript.initial_individual(boss_sequence)
		current_boss["gauge"] = clampi(roundi(boss_bond), 0, 100)
		current_boss["stage"] = BossSystemScript.stage_for_gauge(int(current_boss["gauge"]))
		boss_sequence += 1
	ensure_boss_data()
