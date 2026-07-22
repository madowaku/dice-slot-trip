class_name V1ExplorerSkill
extends RefCounted

enum State { CHARGING, READY, ARMED, ACTIVE, LOCKED }

const MAX_GAUGE := 3
const ROLL_SPEED_SCALE := 0.65
const BOUNCE_SCALE := 0.80
const DRIFT_SCALE := 0.80

var gauge: int = 0
var state: State = State.CHARGING

func add_charge(amount: int) -> int:
	if amount <= 0:
		return 0
	var overflow := maxi(0, gauge + amount - MAX_GAUGE)
	gauge = mini(MAX_GAUGE, gauge + amount)
	if state != State.ARMED and state != State.ACTIVE and state != State.LOCKED:
		state = State.READY if gauge == MAX_GAUGE else State.CHARGING
	return overflow

func toggle_arm() -> bool:
	if state == State.READY:
		state = State.ARMED
		return true
	if state == State.ARMED:
		state = State.READY
		return true
	return false

func begin_roll() -> bool:
	if state != State.ARMED:
		return false
	gauge = 0
	state = State.ACTIVE
	return true

func finish_roll() -> bool:
	if state != State.ACTIVE:
		return false
	state = State.CHARGING
	return true

func reset() -> void:
	gauge = 0
	state = State.CHARGING
