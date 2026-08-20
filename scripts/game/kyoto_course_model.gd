class_name KyotoCourseModel
extends RefCounted

const COURSE_PATH := "res://data/stages/kyoto_thousand_year_grid.json"

var definition: Dictionary = {}
var spaces: Dictionary = {}
var branches: Dictionary = {}
var district_by_main_number: Dictionary = {}
var validation_error := "INVALID_KYOTO_COURSE"


func load_file(path: String = COURSE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		validation_error = "COURSE_FILE_MISSING"
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return load_definition(parsed as Dictionary) if parsed is Dictionary else false


func load_definition(data: Dictionary) -> bool:
	definition.clear()
	spaces.clear()
	branches.clear()
	district_by_main_number.clear()
	validation_error = "INVALID_KYOTO_COURSE"
	if int(data.get("schema_version", 0)) != 2 or str(data.get("stage_id", "")) != "kyoto_thousand_year_grid" or int(data.get("space_count", 0)) != 90:
		return false
	for district_value: Variant in data.get("districts", []):
		if not district_value is Dictionary:
			continue
		var district := district_value as Dictionary
		var span: Array = district.get("range", [])
		if span.size() != 2:
			continue
		for number: int in range(int(span[0]), int(span[1]) + 1):
			district_by_main_number[number] = district.duplicate(true)
	for value: Variant in data.get("main_spaces", []):
		if not value is Dictionary:
			return false
		var item := (value as Dictionary).duplicate(true)
		var number := int(item.get("number", 0))
		if number < 1 or number > 90:
			return false
		var id := "main:%d" % number
		if spaces.has(id):
			return false
		item["id"] = id
		item["route"] = "main"
		item["next_id"] = "main:%d" % (number + 1) if number < 90 else ""
		spaces[id] = item
	for value: Variant in data.get("branches", []):
		if not value is Dictionary:
			return false
		var branch := (value as Dictionary).duplicate(true)
		var branch_id := str(branch.get("id", ""))
		if branch_id.is_empty() or branches.has(branch_id):
			return false
		branches[branch_id] = branch
	var routes: Array = data.get("routes", [])
	for route_value: Variant in routes:
		if not route_value is Dictionary:
			return false
		var route := route_value as Dictionary
		var route_spaces: Array = route.get("spaces", [])
		for index: int in range(route_spaces.size()):
			if not route_spaces[index] is Dictionary:
				return false
			var item := (route_spaces[index] as Dictionary).duplicate(true)
			var id := str(item.get("id", ""))
			if id.is_empty() or spaces.has(id):
				return false
			item["route"] = str(route.get("id", ""))
			item["route_order"] = index
			item["route_count"] = route_spaces.size()
			item["next_id"] = str((route_spaces[index + 1] as Dictionary).get("id", "")) if index + 1 < route_spaces.size() else str(route.get("rejoin", ""))
			spaces[id] = item
	if data.get("main_spaces", []).size() != 90 or not spaces.has("main:1") or not spaces.has("main:90"):
		return false
	if branches.size() != int(data.get("branch_count", -1)) or routes.size() != int(data.get("route_count", -1)):
		return false
	for item: Dictionary in spaces.values():
		var next_id := str(item.get("next_id", ""))
		if not next_id.is_empty() and not spaces.has(next_id):
			return false
		var branch_id := str(item.get("branch_id", ""))
		if not branch_id.is_empty() and not branches.has(branch_id):
			return false
	for branch: Dictionary in branches.values():
		if not spaces.has(str(branch.get("choice_space", ""))):
			return false
		for choice_value: Variant in branch.get("choices", []):
			if not choice_value is Dictionary or not spaces.has(str((choice_value as Dictionary).get("target", ""))):
				return false
	for route_value: Variant in routes:
		var route := route_value as Dictionary
		if not spaces.has(str(route.get("rejoin", ""))):
			return false
	var goshuin_ids: Dictionary = {}
	for item: Dictionary in spaces.values():
		if str(item.get("kind", "")) == "GOSHUIN":
			var goshuin_id := str(item.get("goshuin", ""))
			if goshuin_id not in ["fushimi", "yasaka", "kiyomizu", "tenryuji"] or goshuin_ids.has(goshuin_id):
				return false
			goshuin_ids[goshuin_id] = true
	if goshuin_ids.size() != 4:
		return false
	var expected_kind_counts := {"NORMAL": 43, "COIN": 10, "REST": 7, "RISK": 9, "ITEM": 8, "EVENT": 3, "GOSHUIN": 4, "BYPASS_FORK": 2, "START": 1, "BOSS_FORK": 1, "BOSS_APPROACH": 1, "BOSS": 1}
	var actual_kind_counts: Dictionary = {}
	var auto_event_count := 0
	var choice_event_count := 0
	for number: int in range(1, 91):
		var main_space := space("main:%d" % number)
		var kind := str(main_space.get("kind", ""))
		actual_kind_counts[kind] = int(actual_kind_counts.get(kind, 0)) + 1
		if kind == "EVENT":
			if str(main_space.get("event_mode", "")) == "auto":
				auto_event_count += 1
			elif str(main_space.get("event_mode", "")) == "choice":
				choice_event_count += 1
	for kind: String in expected_kind_counts:
		if int(actual_kind_counts.get(kind, 0)) != int(expected_kind_counts[kind]):
			return false
	if auto_event_count != 2 or choice_event_count != 1:
		return false
	var boss_choice: Dictionary = data.get("boss_choice", {})
	var boss_choices: Array = boss_choice.get("choices", [])
	if str(boss_choice.get("trigger_space_id", "")) != "main:88" or str(boss_choice.get("approach_space_id", "")) != "main:89" or str(boss_choice.get("boss_space_id", "")) != "main:90" or boss_choices.size() != 2:
		return false
	var boss_ids: Array[String] = []
	for choice_value: Variant in boss_choices:
		if not choice_value is Dictionary:
			return false
		boss_ids.append(str((choice_value as Dictionary).get("id", "")))
	if not "direct" in boss_ids or not "foxfire" in boss_ids:
		return false
	definition = data.duplicate(true)
	validation_error = ""
	return true


func start_space_id() -> String:
	return str(definition.get("start_space_id", "main:1"))


func boss_space_id() -> String:
	return str(definition.get("boss_space_id", "main:90"))


func space(space_id: String) -> Dictionary:
	return (spaces.get(space_id, {}) as Dictionary).duplicate(true)


func branch(branch_id: String) -> Dictionary:
	return (branches.get(branch_id, {}) as Dictionary).duplicate(true)


func district_for_space(space_id: String) -> Dictionary:
	if not space_id.begins_with("main:"):
		return {}
	return (district_by_main_number.get(int(space_id.get_slice(":", 1)), {}) as Dictionary).duplicate(true)


func next_step(space_id: String, selected_target: String = "") -> Dictionary:
	var current := space(space_id)
	if current.is_empty():
		return {"ok": false, "error": "UNKNOWN_SPACE", "position": space_id}
	if str(current.get("kind", "")) == "BOSS":
		return {"ok": true, "position": space_id, "boss_reached": true}
	if str(current.get("kind", "")) == "BOSS_FORK" and selected_target.is_empty():
		return {"ok": false, "status": "BOSS_CHOICE_REQUIRED", "position": space_id, "boss_choice": boss_choice()}
	var branch_id := str(current.get("branch_id", ""))
	if not branch_id.is_empty() and selected_target.is_empty():
		return {"ok": false, "status": "CHOICE_REQUIRED", "position": space_id, "branch": branch(branch_id)}
	var next_id := selected_target if not selected_target.is_empty() else str(current.get("next_id", ""))
	if not spaces.has(next_id):
		return {"ok": false, "error": "INVALID_NEXT_SPACE", "position": space_id}
	return {"ok": true, "position": next_id, "boss_reached": next_id == boss_space_id()}


func advance(start_id: String, distance: int, selected_target: String = "") -> Dictionary:
	if not spaces.has(start_id) or distance < 1 or distance > 12:
		return {"ok": false, "error": "INVALID_ADVANCE", "position": start_id}
	var current := start_id
	var remaining := distance
	var path: Array[String] = []
	var target := selected_target
	while remaining > 0:
		var step := next_step(current, target)
		target = ""
		if not bool(step.get("ok", false)):
			step["remaining_steps"] = remaining
			step["path"] = path
			return step
		var next_id := str(step.get("position", current))
		if next_id == current:
			break
		current = next_id
		path.append(current)
		remaining -= 1
		if bool(step.get("boss_reached", false)):
			break
	if remaining == 0:
		var stop := next_step(current)
		if not bool(stop.get("ok", false)) and str(stop.get("status", "")) in ["CHOICE_REQUIRED", "BOSS_CHOICE_REQUIRED"]:
			stop["remaining_steps"] = 0
			stop["path"] = path
			return stop
	return {"ok": true, "position": current, "remaining_steps": remaining, "path": path, "boss_reached": current == boss_space_id()}


func boss_choice() -> Dictionary:
	return (definition.get("boss_choice", {}) as Dictionary).duplicate(true)
