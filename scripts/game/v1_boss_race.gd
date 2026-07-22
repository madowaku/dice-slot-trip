class_name V1BossRace
extends RefCounted

const GOAL := 13
const SAFETY_MAX_TURNS := 12
const WIN_REASON_BASE_MOVE_GOAL: StringName = &"BASE_MOVE_GOAL"
const WIN_REASON_BOOST_MOVE_GOAL: StringName = &"BOOST_MOVE_GOAL"
const WIN_REASON_SAFETY_MAX_TURNS_LEAD: StringName = &"SAFETY_MAX_TURNS_LEAD"
const WIN_REASON_SAFETY_MAX_TURNS_TIE: StringName = &"SAFETY_MAX_TURNS_TIE"
const COURSE := {
	1: &"NORMAL", 2: &"BOOST", 3: &"SAND", 4: &"NORMAL", 5: &"WIND",
	6: &"BOOST", 7: &"SAND", 8: &"NORMAL", 9: &"BOOST", 10: &"WIND",
	11: &"SAND", 12: &"BOOST", 13: &"GOAL",
}

var player_position := 0
var boss_position := 0
var player_pending_modifier := 0
var boss_pending_modifier := 0
var winner: StringName = &""
var win_reason: StringName = &""
var turn_count := 0
var player_ignore_first_sand := false
var player_ignored_sand := false
var player_roll_history: Array[int] = []
var boss_roll_history: Array[int] = []

static func effective_player_roll(tapped_face: int, modifier: int = 0) -> int:
	return clampi(tapped_face + modifier, 1, 6)

static func mirror_roll(effective_roll: int) -> int:
	return 7 - clampi(effective_roll, 1, 6)

func play_turn(tapped_face: int, allowed_modifier: int = 0) -> Dictionary:
	if winner != &"" or tapped_face < 1 or tapped_face > 6:
		return {}
	var player_roll := effective_player_roll(tapped_face, allowed_modifier)
	var boss_roll := mirror_roll(player_roll)
	player_roll_history.append(player_roll)
	boss_roll_history.append(boss_roll)
	turn_count += 1
	var player_move := maxi(1, player_roll + player_pending_modifier)
	var boss_move := maxi(1, boss_roll + boss_pending_modifier)
	player_pending_modifier = 0
	boss_pending_modifier = 0
	var player_distance := GOAL - player_position
	var boss_distance := GOAL - boss_position
	if player_distance <= player_move or boss_distance <= boss_move:
		if player_distance <= player_move and boss_distance <= boss_move:
			winner = &"PLAYER" if player_distance <= boss_distance else &"BOSS"
		else:
			winner = &"PLAYER" if player_distance <= player_move else &"BOSS"
		win_reason = WIN_REASON_BASE_MOVE_GOAL
	player_position = mini(GOAL, player_position + player_move)
	boss_position = mini(GOAL, boss_position + boss_move)
	if winner == &"":
		var player_boost_goal := _resolve_landing(true)
		var boss_boost_goal := _resolve_landing(false)
		if player_position >= GOAL or boss_position >= GOAL:
			if player_boost_goal and boss_boost_goal:
				winner = &"PLAYER"
			else:
				winner = &"PLAYER" if player_boost_goal else &"BOSS"
			win_reason = WIN_REASON_BOOST_MOVE_GOAL
	if winner == &"" and turn_count >= SAFETY_MAX_TURNS:
		winner = &"PLAYER" if player_position >= boss_position else &"BOSS"
		win_reason = WIN_REASON_SAFETY_MAX_TURNS_TIE if player_position == boss_position else WIN_REASON_SAFETY_MAX_TURNS_LEAD
	return _turn_result(player_roll, boss_roll)

func _resolve_landing(is_player: bool) -> bool:
	var position := player_position if is_player else boss_position
	var tile: StringName = COURSE.get(position, &"GOAL")
	var boost_goal := false
	if tile == &"BOOST":
		position = mini(GOAL, position + 2)
		boost_goal = position >= GOAL
	elif tile == &"SAND":
		if is_player:
			if player_ignore_first_sand and not player_ignored_sand:
				player_ignored_sand = true
			else:
				player_pending_modifier = -1
		else:
			boss_pending_modifier = -1
	elif tile == &"WIND":
		if is_player:
			player_pending_modifier = 1
		else:
			boss_pending_modifier = 1
	if is_player:
		player_position = position
	else:
		boss_position = position
	return boost_goal

func result() -> Dictionary:
	if winner == &"":
		return {}
	return {
		"winner": winner,
		"turn_count": turn_count,
		"player_final_position": player_position,
		"boss_final_position": boss_position,
		"player_roll_history": player_roll_history.duplicate(),
		"boss_roll_history": boss_roll_history.duplicate(),
		"win_reason": win_reason,
	}

func _turn_result(player_roll: int, boss_roll: int) -> Dictionary:
	return {
		"player_roll": player_roll,
		"boss_roll": boss_roll,
		"player_position": player_position,
		"boss_position": boss_position,
		"winner": winner,
		"win_reason": win_reason,
	}
