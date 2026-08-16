class_name AmazonJourney
extends StageJourneyBase

const COURSE_PATH := "res://data/stages/amazon_suiu_falls_course.json"

var course := AmazonCourseModel.new()
var course_ready := false


func _init() -> void:
	stage_id = StageCatalog.STAGE_AMAZON
	stage_name = "翠雨の大瀑布"
	max_hp = MAX_HEARTS
	hp = max_hp
	stage_flags = {
		"amazon_flow_tutorial_seen": false,
		"skill_gauge": 0,
		"item_count": 0,
		"item_inventory": {},
		"mission_event_count": 0,
	}
	course_ready = course.load_file(COURSE_PATH)
	current_space_id = course.start_space_id() if course_ready else "main:1"
	discovered[current_space_id] = true


func roll(face: int) -> Dictionary:
	if not course_ready:
		return _reject("INVALID_AMAZON_COURSE")
	if not can_roll() or face < 1 or face > 6:
		return _reject("ROLL_NOT_AVAILABLE")
	roll_count += 1
	var item_bonus := next_move_bonus()
	var move_face := face + item_bonus
	var result := course.advance(current_space_id, move_face)
	for id: String in result.get("path", []):
		discovered[id] = true
	if not bool(result.get("ok", false)) and str(result.get("status", "")) == "CHOICE_REQUIRED":
		if item_bonus > 0:
			consume_next_move_bonus()
		current_space_id = str(result.get("position", current_space_id))
		pending_steps = int(result.get("remaining_steps", 0))
		pending_choices.clear()
		for value: Variant in result.get("choices", []):
			if value is Dictionary:
				pending_choices.append((value as Dictionary).duplicate(true))
		phase = PHASE_BRANCH
		last_result = {"ok": true, "status": "CHOICE_REQUIRED", "face": face, "move_face": move_face, "item_bonus": item_bonus, "path": result.get("path", [])}
		return last_result.duplicate(true)
	if not bool(result.get("ok", false)):
		return result
	if item_bonus > 0:
		consume_next_move_bonus()
	current_space_id = str(result.get("position", current_space_id))
	last_result = {"ok": true, "status": "MOVED", "face": face, "move_face": move_face, "item_bonus": item_bonus, "path": result.get("path", [])}
	_resolve_landing(true)
	return last_result.duplicate(true)


func choose_branch(choice_id: String) -> Dictionary:
	if phase != PHASE_BRANCH:
		return _reject("BRANCH_NOT_AVAILABLE")
	# Keep old/in-flight saves safe too: an Amazon junction opened on an exact
	# landing owns one route-entry hop even if its transient counter was saved as
	# zero by an earlier build.
	var result := course.advance(current_space_id, maxi(pending_steps, 1), choice_id)
	if not bool(result.get("ok", false)):
		return result
	for id: String in result.get("path", []):
		discovered[id] = true
	current_space_id = str(result.get("position", current_space_id))
	if str(result.get("status", "")) == "CHOICE_REQUIRED":
		pending_steps = int(result.get("remaining_steps", 0))
		pending_choices.clear()
		for value: Variant in result.get("choices", []):
			if value is Dictionary:
				pending_choices.append((value as Dictionary).duplicate(true))
		phase = PHASE_BRANCH
		last_result = {"ok": true, "status": "CHOICE_REQUIRED", "choice_id": choice_id, "path": result.get("path", [])}
		return last_result.duplicate(true)
	pending_steps = 0
	pending_choices.clear()
	phase = PHASE_READY
	last_result = {"ok": true, "status": "BRANCH_RESOLVED", "choice_id": choice_id, "path": result.get("path", [])}
	_resolve_landing(true)
	return last_result.duplicate(true)


