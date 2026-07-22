class_name V1PlaySession
extends RefCounted

const Slot = preload("res://scripts/game/v1_three_roll_slot.gd")
const Skill = preload("res://scripts/game/v1_explorer_skill.gd")
const Race = preload("res://scripts/game/v1_boss_race.gd")
const StageModel = preload("res://scripts/game/v1_stage_model.gd")

var slot = Slot.new()
var skill = Skill.new()
var race
var coins := 0
var stage_model = StageModel.new()
var stage_position := ""
var pending_stage_movement: Dictionary = {}
var _pending_stage_roll: Dictionary = {}

func _init() -> void:
	if stage_model.load_bundle():
		stage_position = stage_model.stage.get("stage", {}).get("start_node", "")

func play_stage_roll(face: int) -> Dictionary:
	if race != null or not pending_stage_movement.is_empty() or face < 1 or face > 6 or stage_position.is_empty():
		return {}
	var focus_used := skill.begin_roll()
	var effective_face := Race.effective_player_roll(face, 0)
	var movement: Dictionary = stage_model.advance(stage_position, effective_face)
	if movement.status == StageModel.ADVANCE_REJECTED:
		if focus_used:
			skill.state = skill.State.ARMED
		return {}
	_pending_stage_roll = {"effective_face": effective_face, "focus_used": focus_used}
	return _accept_stage_movement(movement)

func choose_stage_branch(choice: String) -> Dictionary:
	if pending_stage_movement.is_empty() or _pending_stage_roll.is_empty():
		return {}
	var movement := stage_model.advance(stage_position, int(pending_stage_movement.remaining), choice)
	if movement.status == StageModel.ADVANCE_REJECTED:
		return {}
	return _accept_stage_movement(movement)

func begin_boss_race(ignore_first_sand: bool = false) -> void:
	race = Race.new()
	race.player_ignore_first_sand = ignore_first_sand

func play_boss_roll(tapped_face: int, allowed_modifier: int = 0) -> Dictionary:
	if race == null or race.winner != &"":
		return {}
	return _resolve_roll(tapped_face, allowed_modifier, true)

func reset_stage() -> void:
	slot = Slot.new()
	skill.reset()
	race = null
	coins = 0
	pending_stage_movement = {}
	_pending_stage_roll = {}
	stage_position = stage_model.stage.get("stage", {}).get("start_node", "")

func result() -> Dictionary:
	return {} if race == null else race.result()

func _resolve_roll(tapped_face: int, allowed_modifier: int, in_boss: bool) -> Dictionary:
	if tapped_face < 1 or tapped_face > 6:
		return {}
	var focus_used := skill.begin_roll()
	var effective_face := Race.effective_player_roll(tapped_face, allowed_modifier)
	var race_turn := {}
	if in_boss:
		race_turn = race.play_turn(tapped_face, allowed_modifier)
	slot.begin_roll()
	slot.append_face(effective_face)
	if focus_used:
		skill.finish_roll()
	var slot_reward := {}
	if slot.is_complete():
		slot_reward = slot.resolve_reward(skill.gauge)
		coins += int(slot_reward.coins)
		var charge_gain: int = int(slot_reward.gauge) - skill.gauge
		if charge_gain > 0:
			skill.add_charge(charge_gain)
	return {
		"effective_face": effective_face,
		"focus_used": focus_used,
		"slot_faces": slot.faces(),
		"slot_reward": slot_reward,
		"skill_gauge": skill.gauge,
		"coins": coins,
		"race_turn": race_turn,
	}

func _accept_stage_movement(movement: Dictionary) -> Dictionary:
	stage_position = movement.position
	if movement.status == StageModel.ADVANCE_BRANCH_REQUIRED:
		pending_stage_movement = movement
		return {"movement": movement, "effective_face": _pending_stage_roll.effective_face, "focus_used": _pending_stage_roll.focus_used}
	pending_stage_movement = {}
	var committed := _commit_stage_face(int(_pending_stage_roll.effective_face), bool(_pending_stage_roll.focus_used))
	_pending_stage_roll = {}
	committed["movement"] = movement
	if movement.status == StageModel.ADVANCE_BOSS_GATE:
		begin_boss_race()
	return committed

func _commit_stage_face(effective_face: int, focus_used: bool) -> Dictionary:
	slot.begin_roll()
	slot.append_face(effective_face)
	if focus_used:
		skill.finish_roll()
	var slot_reward := {}
	if slot.is_complete():
		slot_reward = slot.resolve_reward(skill.gauge)
		coins += int(slot_reward.coins)
		var charge_gain: int = int(slot_reward.gauge) - skill.gauge
		if charge_gain > 0:
			skill.add_charge(charge_gain)
	return {"effective_face": effective_face, "focus_used": focus_used, "slot_faces": slot.faces(), "slot_reward": slot_reward, "skill_gauge": skill.gauge, "coins": coins, "race_turn": {}}
