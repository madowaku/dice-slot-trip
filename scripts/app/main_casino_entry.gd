extends "res://scripts/app/main.gd"

const CasinoBankScript = preload("res://scripts/game/casino_bank.gd")
const CASINO_HUB_SCENE: PackedScene = preload("res://scenes/casino/CasinoHub.tscn")

var casino_hub_overlay: Control

func _render_stage_select() -> void:
	super._render_stage_select()
	_add_casino_entry_button()

func _add_casino_entry_button() -> void:
	if not is_instance_valid(root_stack):
		return
	if root_stack.has_node("CasinoEntryButton"):
		return
	var entry := _button(
		"LAS VEGAS CASINO　　CHIP %d" % CasinoBankScript.balance(),
		_open_casino_hub,
		true
	)
	entry.name = "CasinoEntryButton"
	entry.custom_minimum_size.y = 58
	root_stack.add_child(entry)

func _open_casino_hub() -> void:
	if is_instance_valid(casino_hub_overlay):
		return
	casino_hub_overlay = CASINO_HUB_SCENE.instantiate() as Control
	casino_hub_overlay.z_index = 500
	casino_hub_overlay.back_requested.connect(_close_casino_hub)
	add_child(casino_hub_overlay)

func _close_casino_hub() -> void:
	if is_instance_valid(casino_hub_overlay):
		casino_hub_overlay.queue_free()
	casino_hub_overlay = null
	call_deferred("show_stage_select")
