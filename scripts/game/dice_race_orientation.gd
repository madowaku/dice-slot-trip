extends RefCounted
class_name DiceRaceOrientation

const DIRECTIONS := ["top", "bottom", "front", "back", "left", "right"]
const RACER_DIRECTION := {
	"fox": "top",
	"rabbit": "bottom",
	"duck": "front",
	"dinosaur": "back",
	"camel": "left",
	"robot": "right",
}

static func base_orientation() -> Dictionary:
	return {
		"top": 1,
		"bottom": 6,
		"front": 2,
		"back": 5,
		"left": 3,
		"right": 4,
	}

static func all_orientations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var queue: Array[Dictionary] = [base_orientation()]
	var seen := {}
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var key := orientation_key(current)
		if seen.has(key):
			continue
		seen[key] = true
		result.append(current)
		queue.append(rotate_x(current))
		queue.append(rotate_y(current))
		queue.append(rotate_z(current))
	return result

static func values_for_racers(orientation: Dictionary) -> Dictionary:
	var assignments := {}
	for racer_id: String in RACER_DIRECTION:
		assignments[racer_id] = int(orientation.get(RACER_DIRECTION[racer_id], 0))
	return assignments

static func is_valid_orientation(orientation: Dictionary) -> bool:
	var values: Array[int] = []
	for direction: String in DIRECTIONS:
		if not orientation.has(direction):
			return false
		values.append(int(orientation[direction]))
	values.sort()
	if values != [1, 2, 3, 4, 5, 6]:
		return false
	return (
		int(orientation.top) + int(orientation.bottom) == 7
		and int(orientation.front) + int(orientation.back) == 7
		and int(orientation.left) + int(orientation.right) == 7
	)

static func orientation_key(orientation: Dictionary) -> String:
	return "%d,%d,%d,%d,%d,%d" % [
		int(orientation.get("top", 0)),
		int(orientation.get("bottom", 0)),
		int(orientation.get("front", 0)),
		int(orientation.get("back", 0)),
		int(orientation.get("left", 0)),
		int(orientation.get("right", 0)),
	]

static func rotate_x(o: Dictionary) -> Dictionary:
	return {
		"top": o.front,
		"bottom": o.back,
		"front": o.bottom,
		"back": o.top,
		"left": o.left,
		"right": o.right,
	}

static func rotate_y(o: Dictionary) -> Dictionary:
	return {
		"top": o.top,
		"bottom": o.bottom,
		"front": o.left,
		"back": o.right,
		"left": o.back,
		"right": o.front,
	}

static func rotate_z(o: Dictionary) -> Dictionary:
	return {
		"top": o.left,
		"bottom": o.right,
		"front": o.front,
		"back": o.back,
		"left": o.bottom,
		"right": o.top,
	}