func resolve_event(choice_id: String = "") -> Dictionary:
	if phase != PHASE_EVENT or pending_event.is_empty():
		return _reject("EVENT_NOT_AVAILABLE")
	var resolved_event_id := str(pending_event.get("id", ""))
	var start_position := current_space_id
	var hp_before := hp
	var coins_before := coins
	var event_consume_once := bool(pending_event.get("consume_once", false))
	var actions: Array = []
	var raw_actions: Variant = pending_event.get("actions", [])
	if raw_actions is Array:
		actions = raw_actions
	var choices: Array = []
	var raw_choices: Variant = pending_event.get("choices", [])
	if raw_choices is Array:
		choices = raw_choices
	if not choices.is_empty():
		var matched := false
		for choice: Dictionary in choices:
			if str(choice.get("id", "")) == choice_id:
				if not _requirements_met(choice.get("requires", {}) as Dictionary):
					return _reject("EVENT_REQUIREMENTS_NOT_MET")
				var choice_actions: Variant = choice.get("actions", [])
				actions = choice_actions if choice_actions is Array else []
				matched = true
		if not matched:
			return _reject("INVALID_EVENT_CHOICE")
	# Clear the resolved card before applying its effects. A move_to action can
	# immediately land on another FLOW/EVENT/BRANCH tile; that target then owns
	# the pending state while the original card is finalized below.
	pending_event.clear()
	phase = PHASE_READY
	last_result.erase("flow_path")
	last_result.erase("flow_chain")
	var action_receipts: Array[Dictionary] = []
	var event_path: Array[String] = []
	var revived_during_actions := false
	for value: Variant in actions:
		if value is Dictionary:
			var action_receipt := _apply_action(value as Dictionary)
			action_receipts.append(action_receipt)
			for path_value: Variant in action_receipt.get("path", []):
				var path_id := str(path_value)
				if not path_id.is_empty() and (event_path.is_empty() or event_path.back() != path_id):
					event_path.append(path_id)
			revived_during_actions = revived_during_actions or bool(action_receipt.get("revived", false))
	var followup_phase := phase
	var followup_pending := pending_event.duplicate(true)
	var followup_flow_chain := int(last_result.get("flow_chain", 0))
	if event_consume_once and not resolved_event_id.is_empty():
		consumed["event:%s" % resolved_event_id] = true
	if followup_phase not in [PHASE_BRANCH, PHASE_EVENT, PHASE_SECRET, PHASE_BOSS, PHASE_RUN_OVER]:
		pending_event.clear()
		phase = PHASE_READY
	else:
		pending_event = followup_pending
	last_result = {
		"ok": true,
		"status": "EVENT_RESOLVED",
		"event_id": resolved_event_id,
		"choice_id": choice_id,
		"actions": action_receipts,
		"start_position": start_position,
		"position": current_space_id,
		"path": event_path,
		"hp_before": hp_before,
		"hp": hp,
		"coins_before": coins_before,
		"coins": coins,
		"next_phase": String(followup_phase),
	}
	if followup_flow_chain > 0:
		last_result["flow_chain"] = followup_flow_chain
	if revived_during_actions:
		last_result["revived"] = true
	_resolve_life_transition()
	return last_result.duplicate(true)


func resolve_secret(accept: bool) -> Dictionary:
	if phase != PHASE_SECRET:
		return _reject("SECRET_NOT_AVAILABLE")
	var secret := pending_event.duplicate(true)
	pending_event.clear()
	phase = PHASE_READY
	if accept:
		var amount := int((secret.get("cost", {}) as Dictionary).get("amount", 0))
		if coins < amount:
			return _reject("NOT_ENOUGH_COINS")
		coins -= amount
		current_space_id = str(secret.get("target", current_space_id))
		discovered[current_space_id] = true
		stage_flags["secret_cave_discovered"] = true
	last_result = {"ok": true, "status": "SECRET_ENTERED" if accept else "SECRET_DECLINED", "position": current_space_id}
	return last_result.duplicate(true)


func _resolve_landing(trigger_special: bool) -> void:
	var current := course.space(current_space_id)
	score += 10
	var kind := str(current.get("kind", "NORMAL"))
	var effect: Dictionary = current.get("effect", {}) as Dictionary
	if kind == "EVENT":
		stage_flags["mission_event_count"] = mini(int(stage_flags.get("mission_event_count", 0)) + 1, 5)
	if kind == "RISK":
		if consume_risk_shield():
			last_result["item_guarded"] = true
		elif not effect.is_empty():
			_apply_effect(effect, current_space_id)
		else:
			_apply_effect({"kind": "hp_damage", "amount": 1}, current_space_id)
	elif kind == "REST":
		var heal_amount := 1
		if str(effect.get("kind", "heal")) == "heal":
			heal_amount = maxi(int(effect.get("amount", 1)), 0)
		last_result.merge(apply_rest_landing(heal_amount))
	elif not effect.is_empty():
		_apply_effect(effect, current_space_id)
	elif kind == "COIN":
		_apply_effect({"kind": "coin_gain", "amount": 2, "consume_once": true}, current_space_id)
	elif kind == "ITEM":
		var item_result := grant_random_item()
		last_result.merge(item_result)
		last_result["item_acquired"] = not bool(item_result.get("full", false))
	if not trigger_special:
		_resolve_life_transition()
		return
	if kind == "FLOW":
		_resolve_flow(current)
		return
	if kind == "EVENT":
		var event_id := str(current.get("event_id", ""))
		if consumed.has("event:%s" % event_id):
			_resolve_life_transition()
			return
		pending_event = course.event(event_id)
		phase = PHASE_EVENT
		last_result["status"] = "EVENT_REQUIRED"
		return
	if str(current.get("special_kind", "")) == "branch":
		var branch := (current.get("branch", {}) as Dictionary).duplicate(true)
		pending_event = branch
		# A die can land exactly on the junction (remaining movement == 0).
		# Amazon opens the route choice on the landing itself, so reserve one
		# route-entry hop for that case. Without this, choose_branch() passed a
		# zero distance to the course model and both choices were rejected as
		# INVALID_ADVANCE, leaving the player stuck at the fork.
		pending_steps = maxi(pending_steps, 1)
		pending_choices.clear()
		for value: Variant in branch.get("choices", []):
			if value is Dictionary:
				pending_choices.append((value as Dictionary).duplicate(true))
		phase = PHASE_BRANCH
		last_result["status"] = "CHOICE_REQUIRED"
		_resolve_life_transition()
		return
	if str(current.get("special_kind", "")) == "secret_entry":
		pending_event = (current.get("secret_entry", {}) as Dictionary).duplicate(true)
		phase = PHASE_SECRET
		last_result["status"] = "SECRET_REQUIRED"
		return
	if kind == "BOSS":
		phase = PHASE_BOSS
		last_result["status"] = "BOSS_READY"
	_resolve_life_transition()


