extends SceneTree

const Parser = preload("res://tools/v1_yaml_subset.gd")
const VERSION := "1"
const OUTPUT := "res://data/generated/cairo_v1_runtime.json"
const SOURCES := ["res://data/stages/cairo_stage_v1.yaml", "res://data/bosses/cairo_boss_race_v1.yaml"]

func _init() -> void:
	var documents := {}
	var source_meta := []
	for path in SOURCES:
		var parser = Parser.new()
		var document = parser.parse_file(path)
		if document == null:
			printerr("%s: %s" % [path, parser.error_message]); quit(1); return
		documents[path.get_file()] = document
		source_meta.append({"path": path.trim_prefix("res://"), "sha256": FileAccess.get_sha256(path)})
	var bundle := {"generator_version": VERSION, "sources": source_meta, "documents": documents}
	var expected := JSON.stringify(bundle, "  ", false) + "\n"
	if "--check" in OS.get_cmdline_user_args():
		var file := FileAccess.open(OUTPUT, FileAccess.READ)
		if file == null or file.get_as_text() != expected:
			printerr("generated bundle is missing or stale: %s" % OUTPUT); quit(1); return
		print("v1 runtime data is current"); quit(0); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if output == null:
		printerr("cannot write %s" % OUTPUT); quit(1); return
	output.store_string(expected)
	print("generated %s" % OUTPUT)
	quit(0)
