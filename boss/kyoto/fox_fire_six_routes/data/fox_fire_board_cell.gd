class_name FoxFireBoardCell
extends RefCounted

enum CellType {
	NORMAL,
	TORII,
	SAKURA,
	BAMBOO,
}

var position: Vector2i = Vector2i.ZERO
var type: CellType = CellType.NORMAL
var torii_id: int = -1
var visited_torii: bool = false
var has_white_fire: bool = false


func _init(
	cell_position: Vector2i = Vector2i.ZERO,
	cell_type: CellType = CellType.NORMAL,
	cell_torii_id: int = -1
) -> void:
	position = cell_position
	type = cell_type
	torii_id = cell_torii_id


func duplicate_cell() -> FoxFireBoardCell:
	var copy := FoxFireBoardCell.new(position, type, torii_id)
	copy.visited_torii = visited_torii
	copy.has_white_fire = has_white_fire
	return copy
