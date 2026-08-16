class_name AquafallBattle
extends RefCounted

const DiceLogicScript = preload("res://scripts/core/dice_logic.gd")
const DATA_PATH := "res://data/bosses/aquafall_waterfall_climb.json"

const PHASE_WAIT_ROLL: StringName = &"WAIT_ROLL"
const PHASE_WAIT_DIRECTION: StringName = &"WAIT_DIRECTION"
const PHASE_VICTORY: StringName = &"VICTORY"
const PHASE_DEFEAT: StringName = &"DEFEAT"
const MAX_HEARTS := 3
const DEFAULT_LANE_COUNT := 5
const DEFAULT_GENERATION_RULES := {
	"max_same_pattern_streak": 2,
	"min_gap_after_giant_log": 1,
	"allow_fully_blocked_row": false,
	"max_candidate_attempts": 96,
	"max_debug_log_entries": 128,
}
const DEFAULT_LEVEL_CONFIG := {
	"level": 1,
	"lap_min": 1,
	"lap_max": 3,
	"decision_pressure_min": 2,
	"decision_pressure_max": 4,
	"max_double_danger": 0,
	"small_log_min": 2,
	"small_log_max": 3,
	"large_log_min": 0,
	"large_log_max": 1,
	"large_log_spawn_chance": 0.40,
	"max_hard_streak": 1,
	"max_deadly_streak": 1,
	"pattern_weights": {"easy": 70, "normal": 30, "hard": 0, "deadly": 0},
}

var phase: StringName = PHASE_WAIT_ROLL
var lane := 3
var height := 0
var goal_height := 24
var hp := MAX_HEARTS
var max_hp := MAX_HEARTS
var lap := 1
var difficulty := 1
var waterfall_level := 1
var level_config: Dictionary = DEFAULT_LEVEL_CONFIG.duplicate(true)
var pending_face := 0
var roll_faces: Array[int] = []
var water_guard_charges := 0
var water_run_rolls := 0
var obstacles: Array[Dictionary] = []
var damage_this_roll := 0
var stats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var lane_count := DEFAULT_LANE_COUNT
var generation_rules: Dictionary = DEFAULT_GENERATION_RULES.duplicate(true)
var slot_rules: Dictionary = {}
var last_spawn_pattern := ""
var spawn_pattern_streak := 0
var giant_log_gap_remaining := 0
var last_role := ""
var last_role_effect := ""
var slot_cleared_logs_this_turn := false
var pattern_definitions: Array[Dictionary] = []
var current_pattern_id := ""
var current_pattern_class := ""
var current_pattern_metrics: Dictionary = {}
var last_preview_table: Dictionary = {}
var hard_streak := 0
var deadly_streak := 0
var debug_logs: Array[Dictionary] = []


func configure(current_lap: int, current_hp: int, current_max_hp: int, seed_value: int = 0) -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary or str((parsed as Dictionary).get("game_type", "")) != "waterfall_lane_climb":
		return false
	var board: Dictionary = (parsed as Dictionary).get("board", {}) as Dictionary
	lane_count = clampi(int(board.get("lane_count", DEFAULT_LANE_COUNT)), 2, 8)
	lane = clampi(int(board.get("start_lane", 3)), 1, lane_count)
	height = int(board.get("start_height", 0))
	goal_height = int(board.get("goal_height", 24))
	lap = maxi(current_lap, 1)
	waterfall_level = _waterfall_level_from_data(parsed as Dictionary, lap)
	difficulty = waterfall_level
	level_config = _load_level_config(parsed as Dictionary, waterfall_level)
	pattern_definitions = _load_pattern_definitions(parsed as Dictionary)
	max_hp = MAX_HEARTS
	hp = clampi(current_hp, 0, max_hp)
	phase = PHASE_WAIT_ROLL
	pending_face = 0
	roll_faces.clear()
	obstacles.clear()
	water_guard_charges = 0
	water_run_rolls = 0
	last_spawn_pattern = ""
	spawn_pattern_streak = 0
	giant_log_gap_remaining = 0
	last_role = ""
	last_role_effect = ""
	slot_cleared_logs_this_turn = false
	current_pattern_id = ""
	current_pattern_class = ""
	current_pattern_metrics.clear()
	last_preview_table.clear()
	hard_streak = 0
	deadly_streak = 0
	debug_logs.clear()
	rng.seed = seed_value if seed_value != 0 else hash("aquafall:%d" % lap)
	generation_rules = DEFAULT_GENERATION_RULES.duplicate(true)
	var parsed_slot_rules: Variant = (parsed as Dictionary).get("slot_rules", {})
	slot_rules = (parsed_slot_rules as Dictionary).duplicate(true) if parsed_slot_rules is Dictionary else {}
	var parsed_generation_rules: Variant = (parsed as Dictionary).get("generation_rules", {})
	if parsed_generation_rules is Dictionary:
		for key: String in DEFAULT_GENERATION_RULES.keys():
			if (parsed_generation_rules as Dictionary).has(key):
				generation_rules[key] = (parsed_generation_rules as Dictionary).get(key)
	_normalize_generation_rules()
	_normalize_level_config()
	stats = {"roll_count": 0, "left_count": 0, "right_count": 0, "small_log_hits": 0, "large_log_hits": 0, "pair_count": 0, "straight_count": 0, "triple_count": 0, "spawn_count": 0}
	spawn_obstacles()
	return hp > 0


static func difficulty_for_lap(current_lap: int) -> int:
	var value := maxi(current_lap, 1)
	if value <= 3:
		return 1
	if value <= 6:
		return 2
	if value <= 10:
		return 3
	if value <= 14:
		return 4
	if value <= 18:
		return 5
	if value <= 22:
		return 6
	if value <= 26:
		return 7
	return 8


static func waterfall_level_for_lap(current_lap: int) -> int:
	return difficulty_for_lap(current_lap)


