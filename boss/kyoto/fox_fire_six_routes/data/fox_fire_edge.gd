class_name FoxFireEdge
extends RefCounted

var a: Vector2i = Vector2i.ZERO
var b: Vector2i = Vector2i.ZERO


func _init(first: Vector2i = Vector2i.ZERO, second: Vector2i = Vector2i.ZERO) -> void:
	if _position_precedes(second, first):
		a = second
		b = first
	else:
		a = first
		b = second


func key() -> String:
	return key_for(a, b)


func touches(position: Vector2i) -> bool:
	return a == position or b == position


func other(position: Vector2i) -> Vector2i:
	if position == a:
		return b
	if position == b:
		return a
	return Vector2i(-1, -1)


func to_snapshot() -> Dictionary:
	return {"a": a, "b": b}


static func key_for(first: Vector2i, second: Vector2i) -> String:
	var left: Vector2i = first
	var right: Vector2i = second
	if _position_precedes(second, first):
		left = second
		right = first
	return "%d,%d|%d,%d" % [left.x, left.y, right.x, right.y]


static func is_orthogonal_unit(first: Vector2i, second: Vector2i) -> bool:
	var delta: Vector2i = second - first
	return absi(delta.x) + absi(delta.y) == 1


static func _position_precedes(left: Vector2i, right: Vector2i) -> bool:
	return left.x < right.x or (left.x == right.x and left.y < right.y)
