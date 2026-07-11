class_name BossSystem
extends RefCounted

const DATA_PATH := "res://data/bosses/cairo_sphinxes.json"
const GAUGE_MAX := 100
const PRESENCE_MAX := 5
const ENCOUNTER_BASE := 0.10
const PRESENCE_STEP := 0.10
const RELIEF_STEP := 0.13
const RELIEF_FORCE_AFTER := 5
const PAIR_BONUS := 3

static func definitions() -> Array[Dictionary]:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Boss data could not be opened.")
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Boss data was invalid JSON.")
		return []
	var result: Array[Dictionary] = []
	for entry: Variant in (parsed as Dictionary).get("definitions", []):
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result

static func definition_by_id(definition_id: String, entries: Array[Dictionary] = []) -> Dictionary:
	var source := entries if not entries.is_empty() else definitions()
	for entry: Dictionary in source:
		if str(entry.get("id", "")) == definition_id:
			return entry.duplicate(true)
	return source[0].duplicate(true) if not source.is_empty() else {}

static func make_individual(definition: Dictionary, sequence: int) -> Dictionary:
	return {
		"individual_id": "%s-%03d" % [str(definition.get("id", "sleepy_sphinx")), sequence],
		"species_id": "cairo_sphinx",
		"definition_id": str(definition.get("id", "sleepy_sphinx")),
		"name": str(definition.get("name", "眠そうなスフィンクス")),
		"personality": str(definition.get("personality", "ゆっくり屋")),
		"gauge": 0,
		"encounters": 0,
		"stage": "guarded",
		"got": false,
		"registered_at": "",
		"registration_order": 0,
		"memo": str(definition.get("memo", ""))
	}

static func initial_individual(sequence: int = 1) -> Dictionary:
	return make_individual(definition_by_id("sleepy_sphinx"), sequence)

static func next_individual(previous_name: String, sequence: int, entries: Array[Dictionary] = []) -> Dictionary:
	var source := entries if not entries.is_empty() else definitions()
	if source.is_empty():
		return initial_individual(sequence)
	var start_index := posmod(sequence - 1, source.size())
	for offset: int in range(source.size()):
		var entry: Dictionary = source[posmod(start_index + offset, source.size())]
		if str(entry.get("name", "")) != previous_name:
			return make_individual(entry, sequence)
	return make_individual(source[0], sequence) if not source.is_empty() else initial_individual(sequence)

static func stage_for_gauge(gauge: int) -> String:
	if gauge >= GAUGE_MAX: return "joined"
	if gauge >= 75: return "trusting"
	if gauge >= 50: return "talking"
	if gauge >= 25: return "remembering"
	return "guarded"

static func encounter_chance(presence: int, relief: int) -> float:
	return minf(0.94, ENCOUNTER_BASE + PRESENCE_STEP * clampi(presence, 0, PRESENCE_MAX) + RELIEF_STEP * clampi(relief, 0, RELIEF_FORCE_AFTER))

static func should_encounter(presence: int, relief: int, forced: bool, roll: float) -> bool:
	return forced or relief >= RELIEF_FORCE_AFTER or roll < encounter_chance(presence, relief)

static func after_no_encounter(state: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	result["relief"] = mini(RELIEF_FORCE_AFTER, int(result.get("relief", 0)) + 1)
	return result

static func after_encounter(state: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	result["presence"] = maxi(0, int(result.get("presence", 0)) - 2)
	result["relief"] = 0
	return result

static func line_for(individual: Dictionary, definition: Dictionary, variant: int = 0) -> String:
	var stage := str(individual.get("stage", stage_for_gauge(int(individual.get("gauge", 0)))))
	var lines: Dictionary = definition.get("lines", {})
	var choices: Array = lines.get(stage, [])
	if choices.is_empty(): return str(lines.get("joined", "風が静かになった。"))
	return str(choices[posmod(variant, choices.size())])

static func resolve_interaction(individual: Dictionary, definition: Dictionary, action_index: int, pair_bonus: bool) -> Dictionary:
	var result := individual.duplicate(true)
	var actions: Array = definition.get("actions", [])
	var action: Dictionary = actions[clampi(action_index, 0, maxi(0, actions.size() - 1))] if not actions.is_empty() else {}
	var gain := 12 + int(action.get("bonus", 2)) + (PAIR_BONUS if pair_bonus else 0)
	var previous := clampi(int(result.get("gauge", 0)), 0, GAUGE_MAX)
	result["gauge"] = mini(GAUGE_MAX, previous + gain)
	result["encounters"] = int(result.get("encounters", 0)) + 1
	result["stage"] = stage_for_gauge(int(result["gauge"]))
	return {"individual": result, "gain": int(result["gauge"]) - previous, "action_label": str(action.get("label", "見守る")), "joined_now": previous < GAUGE_MAX and int(result["gauge"]) >= GAUGE_MAX}
