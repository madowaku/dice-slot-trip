class_name RewardResolver
extends RefCounted

const COINS := {"COIN_XS": 5, "COIN_S": 12, "COIN_M": 30, "COIN_L": 70, "COIN_JACKPOT": 120}
const COIN_MAX := 99999
const ITEMS := {"COMMON": "mint_tea", "UNCOMMON": "dates_pouch", "RARE": "golden_stamp_ink"}

static func apply(state: Dictionary, resolution: Dictionary, log: Array = []) -> Dictionary:
	var id := str(resolution.get("resolution_id", ""))
	if id.is_empty() or id in state.get("applied_resolution_ids", []): return {"applied": false, "summary": []}
	var summary: Array[String] = []
	for change: Variant in resolution.get("state_changes", []): _apply_one(state, change as Dictionary, summary)
	for reward: Variant in resolution.get("rewards", []): _apply_one(state, reward as Dictionary, summary)
	state["applied_resolution_ids"].append(id)
	log.append({"resolution_id": id, "summary": summary.duplicate()})
	return {"applied": true, "summary": summary}

static func _apply_one(state: Dictionary, effect: Dictionary, summary: Array[String]) -> void:
	match str(effect.get("type", "")):
		"COIN":
			var amount := int(effect.get("amount", COINS.get(str(effect.get("amount_key", "COIN_S")), 3)))
			state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + amount); summary.append("旅コイン +%d" % amount)
		"ITEM":
			var rarity := str(effect.get("rarity", _item_rarity(str(effect.get("pool", "COMMON")), str(state.get("applied_resolution_ids", []).size()))))
			var item := str(effect.get("item_id", ITEMS.get(rarity, "mint_tea")))
			state["inventory"][item] = int(state["inventory"].get(item, 0)) + 1; summary.append("%sアイテム %s" % [rarity, item])
		"DICE_ADD_1", "DICE_UNLOCK":
			# DICE_UNLOCK is a data compatibility alias for the existing M4A event
			# definitions. New content should emit DICE_ADD_1.
			var before := clampi(int(state.get("current_dice_count", state.get("unlocked_dice_count", 1))), 1, 3)
			var gained := maxi(0, int(effect.get("value", 1)))
			var after := mini(3, before + gained)
			var overflow := maxi(0, before + gained - 3)
			state["current_dice_count"] = after
			if after > before: summary.append("追加ダイス +%d（%d→%d）" % [after - before, before, after])
			if overflow > 0:
				state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + int(COINS.COIN_S) * overflow)
				summary.append("余剰ダイスを旅コイン +%dへ変換" % (int(COINS.COIN_S) * overflow))
		"DICE_SLOT_READY":
			var before := clampi(int(state.get("current_dice_count", state.get("unlocked_dice_count", 1))), 1, 3)
			state["current_dice_count"] = 3
			if before < 3:
				summary.append("DICE SLOT READY（%d→3）" % before)
			else:
				state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + int(COINS.COIN_S))
				summary.append("余剰ダイスを旅コイン +12へ変換")
		"DICE_KEEP":
			if bool(state.get("dice_keep_active", false)):
				state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + int(COINS.COIN_S))
				summary.append("DICE KEEP保持中：旅コイン +12")
			else:
				state["dice_keep_active"] = true
				summary.append("DICE KEEPを獲得")
		"BOSS_SCENT": state["presence"] = clampi(int(state.get("presence", 0)) + int(effect.get("value", 1)), 0, 5); summary.append("ボスの気配 +%d" % int(effect.get("value", 1)))
		"NEXT_INTERACTION_BONUS": state["next_interaction_bonus"] = int(state.get("next_interaction_bonus", 0)) + int(effect.get("value", 4)); summary.append("次回交流 +%d" % int(effect.get("value", 4)))
		"NEXT_MOVE_BONUS": state["next_move_bonus"] = int(state.get("next_move_bonus", 0)) + int(effect.get("value", 1)); summary.append("次回移動 +%d" % int(effect.get("value", 1)))
		"SKILL_RECOVER":
			if int(state.get("character_skill_charge", 1)) >= 1:
				state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + int(COINS.COIN_S)); summary.append("スキル満タン：旅コイン +12")
			else:
				state["character_skill_charge"] = 1; summary.append("キャラクタースキル回復")
		"TRAVEL_NOTE":
			var note := str(effect.get("note_id", "cairo_event_note")); if note not in state["registered_travel_notes"]: state["registered_travel_notes"].append(note); summary.append("旅メモ登録")
		"POSTCARD":
			var card := str(effect.get("postcard_id", "cairo_postcard")); if card not in state["registered_postcards"]: state["registered_postcards"].append(card); summary.append("ポストカード登録")
		"BOSS_ENCOUNTER", "BOSS_ENCOUNTER_RESERVATION": state["pending_boss_handoff"] = true; summary.append("大きな足跡を追う")
		"MAP_HIGHLIGHT", "MINIMAP_HIGHLIGHT": state["map_highlight"] = str(effect.get("target", "SPECIAL")); summary.append("ミニマップに印")

static func _item_rarity(pool: String, seed_text: String) -> String:
	if pool == "COMMON": return "COMMON"
	var roll := posmod(hash(seed_text + pool), 100)
	return item_rarity_for_roll(pool, roll)

static func item_rarity_for_roll(pool: String, roll: int) -> String:
	# CAI-E30 has its own rare-event table; ordinary ITEM_RARE remains 70/30.
	if pool == "RARE_EVENT": return "UNCOMMON" if clampi(roll, 0, 99) < 55 else "RARE"
	if pool == "RARE": return "UNCOMMON" if clampi(roll, 0, 99) < 70 else "RARE"
	return "COMMON"
