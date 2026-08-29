extends SceneTree

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const ModelScript = preload("res://scripts/game/dice_roulette_model.gd")
const ROULETTE_SCENE: PackedScene = preload("res://scenes/casino/DiceRoulette.tscn")
const HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")
const ScreenScript = preload("res://scripts/app/dice_roulette_screen.gd")
const HubScript = preload("res://scripts/app/casino_hub_screen.gd")
const ROULETTE_BGM_PATH := "res://assets/audio/bgm/lasvegas/ルーレット.mp3"
const ROULETTE_BACKGROUND_PATH := "res://assets/casino/dice_roulette/ui/casino-table-bg-v1.png"
const ROULETTE_BEZEL_PATH := "res://assets/casino/dice_roulette/ui/roulette-bezel-v1.png"
const ROULETTE_SPARKLE_PATH := "res://assets/casino/dice_roulette/ui/sparkle_frames/03.png"
const BUTTON_ORNAMENTS_PATH := "res://assets/art/ui/common/roll-button-ornaments.png"
const SPIN_RING_PATH := "res://assets/casino/dice_roulette/ui/spin-button-amber-v1.png"

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
	test_save_path = "user://dice_slot_trip_dice_roulette_%d.json" % OS.get_process_id()
	CasinoBankScript.set_test_save_path(test_save_path)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	ScreenScript.suppress_audio_for_tests = true
	HubScript.suppress_audio_for_tests = true
	_test_probability_contract()
	_test_payout_contract()
	_test_bank_settlement()
	await _test_ui_contract()
	print("Dice Roulette tests: %d assertions, %d failures" % [assertions, failures])
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	var bgm := root.get_node_or_null("BgmManager")
	if bgm != null:
		bgm.call("stop")
	var sfx := root.get_node_or_null("UiSfxManager")
	if sfx != null:
		sfx.call("stop_all")
	await process_frame
	CasinoBankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false
	HubScript.suppress_audio_for_tests = false
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
	var fixture := CasinoBankScript.default_data()
	fixture["chips"] = 100
	_expect(CasinoBankScript.save_data(fixture), "roulette fixture saves to an isolated path")
	var begun := CasinoBankScript.begin_game("dice_roulette", 20, {"phase": "SPINNING", "pending_rolls": [{"slot": 1, "face": 5}, {"slot": 0, "face": 2}]})
	_expect(bool(begun.get("ok", false)) and int(begun.get("charged", 0)) == 20, "roulette begin charges the wager once")
	var game_id := str(begun.get("game_id", ""))
	_expect(CasinoBankScript.balance() == 80, "roulette begin persists the reduced balance")
	var receipt := CasinoBankScript.settle_game("dice_roulette", 56, {"total_return": 56}, game_id)
	_expect(bool(receipt.get("ok", false)), "roulette settlement succeeds with sufficient chips")
	_expect(CasinoBankScript.balance() == 136, "roulette settlement credits payout after one charge")
	var saved := CasinoBankScript.load_data()
	_expect(int(saved.dice_roulette_play_count) == 1, "roulette play count persists")
	_expect(int(saved.dice_roulette_win_count) == 1, "profitable roulette round records a win")
	_expect(int(saved.dice_roulette_best_payout) == 56, "roulette best payout persists")
	var duplicate := CasinoBankScript.settle_game("dice_roulette", 56, {"total_return": 56}, game_id)
	_expect(not bool(duplicate.get("ok", true)) and bool(duplicate.get("already_settled", false)) and CasinoBankScript.balance() == 136, "duplicate roulette settlement cannot credit twice")

