extends RefCounted
class_name VaultBreakProgress

## Pure VAULT BREAK progression and BLACK-vault lifecycle. `serialize()` always
## returns a JSON-ready v1 Dictionary and never exposes this object's live data.

signal tier_unlocked(tier: String)
signal black_vault_spawned(template_id: String)
signal progress_changed()

const SCHEMA_VERSION := 1
const TIERS: Array[String] = ["bronze", "silver", "gold", "black"]
const NORMAL_TIERS: Array[String] = ["bronze", "silver", "gold"]
const BLACK_BASE_CHANCE := 0.15
const BLACK_GUARANTEED_AFTER_ELIGIBLE_GAMES := 7
const BLACK_COOLDOWN_GAMES_AFTER_ATTEMPT := 2

var data: Dictionary = {}
var spawn_rng := RandomNumberGenerator.new()
var spawn_random_provider := Callable()

func _init(initial_progress: Variant = null) -> void:
	data = normalize_progress(initial_progress)
	spawn_rng.randomize()

static func default_progress() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"tiers": {
			"bronze": _default_tier_progress(true),
			"silver": _default_tier_progress(true),
			"gold": _default_tier_progress(true),
			"black": _default_tier_progress(false),
		},
		"black_spawn": {
			"active_template_id": "",
			"eligible_games": 0,
			"cooldown_remaining": 0,
		},
		"template_stats": {},
	}

static func normalize_progress(raw_progress: Variant) -> Dictionary:
	var normalized := default_progress()
	if not raw_progress is Dictionary:
		return normalized
	var raw: Dictionary = raw_progress as Dictionary
	var normalized_tiers: Dictionary = normalized.get("tiers", {}) as Dictionary
	var raw_tiers: Dictionary = raw.get("tiers", {}) as Dictionary
	for tier: String in TIERS:
		var raw_tier: Dictionary = {}
		if raw_tiers.get(tier) is Dictionary:
			raw_tier = raw_tiers.get(tier, {}) as Dictionary
		normalized_tiers[tier] = _normalize_tier_progress(raw_tier, tier != "black")
	normalized["tiers"] = normalized_tiers

	var raw_spawn: Dictionary = {}
	if raw.get("black_spawn") is Dictionary:
		raw_spawn = raw.get("black_spawn", {}) as Dictionary
	normalized["black_spawn"] = {
		"active_template_id": str(raw_spawn.get("active_template_id", "")),
		"eligible_games": maxi(0, _safe_int(raw_spawn.get("eligible_games", 0))),
		"cooldown_remaining": clampi(_safe_int(raw_spawn.get("cooldown_remaining", 0)), 0, BLACK_COOLDOWN_GAMES_AFTER_ATTEMPT),
	}

	var normalized_stats: Dictionary = {}
	if raw.get("template_stats") is Dictionary:
		var raw_stats: Dictionary = raw.get("template_stats", {}) as Dictionary
		for template_id_value: Variant in raw_stats.keys():
			var template_id := str(template_id_value)
			if template_id.is_empty() or not raw_stats.get(template_id_value) is Dictionary:
				continue
			var raw_entry: Dictionary = raw_stats.get(template_id_value, {}) as Dictionary
			var plays := maxi(0, _safe_int(raw_entry.get("plays", 0)))
			var wins := clampi(_safe_int(raw_entry.get("wins", 0)), 0, plays)
			normalized_stats[template_id] = {"plays": plays, "wins": wins}
	normalized["template_stats"] = normalized_stats
	return normalized

