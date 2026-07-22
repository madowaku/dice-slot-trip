extends SceneTree

const Slot = preload("res://scripts/game/v1_three_roll_slot.gd")
const Skill = preload("res://scripts/game/v1_explorer_skill.gd")
const Race = preload("res://scripts/game/v1_boss_race.gd")
var failures := 0

func _init() -> void:
	_test_slot()
	_test_skill()
	_test_race()
	print("V1_LOGIC_TESTS failures=%d" % failures)
	quit(1 if failures else 0)

func _test_slot() -> void:
	var slot = Slot.new()
	for face in [4, 2, 3]: _expect(slot.append_face(face), "slot accepts face")
	_expect(slot.evaluate_role() == Slot.ROLE_STRAIGHT, "unordered consecutive faces are STRAIGHT")
	_expect(slot.resolve_reward(2) == {"role": &"STRAIGHT", "gauge": 3, "coins": 1}, "gauge overflow becomes coins")
	slot.begin_roll()
	for face in [6, 6, 6]: slot.append_face(face)
	_expect(slot.evaluate_role() == Slot.ROLE_TRIPLE, "TRIPLE has priority")
	_expect(slot.resolve_reward(3).coins == 3, "READY converts all charge to coins")
	slot.begin_roll()
	for face in [1, 3, 6]: slot.append_face(face)
	_expect(slot.resolve_reward(0) == {"role": &"MIX", "gauge": 0, "coins": 1}, "MIX awards one coin")

func _test_skill() -> void:
	var skill = Skill.new()
	_expect(skill.add_charge(3) == 0 and skill.state == Skill.State.READY, "charge reaches READY")
	_expect(skill.toggle_arm() and skill.gauge == 3, "arming does not consume gauge")
	_expect(skill.toggle_arm() and skill.state == Skill.State.READY, "armed skill can be cancelled")
	skill.toggle_arm()
	_expect(skill.begin_roll() and skill.gauge == 0 and skill.state == Skill.State.ACTIVE, "roll start consumes gauge")
	_expect(skill.finish_roll() and skill.state == Skill.State.CHARGING, "focus lasts one roll")
	_expect(is_equal_approx(skill.ROLL_SPEED_SCALE, 0.65), "focus speed is 65 percent")

func _test_race() -> void:
	_expect(Race.effective_player_roll(6, 2) == 6, "player modifier is clamped")
	_expect(Race.mirror_roll(Race.effective_player_roll(2, 1)) == 4, "boss mirrors effective roll")
	var race = Race.new()
	var first: Dictionary = race.play_turn(2)
	_expect(first.player_roll == 2 and first.boss_roll == 5, "mirror pair sums to seven")
	_expect(race.player_position == 4 and race.boss_position == 5 and race.boss_pending_modifier == 1, "BOOST adds two without chaining and WIND queues")
	var tie = Race.new()
	tie.player_position = 11
	tie.boss_position = 11
	tie.play_turn(2)
	_expect(tie.winner == &"PLAYER", "exact same arrival step favors player")
	var earlier = Race.new()
	earlier.player_position = 11
	earlier.boss_position = 12
	earlier.play_turn(5)
	_expect(earlier.winner == &"BOSS", "earlier within-turn arrival wins")
	var effects = Race.new()
	effects.player_position = 2
	effects.boss_position = 4
	effects.play_turn(1)
	_expect(effects.player_pending_modifier == -1 and effects.boss_position == 10 and effects.boss_pending_modifier == 1, "SAND and WIND queue next-move modifiers")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
