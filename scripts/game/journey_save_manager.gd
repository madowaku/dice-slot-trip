class_name JourneySaveManager
extends RefCounted

const SAVE_PATH := "user://journey_stage_v1.json"
const SafeJsonStore = preload("res://scripts/game/safe_json_store.gd")
const SCHEMA_VERSION := 1
const RESUMABLE_STAGE_IDS: Array[StringName] = [
	&"amazon_suiu_falls",
	&"kyoto_thousand_year_grid",
]
static var _test_save_directory: String = ""


func save(stage_id: StringName, journey_snapshot: Dictionary, boss_snapshot: Dictionary = {}) -> bool:
	if stage_id not in RESUMABLE_STAGE_IDS:
		return false
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"stage_id": String(stage_id),
		"journey": journey_snapshot.duplicate(true),
		"boss": boss_snapshot.duplicate(true),
		"saved_unix": int(Time.get_unix_time_from_system()),
	}
	return SafeJsonStore.save_data(stage_save_path(stage_id), payload, _valid_payload.bind(stage_id))

static func stage_save_path(stage_id: StringName) -> String:
	var directory: String = "user://" if _test_save_directory.is_empty() else _test_save_directory.trim_suffix("/") + "/"
	return directory + "journey_stage_v1_%s.json" % String(stage_id)

static func legacy_save_path() -> String:
	return SAVE_PATH if _test_save_directory.is_empty() else _test_save_directory.trim_suffix("/") + "/journey_stage_v1.json"

static func _valid_payload(payload: Dictionary, stage_id: StringName) -> bool:
	return int(payload.get("schema_version", 0)) == SCHEMA_VERSION and str(payload.get("stage_id", "")) == String(stage_id) and payload.get("journey") is Dictionary and payload.get("boss", {}) is Dictionary


static func load_for_stage(stage_id: StringName) -> Dictionary:
	if stage_id not in RESUMABLE_STAGE_IDS:
		return {}
	var path: String = stage_save_path(stage_id)
	# Only fall back to the legacy slot before migration, never after corruption.
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		return SafeJsonStore.load_data(path, _valid_payload.bind(stage_id))
	return SafeJsonStore.load_data(legacy_save_path(), _valid_payload.bind(stage_id))


static func saved_stage_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for stage_id: StringName in RESUMABLE_STAGE_IDS:
		if not load_for_stage(stage_id).is_empty():
			result.append(stage_id)
	return result


func has_stage_save(stage_id: StringName) -> bool:
	return not load_for_stage(stage_id).is_empty()