static func normalize_from_json(json_text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(json_text)
	return normalize_progress(parsed)

func load_progress(raw_progress: Variant) -> void:
	data = normalize_progress(raw_progress)
	progress_changed.emit()

func serialize() -> Dictionary:
	return normalize_progress(data).duplicate(true)

func to_save_data() -> Dictionary:
	return serialize()

func to_json() -> String:
	return JSON.stringify(serialize())

func set_spawn_rng(custom_rng: RandomNumberGenerator) -> void:
	if custom_rng != null:
		spawn_rng = custom_rng

func set_spawn_random_provider(provider: Callable) -> void:
	spawn_random_provider = provider

func get_tier_stats(tier: String) -> Dictionary:
	var tiers: Dictionary = data.get("tiers", {}) as Dictionary
	if not tiers.get(tier) is Dictionary:
		return {}
	return (tiers.get(tier, {}) as Dictionary).duplicate(true)

func get_wins(tier: String) -> int:
	return int(get_tier_stats(tier).get("wins", 0))

func is_first_play_done(tier: String) -> bool:
	return bool(get_tier_stats(tier).get("first_play_done", false))

func is_tier_unlocked(tier: String) -> bool:
	match tier:
		"bronze":
			return true
		"silver":
			return get_wins("bronze") >= 1
		"gold":
			return get_wins("silver") >= 2
		"black":
			return get_wins("gold") >= 1
	return false

func get_active_black_template_id() -> String:
	var spawn: Dictionary = data.get("black_spawn", {}) as Dictionary
	return str(spawn.get("active_template_id", ""))

func record_template_result(template: Dictionary, won: bool) -> bool:
	return record_game_result(
		str(template.get("tier", "")),
		str(template.get("id", "")),
		str(template.get("structure_group", "")),
		won
	)

func record_game_result(tier: String, template_id: String, structure_group: String, won: bool) -> bool:
	if tier not in TIERS or template_id.is_empty():
		return false
	var unlock_before: Dictionary = {}
	for candidate_tier: String in TIERS:
		unlock_before[candidate_tier] = is_tier_unlocked(candidate_tier)

	var tiers: Dictionary = data.get("tiers", {}) as Dictionary
	var tier_stats: Dictionary = tiers.get(tier, {}) as Dictionary
	tier_stats["plays"] = int(tier_stats.get("plays", 0)) + 1
	if won:
		tier_stats["wins"] = int(tier_stats.get("wins", 0)) + 1
	tier_stats["first_play_done"] = true
	tier_stats["recent_template_ids"] = _append_recent(tier_stats.get("recent_template_ids", []), template_id)
	if tier in NORMAL_TIERS:
		tier_stats["recent_structure_groups"] = _append_recent(tier_stats.get("recent_structure_groups", []), structure_group)
	tiers[tier] = tier_stats
	data["tiers"] = tiers

	var template_stats: Dictionary = data.get("template_stats", {}) as Dictionary
	var entry: Dictionary = {}
	if template_stats.get(template_id) is Dictionary:
		entry = template_stats.get(template_id, {}) as Dictionary
	entry["plays"] = int(entry.get("plays", 0)) + 1
	if won:
		entry["wins"] = int(entry.get("wins", 0)) + 1
	else:
		entry["wins"] = int(entry.get("wins", 0))
	template_stats[template_id] = entry
	data["template_stats"] = template_stats

	if tier == "black":
		_apply_black_attempt_finished()

	for candidate_tier: String in TIERS:
		if not bool(unlock_before.get(candidate_tier, false)) and is_tier_unlocked(candidate_tier):
			tier_unlocked.emit(candidate_tier)
	progress_changed.emit()
	return true

## Convenience for a complete result transaction. Stats/history are updated
## before the BLACK eligibility check, so a first GOLD win can spawn BLACK.
func complete_game(template: Dictionary, won: bool, selector: Variant = null, spawn_chance_value: Variant = null, black_selection_value: Variant = null) -> String:
	var tier := str(template.get("tier", ""))
	if not record_template_result(template, won):
		return ""
	if tier in NORMAL_TIERS and selector != null:
		return after_normal_game_completed(selector, spawn_chance_value, black_selection_value)
	return ""

## Returns only a newly spawned template id. An already-active BLACK vault is
## deliberately left unchanged and returns an empty string.
func after_normal_game_completed(selector: Variant, spawn_chance_value: Variant = null, black_selection_value: Variant = null) -> String:
	if not is_tier_unlocked("black"):
		return ""
	if not get_active_black_template_id().is_empty():
		return ""
	if selector == null or not selector.has_method("select_template"):
		return ""

	var spawn: Dictionary = data.get("black_spawn", {}) as Dictionary
	var cooldown := int(spawn.get("cooldown_remaining", 0))
	if cooldown > 0:
		spawn["cooldown_remaining"] = cooldown - 1
		data["black_spawn"] = spawn
		progress_changed.emit()
		return ""

	var eligible_games := int(spawn.get("eligible_games", 0)) + 1
	spawn["eligible_games"] = eligible_games
	var guaranteed := eligible_games >= BLACK_GUARANTEED_AFTER_ELIGIBLE_GAMES
	var should_spawn := guaranteed
	if not guaranteed:
		should_spawn = _resolve_spawn_random_value(spawn_chance_value) < BLACK_BASE_CHANCE
	if not should_spawn:
		data["black_spawn"] = spawn
		progress_changed.emit()
		return ""

	var selected_value: Variant = selector.call("select_template", "black", data, black_selection_value)
	if not selected_value is Dictionary:
		data["black_spawn"] = spawn
		progress_changed.emit()
		return ""
	var selected: Dictionary = selected_value as Dictionary
	var template_id := str(selected.get("id", ""))
	if template_id.is_empty():
		data["black_spawn"] = spawn
		progress_changed.emit()
		return ""
	spawn["active_template_id"] = template_id
	spawn["eligible_games"] = 0
	data["black_spawn"] = spawn
	black_vault_spawned.emit(template_id)
	progress_changed.emit()
	return template_id

func finish_black_attempt() -> void:
	_apply_black_attempt_finished()
	progress_changed.emit()

func _apply_black_attempt_finished() -> void:
	var spawn: Dictionary = data.get("black_spawn", {}) as Dictionary
	spawn["active_template_id"] = ""
	spawn["eligible_games"] = 0
	spawn["cooldown_remaining"] = BLACK_COOLDOWN_GAMES_AFTER_ATTEMPT
	data["black_spawn"] = spawn

func _resolve_spawn_random_value(explicit_value: Variant) -> float:
	if typeof(explicit_value) == TYPE_INT or typeof(explicit_value) == TYPE_FLOAT:
		return clampf(float(explicit_value), 0.0, 1.0)
	if spawn_random_provider.is_valid():
		var provided: Variant = spawn_random_provider.call()
		if typeof(provided) == TYPE_INT or typeof(provided) == TYPE_FLOAT:
			return clampf(float(provided), 0.0, 1.0)
	return spawn_rng.randf()

static func _default_tier_progress(include_structures: bool) -> Dictionary:
	var result := {
		"plays": 0,
		"wins": 0,
		"first_play_done": false,
		"recent_template_ids": [],
	}
	if include_structures:
		result["recent_structure_groups"] = []
	return result

static func _normalize_tier_progress(raw_tier: Dictionary, include_structures: bool) -> Dictionary:
	var plays := maxi(0, _safe_int(raw_tier.get("plays", 0)))
	var wins := clampi(_safe_int(raw_tier.get("wins", 0)), 0, plays)
	var result := {
		"plays": plays,
		"wins": wins,
		"first_play_done": bool(raw_tier.get("first_play_done", false)),
		"recent_template_ids": _normalize_recent(raw_tier.get("recent_template_ids", [])),
	}
	if include_structures:
		result["recent_structure_groups"] = _normalize_recent(raw_tier.get("recent_structure_groups", []))
	return result

static func _normalize_recent(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value as Array:
			var text := str(item)
			if not text.is_empty():
				result.append(text)
	while result.size() > 2:
		result.pop_front()
	return result

static func _append_recent(existing: Variant, value: String) -> Array[String]:
	var result := _normalize_recent(existing)
	if not value.is_empty():
		result.append(value)
	while result.size() > 2:
		result.pop_front()
	return result

static func _safe_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)
	return 0
