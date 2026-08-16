class_name KyotoJourney
extends StageJourneyBase

const GOSHUIN_IDS := ["fushimi", "yasaka", "kiyomizu", "tenryuji"]

var course := KyotoCourseModel.new()
var course_ready := false


func _init() -> void:
	stage_id = StageCatalog.STAGE_KYOTO
	stage_name = "千年碁盤の京都"
	max_hp = MAX_HEARTS
	hp = max_hp
	stage_flags = {
		"goshuin": {"fushimi": false, "yasaka": false, "kiyomizu": false, "tenryuji": false},
		"next_coin_multiplier": 1,
		"otowa_luck_shift": false,
		"completed_loops": {},
		"kyoto_route_tutorial_seen": false,
		"kyoto_goshuin_tutorial_seen": false,
		"skill_gauge": 0,
		"item_count": 0,
		"item_inventory": {},
		"mission_rest_count": 0,
	}
	course_ready = course.load_file()
	current_space_id = course.start_space_id() if course_ready else "main:1"
	discovered[current_space_id] = true


func roll(face: int) -> Dictionary:
	if not course_ready:
		return _reject("INVALID_KYOTO_COURSE")
	if not can_roll() or face < 1 or face > 6:
		return _reject("ROLL_NOT_AVAILABLE")
	roll_count += 1
	var item_bonus := next_move_bonus()
	var move_face := face + item_bonus
	var result := course.advance(current_space_id, move_face)
	var passed_goshuin: Array[Dictionary] = _mark_passed(result.get("path", []))
	if not bool(result.get("ok", false)) and str(result.get("status", "")) == "CHOICE_REQUIRED":
		if item_bonus > 0:
			consume_next_move_bonus()
		current_space_id = str(result.get("position", current_space_id))
		pending_steps = int(result.get("remaining_steps", 0))
		pending_event = (result.get("branch", {}) as Dictionary).duplicate(true)
		pending_choices.clear()
		for value: Variant in pending_event.get("choices", []):
			if value is Dictionary:
				pending_choices.append((value as Dictionary).duplicate(true))
		phase = PHASE_BRANCH
		last_result = {"ok": true, "status": "CHOICE_REQUIRED", "face": face, "move_face": move_face, "item_bonus": item_bonus, "path": result.get("path", []), "branch": pending_event.duplicate(true)}
		_append_goshuin_result(last_result, passed_goshuin)
		return last_result.duplicate(true)
	if not bool(result.get("ok", false)):
		return result
	if item_bonus > 0:
		consume_next_move_bonus()
	current_space_id = str(result.get("position", current_space_id))
	last_result = {"ok": true, "status": "MOVED", "face": face, "move_face": move_face, "item_bonus": item_bonus, "path": result.get("path", [])}
	_append_goshuin_result(last_result, passed_goshuin)
	_resolve_landing()
	return last_result.duplicate(true)


func choose_branch(choice_id: String) -> Dictionary:
	if phase != PHASE_BRANCH:
		return _reject("BRANCH_NOT_AVAILABLE")
	var matched: Dictionary = {}
	for value: Variant in pending_choices:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == choice_id:
			matched = (value as Dictionary).duplicate(true)
	if matched.is_empty():
		return _reject("INVALID_BRANCH_CHOICE")
	var branch_id := str(pending_event.get("id", ""))
	if bool(matched.get("once_per_lap", false)) and (stage_flags.get("completed_loops", {}) as Dictionary).has(branch_id):
		return _reject("ROUTE_ALREADY_USED")
	var cost := int(matched.get("cost", 0))
	if coins < cost:
		return _reject("NOT_ENOUGH_COINS")
	coins -= cost
	if bool(matched.get("once_per_lap", false)):
		(stage_flags.get("completed_loops", {}) as Dictionary)[branch_id] = true
	var result := course.advance(current_space_id, pending_steps, str(matched.get("target", "")))
	if not bool(result.get("ok", false)) and str(result.get("status", "")) != "CHOICE_REQUIRED":
		return result
	var passed_goshuin: Array[Dictionary] = _mark_passed(result.get("path", []))
	current_space_id = str(result.get("position", current_space_id))
	if str(result.get("status", "")) == "CHOICE_REQUIRED":
		pending_steps = int(result.get("remaining_steps", 0))
		pending_event = (result.get("branch", {}) as Dictionary).duplicate(true)
		pending_choices.clear()
		for value: Variant in pending_event.get("choices", []):
			if value is Dictionary:
				pending_choices.append((value as Dictionary).duplicate(true))
		phase = PHASE_BRANCH
		last_result = {"ok": true, "status": "CHOICE_REQUIRED", "choice_id": choice_id, "path": result.get("path", [])}
		_append_goshuin_result(last_result, passed_goshuin)
		return last_result.duplicate(true)
	pending_steps = 0
	pending_choices.clear()
	pending_event.clear()
	phase = PHASE_READY
	last_result = {"ok": true, "status": "BRANCH_RESOLVED", "choice_id": choice_id, "path": result.get("path", [])}
	_append_goshuin_result(last_result, passed_goshuin)
	if current_space_id.begins_with("river_boat:"):
		last_result["camera_cue"] = "river_crossing"
	_resolve_landing()
	return last_result.duplicate(true)


