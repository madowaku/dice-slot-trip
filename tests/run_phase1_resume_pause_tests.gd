extends SceneTree

const ScreenScene: PackedScene = preload("res://scenes/app/JourneyStageScreen.tscn")
const JourneySaveManagerScript = preload("res://scripts/game/journey_save_manager.gd")
const AmazonJourneyScript = preload("res://scripts/game/amazon_journey.gd")
const StageCatalogScript = preload("res://scripts/game/stage_catalog.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_save()
	_expect(JourneySaveManagerScript.saved_stage_ids().is_empty(), "fresh environment exposes no journey continues")

	var seed_journey := AmazonJourneyScript.new()
	seed_journey.coins = 77
	seed_journey.current_space_id = "main:12"
	var manager := JourneySaveManagerScript.new()
	_expect(manager.save(StageCatalogScript.STAGE_AMAZON, seed_journey.snapshot()), "journey snapshot writes through the shared save manager")

	var ids := JourneySaveManagerScript.saved_stage_ids()
	_expect(ids.size() == 1 and ids[0] == &"amazon_suiu_falls", "title continue candidates discover the saved stage")

	var host := Control.new()
	host.size = Vector2(720, 1280)
	root.add_child(host)
	var screen := ScreenScene.instantiate()
	screen.configure_start_context(StageCatalogScript.STAGE_AMAZON, true)
	host.add_child(screen)
	await process_frame
	await process_frame

	_expect(screen.journey != null and screen.journey.coins == 77, "resume restores saved coins during ready")
	_expect(screen.journey != null and screen.journey.current_space_id == "main:12", "resume restores the saved space id")

	if screen.journey != null:
		screen.journey.coins = 88
	screen._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var reloaded := manager.load_for_stage(StageCatalogScript.STAGE_AMAZON)
	_expect(int((reloaded.get("journey", {}) as Dictionary).get("coins", -1)) == 88, "application pause persists journey progress silently")

	host.queue_free()
	await process_frame
	_cleanup_save()
	_expect(JourneySaveManagerScript.saved_stage_ids().is_empty(), "cleanup clears resume discovery state")
	print("PHASE1_TESTS failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _cleanup_save() -> void:
	const SAVE_PATH := "user://journey_stage_v1.json"
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS %s" % label)
	else:
		failures += 1
		push_error("FAIL %s" % label)
