class_name WhiteFoxBattle
extends RefCounted

const DATA_PATH := "res://data/bosses/white_fox_seal.json"
const STATE_EMPTY: StringName = &"EMPTY"
const STATE_CRACKED: StringName = &"CRACKED"
const STATE_NORMAL: StringName = &"NORMAL"
const PHASE_PRE_BONUS: StringName = &"PRE_BONUS"
const PHASE_WAIT_ROLL: StringName = &"WAIT_ROLL"
const PHASE_ACTION: StringName = &"ACTION"
const PHASE_VICTORY: StringName = &"VICTORY"
const PHASE_DEFEAT: StringName = &"DEFEAT"

var phase: StringName = PHASE_WAIT_ROLL
var seals: Array[Dictionary] = []
var dice: Array[int] = []
var selected_die_index := -1
var turn_number := 0
var max_turns := 12
var attack_cursor := 0
var attack_start_turn := 3
var coins := 0
var reroll_cost := 3
var reroll_limit := 2
var rerolls_used := 0
var offering_count := 0
var prayer_count := 0
var max_prayers := 2
var kiyomizu_reroll_available := false
var tenryuji_shift_available := false
var fushimi_preplacement_available := false
var mangan_guard_available := false
var prayer_used_this_turn := false
var rng := RandomNumberGenerator.new()
var stats: Dictionary = {}


func configure(goshuin: Dictionary, starting_coins: int, otowa_luck_shift: bool = false, seed_value: int = 0) -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		return false
	var data := parsed as Dictionary
	if str(data.get("game_type", "")) != "seal_board":
		return false
	seals.clear()
	for value: Variant in data.get("seals", []):
		if value is Dictionary:
			var seal := (value as Dictionary).duplicate(true)
			seal["state"] = STATE_EMPTY
			seals.append(seal)
	if seals.size() != 8:
		return false
	max_turns = int(data.get("max_turns", 12))
	reroll_cost = int(data.get("coin_reroll_cost", 3))
	reroll_limit = int(data.get("coin_reroll_limit", 2))
	max_prayers = int(data.get("max_prayers", 2))
	coins = maxi(starting_coins, 0)
	attack_start_turn = 4 if bool(goshuin.get("yasaka", false)) else 3
	kiyomizu_reroll_available = bool(goshuin.get("kiyomizu", false))
	prayer_count = 1 if bool(goshuin.get("tenryuji", false)) else 0
	tenryuji_shift_available = otowa_luck_shift
	fushimi_preplacement_available = bool(goshuin.get("fushimi", false))
	mangan_guard_available = bool(goshuin.get("fushimi", false)) and bool(goshuin.get("yasaka", false)) and bool(goshuin.get("kiyomizu", false)) and bool(goshuin.get("tenryuji", false))
	phase = PHASE_PRE_BONUS if fushimi_preplacement_available else PHASE_WAIT_ROLL
	turn_number = 0
	rerolls_used = 0
	offering_count = 0
	dice.clear()
	selected_die_index = -1
	rng.seed = seed_value if seed_value != 0 else hash("white_fox:%s" % goshuin)
	attack_cursor = rng.randi_range(0, 7)
	stats = {"turns": 0, "places": 0, "repairs": 0, "offers": 0, "fox_hits": 0, "coin_rerolls": 0, "prayers": 0}
	return true


func apply_fushimi_preplacement(seal_id: String) -> Dictionary:
	if phase != PHASE_PRE_BONUS:
		return _reject("PREPLACEMENT_NOT_AVAILABLE")
	var index := _seal_index(seal_id)
	if index < 0:
		return _reject("INVALID_SEAL")
	seals[index]["state"] = STATE_NORMAL
	fushimi_preplacement_available = false
	phase = PHASE_WAIT_ROLL
	return {"ok": true, "status": "PREPLACED", "seal_id": seal_id, "snapshot": snapshot()}


func roll() -> Dictionary:
	if phase != PHASE_WAIT_ROLL or turn_number >= max_turns:
		return _reject("ROLL_NOT_AVAILABLE")
	turn_number += 1
	prayer_used_this_turn = false
	selected_die_index = -1
	dice = [rng.randi_range(1, 6), rng.randi_range(1, 6), rng.randi_range(1, 6)]
	phase = PHASE_ACTION
	return {"ok": true, "status": "ROLLED", "dice": dice.duplicate(), "snapshot": snapshot()}


