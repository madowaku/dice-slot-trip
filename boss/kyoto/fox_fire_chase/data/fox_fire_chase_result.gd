class_name FoxFireChaseResult
extends RefCounted

var victory: bool = false
var defeat_reason: String = ""
var lap: int = 1
var kyoto_level: int = 1
var roll_speed_scale: float = 1.0
var rolls_used: int = 0
var player_faces: Array[int] = []
var role_counts: Dictionary = {"MIX": 0, "PAIR": 0, "STRAIGHT": 0, "TRIPLE": 0}
var slot_bonus_steps: int = 0
var total_player_steps: int = 0
var total_fox_steps: int = 0
var fox_fire_generated: int = 0
var fox_fire_encounters: int = 0
var fox_fire_detours: int = 0
var goshuin_start: int = 0
var goshuin_used: int = 0
var coin_head_starts: int = 0
var coins_spent: int = 0
var final_distance: int = 10


func to_dictionary() -> Dictionary:
	return {
		"battle_id": "fox_fire_chase",
		"victory": victory,
		"defeat_reason": defeat_reason,
		"outcome": "VICTORY" if victory else ("DEFEAT" if not defeat_reason.is_empty() else "IN_PROGRESS"),
		"lap": lap,
		"kyoto_level": kyoto_level,
		"roll_speed_scale": roll_speed_scale,
		"rolls_used": rolls_used,
		"player_faces": player_faces.duplicate(),
		"slot_role_count": int(role_counts.get("PAIR", 0)) + int(role_counts.get("STRAIGHT", 0)) + int(role_counts.get("TRIPLE", 0)),
		"slot_roll_count": int(role_counts.get("MIX", 0)) + int(role_counts.get("PAIR", 0)) + int(role_counts.get("STRAIGHT", 0)) + int(role_counts.get("TRIPLE", 0)),
		"role_counts": role_counts.duplicate(true),
		"mix_count": int(role_counts.get("MIX", 0)),
		"pair_count": int(role_counts.get("PAIR", 0)),
		"straight_count": int(role_counts.get("STRAIGHT", 0)),
		"triple_count": int(role_counts.get("TRIPLE", 0)),
		"slot_bonus_steps": slot_bonus_steps,
		"total_player_steps": total_player_steps,
		"total_fox_steps": total_fox_steps,
		"fox_fire_generated": fox_fire_generated,
		"fox_fire_encounters": fox_fire_encounters,
		"fox_fire_detours": fox_fire_detours,
		"goshuin_start": goshuin_start,
		"goshuin_used": goshuin_used,
		"coin_head_starts": coin_head_starts,
		"coins_spent": coins_spent,
		"final_distance": final_distance,
	}


static func from_dictionary(data: Dictionary) -> FoxFireChaseResult:
	var result := FoxFireChaseResult.new()
	result.victory = bool(data.get("victory", false))
	result.defeat_reason = str(data.get("defeat_reason", ""))
	result.lap = maxi(int(data.get("lap", 1)), 1)
	result.kyoto_level = clampi(int(data.get("kyoto_level", 1)), 1, 8)
	result.roll_speed_scale = clampf(float(data.get("roll_speed_scale", 0.82)), 0.8, 1.5)
	result.rolls_used = maxi(int(data.get("rolls_used", 0)), 0)
	result.player_faces = []
	for value: Variant in data.get("player_faces", []):
		var face := int(value)
		if face >= 1 and face <= 6:
			result.player_faces.append(face)
	var restored_counts: Dictionary = data.get("role_counts", {})
	result.role_counts = {
		"MIX": maxi(int(restored_counts.get("MIX", data.get("mix_count", 0))), 0),
		"PAIR": maxi(int(restored_counts.get("PAIR", data.get("pair_count", 0))), 0),
		"STRAIGHT": maxi(int(restored_counts.get("STRAIGHT", data.get("straight_count", 0))), 0),
		"TRIPLE": maxi(int(restored_counts.get("TRIPLE", data.get("triple_count", 0))), 0),
	}
	result.slot_bonus_steps = maxi(int(data.get("slot_bonus_steps", 0)), 0)
	result.total_player_steps = maxi(int(data.get("total_player_steps", 0)), 0)
	result.total_fox_steps = maxi(int(data.get("total_fox_steps", 0)), 0)
	result.fox_fire_generated = maxi(int(data.get("fox_fire_generated", 0)), 0)
	result.fox_fire_encounters = maxi(int(data.get("fox_fire_encounters", 0)), 0)
	result.fox_fire_detours = maxi(int(data.get("fox_fire_detours", 0)), 0)
	result.goshuin_start = maxi(int(data.get("goshuin_start", 0)), 0)
	result.goshuin_used = maxi(int(data.get("goshuin_used", 0)), 0)
	result.coin_head_starts = clampi(int(data.get("coin_head_starts", 0)), 0, 2)
	result.coins_spent = maxi(int(data.get("coins_spent", 0)), 0)
	result.final_distance = int(data.get("final_distance", 10))
	return result
