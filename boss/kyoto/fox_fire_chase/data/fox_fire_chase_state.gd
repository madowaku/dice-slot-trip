class_name FoxFireChaseState
extends RefCounted

var phase: int = 0
var lap: int = 1
var difficulty_level: int = 1
var roll_speed_scale: float = 1.0

## Absolute clockwise progress, measured from the cat's specification cell 14.
## Lv1 starts with the fox eight cells ahead. This leaves twelve cells behind
## the cat before a full-lap defeat while preserving the chase composition.
var cat_progress: int = 0
var fox_progress: int = 8
var cat_position: Vector2i = Vector2i(2, 5)
var fox_position: Vector2i = Vector2i(1, 0)
var cat_on_outer: bool = true

var fox_fire_indices: Dictionary = {}
var goshuin_count: int = 0
var coins: int = 0
var head_start_count: int = 0
var boss_shield_charges: int = 0
var boss_stop_turns: int = 0
var reverse_card_count: int = 0

var slot_faces: Array[int] = []
var completed_slot_faces: Array[int] = []
var last_slot_role: StringName = &""
var last_slot_bonus: int = 0

var detour_path: Array[Vector2i] = []
var detour_exit_progress: int = -1

var pending_face: int = 0
var pending_fox_face: int = 0
var pending_player_steps: int = 0
var pending_fire_progress: int = -1
var current_turn_cat_path: Array[Vector2i] = []
var current_turn_fox_path: Array[Vector2i] = []
var current_turn_fire_created: int = -1
var current_turn_reverse_used: bool = false
var current_turn_reverse_acquired: bool = false
var current_turn_fox_resolved: bool = false


func distance_to_fox() -> int:
	return fox_progress - cat_progress


func is_inside_detour() -> bool:
	return not cat_on_outer or not detour_path.is_empty()


func clear_turn_runtime() -> void:
	pending_face = 0
	pending_fox_face = 0
	pending_player_steps = 0
	pending_fire_progress = -1
	current_turn_cat_path.clear()
	current_turn_fox_path.clear()
	current_turn_fire_created = -1
	current_turn_reverse_used = false
	current_turn_reverse_acquired = false
	current_turn_fox_resolved = false
