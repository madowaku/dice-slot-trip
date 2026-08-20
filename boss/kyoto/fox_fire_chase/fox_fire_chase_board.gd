class_name FoxFireChaseBoard
extends RefCounted

## Deterministic geometry for the 6 x 6 chase board. The chase uses the
## centres of square cells: the outer 20 cells are the normal route and the
## inner 16 cells are visited only by generated fire-detour paths.

const BOARD_SIZE: int = 6
const OUTER_CELL_COUNT: int = 20
const CAT_BASE_OUTER_INDEX: int = 13 # Specification cell 14 (zero based).
const FOX_START_OUTER_INDEX: int = 3 # Specification cell 4 (zero based).


## JSON uses integer cell ids instead of Vector2i values.  The id is the
## stable row-major id used by the battle save format (0..35).  Vector2i is
## still used internally and by the renderer.
static func cell_id(position: Vector2i) -> int:
	return position.y * BOARD_SIZE + position.x


static func position_from_cell_id(id: int) -> Vector2i:
	if id < 0 or id >= BOARD_SIZE * BOARD_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(id % BOARD_SIZE, id / BOARD_SIZE)


static func is_valid_cell_id(id: int) -> bool:
	return id >= 0 and id < BOARD_SIZE * BOARD_SIZE


static func outer_cell_id(index: int) -> int:
	return cell_id(outer_position(index))


static func outer_index_for_cell_id(id: int) -> int:
	if not is_valid_cell_id(id):
		return -1
	return outer_index_for_position(position_from_cell_id(id))


static func normalize_outer_index(index: int) -> int:
	return posmod(index, OUTER_CELL_COUNT)


static func outer_position(index: int) -> Vector2i:
	var normalized := normalize_outer_index(index)
	if normalized <= 5:
		return Vector2i(normalized, 0)
	if normalized <= 10:
		return Vector2i(5, normalized - 5)
	if normalized <= 15:
		return Vector2i(15 - normalized, 5)
	return Vector2i(0, 20 - normalized)


static func outer_index_for_position(position: Vector2i) -> int:
	if position.y == 0 and position.x >= 0 and position.x < BOARD_SIZE:
		return position.x
	if position.x == 5 and position.y > 0 and position.y < BOARD_SIZE:
		return 5 + position.y
	if position.y == 5 and position.x >= 0 and position.x < 5:
		return 15 - position.x
	if position.x == 0 and position.y > 0 and position.y < 5:
		return 20 - position.y
	return -1


static func is_outer_position(position: Vector2i) -> bool:
	return outer_index_for_position(position) >= 0


static func is_in_bounds(position: Vector2i) -> bool:
	return (
		position.x >= 0
		and position.y >= 0
		and position.x < BOARD_SIZE
		and position.y < BOARD_SIZE
	)


static func inward_position(index: int) -> Vector2i:
	var normalized := normalize_outer_index(index)
	var outer := outer_position(normalized)
	# Corners deliberately belong to the preceding clockwise edge. This makes
	# a fire on a corner cost no extra steps, as allowed by the specification.
	if normalized <= 5:
		return Vector2i(clampi(outer.x, 1, 4), 1)
	if normalized <= 10:
		return Vector2i(4, clampi(outer.y, 1, 4))
	if normalized <= 15:
		return Vector2i(clampi(outer.x, 1, 4), 4)
	return Vector2i(1, clampi(outer.y, 1, 4))


static func outer_ring() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for index: int in range(OUTER_CELL_COUNT):
		result.append(outer_position(index))
	return result


static func detour_from_progress(entry_progress: int, fire_indices: Dictionary) -> Dictionary:
	## Builds the one-cell-inward route around the contiguous fire run directly
	## ahead. The current outer cell is not included in `path`.
	var first_blocked_progress := entry_progress + 1
	if not fire_indices.has(normalize_outer_index(first_blocked_progress)):
		return {"ok": false, "error": "NEXT_CELL_IS_CLEAR"}

	var exit_progress := first_blocked_progress
	var blocked_indices: Array[int] = []
	while fire_indices.has(normalize_outer_index(exit_progress)):
		blocked_indices.append(normalize_outer_index(exit_progress))
		exit_progress += 1
		if exit_progress - first_blocked_progress >= OUTER_CELL_COUNT:
			return {"ok": false, "error": "OUTER_RING_BLOCKED"}

	var path: Array[Vector2i] = []
	_append_unique(path, inward_position(entry_progress))
	for progress: int in range(first_blocked_progress, exit_progress + 1):
		_append_unique(path, inward_position(progress))
	_append_unique(path, outer_position(exit_progress))
	return {
		"ok": true,
		"path": path,
		"exit_progress": exit_progress,
		"blocked_indices": blocked_indices,
		"outer_advance": exit_progress - entry_progress,
	}


static func extend_detour(
	remaining_path: Array[Vector2i],
	old_exit_progress: int,
	fire_indices: Dictionary
) -> Dictionary:
	## A fox can leave new fire on a pending exit before the cat's next roll.
	## Extend the existing local detour instead of granting a shortcut or
	## allowing the cat to step onto fire.
	if not fire_indices.has(normalize_outer_index(old_exit_progress)):
		return {
			"ok": true,
			"path": remaining_path.duplicate(),
			"exit_progress": old_exit_progress,
			"extended": false,
		}

	var path: Array[Vector2i] = remaining_path.duplicate()
	var old_outer := outer_position(old_exit_progress)
	if not path.is_empty() and path.back() == old_outer:
		path.pop_back()

	var new_exit_progress := old_exit_progress
	var checked := 0
	while fire_indices.has(normalize_outer_index(new_exit_progress)):
		_append_unique(path, inward_position(new_exit_progress))
		new_exit_progress += 1
		checked += 1
		if checked >= OUTER_CELL_COUNT:
			return {"ok": false, "error": "OUTER_RING_BLOCKED"}
	_append_unique(path, inward_position(new_exit_progress))
	_append_unique(path, outer_position(new_exit_progress))
	return {
		"ok": true,
		"path": path,
		"exit_progress": new_exit_progress,
		"extended": true,
	}


static func path_is_orthogonal(path: Array[Vector2i], start: Vector2i) -> bool:
	var previous := start
	for cell: Vector2i in path:
		if not is_in_bounds(cell):
			return false
		if absi(cell.x - previous.x) + absi(cell.y - previous.y) != 1:
			return false
		previous = cell
	return true


static func path_is_valid_remaining(
	path: Array[Vector2i],
	start: Vector2i, expected_exit_progress: int = -1
) -> bool:
	## A saved detour is the *remaining* path, not the original path.  Require
	## every segment to be a one-cell orthogonal move and make sure it reaches
	## the recorded outer exit when one is supplied.  This prevents a malformed
	## save from teleporting the cat or leaving it in an impossible corridor.
	if not is_in_bounds(start) or path.is_empty():
		return false
	if not path_is_orthogonal(path, start):
		return false
	if expected_exit_progress >= 0:
		var last: Vector2i = path.back()
		if is_outer_position(last):
			var expected := outer_position(expected_exit_progress)
			if last != expected:
				return false
		else:
			# The player may have stopped inside the detour.  No outer cell may
			# appear before the final remaining cell in that case.
			for index: int in range(path.size() - 1):
				if is_outer_position(path[index]):
					return false
	return true


static func _append_unique(path: Array[Vector2i], position: Vector2i) -> void:
	if path.is_empty() or path.back() != position:
		path.append(position)
