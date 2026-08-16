class_name FoxFireBattleResult
extends RefCounted

var victory: bool = false
var defeat_reason: String = ""
var turns_used: int = 0
var seal_count: int = 0
var total_steps: int = 0
var white_fire_placed: int = 0
var white_fire_removed: int = 0
var rerolls_used: int = 0
var blessings_used: int = 0
var difficulty_level: int = 1
var city_blocks_sealed: int = 0
var line_cuts_repaired: int = 0


func to_dictionary() -> Dictionary:
	return {
		"victory": victory,
		"defeat_reason": defeat_reason,
		"turns_used": turns_used,
		"seal_count": seal_count,
		"total_steps": total_steps,
		"white_fire_placed": white_fire_placed,
		"white_fire_removed": white_fire_removed,
		"rerolls_used": rerolls_used,
		"blessings_used": blessings_used,
		"difficulty_level": difficulty_level,
		"city_blocks_sealed": city_blocks_sealed,
		"line_cuts_repaired": line_cuts_repaired,
	}


static func from_dictionary(data: Dictionary) -> FoxFireBattleResult:
	var result := FoxFireBattleResult.new()
	result.victory = bool(data.get("victory", false))
	result.defeat_reason = str(data.get("defeat_reason", ""))
	result.turns_used = maxi(int(data.get("turns_used", 0)), 0)
	result.seal_count = clampi(int(data.get("seal_count", 0)), 0, 3)
	result.total_steps = maxi(int(data.get("total_steps", 0)), 0)
	result.white_fire_placed = maxi(int(data.get("white_fire_placed", 0)), 0)
	result.white_fire_removed = maxi(int(data.get("white_fire_removed", 0)), 0)
	result.rerolls_used = maxi(int(data.get("rerolls_used", 0)), 0)
	result.blessings_used = maxi(int(data.get("blessings_used", 0)), 0)
	result.difficulty_level = maxi(int(data.get("difficulty_level", 1)), 1)
	result.city_blocks_sealed = maxi(int(data.get("city_blocks_sealed", 0)), 0)
	result.line_cuts_repaired = maxi(int(data.get("line_cuts_repaired", 0)), 0)
	return result
