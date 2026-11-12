extends SceneTree

const BankScript = preload("res://scripts/game/casino_bank.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const FACILITIES: Array[Dictionary] = [
	{"id": "dice_race", "label": "推しレース", "primary": "ゲーム開始", "scene": preload("res://scenes/casino/DiceRace.tscn")},
	{"id": "dice_tower", "label": "欲張りタワー", "primary": "ゲーム開始", "scene": preload("res://scenes/casino/DiceTower.tscn")},
	{"id": "dice_roulette", "label": "一発ルーレット", "primary": "回す", "scene": preload("res://scenes/casino/DiceRoulette.tscn")},
	{"id": "treasure_21", "label": "宝箱21", "primary": "ゲーム開始", "scene": preload("res://scenes/casino/Treasure21.tscn")},
	{"id": "dice_poker", "label": "役そろえ", "primary": "ゲーム開始", "scene": preload("res://scenes/casino/DicePoker.tscn")},
	{"id": "vault_break", "label": "金庫破り", "primary": "ゲーム開始", "scene": preload("res://scenes/casino/VaultBreak.tscn")},
]
const FORBIDDEN_EXACT_CTAS: Array[String] = [
	"GAME START", "ROLL", "SPIN", "CASH OUT", "PLAY AGAIN", "CHANGE BET", "HOLD", "REROLL", "DISCARD",
]

var assertions: int = 0
var failures: int = 0
var fixture_path: String = ""
var production_save_path: String = ""
var production_hash_before: String = ""

func _init() -> void:
	call_deferred("_run")

func _expect(value: bool, label: String) -> void:
	assertions += 1
	if value:
		return
	failures += 1
	push_error("FAIL: %s" % label)

func _run() -> void:
	production_save_path = ProjectSettings.globalize_path(BankScript.SAVE_PATH)
	production_hash_before = _file_fingerprint(production_save_path)
	fixture_path = ProjectSettings.globalize_path("res://.qa-casino-feel-final-%d.json" % OS.get_process_id())
	_remove_fixture()
	BankScript.set_test_save_path(fixture_path)

	await _run_session_a()
	await _run_session_b()
	await _cleanup()

	_expect(_file_fingerprint(production_save_path) == production_hash_before, "production CasinoBank save hash is unchanged")
	_expect(not FileAccess.file_exists(fixture_path), "temporary CasinoBank fixture is removed")
	print("CASINO FEEL final tests: %d assertions, %d failures" % [assertions, failures])
	if failures == 0:
		print("CASINO_FEEL_FINAL_OBJECTIVE_PASS")
	quit(1 if failures > 0 else 0)

func _run_session_a() -> void:
	for definition: Dictionary in FACILITIES:
		var facility_id: String = str(definition.get("id", ""))
		var data: Dictionary = BankScript.default_data()
		data["chips"] = 300
		_expect(BankScript.save_data(data), "Session A %s starts from an isolated 300 CHIP fixture" % facility_id)
		for round_index: int in range(1, 4):
			var scene: PackedScene = definition.get("scene") as PackedScene
			var screen: Node = scene.instantiate()
			root.add_child(screen)
			await process_frame
			await process_frame
			_assert_facility_shell(screen, definition, round_index)
			await _exercise_round_transaction(facility_id, round_index)
			var weak_screen: WeakRef = weakref(screen)
			screen.queue_free()
			await process_frame
			await process_frame
			_expect(weak_screen.get_ref() == null, "Session A %s round %d teardown completes" % [facility_id, round_index])
		_expect(BankScript.balance() == 300, "Session A %s keeps its three-round fixture balance understandable" % facility_id)
		var active: Dictionary = BankScript.load_data().get(BankScript.ACTIVE_GAMES_KEY, {}) as Dictionary
		_expect(active.is_empty(), "Session A %s leaves no active transaction" % facility_id)

func _assert_facility_shell(screen: Node, definition: Dictionary, round_index: int) -> void:
	var facility_id: String = str(definition.get("id", ""))
	var back: Button = screen.find_child("CasinoBackButton", true, false) as Button
	_expect(back != null and back.text == "カジノへ戻る", "%s round %d exposes the shared casino-return CTA" % [facility_id, round_index])
	var how_to: PanelContainer = screen.find_child("CasinoHowTo3Steps", true, false) as PanelContainer
	_expect(how_to != null and str(how_to.get_meta("facility_id", "")) == facility_id, "%s round %d retains the three-step how-to identity" % [facility_id, round_index])
	var buttons: Array[Node] = screen.find_children("*", "Button", true, false)
	var has_primary: bool = false
	var has_forbidden: bool = false
	for candidate: Node in buttons:
		var button: Button = candidate as Button
		if button == null:
			continue
		var copy: String = button.text.strip_edges()
		if str(definition.get("primary", "")) in copy:
			has_primary = true
		if copy in FORBIDDEN_EXACT_CTAS:
			has_forbidden = true
	_expect(has_primary, "%s round %d exposes an explicit Japanese primary action" % [facility_id, round_index])
	_expect(not has_forbidden, "%s round %d has no legacy English operation CTA" % [facility_id, round_index])

