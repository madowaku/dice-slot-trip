extends RefCounted
class_name DiceRaceModel

const GOAL := 24
const RACERS: Array[String] = ["camel", "crocodile", "fox", "duck", "dinosaur", "robot"]
const WIN_MULTIPLIER := 4.0
const CASHOUT_MULTIPLIERS := {
	1: 1.8,
	2: 1.0,
	3: 0.6,
	4: 0.3,
	5: 0.2,
	6: 0.1,
}

static func new_race(bet_racer: String = "", bet_amount: int = 0) -> Dictionary:
	var racers := {}
	for racer_id: String in RACERS:
		racers[racer_id] = {
			"position": 0,
			"foxfire_pending": false,
			"log_pending": false,
		}
	return {
		"racers": racers,
		"roll_count": 0,
		"finished": false,
		"winner": "",
		"photo_finish_candidates": [],
		"bet_racer": bet_racer if bet_racer in RACERS else "",
		"bet_amount": maxi(0, bet_amount),
		"bet_active": bet_racer in RACERS and bet_amount > 0,
		"cashout_offered": false,
		"cashout_taken": false,
		"cashout_amount": 0,
	}

static func apply_roll(state: Dictionary, assignments: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if bool(next.get("finished", false)) or not _assignments_are_valid(assignments):
		return next
	if not (next.get("photo_finish_candidates", []) as Array).is_empty():
		return resolve_photo_finish(next, assignments)

	var old_racers: Dictionary = next.get("racers", {})
	var resolved := old_racers.duplicate(true)
	var movements := {}

	for racer_id: String in RACERS:
		var racer: Dictionary = old_racers.get(racer_id, {})
		var rolled := int(assignments.get(racer_id, 0))
		var effective := rolled
		var blocked_by_log := false

		if bool(racer.get("log_pending", false)):
			blocked_by_log = rolled <= 3
			effective = 0 if blocked_by_log else rolled
			racer["log_pending"] = false
		elif bool(racer.get("foxfire_pending", false)):
			effective = maxi(1, rolled - 2)
			racer["foxfire_pending"] = false

		var from_pos := int(racer.get("position", 0))
		var landing := from_pos + effective
		var final_pos := landing
		var gimmick := ""

		if effective > 0 and landing < GOAL:
			match landing:
				5, 20:
					racer["foxfire_pending"] = true
					gimmick = "foxfire"
				10:
					final_pos += 3
					gimmick = "rapid"
				15:
					racer["log_pending"] = true
					gimmick = "log"

		racer["position"] = final_pos
		resolved[racer_id] = racer
		movements[racer_id] = {
			"rolled": rolled,
			"effective": effective,
			"from": from_pos,
			"landing": landing,
			"to": final_pos,
			"blocked_by_log": blocked_by_log,
			"gimmick": gimmick,
		}

	next["racers"] = resolved
	next["last_movements"] = movements
	next["last_assignments"] = assignments.duplicate(true)
	next["roll_count"] = int(next.get("roll_count", 0)) + 1
	_update_goal_state(next)

	if not bool(next.get("finished", false)) and (next.get("photo_finish_candidates", []) as Array).is_empty():
		if int(next.get("roll_count", 0)) == 3 and bool(next.get("bet_active", false)):
			next["cashout_offered"] = true
			next["cashout_amount"] = cashout_offer(next)
	return next

static func cashout_offer(state: Dictionary) -> int:
	if not bool(state.get("bet_active", false)):
		return 0
	var racer_id := str(state.get("bet_racer", ""))
	var rank := rank_for_racer(state, racer_id)
	var multiplier := float(CASHOUT_MULTIPLIERS.get(rank, 0.0))
	return int(roundi(float(int(state.get("bet_amount", 0))) * multiplier))

static func take_cashout(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("cashout_offered", false)) or not bool(next.get("bet_active", false)):
		return next
	next["cashout_amount"] = cashout_offer(next)
	next["cashout_taken"] = true
	next["cashout_offered"] = false
	next["bet_active"] = false
	return next

static func ride_on(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	next["cashout_offered"] = false
	return next

static func winning_payout(state: Dictionary) -> int:
	if not bool(state.get("bet_active", false)):
		return 0
	if str(state.get("winner", "")) != str(state.get("bet_racer", "")):
		return 0
	return int(roundi(float(int(state.get("bet_amount", 0))) * WIN_MULTIPLIER))

static func rank_for_racer(state: Dictionary, racer_id: String) -> int:
	if racer_id not in RACERS:
		return 6
	var racers: Dictionary = state.get("racers", {})
	var position := int((racers.get(racer_id, {}) as Dictionary).get("position", 0))
	var ahead := 0
	for other_id: String in RACERS:
		if int((racers.get(other_id, {}) as Dictionary).get("position", 0)) > position:
			ahead += 1
	return ahead + 1

static func ranking(state: Dictionary) -> Array[String]:
	var ordered: Array[String] = []
	for racer_id: String in RACERS:
		ordered.append(racer_id)
	var racers: Dictionary = state.get("racers", {})
	ordered.sort_custom(func(a: String, b: String) -> bool:
		var pa := int((racers.get(a, {}) as Dictionary).get("position", 0))
		var pb := int((racers.get(b, {}) as Dictionary).get("position", 0))
		if pa == pb:
			return RACERS.find(a) < RACERS.find(b)
		return pa > pb
	)
	return ordered

static func resolve_photo_finish(state: Dictionary, assignments: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var candidates: Array = next.get("photo_finish_candidates", [])
	if candidates.is_empty() or not _assignments_are_valid(assignments):
		return next
	var winner := ""
	var best := -1
	for racer_id: Variant in candidates:
		var id := str(racer_id)
		var value := int(assignments.get(id, 0))
		if value > best:
			best = value
			winner = id
	next["winner"] = winner
	next["finished"] = not winner.is_empty()
	next["photo_finish_candidates"] = []
	next["photo_finish_assignments"] = assignments.duplicate(true)
	return next

static func _update_goal_state(state: Dictionary) -> void:
	var racers: Dictionary = state.get("racers", {})
	var goalers: Array[String] = []
	var best_position := -1
	for racer_id: String in RACERS:
		var pos := int((racers.get(racer_id, {}) as Dictionary).get("position", 0))
		if pos < GOAL:
			continue
		if pos > best_position:
			best_position = pos
			goalers = [racer_id]
		elif pos == best_position:
			goalers.append(racer_id)
	if goalers.size() == 1:
		state["winner"] = goalers[0]
		state["finished"] = true
		state["photo_finish_candidates"] = []
	elif goalers.size() > 1:
		state["winner"] = ""
		state["finished"] = false
		state["photo_finish_candidates"] = goalers

static func _assignments_are_valid(assignments: Dictionary) -> bool:
	var values: Array[int] = []
	for racer_id: String in RACERS:
		if not assignments.has(racer_id):
			return false
		values.append(int(assignments[racer_id]))
	values.sort()
	return values == [1, 2, 3, 4, 5, 6]
