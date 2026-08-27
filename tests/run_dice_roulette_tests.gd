extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const ROULETTE_SCENE: PackedScene = preload("res://scenes/casino/DiceRoulette.tscn")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")

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
	_test_probability_contract()
	_test_payout_contract()
	_test_bank_settlement()
	await _test_ui_contract()
	print("Dice Roulette tests: %d assertions, %d failures" % [assertions, failures])
	if FileAccess.file_exists(CasinoBankScript.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	quit(1 if failures > 0 else 0)

func _test_probability_contract() -> void:
	_expect(ModelScript.SLOT_AREAS.size() == 24, "roulette has exactly 24 equally likely slots")
	var counts := {}
	for area: String in ModelScript.SLOT_AREAS:
		counts[area] = int(counts.get(area, 0)) + 1
	_expect(int(counts.get("LOW", 0)) == 5, "LOW occupies five slots")
	_expect(int(counts.get("HIGH", 0)) == 5, "HIGH occupies five slots")
	_expect(int(counts.get("ODD", 0)) == 5, "ODD occupies five slots")
	_expect(int(counts.get("EVEN", 0)) == 5, "EVEN occupies five slots")
	_expect(int(counts.get("LUCKY_7", 0)) == 3, "LUCKY 7 occupies three slots")
	_expect(int(counts.get("JACKPOT", 0)) == 1, "JACKPOT occupies one slot")
	_expect(ModelScript.BET_AMOUNTS == [10, 20, 50], "roulette exposes 10, 20, and 50 chip denominations")
	for area: String in ModelScript.MAIN_AREAS:
		var rtp := ModelScript.expected_main_rtp(area)
		_expect(rtp >= 0.94 and rtp <= 0.96, "%s main bet stays inside the 94-96 percent RTP band" % area)
	for area: String in ModelScript.SIDE_AREAS:
		var rtp := ModelScript.expected_side_rtp(area)
		_expect(rtp >= 0.94 and rtp <= 0.96, "%s side bet stays inside the 94-96 percent RTP band" % area)

func _test_payout_contract() -> void:
	_expect(ModelScript.main_hit_payout("HIGH", 10, "HIGH", 5) == 28, "HIGH 10 chip face-five hit returns 28")
	_expect(ModelScript.main_hit_payout("JACKPOT", 10, "JACKPOT", 6) == 210, "JACKPOT face-six hit returns 21x")
	_expect(ModelScript.main_hit_payout("HIGH", 10, "LOW", 6) == 0, "wrong WHERE never pays despite a six")
	_expect(ModelScript.side_result(5, 2) == "RED_LEADS", "red higher face resolves RED LEADS")
	_expect(ModelScript.side_result(4, 4) == "DRAW", "matching faces resolve DRAW")
	_expect(ModelScript.side_payout("DRAW", 10, 4, 4) == 57, "10 chip DRAW returns 57")

	var double_jackpot := ModelScript.resolve_round(0, 6, 0, 6, {"JACKPOT": 10}, {})
	_expect(bool(double_jackpot.double_jackpot), "both dice may hit the same JACKPOT wager")
	_expect(bool(double_jackpot.double_jackpot_max), "double JACKPOT six-six raises max event")
	_expect(int(double_jackpot.total_return) == 420, "double JACKPOT MAX pays both independent dice")
	_expect(int(double_jackpot.profit) == 410, "double hit subtracts the wager only once")

	var mixed := ModelScript.resolve_round(1, 5, 0, 2, {"HIGH": 20, "JACKPOT": 10}, {"area": "RED_LEADS", "amount": 10})
	_expect(str(mixed.red_area) == "HIGH" and str(mixed.blue_area) == "JACKPOT", "round exposes both WHERE results")
	_expect(int(mixed.main_return) == 126, "mixed HIGH and JACKPOT example pays both hits")
	_expect(int(mixed.side_return) == 23, "RED LEADS side payout is independent of WHERE")
	_expect(int(mixed.total_bet) == 40 and int(mixed.total_return) == 149, "round totals main and side bets and returns")

func _test_bank_settlement() -> void:
	if FileAccess.file_exists(CasinoBankScript.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CasinoBankScript.SAVE_PATH))
	CasinoBankScript.add_chips(100)
	var receipt := CasinoBankScript.settle_dice_roulette(20, 56)
	_expect(bool(receipt.get("ok", false)), "roulette settlement succeeds with sufficient chips")
	_expect(CasinoBankScript.balance() == 136, "roulette settlement atomically applies wager and payout")
	var saved := CasinoBankScript.load_data()
	_expect(int(saved.dice_roulette_play_count) == 1, "roulette play count persists")
	_expect(int(saved.dice_roulette_win_count) == 1, "profitable roulette round records a win")
	_expect(int(saved.dice_roulette_best_payout) == 56, "roulette best payout persists")
	var rejected := CasinoBankScript.settle_dice_roulette(200, 1000)
	_expect(not bool(rejected.get("ok", true)) and CasinoBankScript.balance() == 136, "insufficient wager cannot mutate roulette balance")

func _test_ui_contract() -> void:
	CasinoBankScript.save_data(CasinoBankScript.default_data())
	CasinoBankScript.add_chips(100)
	var roulette := ROULETTE_SCENE.instantiate()
	root.add_child(roulette)
	await process_frame
	_expect(roulette is DiceRouletteScreen, "Dice Roulette scene instantiates its screen")
	_expect(roulette.wheel != null, "Dice Roulette exposes the animated wheel")
	_expect(roulette.amount_buttons.size() == 3 and roulette.selected_bet_amount == 10, "roulette defaults to LONG PLAY 10 chip")
	_expect(roulette.main_bet_buttons.size() == 6, "roulette creates all six main WHERE bet areas")
	_expect(roulette.side_bet_buttons.size() == 3, "roulette creates red draw blue side bets")
	_expect(roulette.phase == DiceRouletteScreen.Phase.BETTING, "roulette opens in BETTING phase")
	roulette.call("_place_main_bet", "HIGH")
	_expect(int(roulette.main_bets.get("HIGH", 0)) == 10 and roulette.call("_current_total_bet") == 10, "main bet tap places selected chip amount")
	roulette.call("_select_amount", 20)
	roulette.call("_place_main_bet", "JACKPOT")
	roulette.call("_place_side_bet", "DRAW")
	_expect(roulette.call("_current_total_bet") == 50, "main plus side bets respect the 50 chip round cap")
	roulette.call("_place_main_bet", "LOW")
	_expect(roulette.call("_current_total_bet") == 50, "bet placement cannot push total beyond 50")
	roulette.call("_undo")
	_expect(roulette.call("_current_total_bet") == 30, "UNDO restores the previous bet snapshot")
	roulette.queue_free()
	await process_frame

	var hub := HUB_SCENE.instantiate()
	root.add_child(hub)
	await process_frame
	_expect(hub is CasinoHubScreen and hub.roulette_host != null, "Casino Hub creates a Dice Roulette host")
	hub.call("_open_dice_roulette")
	await process_frame
	_expect(hub.roulette_host.visible and hub.roulette_host.get_child_count() == 1, "Casino Hub opens Dice Roulette")
	var opened := hub.roulette_host.get_child(0)
	_expect(opened is DiceRouletteScreen, "Casino Hub routes to Dice Roulette instead of HIGH/LOW")
	hub.call("_close_dice_roulette")
	await process_frame
	_expect(hub.hub_root.visible and not hub.roulette_host.visible, "returning from Dice Roulette restores Casino Hub")
	hub.queue_free()
	await process_frame
