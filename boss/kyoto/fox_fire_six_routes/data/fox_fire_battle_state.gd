class_name FoxFireBattleState
extends RefCounted

var phase: int = 0
var turn_number: int = 0
var difficulty_level: int = 1

var cat_position: Vector2i = Vector2i(2, 5)
var current_torii_id: int = 0

var move_steps: int = 0
var current_input_path: Array[Vector2i] = []
var reachable_endpoints: Array[Vector2i] = []

var active_edges: Dictionary = {}
var sealed_edges: Dictionary = {}
var severed_edges: Dictionary = {}
var white_fire_cells: Dictionary = {}

var visited_torii: Dictionary = {0: true}
var seal_count: int = 0
var fox_preview_cells: Array[Vector2i] = []
## Preview scheduling is explicit: the candidates and the hidden committed
## result are both selected before the player rolls, never after movement.
var fox_preview_due_turn: int = 0
var fox_committed_cell: Vector2i = Vector2i(-1, -1)
var next_fox_action_turn: int = 0
## Lv5+ preview. The edge key is stable across snapshots and uses the same
## normalized key as FoxFireEdge.
var fox_preview_line_cut_edge: String = ""
var line_cut_preview_due_turn: int = 0
## Slice 6 pauses on Sakura until the player chooses a fire to purify.
var special_kind: StringName = &""
var block_bonus_pending: bool = false
var block_bonus_signature: String = ""

var forced_exit_direction: Vector2i = Vector2i.ZERO

var yasaka_delay_available: bool = false
var kiyomizu_available: bool = false
var tenryuji_available: bool = false
var fushimi_start_choice_available: bool = false
var mangan_available: bool = false
var mangan_armed: bool = false
var line_cuts_used: int = 0


func remaining_steps() -> int:
	return maxi(move_steps - maxi(current_input_path.size() - 1, 0), 0)


func has_visited_torii(torii_id: int) -> bool:
	return bool(visited_torii.get(torii_id, false))
