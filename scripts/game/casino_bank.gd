extends RefCounted
class_name CasinoBank

const SAVE_PATH := "user://dice_slot_trip_casino.json"
const SAVE_VERSION := 2
const COIN_TO_CHIP_RATE := 2
const CLEAR_CHIP_BONUS := 5
const ACTIVE_GAMES_KEY := "active_games"
const SETTLEMENTS_KEY := "casino_settlements"
const LEGACY_CARD_ALIASES := {
	"dice_racer_crocodile": "dice_racer_rabbit",
}

## Tests may redirect persistence to an isolated user:// file.  This is
## intentionally private at runtime: production callers always use SAVE_PATH.
static var _test_save_path := ""
static var _transaction_nonce := 0

static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"chips": 0,
		"owned_cards": [],
		"conversion_keys": [],
		"dice_race_play_count": 0,
		"dice_race_win_count": 0,
		"dice_race_best_payout": 0,
		"dice_roulette_play_count": 0,
		"dice_roulette_win_count": 0,
		"dice_roulette_best_payout": 0,
		ACTIVE_GAMES_KEY: {},
		SETTLEMENTS_KEY: {},
		"casino_settlement_order": [],
	}

static func set_test_save_path(path: String) -> void:
	_test_save_path = path.strip_edges()

static func clear_test_save_path() -> void:
	_test_save_path = ""

## Compatibility aliases used by isolated test harnesses.
static func set_save_path_override(path: String) -> void:
	set_test_save_path(path)

static func clear_save_path_override() -> void:
	clear_test_save_path()

static func save_path() -> String:
	return _effective_save_path()

static func _effective_save_path() -> String:
	return _test_save_path if not _test_save_path.is_empty() else SAVE_PATH

static func load_data() -> Dictionary:
	var path := _effective_save_path()
	if not FileAccess.file_exists(path):
		return default_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return default_data()
	return _normalize(parsed as Dictionary)

static func save_data(data: Dictionary) -> bool:
	var normalized := _normalize(data)
	var file := FileAccess.open(_effective_save_path(), FileAccess.WRITE)
	if file == null:
		push_warning("CasinoBank could not open its save file.")
		return false
	file.store_string(JSON.stringify(normalized, "  "))
	return true

static func balance() -> int:
	return int(load_data().get("chips", 0))

static func add_chips(amount: int) -> int:
	var data := load_data()
	data["chips"] = maxi(0, int(data.get("chips", 0)) + maxi(0, amount))
	save_data(data)
	return int(data["chips"])

static func spend_chips(amount: int) -> bool:
	var cost := maxi(0, amount)
	var data := load_data()
	var current := int(data.get("chips", 0))
	if current < cost:
		return false
	data["chips"] = current - cost
	return save_data(data)

static func stage_clear_conversion(remaining_trip_coin: int, cleared_boss: bool = true) -> Dictionary:
	return _conversion_receipt(remaining_trip_coin, cleared_boss, true)

static func stage_clear_conversion_once(conversion_key: String, remaining_trip_coin: int, cleared_boss: bool = true) -> Dictionary:
	var key := conversion_key.strip_edges()
	if key.is_empty():
		return stage_clear_conversion(remaining_trip_coin, cleared_boss)
	var data := load_data()
	var keys: Array = data.get("conversion_keys", [])
	if key in keys:
		return {
			"already_converted": true,
			"conversion_key": key,
			"remaining_trip_coin": maxi(0, remaining_trip_coin),
			"converted_chip": 0,
			"clear_bonus": 0,
			"gained_chip": 0,
			"balance_before": int(data.get("chips", 0)),
			"balance_after": int(data.get("chips", 0)),
		}
	var receipt := _conversion_receipt(remaining_trip_coin, cleared_boss, false)
	var before := int(data.get("chips", 0))
	var gained := int(receipt.get("gained_chip", 0))
	data["chips"] = before + gained
	keys.append(key)
	while keys.size() > 256:
		keys.pop_front()
	data["conversion_keys"] = keys
	if not save_data(data):
		return {"ok": false, "conversion_key": key, "gained_chip": 0}
	receipt["ok"] = true
	receipt["already_converted"] = false
	receipt["conversion_key"] = key
	receipt["balance_before"] = before
	receipt["balance_after"] = before + gained
	return receipt

