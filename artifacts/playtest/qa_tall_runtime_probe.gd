extends Control

const ScreenScene: PackedScene = preload("res://scenes/app/V06PlayScreen.tscn")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	OS.set_environment("DICE_QA_V06_SCENARIO", "atlas_18")
	var screen := ScreenScene.instantiate() as Control
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	for ignored: int in range(4):
		await get_tree().process_frame
	print("ROOT_SIZE=", size)
	print("VIEWPORT_RECT=", get_viewport_rect())
	print("SCREEN_RECT=", screen.get_global_rect())
	print("PAGE_RECT=", (screen.get_node("%Page") as Control).get_global_rect())
	print("HUD_RECT=", (screen.get_node("%HudPanel") as Control).get_global_rect())
	print("DOCK_RECT=", (screen.get_node("%ToolDock") as Control).get_global_rect())
	OS.set_environment("DICE_QA_V06_SCENARIO", "")
	get_tree().quit()
