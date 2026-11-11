extends SceneTree

const CairoSave = preload("res://scripts/game/v06_session_save_manager.gd")
const Session = preload("res://scripts/game/v06_play_session.gd")
const Bank = preload("res://scripts/game/casino_bank.gd")
const JourneySave = preload("res://scripts/game/journey_save_manager.gd")
const Store = preload("res://scripts/game/safe_json_store.gd")
const AMAZON: StringName = &"amazon_suiu_falls"
const KYOTO: StringName = &"kyoto_thousand_year_grid"
var failures: int = 0
var checks: int = 0
var test_root: String = ""

func _init() -> void:
	test_root = "user://save_integrity_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(test_root))
	JourneySave._test_save_directory = test_root
	_test_cairo_recovery()
	_test_casino_recovery()
	_test_city_slots()
	_test_write_interruptions()
	_test_unrecoverable_data()
	Bank.clear_test_save_path()
	JourneySave._test_save_directory = ""
	print("SAVE_INTEGRITY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func _expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ", description)

func _write(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _test_cairo_recovery() -> void:
	var manager: RefCounted = CairoSave.new(test_root + "/cairo.json")
	var session: RefCounted = Session.new()
	_expect(manager.save_session(session).ok, "Cairo first checkpoint")
	_expect(manager.save_session(session).ok, "Cairo backup checkpoint")
	_write(manager.save_path, "{broken")
	var recovered: Dictionary = manager.load_result()
	_expect(recovered.ok, "Cairo recovers backup")
	_expect(session.restore_stable_snapshot(recovered.data.session_state, 1000), "restore recovered session")
	_expect(manager.save_session(session).ok, "Cairo can save after recovery")
	_expect(manager.load_result().status == CairoSave.STATUS_VALID_PRIMARY, "Cairo next launch uses repaired primary")
	_expect(FileAccess.get_file_as_string(manager.save_path + ".corrupt") == "{broken", "Cairo damaged file retained for recovery")

func _test_casino_recovery() -> void:
	var path: String = test_root + "/casino.json"
	Bank.set_test_save_path(path)
	var data: Dictionary = Bank.default_data()
	data.chips = 120
	data.owned_cards = ["dice_racer_duck"]
	_expect(Bank.save_data(data), "casino first checkpoint")
	data.chips = 130
	_expect(Bank.save_data(data), "casino second checkpoint")
	_write(path, "{broken")
	var recovered: Dictionary = Bank.load_data()
	_expect(recovered.chips == 120 and "dice_racer_duck" in recovered.owned_cards, "casino backup preserves chips and cards")
	recovered.chips = 140
	_expect(Bank.save_data(recovered), "casino can save after recovery")
	_expect(Bank.balance() == 140, "casino recovered progress persists")

func _test_city_slots() -> void:
	# All fixtures live in this runner's private directory.
	var manager: RefCounted = JourneySave.new()
	var legacy: Dictionary = {"schema_version": 1, "stage_id": String(AMAZON), "journey": {"coins": 66}, "boss": {}}
	_write(JourneySave.legacy_save_path(), JSON.stringify(legacy))
	_expect(manager.load_for_stage(AMAZON).get("journey", {}).get("coins", -1) == 66, "old shared save remains readable")
	_expect(manager.save(AMAZON, {"coins": 77}), "Amazon checkpoint")
	_expect(manager.save(KYOTO, {"coins": 88}), "Kyoto checkpoint")
	var amazon: Dictionary = manager.load_for_stage(AMAZON)
	var kyoto: Dictionary = manager.load_for_stage(KYOTO)
	_expect(amazon.get("journey", {}).get("coins", -1) == 77, "Amazon survives saving Kyoto")
	_expect(kyoto.get("journey", {}).get("coins", -1) == 88, "Kyoto checkpoint preserved")
	_expect(manager.saved_stage_ids().size() == 2, "both cities available for continue")
	_expect(manager.save(AMAZON, {"coins": 99}), "Amazon second checkpoint")
	_write(JourneySave.stage_save_path(AMAZON), "{broken")
	_expect(manager.load_for_stage(AMAZON).journey.coins == 77, "city recovers its own backup instead of stale legacy")
	_expect(manager.save(AMAZON, {"coins": 100}), "city saves after backup recovery")
	_expect(manager.load_for_stage(AMAZON).journey.coins == 100 and manager.load_for_stage(KYOTO).journey.coins == 88, "both cities survive recovery and relaunch")
	_expect(FileAccess.get_file_as_string(JourneySave.legacy_save_path()) == JSON.stringify(legacy), "migration preserves legacy file")
	_expect(not manager.save(&"../../invalid", {}), "unknown city rejected before file access")

func _valid_test_data(data: Dictionary) -> bool:
	return data.get("value") is float or data.get("value") is int

func _test_write_interruptions() -> void:
	for fault: String in ["temp_open", "temp_write", "backup_rename", "install_rename"]:
		var path: String = test_root + "/fault_" + fault + ".json"
		_expect(Store.save_data(path, {"value": 1}, _valid_test_data), "fault seed " + fault)
		_expect(Store.save_data(path, {"value": 2}, _valid_test_data), "fault current checkpoint " + fault)
		_expect(not Store.save_data(path, {"value": 3}, _valid_test_data, {fault: true}), "failure reported " + fault)
		_expect(Store.load_data(path, _valid_test_data).value == 2, "last committed progress survives " + fault)
		_expect(Store.save_data(path, {"value": 4}, _valid_test_data), "retry succeeds " + fault)
		_expect(Store.load_data(path, _valid_test_data).value == 4, "retry survives restart " + fault)
	var path: String = test_root + "/stale.json"
	_write(path + ".tmp", JSON.stringify({"value": 999}))
	_expect(Store.load_data(path, _valid_test_data).is_empty(), "uncommitted temporary file never loaded")
	_expect(Store.save_data(path, {"value": 5}, _valid_test_data), "stale temp does not block fresh save")

func _test_unrecoverable_data() -> void:
	var path: String = test_root + "/unrecoverable.json"
	Bank.set_test_save_path(path)
	_write(path, "{broken")
	_expect(not Bank.save_data(Bank.default_data()), "unrecoverable casino progress cannot be overwritten with defaults")
	_expect(FileAccess.get_file_as_string(path) == "{broken", "unrecoverable evidence preserved")
	var receipt: Dictionary = Bank.stage_clear_conversion(20)
	_expect(not receipt.ok and receipt.gained_chip == 0, "failed persistence cannot claim a chip reward")
