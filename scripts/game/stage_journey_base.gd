class_name StageJourneyBase
extends RefCounted

const MAX_HEARTS := 3
const MAX_LIFE := 3
const ITEM_CAPACITY := 3
const SKILL_GAUGE_MAX := 3
const MISSION_STANDARD_REWARD := 12
const COIN_COST_RISK_INSURANCE := 2
const COIN_COST_REST_BOOST := 2
const COIN_COST_BOSS_SHIELD := 3
const COIN_COST_BOSS_HEAD_START := 4
const COIN_COST_BOSS_SABOTAGE := 5
const COIN_FLAG_NEXT_REST_BOOST := "next_rest_boost"
const COIN_FLAG_BOSS_SHIELD := "boss_support_shield"
const COIN_FLAG_BOSS_HEAD_START := "boss_support_head_start"
const COIN_FLAG_BOSS_SABOTAGE := "boss_support_sabotage"
const JOURNEY_MISSION_POOL := [
	{"id": "journey_face4", "kind": "dice", "short_text": "4を10回出す", "target": 10, "target_face": 4, "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "dice"},
	{"id": "journey_pair4", "kind": "slot", "short_text": "PAIRを4回作る", "target": 4, "target_role": "PAIR", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "slot"},
	{"id": "journey_straight3", "kind": "slot", "short_text": "STRAIGHTを3回作る", "target": 3, "target_role": "STRAIGHT", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "slot"},
	{"id": "journey_triple2", "kind": "slot", "short_text": "TRIPLEを2回作る", "target": 2, "target_role": "TRIPLE", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "slot"},
	{"id": "journey_coin3", "kind": "landing", "short_text": "COINマスに3回止まる", "target": 3, "target_kind": "COIN", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "coin"},
	{"id": "journey_item2", "kind": "landing", "short_text": "ITEMマスに2回止まる", "target": 2, "target_kind": "ITEM", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "item"},
	{"id": "journey_risk3", "kind": "landing", "short_text": "RISKマスに3回止まる", "target": 3, "target_kind": "RISK", "reward_coins": MISSION_STANDARD_REWARD, "icon_kind": "risk"},
]
const RETIRED_JOURNEY_MISSION_IDS := ["journey_travel30", "journey_coin12"]
const ITEM_WATER_CANTEEN := "water_canteen"
const ITEM_BRASS_COMPASS := "brass_compass"
const ITEM_SCARAB_SEAL := "scarab_seal"
const ITEM_IDS := [ITEM_WATER_CANTEEN, ITEM_BRASS_COMPASS, ITEM_SCARAB_SEAL]
const RestEffectModelScript = preload("res://scripts/game/rest_effect_model.gd")

const PHASE_READY: StringName = &"READY"
const PHASE_BRANCH: StringName = &"BRANCH"
const PHASE_EVENT: StringName = &"EVENT"
const PHASE_BOSS_CHOICE: StringName = &"BOSS_CHOICE"
const PHASE_SECRET: StringName = &"SECRET"
const PHASE_BOSS: StringName = &"BOSS"
const PHASE_RUN_OVER: StringName = &"RUN_OVER"

var stage_id: StringName = &""
var stage_name := ""
var phase: StringName = PHASE_READY
var lap := 1
var current_space_id := ""
var hp := MAX_HEARTS
var max_hp := MAX_HEARTS
var life := MAX_LIFE
var coins := 0
var score := 0
var cumulative_score := 0
var roll_count := 0
var discovered: Dictionary = {}
var consumed: Dictionary = {}
var stage_flags: Dictionary = {}
var pending_steps := 0
var pending_choices: Array[Dictionary] = []
var pending_event: Dictionary = {}
var last_result: Dictionary = {}
var item_rng := RandomNumberGenerator.new()
var item_rng_ready := false


func can_roll() -> bool:
	return phase == PHASE_READY


func resolve_life_if_needed() -> Dictionary:
	if hp > 0:
		return {"revived": false, "run_over": false}
	if life > 0:
		life -= 1
		hp = max_hp
		return {"revived": true, "run_over": false, "hp": hp, "life": life}
	phase = PHASE_RUN_OVER
	return {"revived": false, "run_over": true, "hp": hp, "life": life}


func apply_heart_roulette(slot_index: int) -> Dictionary:
	var result := HeartRouletteModel.resolve(hp, max_hp, slot_index)
	if bool(result.get("ok", false)):
		hp = int(result.get("after_hp", hp))
	return result


func apply_rest_landing(heal_amount: int = 1) -> Dictionary:
	var boost := 1 if bool(stage_flags.get(COIN_FLAG_NEXT_REST_BOOST, false)) else 0
	var was_full := hp >= max_hp
	var result := RestEffectModelScript.resolve(hp, max_hp, heal_amount + boost)
	if boost > 0:
		stage_flags.erase(COIN_FLAG_NEXT_REST_BOOST)
		result["rest_boost_used"] = true
	hp = int(result.get("after_hp", hp))
	if was_full:
		var before_skill := skill_gauge()
		stage_flags["skill_gauge"] = mini(before_skill + 1, SKILL_GAUGE_MAX)
		result["coin_bonus"] = 0
		result["skill_bonus"] = int(stage_flags["skill_gauge"]) - before_skill
		result["text"] = "HP FULL  SKILL +1" if before_skill < SKILL_GAUGE_MAX else "HP / SKILL MAX"
	return result


func start_next_lap() -> void:
	var had_journey_mission := stage_flags.has("journey_mission")
	lap += 1
	cumulative_score += score
	score = 0
	roll_count = 0
	coins = 0
	discovered.clear()
	consumed.clear()
	# Travel resources are intentionally lap-local, matching Cairo: the player
	# starts each new sightseeing loop with an empty bag and skill gauge.
	for resource_key: String in ["item_count", "item_inventory", "next_move_bonus", "risk_shield", COIN_FLAG_NEXT_REST_BOOST, COIN_FLAG_BOSS_SHIELD, COIN_FLAG_BOSS_HEAD_START, COIN_FLAG_BOSS_SABOTAGE, "skill_gauge", "skill_last_roll", "skill_next_face", "skill_ready_seen", "mission_event_count", "mission_rest_count", "journey_mission"]:
		stage_flags.erase(resource_key)
	pending_steps = 0
	pending_choices.clear()
	pending_event.clear()
	last_result.clear()
	phase = PHASE_READY
	if had_journey_mission:
		ensure_journey_mission()


func snapshot() -> Dictionary:
	return {
		"stage_id": String(stage_id),
		"stage_name": stage_name,
		"phase": String(phase),
		"lap": lap,
		"current_space_id": current_space_id,
		"hp": hp,
		"max_hp": max_hp,
		"life": life,
		"coins": coins,
		"score": score,
		"cumulative_score": cumulative_score,
		"roll_count": roll_count,
		"discovered": discovered.keys(),
		"consumed": consumed.keys(),
		"stage_flags": stage_flags.duplicate(true),
		"pending_steps": pending_steps,
		"pending_choices": pending_choices.duplicate(true),
		"pending_event": pending_event.duplicate(true),
		"last_result": last_result.duplicate(true),
	}


func restore(data: Dictionary) -> bool:
	if str(data.get("stage_id", "")) != String(stage_id):
		return false
	phase = StringName(str(data.get("phase", PHASE_READY)))
	lap = maxi(int(data.get("lap", 1)), 1)
	current_space_id = str(data.get("current_space_id", current_space_id))
	# Amazon/Kyoto schema v1 saves used six HP. Product journeys share Cairo's
	# fixed three-heart contract, so legacy values are safely clamped on resume.
	max_hp = MAX_HEARTS
	hp = clampi(int(data.get("hp", max_hp)), 0, max_hp)
	life = clampi(int(data.get("life", life)), 0, MAX_LIFE)
	coins = maxi(int(data.get("coins", coins)), 0)
	score = maxi(int(data.get("score", score)), 0)
	cumulative_score = maxi(int(data.get("cumulative_score", cumulative_score)), 0)
	roll_count = maxi(int(data.get("roll_count", roll_count)), 0)
	discovered.clear()
	for value: Variant in data.get("discovered", []):
		discovered[str(value)] = true
	consumed.clear()
	for value: Variant in data.get("consumed", []):
		consumed[str(value)] = true
	stage_flags = (data.get("stage_flags", {}) as Dictionary).duplicate(true)
	_normalize_item_inventory()
	stage_flags["skill_gauge"] = clampi(int(stage_flags.get("skill_gauge", 0)), 0, SKILL_GAUGE_MAX)
	if int(stage_flags.get("skill_next_face", 0)) not in range(1, 7):
		stage_flags.erase("skill_next_face")
	pending_steps = maxi(int(data.get("pending_steps", 0)), 0)
	pending_choices.clear()
	for value: Variant in data.get("pending_choices", []):
		if value is Dictionary:
			pending_choices.append((value as Dictionary).duplicate(true))
	pending_event = (data.get("pending_event", {}) as Dictionary).duplicate(true)
	last_result = (data.get("last_result", {}) as Dictionary).duplicate(true)
	return true


func ensure_journey_mission() -> Dictionary:
	var raw: Variant = stage_flags.get("journey_mission", null)
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		var existing := (raw as Dictionary).duplicate(true)
		if str(existing.get("id", "")) not in RETIRED_JOURNEY_MISSION_IDS:
			existing["progress"] = clampi(int(existing.get("progress", 0)), 0, maxi(int(existing.get("target", 1)), 1))
			existing["completed"] = bool(existing.get("completed", false))
			existing["reward_claimed"] = bool(existing.get("reward_claimed", false))
			stage_flags["journey_mission"] = existing
			return existing.duplicate(true)
		stage_flags.erase("journey_mission")
	var selection_seed := int(Time.get_ticks_usec()) ^ int(hash(String(stage_id))) ^ (lap * 7919)
	var index := posmod(selection_seed, JOURNEY_MISSION_POOL.size())
	var mission := (JOURNEY_MISSION_POOL[index] as Dictionary).duplicate(true)
	mission["progress"] = 0
	mission["completed"] = false
	mission["reward_claimed"] = false
	mission["selection_seed"] = selection_seed
	mission["last_coins"] = coins
	stage_flags["journey_mission"] = mission
	return mission.duplicate(true)


func journey_mission_state() -> Dictionary:
	return ensure_journey_mission()


func record_journey_mission_roll(face: int, traveled_spaces: int) -> Dictionary:
	var mission := ensure_journey_mission()
	if not bool(mission.get("completed", false)):
		match str(mission.get("kind", "")):
			"dice":
				if face == int(mission.get("target_face", 0)):
					mission["progress"] = int(mission.get("progress", 0)) + 1
	_finalize_journey_mission(mission)
	stage_flags["journey_mission"] = mission
	return mission.duplicate(true)


func record_journey_mission_role(role: String) -> Dictionary:
	var mission := ensure_journey_mission()
	if not bool(mission.get("completed", false)) and str(mission.get("kind", "")) == "slot" and role == str(mission.get("target_role", "")):
		mission["progress"] = int(mission.get("progress", 0)) + 1
	_finalize_journey_mission(mission)
	stage_flags["journey_mission"] = mission
	return mission.duplicate(true)


func record_journey_mission_landing(space_kind: String) -> Dictionary:
	var mission := ensure_journey_mission()
	if not bool(mission.get("completed", false)) and str(mission.get("kind", "")) == "landing" and space_kind == str(mission.get("target_kind", "")):
		mission["progress"] = int(mission.get("progress", 0)) + 1
	_finalize_journey_mission(mission)
	stage_flags["journey_mission"] = mission
	return mission.duplicate(true)


func sync_journey_mission() -> Dictionary:
	var mission := ensure_journey_mission()
	_finalize_journey_mission(mission)
	stage_flags["journey_mission"] = mission
	return mission.duplicate(true)


func _finalize_journey_mission(mission: Dictionary) -> void:
	var target := maxi(int(mission.get("target", 1)), 1)
	mission["progress"] = clampi(int(mission.get("progress", 0)), 0, target)
	if int(mission.get("progress", 0)) < target:
		return
	mission["completed"] = true
	if bool(mission.get("reward_claimed", false)):
		return
	coins += maxi(int(mission.get("reward_coins", MISSION_STANDARD_REWARD)), 0)
	mission["reward_claimed"] = true
	mission["last_coins"] = coins


func item_count() -> int:
	return inventory_total()


func add_item(amount: int = 1) -> int:
	for _index: int in range(maxi(amount, 0)):
		grant_random_item()
	return item_count()


func consume_item() -> bool:
	var inventory := item_inventory()
	for item_id: String in ITEM_IDS:
		if int(inventory.get(item_id, 0)) > 0:
			inventory[item_id] = int(inventory.get(item_id, 0)) - 1
			_set_item_inventory(inventory)
			return true
	return false


func item_inventory() -> Dictionary:
	_normalize_item_inventory()
	return (stage_flags.get("item_inventory", {}) as Dictionary).duplicate(true)


func inventory_total() -> int:
	if not stage_flags.has("item_inventory"):
		_normalize_item_inventory()
	var total := 0
	var inventory := stage_flags.get("item_inventory", {}) as Dictionary
	for item_id: String in ITEM_IDS:
		total += maxi(int(inventory.get(item_id, 0)), 0)
	return clampi(total, 0, ITEM_CAPACITY)


func item_catalog() -> Array[Dictionary]:
	return [
		{"id": ITEM_WATER_CANTEEN, "name": "旅人の水筒", "effect_text": "♥ +1", "description": "HPを1回復する。"},
		{"id": ITEM_BRASS_COMPASS, "name": "真鍮のコンパス", "effect_text": "DICE +1", "description": "次の移動を1マス増やす。"},
		{"id": ITEM_SCARAB_SEAL, "name": "スカラベの護符", "effect_text": "RISK ×0", "description": "次に受けるRISKを無効化する。"},
	]


func inventory_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var inventory := item_inventory()
	for definition: Dictionary in item_catalog():
		var amount := maxi(int(inventory.get(str(definition.get("id", "")), 0)), 0)
		if amount <= 0:
			continue
		var entry := definition.duplicate(true)
		entry["amount"] = amount
		entries.append(entry)
	return entries


func grant_random_item() -> Dictionary:
	if inventory_total() >= ITEM_CAPACITY:
		coins += 2
		return {"ok": true, "full": true, "converted_to_coins": 2, "text": "ITEM FULL  COIN +2"}
	if not item_rng_ready:
		item_rng.randomize()
		item_rng_ready = true
	var item_id := ITEM_IDS[item_rng.randi_range(0, ITEM_IDS.size() - 1)] as String
	var inventory := item_inventory()
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	_set_item_inventory(inventory)
	var definition := _item_definition(item_id)
	return {"ok": true, "item_id": item_id, "item_name": str(definition.get("name", item_id)), "text": "ITEM  %s" % str(definition.get("name", item_id))}


func use_item(item_id: String) -> Dictionary:
	if phase != PHASE_READY:
		return {"ok": false, "error": "ITEM_NOT_AVAILABLE"}
	var inventory := item_inventory()
	if int(inventory.get(item_id, 0)) <= 0:
		return {"ok": false, "error": "ITEM_NOT_OWNED"}
	var text := ""
	match item_id:
		ITEM_WATER_CANTEEN:
			if hp >= max_hp:
				return {"ok": false, "error": "HP_FULL"}
			hp = mini(hp + 1, max_hp)
			text = "旅人の水筒を使った。HP +1"
		ITEM_BRASS_COMPASS:
			if next_move_bonus() > 0:
				return {"ok": false, "error": "COMPASS_ALREADY_ACTIVE"}
			stage_flags["next_move_bonus"] = 1
			text = "真鍮のコンパスを使った。次の移動 +1"
		ITEM_SCARAB_SEAL:
			if bool(stage_flags.get("risk_shield", false)):
				return {"ok": false, "error": "SCARAB_ALREADY_ACTIVE"}
			stage_flags["risk_shield"] = true
			text = "スカラベの護符を使った。次のRISKを無効化"
		_:
			return {"ok": false, "error": "UNKNOWN_ITEM"}
	inventory[item_id] = int(inventory.get(item_id, 0)) - 1
	_set_item_inventory(inventory)
	return {"ok": true, "status": "ITEM_USED", "item_id": item_id, "text": text}


func next_move_bonus() -> int:
	return maxi(int(stage_flags.get("next_move_bonus", 0)), 0)


func consume_next_move_bonus() -> int:
	var bonus := next_move_bonus()
	stage_flags.erase("next_move_bonus")
	return bonus


func consume_risk_shield() -> bool:
	if not bool(stage_flags.get("risk_shield", false)):
		return false
	stage_flags.erase("risk_shield")
	return true


func coin_action_catalog(kyoto_boss_copy: bool = false) -> Array[Dictionary]:
	return [
		{"id": "risk_insurance", "name": "RISKガード", "category": "旅の道具", "cost": COIN_COST_RISK_INSURANCE, "effect_text": "次のRISKを1回防ぐ", "timing": "通常マップで有効", "use_rule": "次のRISKで自動発動・1回で消費", "active": bool(stage_flags.get("risk_shield", false))},
		{"id": "rest_boost", "name": "ハート強化", "category": "旅の道具", "cost": COIN_COST_REST_BOOST, "effect_text": "次のREST回復を強化する", "timing": "通常マップで有効", "use_rule": "次のRESTで自動発動・1回で消費", "active": bool(stage_flags.get(COIN_FLAG_NEXT_REST_BOOST, false))},
		{"id": "boss_shield", "name": "ボスの盾", "category": "ボスの準備", "cost": COIN_COST_BOSS_SHIELD, "effect_text": "最初の狐火を1個無効化" if kyoto_boss_copy else "次のボス移動を1回半分にする", "timing": "次のボス戦で有効", "use_rule": "ボス戦で自動発動・1回で消費", "active": bool(stage_flags.get(COIN_FLAG_BOSS_SHIELD, false))},
		{"id": "boss_head_start", "name": "先行スタート", "category": "ボスの準備", "cost": COIN_COST_BOSS_HEAD_START, "effect_text": "猫を+3マスして開始", "timing": "次のボス戦で有効", "use_rule": "開始時に自動発動・1回で消費", "active": bool(stage_flags.get(COIN_FLAG_BOSS_HEAD_START, false))},
		{"id": "boss_sabotage", "name": "ボスを止める", "category": "ボスの準備", "cost": COIN_COST_BOSS_SABOTAGE, "effect_text": "白狐が最初の1回だけ動かない" if kyoto_boss_copy else "次のボス移動を1回止める", "timing": "次のボス戦で有効", "use_rule": "ボス戦で自動発動・1回で消費", "active": bool(stage_flags.get(COIN_FLAG_BOSS_SABOTAGE, false))},
	]


func purchase_coin_action(action_id: String) -> Dictionary:
	if phase != PHASE_READY:
		return {"ok": false, "error": "COIN_ACTION_NOT_AVAILABLE"}
	var flag := ""
	var cost := 0
	match action_id:
		"risk_insurance": flag = "risk_shield"; cost = COIN_COST_RISK_INSURANCE
		"rest_boost": flag = COIN_FLAG_NEXT_REST_BOOST; cost = COIN_COST_REST_BOOST
		"boss_shield": flag = COIN_FLAG_BOSS_SHIELD; cost = COIN_COST_BOSS_SHIELD
		"boss_head_start": flag = COIN_FLAG_BOSS_HEAD_START; cost = COIN_COST_BOSS_HEAD_START
		"boss_sabotage": flag = COIN_FLAG_BOSS_SABOTAGE; cost = COIN_COST_BOSS_SABOTAGE
		_: return {"ok": false, "error": "UNKNOWN_COIN_ACTION"}
	if bool(stage_flags.get(flag, false)):
		return {"ok": false, "error": "COIN_ACTION_ALREADY_ACTIVE"}
	if coins < cost:
		return {"ok": false, "error": "NOT_ENOUGH_COINS", "cost": cost, "coins": coins}
	coins -= cost
	stage_flags[flag] = true
	return {"ok": true, "status": "COIN_ACTION_PURCHASED", "action_id": action_id, "cost": cost, "coins": coins}


func boss_support_snapshot() -> Dictionary:
	return {
		"shield": bool(stage_flags.get(COIN_FLAG_BOSS_SHIELD, false)),
		"head_start": bool(stage_flags.get(COIN_FLAG_BOSS_HEAD_START, false)),
		"sabotage": bool(stage_flags.get(COIN_FLAG_BOSS_SABOTAGE, false)),
	}


func consume_boss_supports() -> Dictionary:
	var supports := boss_support_snapshot()
	stage_flags.erase(COIN_FLAG_BOSS_SHIELD)
	stage_flags.erase(COIN_FLAG_BOSS_HEAD_START)
	stage_flags.erase(COIN_FLAG_BOSS_SABOTAGE)
	return supports


func _item_definition(item_id: String) -> Dictionary:
	for definition: Dictionary in item_catalog():
		if str(definition.get("id", "")) == item_id:
			return definition
	return {"id": item_id, "name": item_id}


func _set_item_inventory(inventory: Dictionary) -> void:
	var normalized: Dictionary = {}
	var total := 0
	for item_id: String in ITEM_IDS:
		var amount := mini(maxi(int(inventory.get(item_id, 0)), 0), ITEM_CAPACITY - total)
		if amount > 0:
			normalized[item_id] = amount
			total += amount
		if total >= ITEM_CAPACITY:
			break
	stage_flags["item_inventory"] = normalized
	stage_flags["item_count"] = clampi(total, 0, ITEM_CAPACITY)


func _normalize_item_inventory() -> void:
	var raw: Variant = stage_flags.get("item_inventory", null)
	var inventory: Dictionary = {}
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		inventory = (raw as Dictionary).duplicate(true)
	else:
		var legacy_count := clampi(int(stage_flags.get("item_count", 0)), 0, ITEM_CAPACITY)
		if legacy_count > 0:
			inventory[ITEM_WATER_CANTEEN] = legacy_count
	_set_item_inventory(inventory)


func skill_gauge() -> int:
	return clampi(int(stage_flags.get("skill_gauge", 0)), 0, SKILL_GAUGE_MAX)


func skill_ready() -> bool:
	return skill_gauge() >= SKILL_GAUGE_MAX


func charge_skill_for_role(role: String, roll_number: int = -1) -> Dictionary:
	var before := skill_gauge()
	return {"ok": false, "error": "SKILL_CHARGES_ON_FULL_REST", "role": role, "roll_number": roll_number, "before": before, "after": before, "changed": false, "ready": skill_ready(), "first_ready": false}


func arm_skill_face(face: int) -> Dictionary:
	if phase != PHASE_READY:
		return {"ok": false, "error": "SKILL_NOT_AVAILABLE"}
	if not skill_ready():
		return {"ok": false, "error": "SKILL_NOT_READY"}
	if face < 1 or face > 6:
		return {"ok": false, "error": "INVALID_FACE"}
	stage_flags["skill_next_face"] = face
	stage_flags["skill_gauge"] = 0
	return {"ok": true, "status": "SKILL_ARMED", "face": face, "text": "次のサイコロ → %d" % face}


func peek_skill_face() -> int:
	return clampi(int(stage_flags.get("skill_next_face", 0)), 0, 6)


func consume_skill_face() -> int:
	var face := peek_skill_face()
	stage_flags.erase("skill_next_face")
	return face
