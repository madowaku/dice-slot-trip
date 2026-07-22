class_name V1ThreeRollSlot
extends RefCounted

const SLOT_COUNT := 3
const MAX_GAUGE := 3
const ROLE_MIX: StringName = &"MIX"
const ROLE_PAIR: StringName = &"PAIR"
const ROLE_STRAIGHT: StringName = &"STRAIGHT"
const ROLE_TRIPLE: StringName = &"TRIPLE"

var _faces: Array[int] = []

func begin_roll() -> void:
	if is_complete():
		_faces.clear()

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
	var sorted := _faces.duplicate()
	sorted.sort()
	if sorted[0] + 1 == sorted[1] and sorted[1] + 1 == sorted[2]:
		return ROLE_STRAIGHT
	if _faces[0] == _faces[1] or _faces[0] == _faces[2] or _faces[1] == _faces[2]:
		return ROLE_PAIR
	return ROLE_MIX

func resolve_reward(current_gauge: int) -> Dictionary:
	if not is_complete():
		return {}
	var role := evaluate_role()
	if role == ROLE_MIX:
		return {"role": role, "gauge": clampi(current_gauge, 0, MAX_GAUGE), "coins": 1}
	var gain := 1 if role == ROLE_PAIR else (2 if role == ROLE_STRAIGHT else 3)
	var gauge := clampi(current_gauge, 0, MAX_GAUGE)
	var applied := mini(gain, MAX_GAUGE - gauge)
	return {"role": role, "gauge": gauge + applied, "coins": gain - applied}