func coin_reroll(die_index: int) -> Dictionary:
	if phase != PHASE_ACTION or die_index < 0 or die_index >= dice.size():
		return _reject("REROLL_NOT_AVAILABLE")
	if rerolls_used >= reroll_limit or coins < reroll_cost:
		return _reject("REROLL_LIMIT_OR_COST")
	coins -= reroll_cost
	rerolls_used += 1
	dice[die_index] = rng.randi_range(1, 6)
	stats["coin_rerolls"] = int(stats.coin_rerolls) + 1
	return {"ok": true, "status": "DIE_REROLLED", "dice": dice.duplicate(), "snapshot": snapshot()}


func kiyomizu_reroll() -> Dictionary:
	if phase != PHASE_ACTION or not kiyomizu_reroll_available:
		return _reject("KIYOMIZU_NOT_AVAILABLE")
	kiyomizu_reroll_available = false
	dice = [rng.randi_range(1, 6), rng.randi_range(1, 6), rng.randi_range(1, 6)]
	return {"ok": true, "status": "KIYOMIZU_REROLL", "dice": dice.duplicate(), "snapshot": snapshot()}


func use_prayer(die_index: int, value: int) -> Dictionary:
	if phase != PHASE_ACTION or prayer_used_this_turn or prayer_count <= 0 or die_index < 0 or die_index >= dice.size() or value < 1 or value > 5:
		return _reject("PRAYER_NOT_AVAILABLE")
	prayer_count -= 1
	prayer_used_this_turn = true
	dice[die_index] = value
	stats["prayers"] = int(stats.prayers) + 1
	_convert_offerings()
	return {"ok": true, "status": "PRAYER_USED", "dice": dice.duplicate(), "snapshot": snapshot()}


func use_luck_shift(die_index: int, delta: int) -> Dictionary:
	if phase != PHASE_ACTION or not tenryuji_shift_available or die_index < 0 or die_index >= dice.size() or absi(delta) != 1:
		return _reject("LUCK_SHIFT_NOT_AVAILABLE")
	var shifted := dice[die_index] + delta
	if shifted < 1 or shifted > 6:
		return _reject("LUCK_SHIFT_OUT_OF_RANGE")
	tenryuji_shift_available = false
	dice[die_index] = shifted
	return {"ok": true, "status": "LUCK_SHIFT_USED", "dice": dice.duplicate(), "snapshot": snapshot()}


func restore(data: Dictionary) -> bool:
	if not data.get("seals", []) is Array or (data.get("seals", []) as Array).size() != 8:
		return false
	phase = StringName(str(data.get("phase", PHASE_WAIT_ROLL)))
	seals.clear()
	for value: Variant in data.get("seals", []):
		if not value is Dictionary:
			return false
		seals.append((value as Dictionary).duplicate(true))
	dice.clear()
	for value: Variant in data.get("dice", []):
		dice.append(clampi(int(value), 1, 6))
	turn_number = clampi(int(data.get("turn_number", 0)), 0, max_turns)
	attack_cursor = posmod(int(data.get("attack_cursor", 0)), 8)
	attack_start_turn = int(data.get("attack_start_turn", attack_start_turn))
	coins = maxi(int(data.get("coins", coins)), 0)
	rerolls_used = clampi(int(data.get("rerolls_used", 0)), 0, reroll_limit)
	offering_count = maxi(int(data.get("offering_count", 0)), 0)
	prayer_count = clampi(int(data.get("prayer_count", 0)), 0, max_prayers)
	kiyomizu_reroll_available = bool(data.get("kiyomizu_reroll_available", false))
	tenryuji_shift_available = bool(data.get("tenryuji_shift_available", false))
	fushimi_preplacement_available = bool(data.get("fushimi_preplacement_available", false))
	mangan_guard_available = bool(data.get("mangan_guard_available", false))
	prayer_used_this_turn = bool(data.get("prayer_used_this_turn", false))
	stats = (data.get("stats", {}) as Dictionary).duplicate(true)
	return true


func available_targets(die_index: int) -> Array[String]:
	var result: Array[String] = []
	if phase != PHASE_ACTION or die_index < 0 or die_index >= dice.size():
		return result
	var face := dice[die_index]
	for seal: Dictionary in seals:
		if (str(seal.get("state", "")) == STATE_EMPTY or str(seal.get("state", "")) == STATE_CRACKED) and (face == 6 or face == int(seal.get("required", 0))):
			result.append(str(seal.get("id", "")))
	return result