static func _waterfall_level_from_data(parsed: Dictionary, current_lap: int) -> int:
	var requested_lap := maxi(current_lap, 1)
	var raw_levels: Variant = parsed.get("waterfall_levels", [])
	if raw_levels is Array:
		for raw_value: Variant in raw_levels:
			if not raw_value is Dictionary:
				continue
			var row := raw_value as Dictionary
			var lap_min := int(row.get("lap_min", 1))
			var lap_max := int(row.get("lap_max", -1))
			if requested_lap >= lap_min and (lap_max < 0 or requested_lap <= lap_max):
				return clampi(int(row.get("level", 1)), 1, 8)
	return difficulty_for_lap(requested_lap)


func level_data() -> Dictionary:
	return level_config.duplicate(true)


func pattern_data() -> Dictionary:
	return {
		"id": current_pattern_id,
		"pattern_class": current_pattern_class,
		"difficulty_class": current_pattern_class,
		"metrics": current_pattern_metrics.duplicate(true),
	}


func debug_log() -> Array[Dictionary]:
	return debug_logs.duplicate(true)


func _load_level_config(parsed: Dictionary, requested_level: int) -> Dictionary:
	var selected := DEFAULT_LEVEL_CONFIG.duplicate(true)
	var raw_levels: Variant = parsed.get("waterfall_levels", [])
	if raw_levels is Array:
		for raw_value: Variant in raw_levels:
			if not raw_value is Dictionary:
				continue
			var candidate := (raw_value as Dictionary).duplicate(true)
			if int(candidate.get("level", 0)) == requested_level:
				for key: String in candidate.keys():
					selected[key] = candidate[key]
				break
	selected["level"] = requested_level
	return selected


func _load_pattern_definitions(parsed: Dictionary) -> Array[Dictionary]:
	var loaded: Array[Dictionary] = []
	var raw_patterns: Variant = parsed.get("log_patterns", [])
	if raw_patterns is Array:
		for raw_value: Variant in raw_patterns:
			if raw_value is Dictionary:
				loaded.append((raw_value as Dictionary).duplicate(true))
	return loaded


func _normalize_level_config() -> void:
	level_config["level"] = maxi(int(level_config.get("level", DEFAULT_LEVEL_CONFIG.get("level", 1))), 1)
	level_config["lap_min"] = maxi(int(level_config.get("lap_min", DEFAULT_LEVEL_CONFIG.get("lap_min", 1))), 1)
	# A lap_max of -1 is the data contract for an open-ended final level.
	level_config["lap_max"] = maxi(int(level_config.get("lap_max", DEFAULT_LEVEL_CONFIG.get("lap_max", -1))), -1)
	for key: String in ["decision_pressure_min", "decision_pressure_max", "max_double_danger", "small_log_min", "small_log_max", "large_log_min", "large_log_max", "max_hard_streak", "max_deadly_streak"]:
		level_config[key] = maxi(int(level_config.get(key, DEFAULT_LEVEL_CONFIG.get(key, 0))), 0)
	level_config["large_log_spawn_chance"] = clampf(float(level_config.get("large_log_spawn_chance", 1.0)), 0.0, 1.0)
	level_config["decision_pressure_max"] = maxi(int(level_config.get("decision_pressure_max", 0)), int(level_config.get("decision_pressure_min", 0)))
	level_config["small_log_max"] = maxi(int(level_config.get("small_log_max", 0)), int(level_config.get("small_log_min", 0)))
	level_config["large_log_max"] = maxi(int(level_config.get("large_log_max", 0)), int(level_config.get("large_log_min", 0)))
	var weights: Dictionary = level_config.get("pattern_weights", {}) as Dictionary
	if weights.is_empty():
		weights = (DEFAULT_LEVEL_CONFIG["pattern_weights"] as Dictionary).duplicate(true)
	var normalized_weights: Dictionary = {}
	for key: Variant in weights.keys():
		normalized_weights[str(key)] = maxi(int(weights[key]), 0)
	level_config["pattern_weights"] = normalized_weights


func _snapshot_pattern_metrics() -> Dictionary:
	# Persist only the scalar summary.  The full preview table is runtime data
	# and would otherwise make JSON snapshots differ after number coercion.
	var persisted: Dictionary = {}
	for key: String in ["decision_pressure", "double_danger_count", "both_safe_count", "one_direction_safe_count", "both_danger_count", "safe_direction_count", "log_count", "small_log_count", "large_log_count"]:
		if current_pattern_metrics.has(key):
			persisted[key] = int(current_pattern_metrics.get(key, 0))
	return persisted


static func reflect_path(start_lane: int, direction: int, steps: int, lane_count: int = 5) -> Array[int]:
	var path: Array[int] = []
	var current := clampi(start_lane, 1, lane_count)
	var travel_direction := -1 if direction < 0 else 1
	for _step: int in range(maxi(steps, 0)):
		var next := current + travel_direction
		if next < 1 or next > lane_count:
			travel_direction *= -1
			next = current + travel_direction
		current = next
		path.append(current)
	return path


static func destination_lane(start_lane: int, direction: int, steps: int, lane_count: int = 5) -> int:
	var path := reflect_path(start_lane, direction, steps, lane_count)
	return path[-1] if not path.is_empty() else start_lane


func preview_direction(direction: int) -> Dictionary:
	var result := _simulate_direction(obstacles, lane, pending_face, direction)
	return result


func simulate_direction(direction: int, dice: int = -1, start_lane: int = -1, board: Array = []) -> Dictionary:
	var chosen_dice := pending_face if dice < 0 else dice
	var chosen_lane := lane if start_lane < 0 else start_lane
	var chosen_board: Array = obstacles if board.is_empty() else board
	return _simulate_direction(chosen_board, chosen_lane, chosen_dice, direction)