static func _conversion_receipt(remaining_trip_coin: int, cleared_boss: bool, persist: bool) -> Dictionary:
	var remainder := maxi(0, remaining_trip_coin)
	var converted := int(remainder / COIN_TO_CHIP_RATE)
	var clear_bonus := CLEAR_CHIP_BONUS if cleared_boss else 0
	var gained := converted + clear_bonus
	var before := balance()
	var after := before + gained
	if persist:
		after = add_chips(gained)
	return {
		"ok": true,
		"remaining_trip_coin": remainder,
		"converted_chip": converted,
		"clear_bonus": clear_bonus,
		"gained_chip": gained,
		"balance_before": before,
		"balance_after": after,
	}

static func own_card(card_id: String, cost: int) -> bool:
	var id := _normalize_card_id(card_id)
	if id.is_empty():
		return false
	var data := load_data()
	var owned: Array = data.get("owned_cards", [])
	if id in owned:
		return false
	var price := maxi(0, cost)
	var chips := int(data.get("chips", 0))
	if chips < price:
		return false
	data["chips"] = chips - price
	owned.append(id)
	data["owned_cards"] = owned
	return save_data(data)

static func record_dice_race(won: bool, payout: int) -> void:
	var data := load_data()
	data["dice_race_play_count"] = int(data.get("dice_race_play_count", 0)) + 1
	if won:
		data["dice_race_win_count"] = int(data.get("dice_race_win_count", 0)) + 1
	data["dice_race_best_payout"] = maxi(int(data.get("dice_race_best_payout", 0)), maxi(0, payout))
	save_data(data)

## Begin one resumable casino transaction.  The wager is charged and the
## session snapshot is persisted in the same save write.  A second begin for
## the same facility is rejected while its first session is still active.
static func begin_game(facility_id: String, bet: int, session: Dictionary = {}) -> Dictionary:
	var key := _facility_key(facility_id)
	var amount := maxi(0, bet)
	if key.is_empty():
		return {"ok": false, "reason": "invalid_facility", "facility_id": key}
	var data := load_data()
	var active := _active_games(data)
	if active.has(key):
		var existing: Dictionary = active[key] as Dictionary
		return {
			"ok": false,
			"reason": "already_active",
			"already_active": true,
			"facility_id": key,
			"game_id": str(existing.get("game_id", "")),
			"session": (existing.get("session", {}) as Dictionary).duplicate(true),
			"balance": int(data.get("chips", 0)),
		}
	var before := int(data.get("chips", 0))
	if before < amount:
		return {
			"ok": false,
			"reason": "insufficient_chips",
			"facility_id": key,
			"bet": amount,
			"balance": before,
		}
	_transaction_nonce += 1
	var game_id := "%s:%d:%d" % [key, Time.get_unix_time_from_system(), _transaction_nonce]
	var payload := session.duplicate(true)
	var record := {
		"facility_id": key,
		"game_id": game_id,
		"bet": amount,
		"stake": amount,
		"status": "active",
		"settled": false,
		"session": payload,
		"pending_rolls": _pending_rolls(payload),
		"started_at": Time.get_unix_time_from_system(),
		"updated_at": Time.get_unix_time_from_system(),
	}
	_copy_session_fields(record, payload)
	active[key] = record
	data[ACTIVE_GAMES_KEY] = active
	data["chips"] = before - amount
	if not save_data(data):
		return {"ok": false, "reason": "save_failed", "facility_id": key, "bet": amount, "balance": before}
	return {
		"ok": true,
		"started": true,
		"charged": amount,
		"facility_id": key,
		"game_id": game_id,
		"bet": amount,
		"balance_before": before,
		"balance_after": before - amount,
		"session": payload.duplicate(true),
		"pending_rolls": _pending_rolls(payload),
	}

