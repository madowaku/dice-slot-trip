extends RefCounted
class_name CasinoBank

const SAVE_PATH := "user://dice_slot_trip_casino.json"
const SAVE_VERSION := 3
const COIN_TO_CHIP_RATE := 2
const CLEAR_CHIP_BONUS := 5
const LEGACY_CARD_ALIASES := {
	"dice_racer_crocodile": "dice_racer_rabbit",
}

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
	}

static func load_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_data()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return default_data()
	return _normalize(parsed as Dictionary)

static func save_data(data: Dictionary) -> bool:
	var normalized := _normalize(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
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

static func settle_dice_roulette(wager: int, payout: int) -> Dictionary:
	var stake := maxi(0, wager)
	var reward := maxi(0, payout)
	if stake <= 0:
		return {"ok": false, "reason": "invalid_wager", "balance": balance()}
	var data := load_data()
	var before := int(data.get("chips", 0))
	if before < stake:
		return {"ok": false, "reason": "insufficient_chips", "balance": before}
	var after := before - stake + reward
	data["chips"] = maxi(0, after)
	data["dice_roulette_play_count"] = int(data.get("dice_roulette_play_count", 0)) + 1
	if reward > stake:
		data["dice_roulette_win_count"] = int(data.get("dice_roulette_win_count", 0)) + 1
	data["dice_roulette_best_payout"] = maxi(int(data.get("dice_roulette_best_payout", 0)), reward)
	if not save_data(data):
		return {"ok": false, "reason": "save_failed", "balance": before}
	return {
		"ok": true,
		"balance_before": before,
		"wager": stake,
		"payout": reward,
		"profit": reward - stake,
		"balance_after": after,
	}

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

static func _normalize_card_id(card_id: String) -> String:
	var id := card_id.strip_edges()
	return str(LEGACY_CARD_ALIASES.get(id, id))

static func _normalize(source: Dictionary) -> Dictionary:
	var data := default_data()
	data["chips"] = maxi(0, int(source.get("chips", 0)))
	var cards: Array = source.get("owned_cards", [])
	var unique_cards: Array[String] = []
	for card: Variant in cards:
		var id := _normalize_card_id(str(card))
		if not id.is_empty() and id not in unique_cards:
			unique_cards.append(id)
	data["owned_cards"] = unique_cards
	var keys: Array = source.get("conversion_keys", [])
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
	return data