func simulate_all_directions(board: Array = [], start_lane: int = -1) -> Dictionary:
	var chosen_lane := lane if start_lane < 0 else start_lane
	var chosen_board: Array = obstacles if board.is_empty() else board
	var table: Dictionary = {}
	for dice: int in range(1, 7):
		table[str(dice)] = {
			"left": _simulate_direction(chosen_board, chosen_lane, dice, -1),
			"right": _simulate_direction(chosen_board, chosen_lane, dice, 1),
		}
	return table


func evaluate_candidate(board: Array, start_lane: int = -1) -> Dictionary:
	var table := simulate_all_directions(board, start_lane)
	var pressure := 0
	var double_danger := 0
	var both_safe := 0
	var one_direction_safe := 0
	var both_danger := 0
	for dice: int in range(1, 7):
		var entry: Dictionary = table.get(str(dice), {}) as Dictionary
		var left: Dictionary = entry.get("left", {}) as Dictionary
		var right: Dictionary = entry.get("right", {}) as Dictionary
		var left_hit := not bool(left.get("safe", true))
		var right_hit := not bool(right.get("safe", true))
		if not left_hit and not right_hit:
			both_safe += 1
		elif left_hit and right_hit:
			pressure += 2
			double_danger += 1
			both_danger += 1
		else:
			pressure += 1
			one_direction_safe += 1
	return {
		"table": table,
		"decision_pressure": pressure,
		"double_danger_count": double_danger,
		"both_safe_count": both_safe,
		"one_direction_safe_count": one_direction_safe,
		"both_danger_count": both_danger,
		"safe_direction_count": 12 - (double_danger * 2) - one_direction_safe,
		"log_count": board.size(),
		"small_log_count": _count_log_type(board, "small"),
		"large_log_count": _count_log_type(board, "large"),
	}


func decision_pressure(board: Array = obstacles, start_lane: int = -1) -> int:
	return int(evaluate_candidate(board, start_lane).get("decision_pressure", 0))


func double_danger_count(board: Array = obstacles, start_lane: int = -1) -> int:
	return int(evaluate_candidate(board, start_lane).get("double_danger_count", 0))


func _simulate_direction(board: Array, start_lane: int, dice: int, direction: int) -> Dictionary:
	var safe_dice := clampi(dice, 0, 6)
	var path := reflect_path(start_lane, direction, safe_dice, lane_count)
	var preview_obstacles: Array[Dictionary] = []
	for raw_obstacle: Variant in board:
		if raw_obstacle is Dictionary:
			preview_obstacles.append(_normalize_obstacle(raw_obstacle as Dictionary))
	var contacts: Array[String] = []
	var contact_details: Array[Dictionary] = []
	for step_index: int in range(path.size()):
		var next_lane: int = path[step_index]
		for obstacle: Dictionary in preview_obstacles:
			_set_obstacle_steps(obstacle, _obstacle_steps(obstacle) - 1)
		for obstacle: Dictionary in preview_obstacles:
			if _is_large_log(obstacle) and _obstacle_steps(obstacle) == 0 and _lane_overlaps(obstacle, next_lane):
				contacts.append("large_log")
				contact_details.append({"type": "large_log", "lane": next_lane, "step": step_index + 1})
	var destination := path[-1] if not path.is_empty() else clampi(start_lane, 1, lane_count)
	for obstacle: Dictionary in preview_obstacles:
		if _is_small_log(obstacle) and _obstacle_steps(obstacle) == 0 and _lane_overlaps(obstacle, destination):
			contacts.append("small_log")
			contact_details.append({"type": "small_log", "lane": destination, "step": path.size()})
	return {
		"path": path,
		"destination_lane": destination,
		"safe": contacts.is_empty(),
		"hit": not contacts.is_empty(),
		"damage": 1 if not contacts.is_empty() else 0,
		"contacts": contacts,
		"contact_details": contact_details,
	}


func _normalize_obstacle(raw_obstacle: Dictionary) -> Dictionary:
	var obstacle := raw_obstacle.duplicate(true)
	var raw_type := str(obstacle.get("type", obstacle.get("log_type", "small_log"))).to_lower()
	var normalized_type := "large_log" if raw_type in ["large", "large_log", "giant", "giant_log"] else "small_log"
	obstacle["type"] = normalized_type
	obstacle["log_type"] = "large" if normalized_type == "large_log" else "small"
	var lanes: Array[int] = []
	var raw_lanes: Variant = obstacle.get("lanes", [])
	if raw_lanes is Array:
		for value: Variant in raw_lanes:
			lanes.append(clampi(int(value), 1, lane_count))
	if lanes.is_empty():
		if normalized_type == "large_log":
			var from_lane := clampi(int(obstacle.get("lane_from", obstacle.get("lane", 1))), 1, lane_count)
			var to_lane := clampi(int(obstacle.get("lane_to", from_lane)), from_lane, lane_count)
			for lane_value: int in range(from_lane, to_lane + 1):
				lanes.append(lane_value)
		else:
			lanes.append(clampi(int(obstacle.get("lane", 1)), 1, lane_count))
	obstacle["lanes"] = lanes
	if normalized_type == "large_log":
		obstacle["lane_from"] = lanes[0] if not lanes.is_empty() else 1
		obstacle["lane_to"] = lanes[-1] if not lanes.is_empty() else obstacle["lane_from"]
	else:
		obstacle["lane"] = lanes[0] if not lanes.is_empty() else 1
	_set_obstacle_steps(obstacle, _obstacle_steps(obstacle))
	return obstacle


func _obstacle_steps(obstacle: Dictionary) -> int:
	if obstacle.has("steps_until_contact"):
		return int(obstacle.get("steps_until_contact", 0))
	return int(obstacle.get("relative_height", 0))


func _set_obstacle_steps(obstacle: Dictionary, value: int) -> void:
	obstacle["steps_until_contact"] = value
	# relative_height remains as a compatibility/rendering alias for the first
	# Amazon boss implementation and old saves.
	obstacle["relative_height"] = value


func _is_large_log(obstacle: Dictionary) -> bool:
	return str(obstacle.get("type", obstacle.get("log_type", ""))).to_lower() in ["large", "large_log", "giant", "giant_log"]