static func begin_active_game(facility_id: String, bet: int, session: Dictionary = {}) -> Dictionary:
	return begin_game(facility_id, bet, session)

static func begin_session(facility_id: String, bet: int, session: Dictionary = {}) -> Dictionary:
	return begin_game(facility_id, bet, session)

## Update only the resumable session.  No chips are charged or returned here.
## Pending rolls are copied before any animation starts by the caller.
static func update_game(facility_id: String, session: Dictionary, game_id: String = "") -> Dictionary:
	var key := _facility_key(facility_id)
	var data := load_data()
	var active := _active_games(data)
	if not active.has(key) or not active[key] is Dictionary:
		return {"ok": false, "reason": "no_active_game", "facility_id": key}
	var record: Dictionary = (active[key] as Dictionary).duplicate(true)
	if not game_id.is_empty() and str(record.get("game_id", "")) != game_id:
		return {"ok": false, "reason": "game_id_mismatch", "facility_id": key}
	var merged: Dictionary = record.get("session", {}) as Dictionary
	merged = merged.duplicate(true)
	for field: Variant in session.keys():
		merged[str(field)] = (session[field] as Variant).duplicate(true) if session[field] is Array or session[field] is Dictionary else session[field]
	record["session"] = merged
	record["pending_rolls"] = _pending_rolls(merged)
	record["updated_at"] = Time.get_unix_time_from_system()
	_copy_session_fields(record, session)
	active[key] = record
	data[ACTIVE_GAMES_KEY] = active
	if not save_data(data):
		return {"ok": false, "reason": "save_failed", "facility_id": key, "game_id": str(record.get("game_id", ""))}
	return {
		"ok": true,
		"updated": true,
		"facility_id": key,
		"game_id": str(record.get("game_id", "")),
		"session": merged.duplicate(true),
		"pending_rolls": _pending_rolls(merged),
		"balance": int(data.get("chips", 0)),
	}

static func update_active_game(facility_id: String, session: Dictionary, game_id: String = "") -> Dictionary:
	return update_game(facility_id, session, game_id)

static func update_session(facility_id: String, session: Dictionary, game_id: String = "") -> Dictionary:
	return update_game(facility_id, session, game_id)

static func update_pending_rolls(facility_id: String, pending_rolls: Array, game_id: String = "") -> Dictionary:
	return update_game(facility_id, {"pending_rolls": pending_rolls.duplicate(true)}, game_id)

