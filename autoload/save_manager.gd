extends Node

const SAVE_PATH: String = "user://dice_slot_trip_save.json"

func save_now() -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Autosave could not open the save file.")
		return false
	file.store_string(JSON.stringify(GameState.to_dictionary(), "  "))
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_now() -> bool:
	if not has_save():
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Save data was invalid; starting safely with defaults.")
		return false
	GameState.apply_dictionary(parsed as Dictionary)
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		# The V06 session owns its separate checkpoint while the released 58-space
		# screen is active. Keep the legacy manager intact for the 90-space game,
		# but do not let its lifecycle save overwrite V06's product session.
		if not get_tree().get_nodes_in_group("v06_session_screen").is_empty():
			return
		save_now()
