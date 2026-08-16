class_name HeartRouletteModel
extends RefCounted

# The six wedges are part of the player-facing roulette contract. Keep this
# order aligned with the artwork: +1, +2, +1, Full, +1, 0.
const VALUES: Array[int] = [1, 2, 1, 3, 1, 0]


static func resolve(current_hp: int, max_hp: int, slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= VALUES.size():
		return {"ok": false, "error": "INVALID_HEART_ROULETTE_SLOT"}
	var safe_max := maxi(max_hp, 1)
	var before := clampi(current_hp, 0, safe_max)
	var rolled := VALUES[slot_index]
	var after := safe_max if rolled >= 3 else mini(before + rolled, safe_max)
	var label := "0 HP"
	if rolled >= 3:
		label = "FULL"
	elif rolled > 0:
		label = "+%d HP" % rolled
	return {
		"ok": true,
		"slot_index": slot_index,
		"rolled_value": rolled,
		"before_hp": before,
		"after_hp": after,
		"healed": after - before,
		"label": label,
	}
