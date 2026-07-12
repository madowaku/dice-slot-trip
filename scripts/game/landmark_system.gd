class_name LandmarkSystem
extends RefCounted

const DATA_PATH := "res://data/landmarks/cairo_landmarks.json"
const MAX_LEVEL: int = 3
const STOP_LAP_BONUS: int = 8

static func definitions() -> Array[Dictionary]:
	if not FileAccess.file_exists(DATA_PATH):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		return []
	var result: Array[Dictionary] = []
	for value: Variant in (parsed as Dictionary).get("landmarks", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result

static func definition_for_tile(tile_index: int, source: Array[Dictionary] = []) -> Dictionary:
	var pool := source if not source.is_empty() else definitions()
	for definition: Dictionary in pool:
		if int(definition.get("tile_index", -1)) == tile_index:
			return definition
	return {}

static func definition_by_id(landmark_id: String, source: Array[Dictionary] = []) -> Dictionary:
	var pool := source if not source.is_empty() else definitions()
	for definition: Dictionary in pool:
		if str(definition.get("id", "")) == landmark_id:
			return definition
	return {}

static func resolve_stop(state: Dictionary, tile_index: int, resolution_id: String, source: Array[Dictionary] = []) -> Dictionary:
	var definition := definition_for_tile(tile_index, source)
	if definition.is_empty() or resolution_id.is_empty():
		return {}
	var landmark_id := str(definition.get("id", ""))
	var levels: Dictionary = state.get("landmark_levels", {})
	var old_level := clampi(int(levels.get(landmark_id, 0)), 0, MAX_LEVEL)
	var new_level := mini(MAX_LEVEL, old_level + 1)
	var rewards: Array[Dictionary] = [
		{"type": "LAP_BONUS", "amount": STOP_LAP_BONUS},
		{"type": "SOUVENIR", "amount": 1},
		{"type": "BOSS_SCENT", "value": 2},
	]
	var state_changes: Array[Dictionary] = []
	if new_level > old_level:
		state_changes.append({
			"type": "LANDMARK_LEVEL",
			"landmark_id": landmark_id,
			"level": new_level,
			"resolution_id": resolution_id,
		})
		for level_definition: Variant in definition.get("levels", []):
			if level_definition is Dictionary and int((level_definition as Dictionary).get("level", -1)) == new_level:
				for reward: Variant in (level_definition as Dictionary).get("rewards", []):
					if reward is Dictionary:
						rewards.append((reward as Dictionary).duplicate(true))
				break
	state_changes.append({
		"type": "LANDMARK_COMMIT",
		"landmark_id": landmark_id,
		"resolution_id": resolution_id,
	})
	return {
		"resolution_id": resolution_id,
		"result_id": "landmark_developed" if new_level > old_level else "landmark_complete",
		"result": {
			"landmark_id": landmark_id,
			"name": str(definition.get("name", "名所")),
			"district": str(definition.get("district", "")),
			"old_level": old_level,
			"new_level": new_level,
			"developed": new_level > old_level,
		},
		"state_changes": state_changes,
		"rewards": rewards,
	}

static func development_total(levels: Dictionary) -> int:
	var total := 0
	for definition: Dictionary in definitions():
		total += clampi(int(levels.get(str(definition.get("id", "")), 0)), 0, MAX_LEVEL)
	return total
