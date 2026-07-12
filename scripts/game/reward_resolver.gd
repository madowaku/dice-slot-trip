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
		"LAP_BONUS":
			var lap_amount := maxi(0, int(effect.get("amount", 0)))
			state["current_lap_bonus"] = maxi(0, int(state.get("current_lap_bonus", 0)) + lap_amount)
			summary.append("ラップボーナス +%d" % lap_amount)
		"SOUVENIR":
			var souvenir_amount := maxi(0, int(effect.get("amount", 1)))
			state["souvenirs"] = maxi(0, int(state.get("souvenirs", 0)) + souvenir_amount)
			summary.append("旅の記憶 +%d" % souvenir_amount)
		"LANDMARK_LEVEL":
			var landmark_id := str(effect.get("landmark_id", ""))
			var levels: Dictionary = (state.get("landmark_levels", {}) as Dictionary).duplicate(true)
			levels[landmark_id] = clampi(int(effect.get("level", levels.get(landmark_id, 0))), 0, 3)
			state["landmark_levels"] = levels
			var development := 0
			for level: Variant in levels.values(): development += clampi(int(level), 0, 3)
			state["stage_development"] = clampi(development, 0, 9)
			summary.append("名所 Lv.%d" % int(levels[landmark_id]))
		"LANDMARK_COMMIT":
			state["landmark_resolution_id"] = str(effect.get("resolution_id", ""))
			state["landmark_reward_committed"] = true
		"LAP_COMMIT":
			var lap_number := int(effect.get("lap_number", int(state.get("laps", 0)) + 1))
			var total_lap_number := int(effect.get("total_lap_number", int(state.get("total_laps", 0)) + 1))
			var points := maxi(100, int(effect.get("points", 100)))
			var score := maxi(0, int(effect.get("score", 0)))
			state["laps"] = lap_number
			state["total_laps"] = total_lap_number
			state["highest_laps_in_one_journey"] = maxi(int(state.get("highest_laps_in_one_journey", 0)), lap_number)
			state["total_lap_points"] = maxi(0, int(state.get("total_lap_points", 0)) + points)
			state["best_lap_score"] = maxi(int(state.get("best_lap_score", 0)), score)
			state["coins"] = mini(COIN_MAX, int(state.get("coins", 0)) + maxi(0, int(effect.get("coins", 15))))
			state["current_lap_bonus"] = 0
			state["current_lap_roll_count"] = 0
			state["current_lap_clean"] = true
			state["current_lap_penalty_count"] = 0
			state["flow_reward_3_claimed_this_lap"] = false
			state["flow_reward_5_claimed_this_lap"] = false
			state["lap_resolution_id"] = str(effect.get("resolution_id", ""))
			state["lap_reward_committed"] = true
			state["last_lap_result"] = (effect.get("result", {}) as Dictionary).duplicate(true)
			var stamps: Array = state.get("stamps", [])
			var stamp := "CAIRO-%02d" % lap_number
			if stamp not in stamps: stamps.append(stamp)
			state["stamps"] = stamps
			var memos: Array = state.get("memos", [])
			memos.append("カイロを一周。砂時計のスタンプを押した。")
			state["memos"] = memos
			# M4A's once-per-loop state changes at the same durable commit as
			# points and legacy coins, regardless of NORMAL or WARP source.
			state["events_seen_this_loop"] = []
			state["rare_event_used_this_loop"] = false
			state["events_since_rare"] = 99
			summary.append("LAP POINT +%d" % points)
			summary.append("旅コイン +%d" % maxi(0, int(effect.get("coins", 15))))
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