func _is_small_log(obstacle: Dictionary) -> bool:
	return not _is_large_log(obstacle)


func _lane_overlaps(obstacle: Dictionary, lane_value: int) -> bool:
	var lanes: Array = obstacle.get("lanes", []) as Array
	return lane_value in lanes


func _count_log_type(board: Array, requested_type: String) -> int:
	var count := 0
	for raw_obstacle: Variant in board:
		if raw_obstacle is Dictionary and ((_is_large_log(raw_obstacle as Dictionary) and requested_type == "large") or (_is_small_log(raw_obstacle as Dictionary) and requested_type == "small")):
			count += 1
	return count


func request_roll(face: int) -> Dictionary:
	if phase != PHASE_WAIT_ROLL or face < 1 or face > 6:
		return {"ok": false, "error": "ROLL_NOT_AVAILABLE"}
	pending_face = face
	phase = PHASE_WAIT_DIRECTION
	last_preview_table = simulate_all_directions(obstacles, lane)
	var left_preview: Dictionary = last_preview_table.get(str(face), {}).get("left", {}) as Dictionary
	var right_preview: Dictionary = last_preview_table.get(str(face), {}).get("right", {}) as Dictionary
	return {
		"ok": true,
		"face": face,
		"left_lane": destination_lane(lane, -1, face, lane_count),
		"right_lane": destination_lane(lane, 1, face, lane_count),
		"left_result": "hit" if not bool(left_preview.get("safe", true)) else "safe",
		"right_result": "hit" if not bool(right_preview.get("safe", true)) else "safe",
	}


func choose_direction(direction: int) -> Dictionary:
	if phase != PHASE_WAIT_DIRECTION or direction == 0:
		return {"ok": false, "error": "DIRECTION_NOT_AVAILABLE"}
	last_role = ""
	last_role_effect = ""
	slot_cleared_logs_this_turn = false
	damage_this_roll = 0
	var active_water_run := water_run_rolls > 0
	var left_preview := _simulate_direction(obstacles, lane, pending_face, -1)
	var right_preview := _simulate_direction(obstacles, lane, pending_face, 1)
	var path := reflect_path(lane, direction, pending_face, lane_count)
	for next_lane: int in path:
		lane = next_lane
		for obstacle: Dictionary in obstacles:
			_set_obstacle_steps(obstacle, _obstacle_steps(obstacle) - 1)
			if _is_large_log(obstacle) and _obstacle_steps(obstacle) == 0 and _lane_overlaps(obstacle, lane):
				_resolve_hit("large_log", active_water_run)
	height = mini(height + pending_face, goal_height)
	if direction < 0:
		stats["left_count"] = int(stats.left_count) + 1
	else:
		stats["right_count"] = int(stats.right_count) + 1
	stats["roll_count"] = int(stats.roll_count) + 1
	# The roll still resolves its landing/hit before victory. Reaching the goal
	# cannot be used to skip a log occupying the destination row.
	if height >= goal_height and hp > 0:
		phase = PHASE_VICTORY
	for obstacle: Dictionary in obstacles:
		if _is_small_log(obstacle) and _obstacle_steps(obstacle) == 0 and _lane_overlaps(obstacle, lane):
			_resolve_hit("small_log", active_water_run)
	_record_debug_turn(left_preview, right_preview, direction, damage_this_roll)
	if active_water_run:
		water_run_rolls = maxi(water_run_rolls - 1, 0)
	roll_faces.append(pending_face)
	if roll_faces.size() == 3:
		_resolve_slot()
	obstacles = obstacles.filter(func(obstacle: Dictionary) -> bool: return _obstacle_steps(obstacle) >= -1)
	if hp <= 0:
		phase = PHASE_DEFEAT
		return _turn_receipt(path, "DEFEAT")
	if phase == PHASE_VICTORY:
		return _turn_receipt(path, "VICTORY")
	pending_face = 0
	phase = PHASE_WAIT_ROLL
	if not slot_cleared_logs_this_turn:
		spawn_obstacles()
	return _turn_receipt(path, "TURN_RESOLVED")


func _resolve_hit(obstacle_type: String, immune: bool) -> void:
	stats["%s_hits" % obstacle_type] = int(stats.get("%s_hits" % obstacle_type, 0)) + 1
	if immune:
		return
	if water_guard_charges > 0:
		water_guard_charges -= 1
		return
	damage_this_roll += 1
	hp = maxi(hp - 1, 0)


func _record_debug_turn(left_result: Dictionary, right_result: Dictionary, direction: int, damage: int) -> void:
	var entry := {
		"lap": lap,
		"waterfall_level": waterfall_level,
		"pattern_id": current_pattern_id,
		"pattern_class": current_pattern_class,
		"player_lane": lane,
		"dice": pending_face,
		"left_result": "hit" if not bool(left_result.get("safe", true)) else "safe",
		"right_result": "hit" if not bool(right_result.get("safe", true)) else "safe",
		"selected_direction": "LEFT" if direction < 0 else "RIGHT",
		"damage": damage,
		"current_height": height,
		"remaining_hp": hp,
	}
	debug_logs.append(entry)
	var max_entries := maxi(int(generation_rules.get("max_debug_log_entries", 128)), 1)
	while debug_logs.size() > max_entries:
		debug_logs.pop_front()


func _resolve_slot() -> void:
	var role := StringName(DiceLogicScript.evaluate(roll_faces).get("main", &""))
	last_role = str(role) if not role.is_empty() else "NONE"
	var effects: Dictionary = slot_rules.get("effects", {}) as Dictionary
	var role_config: Dictionary = effects.get(last_role, {}) as Dictionary
	last_role_effect = str(role_config.get("label", "役なし。次の3投へ。"))
	match role:
		DiceLogicScript.PAIR:
			water_guard_charges = maxi(water_guard_charges, int(role_config.get("charges", 1)))
			stats["pair_count"] = int(stats.pair_count) + 1
		DiceLogicScript.STRAIGHT:
			water_run_rolls = maxi(water_run_rolls, int(role_config.get("rolls", 1)))
			stats["straight_count"] = int(stats.straight_count) + 1
		DiceLogicScript.TRIPLE:
			obstacles.clear()
			slot_cleared_logs_this_turn = true
			height = mini(height + int(role_config.get("height_bonus", 2)), goal_height)
			stats["triple_count"] = int(stats.triple_count) + 1
	roll_faces.clear()
	if height >= goal_height:
		phase = PHASE_VICTORY


