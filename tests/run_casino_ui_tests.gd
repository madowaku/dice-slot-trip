extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const RACE_SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const CAIRO_SCENE: PackedScene = preload("res://scenes/casino/CairoCasinoPlayScreen.tscn")

var failures := 0
var assertions := 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	if FileAccess.file_exists(CasinoBankScript.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	CasinoBankScript.add_chips(100)

	var hub := HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	_expect(hub is CasinoHubScreen, "Casino Hub scene instantiates its screen script")
	_expect(hub.chip_label != null and "100" in hub.chip_label.text, "Casino Hub shows persistent chip balance")
	_expect(hub.card_data.size() == 6, "Prize Counter loads six initial racer cards")
	hub.queue_free()
	await process_frame

	var race := RACE_SCENE.instantiate()
	root.add_child(race)
	await process_frame
	_expect(race is DiceRaceScreen, "Dice Race scene instantiates its screen script")
	_expect(race.orientations.size() == 24, "Dice Race UI receives all 24 physical orientations")
	_expect(race.roll_button != null and race.start_button != null, "Dice Race exposes start and roll controls")
	_expect(race.racer_nodes.size() == 6, "Dice Race creates six racer markers")
	race.queue_free()
	await process_frame

	var cairo := CAIRO_SCENE.instantiate()
	root.add_child(cairo)
	await process_frame
	_expect(cairo is V06PlayScreen, "casino-aware Cairo scene preserves the V06PlayScreen contract")
	_expect(cairo.has_method("_bank_cairo_completed_lap"), "casino-aware Cairo scene exposes the lap banking hook")
	_expect(cairo.session_for_test() != null, "casino-aware Cairo scene initializes the established V06 session")
	cairo.queue_free()
	await process_frame

	DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	print("Casino UI tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
