class_name RestEffectModel
extends RefCounted


static func resolve(current_hp: int, max_hp: int, heal_amount: int = 1) -> Dictionary:
	var safe_max := maxi(max_hp, 1)
	var before := clampi(current_hp, 0, safe_max)
	var after := mini(before + maxi(heal_amount, 0), safe_max)
	var healed := after - before
	var coin_bonus := 1 if before >= safe_max else 0
	return {
		"before_hp": before,
		"after_hp": after,
		"healed": healed,
		"coin_bonus": coin_bonus,
		"text": "HP FULL  COIN +1" if coin_bonus > 0 else "HP +%d" % healed,
	}
