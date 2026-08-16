class_name AmazonCourseModel
extends RefCounted

var definition: Dictionary = {}
var spaces: Dictionary = {}
var events: Dictionary = {}
var validation_error := "INVALID_AMAZON_COURSE"


func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		validation_error = "COURSE_FILE_MISSING"
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return load_definition(parsed as Dictionary) if parsed is Dictionary else false


func load_definition(data: Dictionary) -> bool:
	definition.clear()
	spaces.clear()
	events.clear()
	if str(data.get("stage_id", "")) != "amazon_suiu_falls" or int(data.get("space_count", 0)) != 120:
		return false
	for value: Variant in data.get("spaces", []):
		if not value is Dictionary:
			return false
		var space := value as Dictionary
		var id := str(space.get("id", ""))
		if id.is_empty() or spaces.has(id):
			return false
		spaces[id] = space.duplicate(true)
	for value: Variant in data.get("events", []):
		if value is Dictionary:
			var event := value as Dictionary
			events[str(event.get("id", ""))] = event.duplicate(true)
	if spaces.size() != 120 or not spaces.has("main:1") or not spaces.has("main:120") or events.size() != 15:
		return false
	for space: Dictionary in spaces.values():
		for target: Variant in space.get("next", []):
			if not spaces.has(str(target)):
				return false
		for nested_key: String in ["transition", "secret_entry"]:
			var nested: Variant = space.get(nested_key, null)
			if nested is Dictionary and not spaces.has(str((nested as Dictionary).get("target", ""))):
				return false
		var event_id := str(space.get("event_id", ""))
		if not event_id.is_empty() and not events.has(event_id):
			return false
	definition = data.duplicate(true)
	validation_error = ""
	return true


func start_space_id() -> String:
	return str(definition.get("start_space_id", "main:1"))


func boss_space_id() -> String:
	return str(definition.get("boss_space_id", "main:120"))


func space(space_id: String) -> Dictionary:
	return (spaces.get(space_id, {}) as Dictionary).duplicate(true)


func event(event_id: String) -> Dictionary:
	return (events.get(event_id, {}) as Dictionary).duplicate(true)


func route_groups() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value: Variant in definition.get("route_groups", []):
		if value is Dictionary:
			result.append((value as Dictionary).duplicate(true))
	return result


func advance(start_id: String, distance: int, route_choice: String = "") -> Dictionary:
	if not spaces.has(start_id) or distance < 1 or distance > 12:
		return {"ok": false, "error": "INVALID_ADVANCE", "position": start_id}
	var current := start_id
	var remaining := distance
	var path: Array[String] = []
	while remaining > 0:
		var current_space := space(current)
		if str(current_space.get("kind", "")) == "BOSS":
			break
		var next_values: Array = current_space.get("next", [])
		if next_values.size() > 1:
			if route_choice.is_empty():
				return {
					"ok": false,
					"status": "CHOICE_REQUIRED",
					"position": current,
					"remaining_steps": remaining,
					"path": path,
					"choices": (current_space.get("branch", {}) as Dictionary).get("choices", []).duplicate(true),
				}
			var matched := ""
			for choice: Dictionary in (current_space.get("branch", {}) as Dictionary).get("choices", []):
				if route_choice in [str(choice.get("id", "")), str(choice.get("target", ""))]:
					matched = str(choice.get("target", ""))
			if matched.is_empty():
				return {"ok": false, "error": "INVALID_ROUTE_CHOICE", "position": current}
			current = matched
		else:
			if next_values.is_empty():
				break
			current = str(next_values[0])
		path.append(current)
		remaining -= 1
	return {
		"ok": true,
		"status": "BOSS_REACHED" if current == boss_space_id() else "OK",
		"position": current,
		"remaining_steps": remaining,
		"path": path,
		"boss_reached": current == boss_space_id(),
	}