func _resolve_flow(current: Dictionary) -> void:
	var chain := 0
	var active := current
	var flow_path: Array[String] = []
	last_result.erase("flow_path")
	while chain < 4 and str(active.get("kind", "")) == "FLOW":
		var transition: Dictionary = active.get("transition", {}) as Dictionary
		var target := str(transition.get("target", ""))
		if target.is_empty():
			break
		current_space_id = target
		discovered[target] = true
		chain += 1
		flow_path.append(target)
		active = course.space(target)
		if bool(transition.get("trigger_target_effect", true)):
			last_result["flow_chain"] = chain
			last_result["flow_path"] = flow_path.duplicate()
			_resolve_landing(chain < 4)
			return
	last_result["flow_chain"] = chain
	last_result["flow_path"] = flow_path
	_resolve_life_transition()


func _apply_effect(effect: Dictionary, resolution_id: String) -> void:
	if bool(effect.get("consume_once", false)) and consumed.has(resolution_id):
		return
	match str(effect.get("kind", "")):
		"coin_gain": coins += int(effect.get("amount", 0))
		"heal": hp = mini(hp + int(effect.get("amount", 0)), max_hp)
		"hp_damage": hp = maxi(hp - int(effect.get("amount", 0)), 0)
	if bool(effect.get("consume_once", false)):
		consumed[resolution_id] = true


func _apply_action(action: Dictionary) -> Dictionary:
	var receipt := action.duplicate(true)
	var action_path: Array[String] = []
	receipt["position_before"] = current_space_id
	receipt["hp_before"] = hp
	receipt["coins_before"] = coins
	var life_before := life
	match str(action.get("type", "")):
		"coin_gain": coins += int(action.get("amount", 0))
		"coin_spend": coins = maxi(coins - int(action.get("amount", 0)), 0)
		"heal": hp = mini(hp + int(action.get("amount", 0)), max_hp)
		"hp_damage": hp = maxi(hp - int(action.get("amount", 0)), 0)
		"move_to":
			current_space_id = str(action.get("target", current_space_id))
			discovered[current_space_id] = true
			if not current_space_id.is_empty():
				action_path.append(current_space_id)
			if bool(action.get("trigger_target_effect", false)):
				last_result.erase("flow_path")
				last_result.erase("flow_chain")
				_resolve_landing(true)
				for path_value: Variant in last_result.get("flow_path", []):
					var flow_id := str(path_value)
					if not flow_id.is_empty() and (action_path.is_empty() or action_path.back() != flow_id):
						action_path.append(flow_id)
		"camera_cue": stage_flags["last_camera_cue"] = str(action.get("cue_id", ""))
	receipt["position"] = current_space_id
	receipt["path"] = action_path
	receipt["hp"] = hp
	receipt["coins"] = coins
	receipt["life_before"] = life_before
	receipt["life"] = life
	if life < life_before:
		receipt["revived"] = true
	return receipt


func _requirements_met(requirements: Dictionary) -> bool:
	return requirements.is_empty() or coins >= int(requirements.get("coin_gte", 0))


func _resolve_life_transition() -> void:
	var life_result := resolve_life_if_needed()
	if bool(life_result.get("run_over", false)):
		last_result["status"] = "RUN_OVER"
	elif bool(life_result.get("revived", false)):
		last_result["revived"] = true


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}


func start_next_lap() -> void:
	super.start_next_lap()
	current_space_id = course.start_space_id()
	discovered[current_space_id] = true
