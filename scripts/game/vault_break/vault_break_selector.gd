extends RefCounted
class_name VaultBreakSelector

## Deterministic, tier-local template selection. Candidate ordering is sorted
## by template id before weighting, so the same injected value is stable even
## if a repository was assembled from a Dictionary in a different order.

const NORMAL_TIERS: Array[String] = ["bronze", "silver", "gold"]

var repository: RefCounted = null
var rng := RandomNumberGenerator.new()
var random_provider := Callable()

func _init(template_repository: RefCounted = null) -> void:
	repository = template_repository
	rng.randomize()

func set_repository(template_repository: RefCounted) -> void:
	repository = template_repository

func set_rng(custom_rng: RandomNumberGenerator) -> void:
	if custom_rng != null:
		rng = custom_rng

func set_random_provider(provider: Callable) -> void:
	random_provider = provider

func select_template(tier: String, progress: Variant, random_value: Variant = null) -> Dictionary:
	if not _repository_ready() or tier not in ["bronze", "silver", "gold", "black"]:
		return {}
	var stats := _get_tier_stats(progress, tier)
	if not bool(stats.get("first_play_done", false)):
		var config: Dictionary = repository.call("get_tier_config", tier) as Dictionary
		return repository.call("get_template", str(config.get("first_template", ""))) as Dictionary
	var pool := candidate_pool(tier, progress)
	var candidates: Array[Dictionary] = pool.get("candidates", []) as Array[Dictionary]
	return weighted_select(candidates, _resolve_random_value(random_value))

func candidate_pool(tier: String, progress: Variant) -> Dictionary:
	if not _repository_ready():
		return {"candidates": [], "fallback_level": "invalid"}
	var all_candidates: Array[Dictionary] = repository.call("get_templates_for_tier", tier) as Array[Dictionary]
	all_candidates.sort_custom(_template_id_before)
	if all_candidates.is_empty():
		return {"candidates": [], "fallback_level": "invalid"}

	var stats := _get_tier_stats(progress, tier)
	var recent_ids := _string_array(stats.get("recent_template_ids", []), 2)
	var recent_structures := _string_array(stats.get("recent_structure_groups", []), 2)
	var blocked_structure := ""
	if tier in NORMAL_TIERS and recent_structures.size() >= 2:
		var latest := recent_structures[recent_structures.size() - 1]
		var previous := recent_structures[recent_structures.size() - 2]
		if latest == previous:
			blocked_structure = latest

	var candidates := _filter_candidates(all_candidates, recent_ids, blocked_structure)
	if not candidates.is_empty():
		return {"candidates": candidates, "fallback_level": "A"}

	candidates = _filter_candidates(all_candidates, recent_ids, "")
	if not candidates.is_empty():
		return {"candidates": candidates, "fallback_level": "B"}

	var last_one: Array[String] = []
	if not recent_ids.is_empty():
		last_one.append(recent_ids[recent_ids.size() - 1])
	candidates = _filter_candidates(all_candidates, last_one, "")
	if not candidates.is_empty():
		return {"candidates": candidates, "fallback_level": "C"}

	return {"candidates": all_candidates, "fallback_level": "D"}

func candidate_ids(tier: String, progress: Variant) -> Array[String]:
	var result: Array[String] = []
	var pool := candidate_pool(tier, progress)
	var candidates: Array[Dictionary] = pool.get("candidates", []) as Array[Dictionary]
	for template: Dictionary in candidates:
		result.append(str(template.get("id", "")))
	return result

func weighted_select(candidates: Array[Dictionary], random_value: float) -> Dictionary:
	if candidates.is_empty():
		return {}
	var stable_candidates := candidates.duplicate(true)
	stable_candidates.sort_custom(_template_id_before)
	var total_weight := 0.0
	for template: Dictionary in stable_candidates:
		total_weight += maxf(0.0, float(template.get("weight", 0.0)))
	if total_weight <= 0.0:
		return {}
	var normalized := clampf(random_value, 0.0, 1.0)
	if normalized >= 1.0:
		return stable_candidates[stable_candidates.size() - 1].duplicate(true)
	var target := normalized * total_weight
	var cumulative := 0.0
	for template: Dictionary in stable_candidates:
		cumulative += maxf(0.0, float(template.get("weight", 0.0)))
		if target < cumulative:
			return template.duplicate(true)
	return stable_candidates[stable_candidates.size() - 1].duplicate(true)

func _repository_ready() -> bool:
	return repository != null and repository.has_method("get_templates_for_tier") and repository.has_method("get_tier_config")

func _get_tier_stats(progress: Variant, tier: String) -> Dictionary:
	if progress is Dictionary:
		var progress_data: Dictionary = progress as Dictionary
		var tiers: Dictionary = progress_data.get("tiers", {}) as Dictionary
		if tiers.get(tier) is Dictionary:
			return (tiers.get(tier, {}) as Dictionary).duplicate(true)
	if progress != null and progress.has_method("get_tier_stats"):
		var stats_value: Variant = progress.call("get_tier_stats", tier)
		if stats_value is Dictionary:
			return (stats_value as Dictionary).duplicate(true)
	return {
		"first_play_done": false,
		"recent_template_ids": [],
		"recent_structure_groups": [],
	}

func _filter_candidates(all_candidates: Array[Dictionary], excluded_ids: Array[String], blocked_structure: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for template: Dictionary in all_candidates:
		if str(template.get("id", "")) in excluded_ids:
			continue
		if not blocked_structure.is_empty() and str(template.get("structure_group", "")) == blocked_structure:
			continue
		result.append(template.duplicate(true))
	return result

func _string_array(value: Variant, maximum_size: int) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value as Array:
			var text := str(item)
			if not text.is_empty():
				result.append(text)
	while result.size() > maximum_size:
		result.pop_front()
	return result

func _resolve_random_value(explicit_value: Variant) -> float:
	if typeof(explicit_value) == TYPE_INT or typeof(explicit_value) == TYPE_FLOAT:
		return clampf(float(explicit_value), 0.0, 1.0)
	if random_provider.is_valid():
		var provided: Variant = random_provider.call()
		if typeof(provided) == TYPE_INT or typeof(provided) == TYPE_FLOAT:
			return clampf(float(provided), 0.0, 1.0)
	return rng.randf()

func _template_id_before(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("id", "")) < str(right.get("id", ""))