func spawn_obstacles() -> void:
	if phase != PHASE_WAIT_ROLL or obstacles.size() >= 24:
		return
	var selected := _select_pattern_candidate()
	var logs: Array = selected.get("logs", []) as Array
	if logs.is_empty():
		var fallback := _normalize_obstacle(_make_obstacle("small_log", 5 + rng.randi_range(0, 3)))
		if not _would_fully_block_row(fallback):
			_commit_spawn(fallback)
			stats["spawn_count"] = int(stats.get("spawn_count", 0)) + 1
		return
	current_pattern_id = str(selected.get("pattern_id", "synthetic_fallback"))
	current_pattern_class = str(selected.get("pattern_class", "NORMAL"))
	current_pattern_metrics = (selected.get("metrics", {}) as Dictionary).duplicate(true)
	for raw_log: Variant in logs:
		if raw_log is Dictionary:
			var log := _normalize_obstacle(raw_log as Dictionary)
			if not _would_fully_block_row(log):
				_commit_spawn(log)
	stats["spawn_count"] = int(stats.get("spawn_count", 0)) + 1
	var has_large := _count_log_type(logs, "large") > 0
	if has_large:
		giant_log_gap_remaining = maxi(int(generation_rules.get("min_gap_after_giant_log", 1)), 0)
	elif giant_log_gap_remaining > 0:
		giant_log_gap_remaining -= 1
	if current_pattern_class == "HARD":
		hard_streak += 1
	else:
		hard_streak = 0
	if current_pattern_class == "DEADLY":
		deadly_streak += 1
	else:
		deadly_streak = 0


func _next_spawn_pattern() -> String:
	var max_streak := maxi(int(generation_rules.get("max_same_pattern_streak", 2)), 1)
	var can_large := giant_log_gap_remaining <= 0
	if not can_large:
		return "small_log"
	if spawn_pattern_streak >= max_streak:
		return "large_log" if last_spawn_pattern == "small_log" else "small_log"
	return "large_log" if rng.randf() < (0.35 if waterfall_level >= 3 else 0.18) else "small_log"


func _make_obstacle(pattern: String, spawn_height: int) -> Dictionary:
	var lane_roll := rng.randi_range(1, lane_count)
	if pattern != "large_log":
		return {"type": "small_log", "lane": lane_roll, "lanes": [lane_roll], "steps_until_contact": spawn_height, "relative_height": spawn_height}
	var width := 2 if waterfall_level < 6 else rng.randi_range(2, 3)
	var start := clampi(lane_roll, 1, lane_count - width + 1)
	var occupied: Array[int] = []
	for value: int in range(start, start + width):
		occupied.append(value)
	return {"type": "large_log", "lanes": occupied, "lane_from": start, "lane_to": start + width - 1, "steps_until_contact": spawn_height, "relative_height": spawn_height}


func _would_fully_block_row(candidate: Dictionary) -> bool:
	if bool(generation_rules.get("allow_fully_blocked_row", false)):
		return false
	var target_height := _obstacle_steps(candidate)
	var blocked: Dictionary = {}
	for obstacle: Dictionary in obstacles:
		if _obstacle_steps(obstacle) != target_height:
			continue
		for lane_value: Variant in obstacle.get("lanes", []):
			blocked[int(lane_value)] = true
	for lane_value: Variant in candidate.get("lanes", []):
		blocked[int(lane_value)] = true
	return blocked.size() >= lane_count


func _commit_spawn(obstacle: Dictionary) -> void:
	var normalized := _normalize_obstacle(obstacle)
	obstacles.append(normalized)
	var pattern := "large_log" if _is_large_log(normalized) else "small_log"
	if pattern == last_spawn_pattern:
		spawn_pattern_streak += 1
	else:
		last_spawn_pattern = pattern
		spawn_pattern_streak = 1
	# The pattern-level spawn counter is incremented by spawn_obstacles. Keeping
	# this helper side-effect-light preserves compatibility with old fixtures
	# that commit one hand-authored log at a time.


func _select_pattern_candidate() -> Dictionary:
	var attempts := maxi(int(generation_rules.get("max_candidate_attempts", 96)), 8)
	var eligible: Array[Dictionary] = []
	for pattern: Dictionary in pattern_definitions:
		if not _pattern_allows_level(pattern, waterfall_level):
			continue
		var pattern_class_name := str(pattern.get("difficulty_class", "NORMAL")).to_upper()
		if not _class_allowed_by_streak(pattern_class_name):
			continue
		eligible.append(pattern)
	if eligible.is_empty():
		for pattern: Dictionary in pattern_definitions:
			if _pattern_allows_level(pattern, waterfall_level):
				eligible.append(pattern)
	if eligible.is_empty():
		return _synthesize_candidate("NORMAL", attempts)
	for _attempt: int in range(attempts):
		var pattern := _weighted_pattern_pick(eligible)
		var candidate_logs := _transform_pattern_logs(pattern)
		candidate_logs = _fit_log_counts(candidate_logs)
		var metrics := evaluate_candidate(candidate_logs, lane)
		if _candidate_matches_level(metrics) and not _candidate_is_forced_loss(metrics):
			return {"logs": candidate_logs, "pattern_id": str(pattern.get("id", "pattern")), "pattern_class": str(pattern.get("difficulty_class", "NORMAL")).to_upper(), "metrics": metrics}
	return _synthesize_candidate(str(eligible[0].get("difficulty_class", "NORMAL")).to_upper(), attempts)


