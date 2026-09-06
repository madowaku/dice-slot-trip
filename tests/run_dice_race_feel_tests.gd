extends SceneTree

const RaceScript = preload("res://scripts/game/dice_race_model.gd")
const BankScript = preload("res://scripts/game/casino_bank.gd")
const ScreenScript = preload("res://scripts/app/dice_race_screen.gd")
const SCENE: PackedScene = preload("res://scenes/casino/DiceRace.tscn")
const TEST_SAVE_RELATIVE_PATH: String = ".qa-dice-race-feel-tests.json"

var assertions: int = 0
var failures: int = 0
var test_save_path: String = ""

func _init() -> void:
	call_deferred("_run")

func _expect(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("FAIL: %s" % label)

func _fixture(positions: Dictionary, bet_racer: String = "rabbit") -> Dictionary:
	var state: Dictionary = RaceScript.new_race(bet_racer, 20)
	var racers: Dictionary = state.get("racers", {}) as Dictionary
	for racer_id: String in RaceScript.RACERS:
		var racer: Dictionary = racers.get(racer_id, {}) as Dictionary
		racer["position"] = int(positions.get(racer_id, 0))
		racers[racer_id] = racer
	state["racers"] = racers
	return state

func _assignments(values: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for racer_id: String in RaceScript.RACERS:
		result[racer_id] = int(values.get(racer_id, 1))
	return result

func _run() -> void:
	test_save_path = ProjectSettings.globalize_path("res://" + TEST_SAVE_RELATIVE_PATH)
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	BankScript.set_test_save_path(test_save_path)
	ScreenScript.suppress_audio_for_tests = true
	var data: Dictionary = BankScript.default_data()
	data["chips"] = 300
	BankScript.save_data(data)

	var normal: Dictionary = _fixture({"rabbit": 2})
	var normal_next: Dictionary = RaceScript.apply_roll(normal, _assignments({
		"camel": 1, "rabbit": 2, "fox": 3, "duck": 4, "dinosaur": 5, "robot": 6,
	}))
	_expect(int(normal_next.get("roll_count", 0)) == 1, "A normal roll increments roll count once")
	_expect(not bool(normal_next.get("finished", false)), "A normal roll is not prematurely finished")

	var overtake_before: Dictionary = _fixture({"camel": 10, "rabbit": 4, "fox": 8})
	var overtake_after: Dictionary = RaceScript.apply_roll(overtake_before, _assignments({
		"camel": 2, "rabbit": 5, "fox": 1, "duck": 3, "dinosaur": 4, "robot": 6,
	}))
	_expect(RaceScript.rank_for_racer(overtake_before, "rabbit") == 3 and RaceScript.rank_for_racer(overtake_after, "rabbit") == 2, "B overtake 3rd to 2nd")
	var leader_before: Dictionary = _fixture({"rabbit": 8, "fox": 10})
	var leader_after: Dictionary = RaceScript.apply_roll(leader_before, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5,
	}))
	_expect(RaceScript.rank_for_racer(leader_before, "rabbit") == 2 and RaceScript.rank_for_racer(leader_after, "rabbit") == 1, "C leader change 2nd to 1st")
	var drop_before: Dictionary = _fixture({"rabbit": 10, "fox": 9})
	var drop_after: Dictionary = RaceScript.apply_roll(drop_before, _assignments({
		"camel": 2, "rabbit": 1, "fox": 6, "duck": 3, "dinosaur": 4, "robot": 5,
	}))
	_expect(RaceScript.rank_for_racer(drop_before, "rabbit") == 1 and RaceScript.rank_for_racer(drop_after, "rabbit") == 2, "D selected racer drops 1st to 2nd")

	var goal_state: Dictionary = _fixture({"rabbit": 20})
	var goal_next: Dictionary = RaceScript.apply_roll(goal_state, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5,
	}))
	_expect(bool(goal_next.get("finished", false)) and str(goal_next.get("winner", "")) == "rabbit", "E goal produces a unique winner")
	var loss_state: Dictionary = _fixture({"rabbit": 20, "fox": 21})
	var loss_valid: Dictionary = RaceScript.apply_roll(loss_state, _assignments({
		"camel": 2, "rabbit": 3, "fox": 6, "duck": 1, "dinosaur": 4, "robot": 5,
	}))
	_expect(bool(loss_valid.get("finished", false)) and str(loss_valid.get("winner", "")) == "fox", "G losing bet keeps the model winner")

	var photo_state: Dictionary = _fixture({"rabbit": 20, "fox": 21})
	var photo_next: Dictionary = RaceScript.apply_roll(photo_state, _assignments({
		"camel": 1, "rabbit": 5, "fox": 4, "duck": 2, "dinosaur": 3, "robot": 6,
	}))
	var photo_candidates: Array = photo_next.get("photo_finish_candidates", []) as Array
	_expect(not bool(photo_next.get("finished", false)) and photo_candidates.size() == 2, "F photo finish leaves two candidates")
	var photo_resolved: Dictionary = RaceScript.apply_roll(photo_next, _assignments({
		"camel": 1, "rabbit": 6, "fox": 2, "duck": 3, "dinosaur": 4, "robot": 5,
	}))
	_expect(bool(photo_resolved.get("finished", false)) and str(photo_resolved.get("winner", "")) == "rabbit", "F next roll resolves photo finish")

	var cashout_state: Dictionary = _fixture({})
	var cashout_assignments: Dictionary = _assignments({
		"camel": 1, "rabbit": 2, "fox": 3, "duck": 4, "dinosaur": 5, "robot": 6,
	})
	for index: int in 3:
		cashout_state = RaceScript.apply_roll(cashout_state, cashout_assignments)
	_expect(bool(cashout_state.get("cashout_offered", false)) and int(cashout_state.get("roll_count", 0)) == 3, "H cashout offered after third roll")
	var ride_on: Dictionary = RaceScript.ride_on(cashout_state)
	var extra_roll: Dictionary = RaceScript.apply_roll(ride_on, cashout_assignments)
	_expect(int(extra_roll.get("roll_count", 0)) == 4 and not bool(extra_roll.get("cashout_offered", false)), "H extra roll remains available after ride on")

	var viewport: SubViewport = SubViewport.new()
	viewport.name = "DiceRaceFeelViewport"
	viewport.size = Vector2i(360, 800)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var screen_node: Node = SCENE.instantiate()
	viewport.add_child(screen_node)
	await process_frame
	await process_frame
	_expect(screen_node is ScreenScript, "runtime scene uses DiceRaceScreen")
	if screen_node is ScreenScript:
		var screen: ScreenScript = screen_node as ScreenScript
		_expect(screen.start_button != null and screen.start_button.text == "ゲーム開始", "start CTA is explicit")
		_expect(screen.roll_button != null and screen.roll_button.text == "サイコロを振る", "roll CTA is explicit")
		_expect(screen.result_panel != null and screen.result_panel.custom_minimum_size.x <= 324.0, "result panel is compact for 360px")
		_expect(screen.result_view != null and not screen.result_view.visible, "result view starts hidden")
		screen.stage_trace.clear()
		screen._set_phase("result_rank")
		screen._set_phase("result_outcome")
		screen._set_phase("result_metrics")
		screen._set_phase("result_chip")
		screen._set_phase("result_cta")
		_expect(screen.stage_trace == ["result_rank", "result_outcome", "result_metrics", "result_chip", "result_cta"], "result stage order is explicit")
		screen._set_result_controls_enabled(false)
		_expect(screen.again_button.disabled and screen.change_bet_button.disabled and screen.result_exit_button.disabled, "result CTAs stay locked during presentation")
		screen._set_result_controls_enabled(true)
		_expect(not screen.again_button.disabled and not screen.change_bet_button.disabled and not screen.result_exit_button.disabled, "result CTAs unlock together")
		_expect(not screen.exiting, "screen starts in a live non-exiting state")
		# Exercise the real settlement path once, then invoke it again to prove
		# result presentation/Bank settlement are idempotent.
		var begin: Dictionary = BankScript.begin_game("dice_race", 20, RaceScript.new_race("rabbit", 20))
		screen.selected_racer = "rabbit"
		screen.selected_bet = 20
		screen.race = goal_next.duplicate(true)
		screen.wager_committed = true
		screen.result_recorded = false
		screen.settled = false
		screen.game_id = str(begin.get("game_id", ""))
		screen.presentation_locked = true
		screen._finish_race()
		await create_timer(1.25).timeout
		_expect(screen.result_panel.visible and screen.result_rank_label.visible, "result view presents rank after settlement")
		_expect(screen.result_outcome_label.visible and screen.result_bet_value.visible, "result view presents outcome then metrics")
		_expect(not screen.again_button.disabled and not screen.change_bet_button.disabled and not screen.result_exit_button.disabled, "result CTAs unlock after chip count")
		var settled_balance: int = BankScript.balance()
		screen._finish_race()
		_expect(BankScript.balance() == settled_balance, "duplicate finish does not settle Bank twice")
	screen_node.queue_free()
	await process_frame
	_expect(not is_instance_valid(screen_node), "I queue_free tears down the screen")
	viewport.queue_free()
	await process_frame
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)
	BankScript.clear_test_save_path()
	ScreenScript.suppress_audio_for_tests = false
	print("DICE RACE feel tests: %d assertions, %d failures" % [assertions, failures])
	quit(1 if failures > 0 else 0)
