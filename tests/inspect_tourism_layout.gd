extends SceneTree

const TourismMapViewScript = preload("res://scripts/game/tourism_map_view.gd")

func _init() -> void:
	for view_size: Vector2 in [Vector2(360, 250), Vector2(720, 390)]:
		var bounds := Rect2(Vector2.ZERO, view_size)
		var rects := TourismMapViewScript.tile_rects(view_size)
		print("LAYOUT ", view_size, " fits=", TourismMapViewScript.rects_fit_without_overlap(rects, bounds, 2.0))
		for index: int in range(rects.size()):
			if not bounds.encloses(rects[index]):
				print("OUT ", index, " rect=", rects[index])
			for other: int in range(index + 1, rects.size()):
				if rects[index].grow(1.0).intersects(rects[other].grow(1.0)):
					print("OVERLAP ", index, " / ", other)
	quit()