func _pattern_allows_level(pattern: Dictionary, requested_level: int) -> bool:
	var allowed: Variant = pattern.get("allowed_levels", [])
	if not allowed is Array or (allowed as Array).is_empty():
		return true
	for raw_level: Variant in allowed as Array:
		# JSON numbers are parsed as floats; compare their integer value so the
		# data file remains portable across Godot/JSON loaders.
		if int(raw_level) == requested_level:
			return true
	return false


func _pattern_has_large(pattern: Dictionary) -> bool:
	var raw_logs: Variant = pattern.get("logs", [])
	if not raw_logs is Array:
		return false
	for raw_log: Variant in raw_logs:
		if raw_log is Dictionary and _is_large_log(raw_log as Dictionary):
			return true
	return false


func _class_allowed_by_streak(pattern_class_name: String) -> bool:
	if pattern_class_name == "HARD" and hard_streak >= maxi(int(level_config.get("max_hard_streak", 1)), 1):
		return false
	if pattern_class_name == "DEADLY" and deadly_streak >= maxi(int(level_config.get("max_deadly_streak", 1)), 1):
		return false
	return true


func _weighted_pattern_pick(patterns: Array[Dictionary]) -> Dictionary:
	if patterns.size() == 1:
		return patterns[0]
	var weights: Array[Dictionary] = []
	var total := 0
	var config_weights: Dictionary = level_config.get("pattern_weights", {}) as Dictionary
	for pattern: Dictionary in patterns:
		var class_key := str(pattern.get("difficulty_class", "NORMAL")).to_lower()
		var weight := maxi(int(config_weights.get(class_key, 0)), 0)
		if weight <= 0:
			continue
		weights.append({"pattern": pattern, "weight": weight})
		total += weight
	if weights.is_empty():
		return patterns[0]
	var pick := rng.randi_range(1, maxi(total, 1))
	for entry: Dictionary in weights:
		pick -= int(entry.get("weight", 1))
		if pick <= 0:
			return entry.get("pattern", patterns[0]) as Dictionary
	return patterns.back()


