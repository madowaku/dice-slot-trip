class_name V06BossBattle
extends RefCounted

const V06RollSetScript = preload("res://scripts/game/v06_roll_set.gd")

const ACTION_SAND_GAZE: StringName = &"SAND_GAZE"
const ACTION_STONE_WARD: StringName = &"STONE_WARD"
const ACTION_SOLAR_SEAL: StringName = &"SOLAR_SEAL"
const PLAYER_MAX_HP: int = 3
const BOSS_MAX_HP: int = 3

var _lap: int = 1
var _round: int = 1
var _player_hp: int = PLAYER_MAX_HP
var _boss_hp: int = BOSS_MAX_HP
var _roll_set: RefCounted
var _pending_ack: bool = false
var _terminal: bool = false
var _last_result: Dictionary = {}


func _init() -> void:
	_roll_set = V06RollSetScript.new()


func configure_lap(lap: int, player_hp: int = PLAYER_MAX_HP) -> bool:
	if lap < 1 or player_hp < 1 or player_hp > PLAYER_MAX_HP or _round != 1 or not _roll_set.faces().is_empty() or _pending_ack or _terminal:
		return false
	_lap = lap
	_player_hp = player_hp
	_boss_hp = BOSS_MAX_HP
	return true


func roll_face(face: int) -> Dictionary:
	if face < 1 or face > 6:
		return _rejected("INVALID_FACE")
	if _terminal:
		return _rejected("BATTLE_TERMINAL")
	if _pending_ack or _roll_set.is_complete():
		return _rejected("ROUND_ACK_REQUIRED")
	if not _roll_set.append_face(face):
		return _rejected("ROLL_REJECTED")
	if not _roll_set.is_complete():
		return {"ok": true, "status": "FACE_ACCEPTED", "faces": _roll_set.faces()}
	_resolve_round()
	return {"ok": true, "status": "ROUND_RESOLVED", "result": result()}


func acknowledge_round() -> bool:
	if _terminal or not _pending_ack or not _roll_set.is_complete():
		return false
	if not _roll_set.reset_after_resolution():
		return false
	_pending_ack = false
	if bool(_last_result.get("victory", false)) or bool(_last_result.get("defeat", false)):
		_terminal = true
		return true
	_round += 1
	_last_result.clear()
	return true


func faces() -> Array[int]:
	return _roll_set.faces()


func result() -> Dictionary:
	return _last_result.duplicate(true)


func snapshot() -> Dictionary:
	return {
		"lap": _lap,
		"round": _round,
		"faces": faces(),
		"action": current_action(),
		"defense": current_defense(),
		"player_hp": _player_hp,
		"boss_hp": _boss_hp,
		"pending_ack": _pending_ack,
		"victory": _terminal and _boss_hp == 0,
		"defeat": _terminal and _player_hp == 0,
		"terminal": _terminal,
		"result": result(),
	}


func current_action() -> StringName:
	match (_round - 1) % 3:
		0:
			return ACTION_SAND_GAZE
		1:
			return ACTION_STONE_WARD
		_:
			return ACTION_SOLAR_SEAL


func current_defense() -> int:
	var base_defense: int = [9, 11, 13][(_round - 1) % 3]
	return base_defense + (2 if _lap % 10 == 0 else 0)


func _resolve_round() -> void:
	var resolved_faces: Array[int] = _roll_set.faces()
	var attack_sum: int = 0
	for face: int in resolved_faces:
		attack_sum += face
	var role: StringName = _roll_set.evaluate_role()
	var action: StringName = current_action()
	var defense: int = current_defense()
	var player_before := _player_hp
	var boss_before := _boss_hp
	var attempted_player_damage := 0
	var attempted_boss_damage := 0
	var guard := false
	if role == V06RollSetScript.ROLE_TRIPLE:
		attempted_boss_damage = 2
	elif attack_sum >= defense:
		attempted_boss_damage = 1
	elif role == V06RollSetScript.ROLE_PAIR:
		attempted_player_damage = 1
		guard = true
	else:
		attempted_player_damage = 1
	var applied_player_damage: int = 0 if guard else mini(attempted_player_damage, _player_hp)
	var applied_boss_damage: int = mini(attempted_boss_damage, _boss_hp)
	_player_hp -= applied_player_damage
	_boss_hp -= applied_boss_damage
	_pending_ack = true
	_last_result = {
		"action": action,
		"round": _round,
		"faces": resolved_faces.duplicate(),
		"sum": attack_sum,
		"role": role,
		"defense": defense,
		"player_hp_before": player_before,
		"player_hp_after": _player_hp,
		"boss_hp_before": boss_before,
		"boss_hp_after": _boss_hp,
		"attempted_player_damage": attempted_player_damage,
		"applied_player_damage": applied_player_damage,
		"attempted_boss_damage": attempted_boss_damage,
		"applied_boss_damage": applied_boss_damage,
		"guard": guard,
		"triple": role == V06RollSetScript.ROLE_TRIPLE,
		"victory": _boss_hp == 0,
		"defeat": _player_hp == 0,
	}


func _rejected(error: String) -> Dictionary:
	return {"ok": false, "status": error, "error": error}