func _exercise_round_transaction(facility_id: String, round_index: int) -> void:
	var balance_before: int = BankScript.balance()
	var started: Dictionary = BankScript.begin_game(facility_id, 1, {"qa_round": round_index})
	_expect(bool(started.get("ok", false)) and BankScript.balance() == balance_before - 1, "%s round %d accepts one input and charges once" % [facility_id, round_index])
	var game_id: String = str(started.get("game_id", ""))
	var settled: Dictionary = BankScript.settle_game(facility_id, 1, {"qa": true, "won": false}, game_id)
	_expect(bool(settled.get("ok", false)) and BankScript.balance() == balance_before, "%s round %d returns a readable break-even result" % [facility_id, round_index])
	var duplicate: Dictionary = BankScript.settle_game(facility_id, 1, {"qa": true}, game_id)
	_expect(bool(duplicate.get("already_settled", false)) and BankScript.balance() == balance_before, "%s round %d rejects duplicate settlement" % [facility_id, round_index])

func _run_session_b() -> void:
	var data: Dictionary = BankScript.default_data()
	data["chips"] = 300
	_expect(BankScript.save_data(data), "Session B Casino Tour starts once at 300 CHIP")
	HubScript.suppress_audio_for_tests = false
	var hub: Node = HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	await process_frame
	var expected_ids: Array[String] = []
	for definition: Dictionary in FACILITIES:
		expected_ids.append(str(definition.get("id", "")))
	var actual_ids: Array[String] = []
	for definition: Dictionary in hub.facility_definitions:
		actual_ids.append(str(definition.get("id", "")))
	_expect(actual_ids == expected_ids, "Session B follows the actual displayed HUB order")
	var expected_balance: int = 300
	for index: int in range(FACILITIES.size()):
		var definition: Dictionary = FACILITIES[index]
		var facility_id: String = str(definition.get("id", ""))
		var button: Button = hub.facility_buttons.get(facility_id) as Button
		_expect(button != null and not button.disabled, "Tour stop %d %s is selectable" % [index + 1, facility_id])
		button.pressed.emit()
		await process_frame
		await process_frame
		var host: Control = hub.facility_hosts.get(facility_id) as Control
		_expect(hub.active_facility_id == facility_id and not hub.hub_root.visible and host != null and host.visible and host.get_child_count() == 1, "Tour stop %d opens only %s" % [index + 1, facility_id])
		var screen: Node = host.get_child(0)
		var tour_round: Dictionary = BankScript.begin_game(facility_id, 1, {"tour_stop": index + 1})
		var payout: int = 2 if index % 2 == 0 else 0
		var receipt: Dictionary = BankScript.settle_game(facility_id, payout, {"qa_tour": true, "won": payout > 1}, str(tour_round.get("game_id", "")))
		expected_balance += payout - 1
		_expect(bool(tour_round.get("ok", false)) and bool(receipt.get("ok", false)) and BankScript.balance() == expected_balance, "Tour stop %d carries CHIP balance into the next facility" % [index + 1])
		screen.emit_signal("back_requested")
		await process_frame
		await process_frame
		_expect(hub.hub_root.visible and hub.active_facility_id.is_empty() and not host.visible and host.get_child_count() == 0, "Tour stop %d returns cleanly to HUB" % [index + 1])
		var bgm: Node = root.get_node_or_null("BgmManager")
		_expect(bgm == null or bgm.call("current_track") == &"lasvegas_main", "Tour stop %d restores Las Vegas HUB BGM" % [index + 1])
	var active: Dictionary = BankScript.load_data().get(BankScript.ACTIVE_GAMES_KEY, {}) as Dictionary
	_expect(active.is_empty(), "Casino Tour leaves no active game")
	_expect(BankScript.balance() == expected_balance, "Casino Tour retains one continuous final CHIP balance")
	var trip_back: Button = hub.find_child("BackToTripButton", true, false) as Button
	_expect(trip_back != null and trip_back.text == "旅へ戻る", "Casino Tour ends at the explicit trip-return CTA")
	var weak_hub: WeakRef = weakref(hub)
	hub.queue_free()
	await process_frame
	await process_frame
	_expect(weak_hub.get_ref() == null, "Casino Tour HUB teardown completes")

func _cleanup() -> void:
	var ui_sfx: Node = root.get_node_or_null("UiSfxManager")
	if ui_sfx != null:
		ui_sfx.call("stop_all")
	var bgm: Node = root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	await process_frame
	_remove_fixture()
	BankScript.clear_test_save_path()
	HubScript.suppress_audio_for_tests = false

func _remove_fixture() -> void:
	if not fixture_path.is_empty() and FileAccess.file_exists(fixture_path):
		DirAccess.remove_absolute(fixture_path)

func _file_fingerprint(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<missing>"
	return FileAccess.get_sha256(path)
