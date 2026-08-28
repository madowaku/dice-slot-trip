extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const RouletteScript = preload("res://scripts/app/dice_roulette_screen.gd")

var failures := 0
var assertions := 0
var test_save_path := ""

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	_configure_test_save()
	HubScript.suppress_audio_for_tests = true
	RouletteScript.suppress_audio_for_tests = true
	_test_save_migration_and_unknown_keys()
	_test_active_game_transaction()
	await _test_hub_ring_and_lazy_load()
	_cleanup_test_save()
	HubScript.suppress_audio_for_tests = false
	RouletteScript.suppress_audio_for_tests = false
	print("Casino foundation tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)

func _configure_test_save() -> void:
	test_save_path = "user://dice_slot_trip_casino_foundation_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))

func _cleanup_test_save() -> void:
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	CasinoBankScript.clear_test_save_path()

func _test_save_migration_and_unknown_keys() -> void:
	var legacy := CasinoBankScript.default_data()
	legacy["version"] = 1
	legacy["chips"] = 31
	legacy["owned_cards"] = ["dice_racer_crocodile", "dice_racer_duck", "dice_racer_duck"]
	legacy["conversion_keys"] = [" lap:1 ", "lap:1"]
	legacy["dice_race_play_count"] = 4
	legacy["dice_race_win_count"] = 2
	legacy["dice_race_best_payout"] = 17
	legacy["future_facility_payload"] = {"schema": 9, "nested": [1, 2, 3]}
	_expect(CasinoBankScript.save_data(legacy), "isolated migration fixture saves")
	var loaded := CasinoBankScript.load_data()
	_expect(int(loaded.get("version", 0)) == CasinoBankScript.SAVE_VERSION, "known save version normalizes")
	_expect(int(loaded.get("chips", 0)) == 31, "chips migrate unchanged")
	_expect("dice_racer_rabbit" in loaded.get("owned_cards", []) and "dice_racer_crocodile" not in loaded.get("owned_cards", []), "legacy card alias migrates")
	_expect((loaded.get("conversion_keys", []) as Array).size() == 1 and "lap:1" in loaded.get("conversion_keys", []), "conversion ledger normalizes without duplication")
	_expect(int(loaded.get("dice_race_play_count", 0)) == 4 and int(loaded.get("dice_race_win_count", 0)) == 2 and int(loaded.get("dice_race_best_payout", 0)) == 17, "race statistics migrate unchanged")
	var future: Dictionary = loaded.get("future_facility_payload", {}) as Dictionary
	_expect(int(future.get("schema", 0)) == 9 and (future.get("nested", []) as Array).size() == 3 and int((future.get("nested", []) as Array)[2]) == 3, "unknown future keys survive normalization")

func _test_active_game_transaction() -> void:
	var reset := CasinoBankScript.default_data()
	reset["chips"] = 60
	reset["future_marker"] = "kept"
	_expect(CasinoBankScript.save_data(reset), "transaction fixture saves")
	var started := CasinoBankScript.begin_game("high_low", 20, {"phase": "READY", "pending_rolls": [2, 5]})
	_expect(bool(started.get("ok", false)) and int(started.get("charged", 0)) == 20, "begin charges the wager once")
	_expect(CasinoBankScript.balance() == 40, "begin persists the reduced balance")
	var duplicate_begin := CasinoBankScript.begin_game("high_low", 20, {"phase": "OTHER"})
	_expect(not bool(duplicate_begin.get("ok", true)) and bool(duplicate_begin.get("already_active", false)) and CasinoBankScript.balance() == 40, "duplicate begin is rejected without a second charge")
	var active := CasinoBankScript.active_game("high_low")
	var pending: Array = active.get("pending_rolls", []) as Array
	_expect(str(active.get("phase", "")) == "READY" and pending.size() == 2 and int(pending[0]) == 2 and int(pending[1]) == 5, "active session and pending rolls are resumable")
	var updated := CasinoBankScript.update_game("high_low", {"phase": "WAITING_FOR_ROLL", "pending_rolls": [6]})
	_expect(bool(updated.get("ok", false)) and str(CasinoBankScript.active_game("high_low").get("phase", "")) == "WAITING_FOR_ROLL", "update persists the next session snapshot")
	var settled := CasinoBankScript.settle_game("high_low", 36, {"current": 6})
	_expect(bool(settled.get("ok", false)) and int(settled.get("payout", 0)) == 36 and CasinoBankScript.balance() == 76, "settle credits payout and clears active session once")
	var duplicate_settle := CasinoBankScript.settle_game("high_low", 36, {"current": 6})
	_expect(not bool(duplicate_settle.get("ok", true)) and bool(duplicate_settle.get("already_settled", false)) and CasinoBankScript.balance() == 76, "duplicate settlement is rejected without a second credit")
	_expect(CasinoBankScript.load_data().get("future_marker", "") == "kept", "transaction writes preserve unknown save keys")

func _test_hub_ring_and_lazy_load() -> void:
	var hub := HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	_expect(hub is CasinoHubScreen, "Casino Hub foundation scene instantiates")
	_expect(hub.facility_definitions.size() == 6, "hub registers exactly six facilities")
	var expected_ids := ["dice_race", "dice_tower", "dice_roulette", "treasure_21", "dice_poker", "vault_break"]
	var actual_ids: Array[String] = []
	for definition: Dictionary in hub.facility_definitions:
		actual_ids.append(str(definition.get("id", "")))
	_expect(actual_ids == expected_ids, "hub facility order is stable around the ring")
	_expect(hub.find_child("CasinoRingMap", true, false) != null, "hub exposes the circular map shell")
	for id: String in expected_ids:
		var button := hub.facility_nodes.get(id) as Button
		_expect(button != null and button.custom_minimum_size.x >= 96.0 and button.custom_minimum_size.y >= 96.0, "%s keeps the 96 design-unit touch target" % id)
	_expect(bool(hub.facility_availability.get("dice_race", false)) and bool(hub.facility_availability.get("dice_tower", false)), "existing DICE RACE and DICE TOWER stay available")
	for id: String in ["dice_roulette", "treasure_21", "dice_poker", "vault_break"]:
		_expect(bool(hub.facility_availability.get(id, false)) and (hub.facility_nodes.get(id) as Button).visible, "%s remains available and visible in the ring" % id)
	hub.call("_open_dice_roulette")
	await process_frame
	_expect(not hub.hub_root.visible and hub.roulette_host.visible and hub.roulette_host.get_child_count() == 1, "DICE ROULETTE lazy-loads into its host")
	hub.call("_close_dice_roulette")
	await process_frame
	_expect(hub.hub_root.visible and not hub.roulette_host.visible, "DICE ROULETTE close flow restores the ring hub")
	hub.call("_open_dice_race")
	await process_frame
	_expect(not hub.hub_root.visible and hub.race_host.visible and hub.race_host.get_child_count() == 1, "DICE RACE still lazy-loads into its tested host")
	hub.call("_close_dice_race")
	await process_frame
	_expect(hub.hub_root.visible and not hub.race_host.visible, "DICE RACE close flow restores the ring hub")
	hub.call("_open_dice_tower")
	await process_frame
	_expect(not hub.hub_root.visible and hub.tower_host.visible and hub.tower_host.get_child_count() == 1, "DICE TOWER still lazy-loads into its tested host")
	hub.call("_close_dice_tower")
	hub.queue_free()
	await process_frame
	await process_frame