func _test_ui_contract() -> void:
	_expect(FileAccess.file_exists(ROULETTE_BGM_PATH), "roulette BGM asset is present for runtime import")
	var roulette_bgm: Resource = ResourceLoader.load(ROULETTE_BGM_PATH)
	_expect(roulette_bgm is AudioStreamMP3, "roulette BGM imports as an AudioStreamMP3")
	_expect(ResourceLoader.load(ROULETTE_BACKGROUND_PATH) is Texture2D, "roulette casino background imports as a production texture")
	_expect(ResourceLoader.load(ROULETTE_BEZEL_PATH) is Texture2D, "roulette jeweled bezel imports with transparency")
	_expect(ResourceLoader.load(ROULETTE_SPARKLE_PATH) is Texture2D, "roulette normalized sparkle frame imports as a texture")
	_expect(ResourceLoader.load(BUTTON_ORNAMENTS_PATH) is Texture2D, "roulette button ornament strip imports as a production texture")
	_expect(ResourceLoader.load(SPIN_RING_PATH) is Texture2D, "roulette round SPIN ring imports as a production texture")
	CasinoBankScript.save_data(CasinoBankScript.default_data())
	CasinoBankScript.add_chips(100)
	var roulette := ROULETTE_SCENE.instantiate()
	root.add_child(roulette)
	await process_frame
	_expect(roulette.get_script() == ScreenScript, "Dice Roulette scene instantiates its screen")
	_expect(roulette.wheel != null, "Dice Roulette exposes the animated wheel")
	_expect(roulette.wheel.red_marker != null and roulette.wheel.red_marker.has_method("set_face") and roulette.wheel.red_marker.custom_minimum_size.x >= 68.0, "roulette wheel uses a readable dimensional red die marker")
	_expect(roulette.wheel.blue_marker != null and roulette.wheel.blue_marker.has_method("set_face") and roulette.wheel.blue_marker.custom_minimum_size.x >= 68.0, "roulette wheel uses a readable dimensional blue die marker")
	_expect(roulette.amount_buttons.size() == 3 and roulette.selected_bet_amount == 10, "roulette defaults to LONG PLAY 10 chip")
	_expect(roulette.main_bet_buttons.size() == 6, "roulette creates all six main WHERE bet areas")
	_expect(roulette.side_bet_buttons.size() == 3, "roulette creates red draw blue side bets")
	_expect(roulette.spin_button != null and roulette.spin_button.custom_minimum_size.x >= 192.0, "roulette SPIN keeps a 96px physical touch target on the 360px canvas")
	_expect(roulette.spin_button.get_node_or_null("SpinGoldRing") is TextureRect and roulette.spin_button.get_node_or_null("SpinCaption") is Label, "roulette SPIN uses the premium round gold ring and readable live caption")
	_expect(roulette.guide_label != null and "①" in roulette.guide_label.text and "ベット額" in roulette.guide_label.text, "roulette opens with a Japanese current-step guide")
	_expect(roulette.betting_shell != null and roulette.betting_shell.visible, "roulette lower controls sit on a decorated betting-table panel")
	_expect((roulette.amount_buttons.get(10) as Button).get_node_or_null("ButtonOrnament") is TextureRect, "roulette amount buttons use the production gold ornament frames")
	_expect((roulette.side_bet_buttons.get("RED_LEADS") as Button).get_node_or_null("SideDiceIcon") is TextureRect, "roulette color bets carry readable dice art")
	_expect(roulette.action_dock != null and roulette.action_dock.visible and roulette.action_dock.is_ancestor_of(roulette.spin_button), "roulette keeps a visible fixed action dock independent of the scrolling betting table")
	var undo_caption := roulette.undo_button.get_node_or_null("ButtonCaption") as Label
	var clear_caption := roulette.clear_button.get_node_or_null("ButtonCaption") as Label
	_expect(undo_caption != null and undo_caption.text == "もどす" and clear_caption != null and clear_caption.text == "消す", "roulette utility controls use first-play Japanese labels")
	var casino_back := roulette.find_child("CasinoBackButton", true, false) as Button
	_expect(casino_back != null and casino_back.custom_minimum_size.y >= 54.0, "roulette keeps an always-visible casino return target")
	_expect(int(roulette.get("phase")) == 1, "roulette opens in BETTING phase")
	roulette.call("_place_main_bet", "HIGH")
	_expect(int(roulette.main_bets.get("HIGH", 0)) == 10 and roulette.call("_current_total_bet") == 10, "main bet tap places selected chip amount")
	var high_chip_badge := (roulette.main_bet_buttons.get("HIGH") as Button).get_node_or_null("BetChipBadge") as Label
	_expect(high_chip_badge != null and high_chip_badge.visible and high_chip_badge.text == "10 CHIP", "placed main bet shows a physical chip badge on its table cell")
	_expect("③" in roulette.guide_label.text and "SPIN" in roulette.guide_label.text, "placing a bet advances the guide to the primary SPIN action")
	_expect("おすすめ" in (roulette.main_bet_buttons.get("HIGH") as Button).text and "大穴" in (roulette.main_bet_buttons.get("JACKPOT") as Button).text, "main table exposes concise Japanese bet personalities")
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
	var opened: Node = hub.roulette_host.get_child(0)
	_expect(opened.get_script() == ScreenScript, "Casino Hub routes to Dice Roulette instead of HIGH/LOW")
	hub.call("_close_dice_roulette")
	await process_frame
	_expect(hub.hub_root.visible and not hub.roulette_host.visible, "returning from Dice Roulette restores Casino Hub")
	hub.queue_free()
	await process_frame
