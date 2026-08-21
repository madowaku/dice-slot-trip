extends RefCounted
class_name CasinoBank

const SAVE_PATH := "user://dice_slot_trip_casino.json"
const SAVE_VERSION := 1
const COIN_TO_CHIP_RATE := 2
const CLEAR_CHIP_BONUS := 5

static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"chips": 0,
		"owned_cards": [],
		"dice_race_play_count": 0,
		"dice_race_win_count": 0,
		"dice_race_best_payout": 0,
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

static func stage_clear_conversion(remaining_trip_coin: int, cleared_boss: bool = true) -> Dictionary:
	var remainder := maxi(0, remaining_trip_coin)
	var converted := remainder / COIN_TO_CHIP_RATE
	var clear_bonus := CLEAR_CHIP_BONUS if cleared_boss else 0
	var gained := int(converted) + clear_bonus
	var before := balance()
	var after := add_chips(gained)
	return {
		"remaining_trip_coin": remainder,
		"converted_chip": int(converted),
		"clear_bonus": clear_bonus,
		"gained_chip": gained,
		"balance_before": before,
		"balance_after": after,
	}

static func own_card(card_id: String, cost: int) -> bool:
	var id := card_id.strip_edges()
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

static func _normalize(source: Dictionary) -> Dictionary:
	var data := default_data()
	data["chips"] = maxi(0, int(source.get("chips", 0)))
	var cards: Array = source.get("owned_cards", [])
	var unique_cards: Array[String] = []
	for card: Variant in cards:
		var id := str(card).strip_edges()
		if not id.is_empty() and id not in unique_cards:
			unique_cards.append(id)
	data["owned_cards"] = unique_cards
	data["dice_race_play_count"] = maxi(0, int(source.get("dice_race_play_count", 0)))
	data["dice_race_win_count"] = maxi(0, int(source.get("dice_race_win_count", 0)))
	data["dice_race_best_payout"] = maxi(0, int(source.get("dice_race_best_payout", 0)))
	return data