## Settle an active game exactly once.  The active record is removed and the
## payout is credited in one save write; a settlement receipt remains so a
## replay cannot pay twice.
static func settle_game(facility_id: String, payout: int, result: Dictionary = {}, game_id: String = "") -> Dictionary:
	var key := _facility_key(facility_id)
	var data := load_data()
	var active := _active_games(data)
	if not active.has(key) or not active[key] is Dictionary:
		var previous := _latest_settlement_for(data, key, game_id)
		if not previous.is_empty():
			return {
				"ok": false,
				"reason": "already_settled",
				"already_settled": true,
				"duplicate_settlement": true,
				"facility_id": key,
				"game_id": str(previous.get("game_id", game_id)),
				"payout": int(previous.get("payout", 0)),
				"balance": int(data.get("chips", 0)),
			}
		return {"ok": false, "reason": "no_active_game", "facility_id": key}
	var record: Dictionary = (active[key] as Dictionary).duplicate(true)
	var active_game_id := str(record.get("game_id", ""))
	if not game_id.is_empty() and active_game_id != game_id:
		return {"ok": false, "reason": "game_id_mismatch", "facility_id": key, "game_id": active_game_id}
	var amount := maxi(0, payout)
	var before := int(data.get("chips", 0))
	var settlement := {
		"facility_id": key,
		"game_id": active_game_id,
		"bet": int(record.get("bet", record.get("stake", 0))),
		"payout": amount,
		"result": result.duplicate(true),
		"settled": true,
		"settled_at": Time.get_unix_time_from_system(),
	}
	var settlements := _settlements(data)
	settlements[active_game_id] = settlement
	var order: Array = data.get("casino_settlement_order", []) as Array
	order = order.duplicate(true)
	order.append(active_game_id)
	while order.size() > 128:
		var old_id := str(order.pop_front())
		settlements.erase(old_id)
	active.erase(key)
	data[ACTIVE_GAMES_KEY] = active
	data[SETTLEMENTS_KEY] = settlements
	data["casino_settlement_order"] = order
	data["chips"] = before + amount
	if key == "dice_roulette":
		data["dice_roulette_play_count"] = int(data.get("dice_roulette_play_count", 0)) + 1
		var bet_amount := int(record.get("bet", record.get("stake", 0)))
		if amount > bet_amount:
			data["dice_roulette_win_count"] = int(data.get("dice_roulette_win_count", 0)) + 1
		data["dice_roulette_best_payout"] = maxi(int(data.get("dice_roulette_best_payout", 0)), amount)
	if not save_data(data):
		return {"ok": false, "reason": "save_failed", "facility_id": key, "game_id": active_game_id}
	return {
		"ok": true,
		"settled": true,
		"facility_id": key,
		"game_id": active_game_id,
		"payout": amount,
		"balance_before": before,
		"balance_after": before + amount,
		"result": result.duplicate(true),
	}

static func settle_active_game(facility_id: String, payout: int, result: Dictionary = {}, game_id: String = "") -> Dictionary:
	return settle_game(facility_id, payout, result, game_id)

static func settle_session(facility_id: String, payout: int, result: Dictionary = {}, game_id: String = "") -> Dictionary:
	return settle_game(facility_id, payout, result, game_id)

static func active_game(facility_id: String) -> Dictionary:
	var key := _facility_key(facility_id)
	var active := _active_games(load_data())
	if not active.has(key) or not active[key] is Dictionary:
		return {}
	return (active[key] as Dictionary).duplicate(true)

static func load_active_game(facility_id: String) -> Dictionary:
	return active_game(facility_id)

static func resume_game(facility_id: String) -> Dictionary:
	return active_game(facility_id)

static func active_games() -> Dictionary:
	return _active_games(load_data()).duplicate(true)

static func has_active_game(facility_id: String) -> bool:
	return not active_game(facility_id).is_empty()

static func _normalize_card_id(card_id: String) -> String:
	var id := card_id.strip_edges()
	return str(LEGACY_CARD_ALIASES.get(id, id))

