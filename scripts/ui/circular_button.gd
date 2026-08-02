class_name CircularButton
extends Button


func _has_point(point: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	var radius := minf(size.x, size.y) * 0.5
	return point.distance_to(size * 0.5) <= radius
