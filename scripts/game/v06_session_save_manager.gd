class_name V06SessionSaveManager
extends RefCounted

const V06SessionSaveDataScript = preload("res://scripts/game/v06_session_save_data.gd")

const DEFAULT_SAVE_PATH := "user://v06_session_v1.json"
const OLD_SAVE_PATH := "user://dice_slot_trip_save.json"
const STATUS_VALID_PRIMARY := "VALID_PRIMARY"
const STATUS_RECOVERED_BACKUP := "RECOVERED_BACKUP"
const STATUS_NO_SAVE := "NO_SAVE"
const STATUS_INCOMPATIBLE_VERSION := "INCOMPATIBLE_VERSION"
const STATUS_CORRUPT := "CORRUPT"
const STATUS_SAVED := "SAVED"
const STATUS_WRITE_FAILED := "WRITE_FAILED"
const STATUS_NOT_STABLE := "NOT_STABLE"

var save_path: String
var backup_path: String
var temp_path: String
var backup_hold_path: String
var test_faults: Dictionary = {}


func _init(base_path: String = DEFAULT_SAVE_PATH) -> void:
	save_path = base_path
	backup_path = "%s.bak" % base_path
	temp_path = "%s.tmp" % base_path
	backup_hold_path = "%s.swap" % backup_path


func set_test_fault(name: String, enabled: bool = true) -> void:
	test_faults[name] = enabled


func clear_test_faults() -> void:
	test_faults.clear()


func _fault(name: String) -> bool:
	return bool(test_faults.get(name, false))


func has_valid_save() -> bool:
	var result := load_result()
	return str(result.get("status", STATUS_NO_SAVE)) in [STATUS_VALID_PRIMARY, STATUS_RECOVERED_BACKUP]


func load_result() -> Dictionary:
	# A stale temp file is never a candidate. Ignore it and remove it when possible.
	_cleanup_temp()
	var primary := _read_candidate(save_path)
	if str(primary.get("status", "")) == V06SessionSaveDataScript.STATUS_INCOMPATIBLE_VERSION:
		return {"ok": false, "status": STATUS_INCOMPATIBLE_VERSION, "data": {}}
	if bool(primary.get("valid", false)):
		return {"ok": true, "status": STATUS_VALID_PRIMARY, "data": primary.get("data", {})}
	var backup := _read_candidate(backup_path)
	if bool(backup.get("valid", false)):
		push_warning("V06 primary save was unavailable; recovered the backup save.")
		return {"ok": true, "status": STATUS_RECOVERED_BACKUP, "data": backup.get("data", {})}
	if not bool(primary.get("exists", false)) and not bool(backup.get("exists", false)):
		return {"ok": false, "status": STATUS_NO_SAVE, "data": {}}
	if str(backup.get("status", "")) == V06SessionSaveDataScript.STATUS_INCOMPATIBLE_VERSION:
		return {"ok": false, "status": STATUS_INCOMPATIBLE_VERSION, "data": {}}
	return {"ok": false, "status": STATUS_CORRUPT, "data": {}}


func save_session(session: RefCounted) -> Dictionary:
	if session == null or not session.has_method("is_stable_for_save") or not bool(session.is_stable_for_save()):
		return {"ok": false, "status": STATUS_NOT_STABLE}
	var dto: Dictionary = V06SessionSaveDataScript.from_session(session)
	var dto_validation := V06SessionSaveDataScript.validate(dto)
	if not bool(dto_validation.get("ok", false)):
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "DTO validation failed: %s" % str(dto_validation.get("error", "unknown"))}
	var write_result := _write_temp_and_verify(dto)
	if not bool(write_result.get("ok", false)):
		return write_result
	var primary_before := _read_candidate(save_path)
	if bool(primary_before.get("exists", false)) and not bool(primary_before.get("valid", false)):
		_cleanup_temp()
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "existing primary is invalid; left it untouched"}
	var had_primary := bool(primary_before.get("exists", false))
	var moved_primary := false
	var moved_old_backup := false
	if had_primary:
		if FileAccess.file_exists(backup_hold_path) and DirAccess.remove_absolute(_absolute(backup_hold_path)) != OK:
			_cleanup_temp()
			return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not clear stale backup swap"}
		if FileAccess.file_exists(backup_path):
			if _fault("fail_backup_to_hold_rename") or DirAccess.rename_absolute(_absolute(backup_path), _absolute(backup_hold_path)) != OK:
				_cleanup_temp()
				return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not stage old backup"}
			moved_old_backup = true
		if _fault("fail_primary_to_backup_rename") or DirAccess.rename_absolute(_absolute(save_path), _absolute(backup_path)) != OK:
			if moved_old_backup:
				DirAccess.rename_absolute(_absolute(backup_hold_path), _absolute(backup_path))
			_cleanup_temp()
			return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not move primary to backup"}
		moved_primary = true
	if _fault("fail_temp_to_primary_rename") or DirAccess.rename_absolute(_absolute(temp_path), _absolute(save_path)) != OK:
		_cleanup_temp()
		_restore_primary_from_backup()
		_cleanup_backup_hold()
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not install primary"}
	var installed := {"valid": false}
	if not _fault("fail_final_readback"):
		installed = _read_candidate(save_path)
	if not bool(installed.get("valid", false)):
		DirAccess.remove_absolute(_absolute(save_path))
		_restore_primary_from_backup()
		_cleanup_backup_hold()
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "read-back validation failed"}
	_cleanup_backup_hold()
	return {"ok": true, "status": STATUS_SAVED, "data": installed.get("data", {})}


func _write_temp_and_verify(dto: Dictionary) -> Dictionary:
	_cleanup_temp()
	if _fault("fail_temp_open"):
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not open temporary save"}
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "could not open temporary save"}
	var serialized := JSON.stringify(dto, "  ")
	if _fault("fail_temp_write") or _fault("fail_temp_flush"):
		serialized = serialized.left(maxi(1, serialized.length() / 2))
	file.store_string(serialized)
	if not _fault("fail_temp_flush"):
		file.flush()
	file.close()
	if _fault("fail_temp_close") or _fault("fail_temp_parse") or _fault("fail_temp_validation"):
		_cleanup_temp()
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "temporary save operation failed"}
	var verified := _read_candidate(temp_path)
	if not bool(verified.get("valid", false)):
		_cleanup_temp()
		return {"ok": false, "status": STATUS_WRITE_FAILED, "error": "temporary save did not validate"}
	return {"ok": true, "status": STATUS_SAVED}


func _read_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "valid": false, "status": STATUS_NO_SAVE, "data": {}}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": true, "valid": false, "status": STATUS_CORRUPT, "data": {}}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {"exists": true, "valid": false, "status": STATUS_CORRUPT, "data": {}}
	var parsed: Variant = parser.data
	var validation := V06SessionSaveDataScript.validate(parsed)
	return {"exists": true, "valid": bool(validation.get("ok", false)), "status": str(validation.get("status", STATUS_CORRUPT)), "data": parsed if bool(validation.get("ok", false)) else {}, "error": str(validation.get("error", ""))}


func _cleanup_temp() -> void:
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(_absolute(temp_path))


func _cleanup_backup_hold() -> void:
	if FileAccess.file_exists(backup_hold_path):
		DirAccess.remove_absolute(_absolute(backup_hold_path))


func _restore_primary_from_backup() -> bool:
	var backup := _read_candidate(backup_path)
	if not bool(backup.get("valid", false)):
		return false
	return DirAccess.copy_absolute(_absolute(backup_path), _absolute(save_path)) == OK


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)