static func _normalize(source: Dictionary) -> Dictionary:
	# Start with the user's full payload so future casino fields survive a
	# version bump.  Known fields below are normalized in place.
	var data: Dictionary = source.duplicate(true)
	for key: Variant in default_data().keys():
		if not data.has(key):
			data[key] = default_data()[key]
	data["version"] = SAVE_VERSION
	data["chips"] = maxi(0, int(source.get("chips", 0)))
	var cards: Array = source.get("owned_cards", []) as Array if source.get("owned_cards", []) is Array else []
	var unique_cards: Array[String] = []
	for card: Variant in cards:
		var id := _normalize_card_id(str(card))
		if not id.is_empty() and id not in unique_cards:
			unique_cards.append(id)
	data["owned_cards"] = unique_cards
	var keys: Array = source.get("conversion_keys", []) as Array if source.get("conversion_keys", []) is Array else []
	var unique_keys: Array[String] = []
	for value: Variant in keys:
		var key := str(value).strip_edges()
		if not key.is_empty() and key not in unique_keys:
			unique_keys.append(key)
	while unique_keys.size() > 256:
		unique_keys.pop_front()
	data["conversion_keys"] = unique_keys
	data["dice_race_play_count"] = maxi(0, int(source.get("dice_race_play_count", 0)))
	data["dice_race_win_count"] = maxi(0, int(source.get("dice_race_win_count", 0)))
	data["dice_race_best_payout"] = maxi(0, int(source.get("dice_race_best_payout", 0)))
	data["dice_roulette_play_count"] = maxi(0, int(source.get("dice_roulette_play_count", 0)))
	data["dice_roulette_win_count"] = maxi(0, int(source.get("dice_roulette_win_count", 0)))
	data["dice_roulette_best_payout"] = maxi(0, int(source.get("dice_roulette_best_payout", 0)))
	data[ACTIVE_GAMES_KEY] = _normalize_active_games(source.get(ACTIVE_GAMES_KEY, {}))
	data[SETTLEMENTS_KEY] = source.get(SETTLEMENTS_KEY, {}) as Dictionary if source.get(SETTLEMENTS_KEY, {}) is Dictionary else {}
	data["casino_settlement_order"] = source.get("casino_settlement_order", []) as Array if source.get("casino_settlement_order", []) is Array else []
	return data

static func _facility_key(facility_id: String) -> String:
	return facility_id.strip_edges().to_lower()

static func _pending_rolls(session: Dictionary) -> Array:
	var pending: Variant = session.get("pending_rolls", [])
	return (pending as Array).duplicate(true) if pending is Array else []

static func _copy_session_fields(record: Dictionary, session: Dictionary) -> void:
	for field: Variant in session.keys():
		var name := str(field)
		if name in ["facility_id", "game_id", "bet", "stake", "status", "settled", "session", "pending_rolls", "started_at", "updated_at"]:
			continue
		record[name] = (session[field] as Variant).duplicate(true) if session[field] is Array or session[field] is Dictionary else session[field]

static func _active_games(data: Dictionary) -> Dictionary:
	var value: Variant = data.get(ACTIVE_GAMES_KEY, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

static func _settlements(data: Dictionary) -> Dictionary:
	var value: Variant = data.get(SETTLEMENTS_KEY, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}

static func _latest_settlement_for(data: Dictionary, facility_id: String, game_id: String = "") -> Dictionary:
	var settlements := _settlements(data)
	if not game_id.is_empty() and settlements.has(game_id) and settlements[game_id] is Dictionary:
		return (settlements[game_id] as Dictionary).duplicate(true)
	var order: Array = data.get("casino_settlement_order", []) as Array if data.get("casino_settlement_order", []) is Array else []
	for index: int in range(order.size() - 1, -1, -1):
		var candidate_id := str(order[index])
		var candidate: Variant = settlements.get(candidate_id, {})
		if candidate is Dictionary and str((candidate as Dictionary).get("facility_id", "")) == facility_id:
			return (candidate as Dictionary).duplicate(true)
	return {}

static func _normalize_active_games(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var result: Dictionary = {}
	for raw_key: Variant in (value as Dictionary).keys():
		var key := _facility_key(str(raw_key))
		var raw: Variant = (value as Dictionary)[raw_key]
		if key.is_empty() or not raw is Dictionary:
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate(true)
		entry["facility_id"] = key
		entry["game_id"] = str(entry.get("game_id", "%s:legacy" % key))
		entry["bet"] = maxi(0, int(entry.get("bet", entry.get("stake", 0))))
		entry["stake"] = int(entry["bet"])
		entry["status"] = "active"
		entry["settled"] = false
		var nested: Variant = entry.get("session", {})
		entry["session"] = (nested as Dictionary).duplicate(true) if nested is Dictionary else {}
		entry["pending_rolls"] = _pending_rolls(entry["session"] as Dictionary)
		result[key] = entry
	return result
