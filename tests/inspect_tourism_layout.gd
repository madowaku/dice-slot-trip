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
		var reserved := TourismMapViewScript.map_dice_reserved_rect(view_size)
		var player := TourismMapViewScript.player_rect(view_size)
		for level: int in [0, 3]:
			var props := TourismMapViewScript.market_prop_specs(view_size, 0, level)
			print("PROPS level=", level, " clear=", TourismMapViewScript.prop_specs_are_clear(props, view_size))
			for prop: Dictionary in props:
				var prop_rect: Rect2 = prop["rect"]
				if prop_rect.intersects(reserved):
					print("PROP RESERVED ", prop["id"])
				if prop_rect.intersects(player):
					print("PROP PLAYER ", prop["id"])
				for tile_index: int in range(rects.size()):
					if prop_rect.intersects(rects[tile_index]):
						print("PROP TILE ", prop["id"], " / ", tile_index)
	quit()
