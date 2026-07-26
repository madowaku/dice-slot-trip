class_name V06RollSet
extends RefCounted

const SLOT_COUNT: int = 3
const ROLE_MIX: StringName = &"MIX"
const ROLE_NONE: StringName = ROLE_MIX # Compatibility alias for older callers.
const ROLE_PAIR: StringName = &"PAIR"
const ROLE_STRAIGHT: StringName = &"STRAIGHT"
const ROLE_TRIPLE: StringName = &"TRIPLE"

var _faces: Array[int] = []

func append_face(face: int) -> bool:
	if face < 1 or face > 6 or is_complete():
		return false
	_faces.append(face)
	return true

func faces() -> Array[int]:
	return _faces.duplicate()

func is_complete() -> bool:
	return _faces.size() == SLOT_COUNT

func evaluate_role() -> StringName:
	if not is_complete():
		return &""
	if _faces[0] == _faces[1] and _faces[1] == _faces[2]:
		return ROLE_TRIPLE
	if _faces[0] == _faces[1] or _faces[0] == _faces[2] or _faces[1] == _faces[2]:
		return ROLE_PAIR
	var ordered := _faces.duplicate()
	ordered.sort()
	if ordered[1] == ordered[0] + 1 and ordered[2] == ordered[1] + 1:
		return ROLE_STRAIGHT
	return ROLE_MIX

func reset_after_resolution() -> bool:
	if not is_complete():
		return false
	_faces.clear()
	return true
