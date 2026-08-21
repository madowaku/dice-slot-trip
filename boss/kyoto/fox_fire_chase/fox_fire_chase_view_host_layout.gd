extends "res://boss/kyoto/fox_fire_chase/fox_fire_chase_view.gd"

# The chase scene is embedded inside JourneyStageScreen. In that host, the
# Control's local size is already expressed in the game's logical coordinates,
# while get_viewport_rect() can report the physical half-resolution viewport.
# Scaling the authored 720x1280 composition from that physical viewport shrinks
# it a second time and pins the boss UI to the upper-left quarter.
#
# Use this View control's actual host size as the layout authority. Keep the
# base class bookkeeping in sync with the physical viewport/root so its process
# loop does not relayout every frame.


func _layout_composition() -> void:
	if design_root == null:
		return

	var host_size := size
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		host_size = get_parent_area_size()
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		host_size = get_viewport_rect().size
	if host_size.x <= 0.0 or host_size.y <= 0.0:
		return

	_layout_viewport_size = get_viewport_rect().size
	_layout_root_size = Vector2(get_tree().root.size)

	var scale_value := minf(host_size.x / DESIGN_SIZE.x, host_size.y / DESIGN_SIZE.y)
	if scale_value <= 0.0:
		scale_value = 1.0

	design_root.scale = Vector2(scale_value, scale_value)
	design_root.position = Vector2(
		(host_size.x - DESIGN_SIZE.x * scale_value) * 0.5,
		(host_size.y - DESIGN_SIZE.y * scale_value) * 0.5
	)