func _transform_pattern_logs(pattern: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mirror := bool(pattern.get("allow_mirror", false)) and rng.randf() < 0.5
	var raw_logs: Variant = pattern.get("logs", [])
	if not raw_logs is Array:
		return result
	# Patterns are authored in board coordinates, then translated toward the
	# current player lane while staying inside the five-lane board.  Most of the
	# bundled patterns already span both edges (so their offset is zero), but the
	# same transform also supports narrower future patterns without hardcoding
	# their placement.
	var pattern_min_lane := lane_count
	var pattern_max_lane := 1
	for raw_log: Variant in raw_logs:
		if not raw_log is Dictionary:
			continue
		var source := raw_log as Dictionary
		var raw_type := str(source.get("type", "small")).to_lower()
		var large := raw_type in ["large", "large_log", "giant", "giant_log"]
		var from_lane := int(source.get("lane_from", source.get("lane", 1)))
		var to_lane := int(source.get("lane_to", from_lane)) if large else from_lane
		if mirror:
			var mirrored_from := lane_count + 1 - to_lane
			var mirrored_to := lane_count + 1 - from_lane
			from_lane = mirrored_from
			to_lane = mirrored_to
		pattern_min_lane = mini(pattern_min_lane, from_lane)
		pattern_max_lane = maxi(pattern_max_lane, to_lane)
	var min_offset := 1 - pattern_min_lane
	var max_offset := lane_count - pattern_max_lane
	var pattern_center := float(pattern_min_lane + pattern_max_lane) * 0.5
	var lane_offset := clampi(roundi(float(lane) - pattern_center), min_offset, max_offset)
	for raw_log: Variant in raw_logs:
		if not raw_log is Dictionary:
			continue
		var log := (raw_log as Dictionary).duplicate(true)
		var raw_type := str(log.get("type", "small")).to_lower()
		var large := raw_type in ["large", "large_log", "giant", "giant_log"]
		if large:
			var from_lane := int(log.get("lane_from", log.get("lane", 1)))
			var to_lane := int(log.get("lane_to", from_lane))
			if mirror:
				var mirrored_from := lane_count + 1 - to_lane
				var mirrored_to := lane_count + 1 - from_lane
				from_lane = mirrored_from
				to_lane = mirrored_to
			from_lane = clampi(from_lane + lane_offset, 1, lane_count)
			to_lane = clampi(to_lane + lane_offset, from_lane, lane_count)
			log["lane_from"] = from_lane
			log["lane_to"] = to_lane
			log["lanes"] = _lane_range(from_lane, to_lane)
			log["type"] = "large_log"
		else:
			var lane_value := int(log.get("lane", 1))
			if mirror:
				lane_value = lane_count + 1 - lane_value
			lane_value = clampi(lane_value + lane_offset, 1, lane_count)
			log["lane"] = lane_value
			log["lanes"] = [lane_value]
			log["type"] = "small_log"
		var contact := clampi(int(log.get("steps_until_contact", log.get("relative_height", 1))), 1, 8)
		log["steps_until_contact"] = contact
		log["relative_height"] = contact
		result.append(_normalize_obstacle(log))
	return result


func _fit_log_counts(candidate: Array[Dictionary]) -> Array[Dictionary]:
	var fitted: Array[Dictionary] = candidate.duplicate(true)
	var desired_small := clampi(int(level_config.get("small_log_min", 0)), 0, int(level_config.get("small_log_max", 99)))
	var desired_large := clampi(int(level_config.get("large_log_min", 0)), 0, int(level_config.get("large_log_max", 99)))
	while _count_log_type(fitted, "small") < desired_small:
		fitted.append(_normalize_obstacle({"type": "small_log", "lane": rng.randi_range(1, lane_count), "steps_until_contact": rng.randi_range(1, 6)}))
	while _count_log_type(fitted, "large") < desired_large:
		var width := 2 if waterfall_level < 7 else rng.randi_range(2, 3)
		var from_lane := rng.randi_range(1, maxi(1, lane_count - width + 1))
		fitted.append(_normalize_obstacle({"type": "large_log", "lane_from": from_lane, "lane_to": from_lane + width - 1, "steps_until_contact": rng.randi_range(1, 6)}))
	var max_small := maxi(int(level_config.get("small_log_max", fitted.size())), desired_small)
	var max_large := maxi(int(level_config.get("large_log_max", fitted.size())), desired_large)
	while _count_log_type(fitted, "small") > max_small:
		for index: int in range(fitted.size() - 1, -1, -1):
			if _is_small_log(fitted[index]):
				fitted.remove_at(index)
				break
	while _count_log_type(fitted, "large") > max_large:
		for index: int in range(fitted.size() - 1, -1, -1):
			if _is_large_log(fitted[index]):
				fitted.remove_at(index)
				break
	var large_spawn_chance := clampf(float(level_config.get("large_log_spawn_chance", 1.0)), 0.0, 1.0)
	if desired_large == 0 and large_spawn_chance < 1.0 and rng.randf() > large_spawn_chance:
		for index: int in range(fitted.size() - 1, -1, -1):
			if _is_large_log(fitted[index]):
				fitted.remove_at(index)
	return fitted


func _synthesize_candidate(pattern_class: String, attempts: int) -> Dictionary:
	var min_small := int(level_config.get("small_log_min", 0))
	var max_small := maxi(int(level_config.get("small_log_max", min_small)), min_small)
	var min_large := int(level_config.get("large_log_min", 0))
	var max_large := maxi(int(level_config.get("large_log_max", min_large)), min_large)
	var best_logs: Array[Dictionary] = []
	var best_metrics: Dictionary = {}
	var best_distance := 999
	for _attempt: int in range(maxi(attempts * 4, 32)):
		var logs: Array[Dictionary] = []
		var small_count := rng.randi_range(min_small, max_small)
		var large_count := rng.randi_range(min_large, max_large)
		for _small_index: int in range(small_count):
			logs.append(_normalize_obstacle({"type": "small_log", "lane": rng.randi_range(1, lane_count), "steps_until_contact": rng.randi_range(1, 6)}))
		for _large_index: int in range(large_count):
			var width := 2 if waterfall_level < 7 else rng.randi_range(2, 3)
			var from_lane := rng.randi_range(1, maxi(1, lane_count - width + 1))
			logs.append(_normalize_obstacle({"type": "large_log", "lane_from": from_lane, "lane_to": from_lane + width - 1, "steps_until_contact": rng.randi_range(1, 6)}))
		var metrics := evaluate_candidate(logs, lane)
		var distance := absi(int(metrics.get("decision_pressure", 0)) - int(level_config.get("decision_pressure_min", 0)))
		distance += maxi(int(metrics.get("double_danger_count", 0)) - int(level_config.get("max_double_danger", 0)), 0) * 4
		distance += absi(int(metrics.get("small_log_count", 0)) - min_small) * 6
		distance += absi(int(metrics.get("large_log_count", 0)) - min_large) * 6
		if _candidate_matches_level(metrics) and not _candidate_is_forced_loss(metrics):
			return {"logs": logs, "pattern_id": "synthetic_%s_%d" % [pattern_class.to_lower(), rng.randi_range(1000, 9999)], "pattern_class": pattern_class, "metrics": metrics}
		if distance < best_distance:
			best_distance = distance
			best_logs = logs
			best_metrics = metrics
	if best_logs.is_empty():
		best_logs.append(_normalize_obstacle({"type": "small_log", "lane": clampi(lane, 1, lane_count), "steps_until_contact": 4}))
		best_metrics = evaluate_candidate(best_logs, lane)
	return {"logs": best_logs, "pattern_id": "synthetic_%s_fallback" % pattern_class.to_lower(), "pattern_class": pattern_class, "metrics": best_metrics}


func _candidate_matches_level(metrics: Dictionary) -> bool:
	return int(metrics.get("decision_pressure", 0)) >= int(level_config.get("decision_pressure_min", 0)) \
		and int(metrics.get("decision_pressure", 0)) <= int(level_config.get("decision_pressure_max", 999)) \
		and int(metrics.get("double_danger_count", 0)) <= int(level_config.get("max_double_danger", 999)) \
		and int(metrics.get("small_log_count", 0)) >= int(level_config.get("small_log_min", 0)) \
		and int(metrics.get("small_log_count", 0)) <= int(level_config.get("small_log_max", 999)) \
		and int(metrics.get("large_log_count", 0)) >= int(level_config.get("large_log_min", 0)) \
		and int(metrics.get("large_log_count", 0)) <= int(level_config.get("large_log_max", 999))


func _candidate_is_forced_loss(metrics: Dictionary) -> bool:
	return int(metrics.get("both_danger_count", 0)) >= 6


func _lane_range(from_lane: int, to_lane: int) -> Array[int]:
	var lanes: Array[int] = []
	for lane_value: int in range(from_lane, to_lane + 1):
		lanes.append(clampi(lane_value, 1, lane_count))
	return lanes


func _turn_receipt(path: Array[int], status: String) -> Dictionary:
	return {"ok": true, "status": status, "path": path, "role": last_role, "role_effect": last_role_effect, "snapshot": snapshot()}


func snapshot() -> Dictionary:
	return {
		"phase": String(phase), "lane": lane, "lane_count": lane_count, "height": height, "goal_height": goal_height,
		"hp": hp, "max_hp": max_hp, "lap": lap, "difficulty": difficulty, "waterfall_level": waterfall_level,
		"level_config": level_config.duplicate(true),
		"pending_face": pending_face, "roll_faces": roll_faces.duplicate(),
		"water_guard_charges": water_guard_charges, "water_run_rolls": water_run_rolls,
		"obstacles": obstacles.duplicate(true), "stats": stats.duplicate(true),
		"generation_rules": generation_rules.duplicate(true),
		"last_spawn_pattern": last_spawn_pattern, "spawn_pattern_streak": spawn_pattern_streak,
		"last_role": last_role, "last_role_effect": last_role_effect,
		"current_pattern_id": current_pattern_id, "current_pattern_class": current_pattern_class,
		"current_pattern_metrics": _snapshot_pattern_metrics(),
		"hard_streak": hard_streak, "deadly_streak": deadly_streak,
		"debug_logs": debug_logs.duplicate(true),
		# RandomNumberGenerator.state is a 64-bit value. Persist it as text so
		# JSON round-trips cannot round it through a double and change the next
		# obstacle sequence after resume.
		"giant_log_gap_remaining": giant_log_gap_remaining, "rng_state": str(rng.state),
	}


func restore(data: Dictionary) -> bool:
	var restored_phase := StringName(str(data.get("phase", PHASE_WAIT_ROLL)))
	if restored_phase not in [PHASE_WAIT_ROLL, PHASE_WAIT_DIRECTION, PHASE_VICTORY, PHASE_DEFEAT]:
		return false
	phase = restored_phase
	lane_count = clampi(int(data.get("lane_count", DEFAULT_LANE_COUNT)), 2, 8)
	lane = clampi(int(data.get("lane", 3)), 1, lane_count)
	goal_height = maxi(int(data.get("goal_height", 24)), 1)
	height = clampi(int(data.get("height", 0)), 0, goal_height)
	max_hp = MAX_HEARTS
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)
	lap = maxi(int(data.get("lap", 1)), 1)
	waterfall_level = clampi(int(data.get("waterfall_level", data.get("difficulty", difficulty_for_lap(lap)))), 1, 8)
	difficulty = waterfall_level
	var restored_level_config: Variant = data.get("level_config", DEFAULT_LEVEL_CONFIG)
	level_config = (restored_level_config as Dictionary).duplicate(true) if restored_level_config is Dictionary else DEFAULT_LEVEL_CONFIG.duplicate(true)
	_normalize_level_config()
	pending_face = clampi(int(data.get("pending_face", 0)), 0, 6)
	roll_faces.clear()
	for value: Variant in data.get("roll_faces", []):
		roll_faces.append(clampi(int(value), 1, 6))
	water_guard_charges = maxi(int(data.get("water_guard_charges", 0)), 0)
	water_run_rolls = maxi(int(data.get("water_run_rolls", 0)), 0)
	generation_rules = DEFAULT_GENERATION_RULES.duplicate(true)
	var restored_generation_rules: Variant = data.get("generation_rules", {})
	if restored_generation_rules is Dictionary:
		for key: String in DEFAULT_GENERATION_RULES.keys():
			if (restored_generation_rules as Dictionary).has(key):
				generation_rules[key] = (restored_generation_rules as Dictionary).get(key)
	_normalize_generation_rules()
	last_spawn_pattern = str(data.get("last_spawn_pattern", ""))
	spawn_pattern_streak = maxi(int(data.get("spawn_pattern_streak", 0)), 0)
	giant_log_gap_remaining = maxi(int(data.get("giant_log_gap_remaining", 0)), 0)
	last_role = str(data.get("last_role", ""))
	last_role_effect = str(data.get("last_role_effect", ""))
	current_pattern_id = str(data.get("current_pattern_id", ""))
	current_pattern_class = str(data.get("current_pattern_class", ""))
	var restored_metrics: Variant = data.get("current_pattern_metrics", {})
	current_pattern_metrics = (restored_metrics as Dictionary).duplicate(true) if restored_metrics is Dictionary else {}
	hard_streak = maxi(int(data.get("hard_streak", 0)), 0)
	deadly_streak = maxi(int(data.get("deadly_streak", 0)), 0)
	debug_logs.clear()
	var restored_debug: Variant = data.get("debug_logs", [])
	if restored_debug is Array:
		for value: Variant in restored_debug:
			if value is Dictionary:
				debug_logs.append((value as Dictionary).duplicate(true))
	if data.has("rng_state"):
		var restored_rng_state := int(str(data.get("rng_state", "0")))
		if restored_rng_state != 0:
			rng.state = restored_rng_state
	obstacles.clear()
	var restored_obstacles: Variant = data.get("obstacles", [])
	if restored_obstacles is Array:
		for value: Variant in restored_obstacles:
			if value is Dictionary:
				obstacles.append(_normalize_obstacle(value as Dictionary))
	var restored_stats: Variant = data.get("stats", stats)
	stats = (restored_stats as Dictionary).duplicate(true) if restored_stats is Dictionary else stats.duplicate(true)
	for key: String in ["roll_count", "left_count", "right_count", "small_log_hits", "large_log_hits", "pair_count", "straight_count", "triple_count", "spawn_count"]:
		if stats.has(key):
			stats[key] = int(stats[key])
	return true


func _normalize_generation_rules() -> void:
	generation_rules["max_same_pattern_streak"] = maxi(int(generation_rules.get("max_same_pattern_streak", DEFAULT_GENERATION_RULES["max_same_pattern_streak"])), 1)
	generation_rules["min_gap_after_giant_log"] = maxi(int(generation_rules.get("min_gap_after_giant_log", DEFAULT_GENERATION_RULES["min_gap_after_giant_log"])), 0)
	generation_rules["allow_fully_blocked_row"] = bool(generation_rules.get("allow_fully_blocked_row", DEFAULT_GENERATION_RULES["allow_fully_blocked_row"]))
	generation_rules["max_candidate_attempts"] = maxi(int(generation_rules.get("max_candidate_attempts", DEFAULT_GENERATION_RULES["max_candidate_attempts"])), 8)
	generation_rules["max_debug_log_entries"] = maxi(int(generation_rules.get("max_debug_log_entries", DEFAULT_GENERATION_RULES["max_debug_log_entries"])), 1)
