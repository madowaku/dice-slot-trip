extends RefCounted

## Synchronous single-writer store. Only verified files become checkpoints;
## a failed install leaves the preceding checkpoint available in .bak.
static func read_candidate(path: String, validator: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "ok": false, "data": {}}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": true, "ok": false, "data": {}}
	var parser: JSON = JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {"exists": true, "ok": false, "data": {}}
	var data: Dictionary = parser.data
	return {"exists": true, "ok": bool(validator.call(data)), "data": data}

static func load_data(path: String, validator: Callable) -> Dictionary:
	var primary: Dictionary = read_candidate(path, validator)
	if primary.ok:
		return primary.data
	var backup: Dictionary = read_candidate(path + ".bak", validator)
	return backup.data if backup.ok else {}

static func save_data(path: String, data: Dictionary, validator: Callable, faults: Dictionary = {}) -> bool:
	if not bool(validator.call(data)):
		return false
	var primary: Dictionary = read_candidate(path, validator)
	var backup: Dictionary = read_candidate(path + ".bak", validator)
	# Never replace unrecoverable existing progress with caller defaults.
	if not primary.ok and not backup.ok and (primary.exists or backup.exists):
		return false
	var temp: String = path + ".tmp"
	if bool(faults.get("temp_open", false)):
		return false
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var content: String = JSON.stringify(data)
	file.store_string(content.left(1) if bool(faults.get("temp_write", false)) else content)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	var verified: Dictionary = read_candidate(temp, validator)
	if write_error != OK or not verified.ok:
		return false
	if primary.ok:
		if bool(faults.get("backup_rename", false)):
			return false
		if backup.exists and DirAccess.remove_absolute(_absolute(path + ".bak")) != OK:
			return false
		if DirAccess.rename_absolute(_absolute(path), _absolute(path + ".bak")) != OK:
			return false
	elif primary.exists:
		if not quarantine(path):
			return false
	if bool(faults.get("install_rename", false)):
		return false
	if DirAccess.rename_absolute(_absolute(temp), _absolute(path)) != OK:
		return false
	return bool(read_candidate(path, validator).ok)

static func quarantine(path: String) -> bool:
	var destination: String = path + ".corrupt"
	var index: int = 0
	while FileAccess.file_exists(destination):
		index += 1
		destination = path + ".corrupt.%d" % index
	return DirAccess.rename_absolute(_absolute(path), _absolute(destination)) == OK

static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)
