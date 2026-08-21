extends "res://scripts/app/v06_play_screen.gd"

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")

var last_casino_chip_result: Dictionary = {}

func _on_next_lap_requested() -> void:
	# The first press can resolve Heart Chance and deliberately remains on the
	# victory screen. Bank only on the press that actually advances the lap.
	if _session != null and not _session.heart_roulette_pending():
		_bank_cairo_completed_lap()
	super._on_next_lap_requested()

func _bank_cairo_completed_lap() -> Dictionary:
	if _session == null:
		return {}
	var boss_result: Dictionary = _session.boss_result()
	if not bool(boss_result.get("victory", false)):
		return {}
	var bankable_coins := int(_session.coins())
	var mission: Dictionary = _session.mission_state()
	# Cairo's risk-survival mission is finalized inside next_lap(). Its reward
	# is therefore added after this screen reads coins and immediately before the
	# lap wallet is reset. Include that pending reward in the CHIP conversion.
	if _pending_lap_boundary_mission_reward(mission):
		bankable_coins += maxi(0, int(mission.get("reward_coins", 0)))
	var key := _cairo_conversion_key(bankable_coins, mission, boss_result)
	last_casino_chip_result = CasinoBankScript.stage_clear_conversion_once(key, bankable_coins, true)
	return last_casino_chip_result.duplicate(true)

func _pending_lap_boundary_mission_reward(mission: Dictionary) -> bool:
	return (
		str(mission.get("active_id", "")) == "cairo_risk6_survive"
		and not bool(mission.get("survival_failed", false))
		and not bool(mission.get("completed", false))
		and not bool(mission.get("reward_claimed", false))
		and int(mission.get("progress", 0)) >= maxi(1, int(mission.get("target", 1)))
	)

func _cairo_conversion_key(bankable_coins: int, mission: Dictionary, boss_result: Dictionary) -> String:
	var snapshot: Dictionary = _session.snapshot()
	return "cairo:%d:%d:%d:%d:%d:%s:%d:%d" % [
		int(_session.lap()),
		int(snapshot.get("rolls_used", 0)),
		int(snapshot.get("score", 0)),
		maxi(0, bankable_coins),
		int(snapshot.get("elapsed_ms", 0)),
		str(mission.get("active_id", "")),
		int(mission.get("progress", 0)),
		int(boss_result.get("player_position", boss_result.get("player", 0))),
	]