func can_offer(die_index: int) -> bool:
	return phase == PHASE_ACTION and die_index >= 0 and die_index < dice.size() and available_targets(die_index).is_empty()


func commit_die(die_index: int, seal_id: String = "") -> Dictionary:
	if phase != PHASE_ACTION or die_index < 0 or die_index >= dice.size():
		return _reject("ACTION_NOT_AVAILABLE")
	var face := dice[die_index]
	var action := ""
	if seal_id.is_empty():
		if not can_offer(die_index):
			return _reject("DIE_HAS_VALID_TARGET")
		offering_count += 1
		action = "OFFER"
		stats["offers"] = int(stats.offers) + 1
		_convert_offerings()
	else:
		var index := _seal_index(seal_id)
		if index < 0 or not seal_id in available_targets(die_index):
			return _reject("INVALID_SEAL_TARGET")
		var previous_state := StringName(str(seals[index].get("state", STATE_EMPTY)))
		seals[index]["state"] = STATE_NORMAL
		action = "REPAIR" if previous_state == STATE_CRACKED else "PLACE"
		stats["repairs" if action == "REPAIR" else "places"] = int(stats.get("repairs" if action == "REPAIR" else "places", 0)) + 1
	if completed_seals() == 8:
		phase = PHASE_VICTORY
		stats["turns"] = turn_number
		return {"ok": true, "status": "VICTORY", "action": action, "snapshot": snapshot()}
	var attack_result := _resolve_fox_attack()
	if turn_number >= max_turns:
		phase = PHASE_DEFEAT
	else:
		phase = PHASE_WAIT_ROLL
	dice.clear()
	selected_die_index = -1
	stats["turns"] = turn_number
	return {"ok": true, "status": "DEFEAT" if phase == PHASE_DEFEAT else "TURN_RESOLVED", "action": action, "fox_attack": attack_result, "snapshot": snapshot()}


func completed_seals() -> int:
	var total := 0
	for seal: Dictionary in seals:
		if str(seal.get("state", "")) != STATE_EMPTY:
			total += 1
	return total


func current_attack_id() -> String:
	return str(seals[attack_cursor].get("id", "")) if not seals.is_empty() else ""


func next_attack_id() -> String:
	return str(seals[(attack_cursor + 1) % seals.size()].get("id", "")) if not seals.is_empty() else ""


func _resolve_fox_attack() -> Dictionary:
	if turn_number < attack_start_turn:
		return {"attacked": false, "status": "WATCHING", "target": current_attack_id()}
	var target_id := current_attack_id()
	if mangan_guard_available:
		mangan_guard_available = false
		attack_cursor = (attack_cursor + 1) % seals.size()
		return {"attacked": false, "status": "MANGAN_GUARD", "target": target_id}
	var state := StringName(str(seals[attack_cursor].get("state", STATE_EMPTY)))
	match state:
		STATE_NORMAL: seals[attack_cursor]["state"] = STATE_CRACKED
		STATE_CRACKED: seals[attack_cursor]["state"] = STATE_EMPTY
	stats["fox_hits"] = int(stats.fox_hits) + 1
	attack_cursor = (attack_cursor + 1) % seals.size()
	return {"attacked": true, "status": "FOX_FIRE", "target": target_id, "before": String(state)}


func _convert_offerings() -> void:
	while offering_count >= 2 and prayer_count < max_prayers:
		offering_count -= 2
		prayer_count += 1


func _seal_index(seal_id: String) -> int:
	for index: int in range(seals.size()):
		if str(seals[index].get("id", "")) == seal_id:
			return index
	return -1


func _reject(error: String) -> Dictionary:
	return {"ok": false, "error": error}


func snapshot() -> Dictionary:
	return {
		"phase": String(phase), "seals": seals.duplicate(true), "dice": dice.duplicate(),
		"turn_number": turn_number, "max_turns": max_turns, "attack_cursor": attack_cursor,
		"attack_start_turn": attack_start_turn, "coins": coins, "rerolls_used": rerolls_used,
		"offering_count": offering_count, "prayer_count": prayer_count,
		"kiyomizu_reroll_available": kiyomizu_reroll_available,
		"tenryuji_shift_available": tenryuji_shift_available,
		"fushimi_preplacement_available": fushimi_preplacement_available,
		"mangan_guard_available": mangan_guard_available, "stats": stats.duplicate(true),
		"prayer_used_this_turn": prayer_used_this_turn,
	}
