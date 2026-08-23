class_name JourneySaveManager
extends RefCounted

const SAVE_PATH := "user://journey_stage_v1.json"
const SCHEMA_VERSION := 1
const RESUMABLE_STAGE_IDS: Array[StringName] = [
	&"amazon_suiu_falls",
	&"kyoto_thousand_year_grid",
]


func save(stage_id: StringName, journey_snapshot: Dictionary, boss_snapshot: Dictionary = {}) -> bool:
	var payload := {
		"schema_version": SCHEMA_VERSION,
		"stage_id": String(stage_id),
		"journey": journey_snapshot.duplicate(true),
		"boss": boss_snapshot.duplicate(true),
		"saved_unix": int(Time.get_unix_time_from_system()),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true


static func load_for_stage(stage_id: StringName) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary:
		return {}
	var payload := parsed as Dictionary
	if int(payload.get("schema_version", 0)) != SCHEMA_VERSION or str(payload.get("stage_id", "")) != String(stage_id):
		return {}
	return payload.duplicate(true)


static func saved_stage_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for stage_id: StringName in RESUMABLE_STAGE_IDS:
		if not load_for_stage(stage_id).is_empty():
			result.append(stage_id)
	return result


func has_stage_save(stage_id: StringName) -> bool:
	return not load_for_stage(stage_id).is_empty()