func resolve_event(choice_id: String = "") -> Dictionary:
	if phase != PHASE_EVENT:
		return _reject("EVENT_NOT_AVAILABLE")
	var event_id := str(pending_event.get("event_id", ""))
	if event_id == "otowa_three_waters":
		match choice_id:
			"health": hp = mini(hp + 2, max_hp)
			"commerce": stage_flags["next_coin_multiplier"] = 2
			"luck": stage_flags["otowa_luck_shift"] = true
			_: return _reject("INVALID_EVENT_CHOICE")
	else:
		match choice_id:
			"heal": hp = mini(hp + 1, max_hp)
			"coin": coins += 2
			_: return _reject("INVALID_EVENT_CHOICE")
	pending_event.clear()
	phase = PHASE_READY
	last_result = {"ok": true, "status": "EVENT_RESOLVED", "choice_id": choice_id}
	return last_result.duplicate(true)


func goshuin_state() -> Dictionary:
	return _ensure_goshuin_flags().duplicate(true)


func goshuin_count() -> int:
	var count := 0
	for value: Variant in _ensure_goshuin_flags().values():
		if bool(value):
			count += 1
	return count


func _mark_passed(path: Array) -> Array[Dictionary]:
	var acquired: Array[Dictionary] = []
	var goshuin_state := _ensure_goshuin_flags()
	for value: Variant in path:
		var id := str(value)
		discovered[id] = true
		var passed := course.space(id)
		if str(passed.get("kind", "")) == "GOSHUIN":
			var goshuin_id := str(passed.get("goshuin", ""))
			if not goshuin_id.is_empty() and not bool(goshuin_state.get(goshuin_id, false)):
				goshuin_state[goshuin_id] = true
				acquired.append({
					"id": goshuin_id,
					"space_id": id,
					"title": _goshuin_title(goshuin_id),
					"space_name": str(passed.get("name", "御朱印所")),
				})
	return acquired


func _ensure_goshuin_flags() -> Dictionary:
	var flags: Dictionary = {}
	var raw: Variant = stage_flags.get("goshuin", {})
	if raw is Dictionary:
		flags = (raw as Dictionary).duplicate(true)
	for value: Variant in GOSHUIN_IDS:
		var goshuin_id := str(value)
		flags[goshuin_id] = bool(flags.get(goshuin_id, false))
	stage_flags["goshuin"] = flags
	return flags


func _append_goshuin_result(target: Dictionary, acquired: Array[Dictionary]) -> void:
	if acquired.is_empty():
		return
	target["goshuin_passed"] = acquired.duplicate(true)
	if acquired.size() == 1:
		target["goshuin_acquired"] = str(acquired[0].get("id", ""))


func _goshuin_title(goshuin_id: String) -> String:
	return {
		"fushimi": "伏見稲荷",
		"yasaka": "八坂神社",
		"kiyomizu": "清水寺",
		"tenryuji": "天龍寺",
	}.get(goshuin_id, "寺社")


func _resolve_landing() -> void:
	var current := course.space(current_space_id)
	var kind := str(current.get("kind", "NORMAL"))
	score += 10
	if kind == "REST":
		stage_flags["mission_rest_count"] = mini(int(stage_flags.get("mission_rest_count", 0)) + 1, 5)
	match kind:
		"COIN":
			var multiplier := int(stage_flags.get("next_coin_multiplier", 1))
			coins += int(current.get("amount", 2)) * multiplier
			stage_flags["next_coin_multiplier"] = 1
		"ITEM":
			var item_result := grant_random_item()
			last_result.merge(item_result)
			last_result["item_acquired"] = not bool(item_result.get("full", false))
		"REST": last_result.merge(apply_rest_landing())
		"RISK":
			if consume_risk_shield():
				last_result["item_guarded"] = true
			else:
				hp = maxi(hp - 1, 0)
		"EVENT":
			pending_event = current.duplicate(true)
			phase = PHASE_EVENT
			last_result["status"] = "EVENT_REQUIRED"
		"BOSS":
			phase = PHASE_BOSS
			last_result["status"] = "BOSS_READY"
	var life_result := resolve_life_if_needed()
	if bool(life_result.get("run_over", false)):
		last_result["status"] = "RUN_OVER"
	elif bool(life_result.get("revived", false)):
		last_result["revived"] = true


func district() -> Dictionary:
	return course.district_for_space(current_space_id)


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}


func start_next_lap() -> void:
	super.start_next_lap()
	current_space_id = course.start_space_id()
	stage_flags["goshuin"] = {"fushimi": false, "yasaka": false, "kiyomizu": false, "tenryuji": false}
	stage_flags["completed_loops"] = {}
	stage_flags["next_coin_multiplier"] = 1
	stage_flags["otowa_luck_shift"] = false
	discovered[current_space_id] = true
