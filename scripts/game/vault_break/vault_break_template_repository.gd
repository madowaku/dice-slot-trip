extends RefCounted
class_name VaultBreakTemplateRepository

## Loads and validates the complete v1 authoring document. Invalid data is
## rejected as a whole so a malformed vault can never silently enter rotation.

const DATA_PATH := "res://data/casino/vault_break_templates.json"
const VALID_TIERS: Array[String] = ["bronze", "silver", "gold", "black"]
const EXPECTED_TIER_COUNTS := {
	"bronze": 8,
	"silver": 8,
	"gold": 8,
	"black": 6,
}
const EXPECTED_TIER_CONFIGS := {
	"bronze": {"lock_count": 3, "max_rolls": 5, "payout_multiplier": 1.7, "first_template": "B01"},
	"silver": {"lock_count": 4, "max_rolls": 5, "payout_multiplier": 2.2, "first_template": "S05"},
	"gold": {"lock_count": 4, "max_rolls": 6, "payout_multiplier": 3.0, "first_template": "G01"},
	"black": {"lock_count": 3, "max_rolls": 5, "payout_multiplier": 5.5, "first_template": "K01"},
}

var source_data: Dictionary = {}
var templates_by_id: Dictionary = {}
var templates_by_tier: Dictionary = {}
var tier_config: Dictionary = {}
var lock_rules: Dictionary = {}
var selection_rules: Dictionary = {}
var rules: Dictionary = {}
var validation_errors: Array[String] = []

func load_default() -> bool:
	return load_from_file(DATA_PATH)

func load_from_file(path: String = DATA_PATH) -> bool:
	_clear_loaded_data()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		validation_errors.append("Unable to open %s" % path)
		return false
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		validation_errors.append("JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false
	if not json.data is Dictionary:
		validation_errors.append("Root JSON value must be a Dictionary")
		return false
	return load_from_data(json.data as Dictionary)

func load_from_data(candidate_data: Dictionary) -> bool:
	_clear_loaded_data()
	_validate_source(candidate_data)
	if not validation_errors.is_empty():
		return false
	source_data = candidate_data.duplicate(true)
	rules = (source_data.get("rules", {}) as Dictionary).duplicate(true)
	lock_rules = (source_data.get("lock_rules", {}) as Dictionary).duplicate(true)
	tier_config = (source_data.get("tiers", {}) as Dictionary).duplicate(true)
	selection_rules = (source_data.get("selection_rules", {}) as Dictionary).duplicate(true)
	for tier: String in VALID_TIERS:
		templates_by_tier[tier] = []
	var authored_templates: Array = source_data.get("templates", []) as Array
	for template_value: Variant in authored_templates:
		var template: Dictionary = (template_value as Dictionary).duplicate(true)
		var template_id := str(template.get("id", ""))
		var tier := str(template.get("tier", ""))
		templates_by_id[template_id] = template
		var tier_templates: Array = templates_by_tier.get(tier, []) as Array
		tier_templates.append(template)
		templates_by_tier[tier] = tier_templates
	return true

func is_loaded() -> bool:
	return validation_errors.is_empty() and templates_by_id.size() == 30

func get_template(template_id: String) -> Dictionary:
	if not templates_by_id.has(template_id):
		return {}
	return (templates_by_id.get(template_id, {}) as Dictionary).duplicate(true)

func get_templates_for_tier(tier: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var authored: Array = templates_by_tier.get(tier, []) as Array
	for template_value: Variant in authored:
		result.append((template_value as Dictionary).duplicate(true))
	return result

func get_tier_config(tier: String) -> Dictionary:
	if not tier_config.has(tier):
		return {}
	return (tier_config.get(tier, {}) as Dictionary).duplicate(true)

func get_template_ids_for_tier(tier: String) -> Array[String]:
	var result: Array[String] = []
	for template: Dictionary in get_templates_for_tier(tier):
		result.append(str(template.get("id", "")))
	return result

func _clear_loaded_data() -> void:
	source_data.clear()
	templates_by_id.clear()
	templates_by_tier.clear()
	tier_config.clear()
	lock_rules.clear()
	selection_rules.clear()
	rules.clear()
	validation_errors.clear()

func _validate_source(candidate_data: Dictionary) -> void:
	if int(candidate_data.get("schema_version", 0)) != 1:
		validation_errors.append("schema_version must be 1")
	if str(candidate_data.get("game_id", "")) != "vault_break":
		validation_errors.append("game_id must be vault_break")
	for required_key: String in ["rules", "lock_rules", "tiers", "selection_rules"]:
		if not candidate_data.get(required_key) is Dictionary:
			validation_errors.append("%s must be a Dictionary" % required_key)
	if not candidate_data.get("templates") is Array:
		validation_errors.append("templates must be an Array")
	if not validation_errors.is_empty():
		return

	var candidate_rules: Dictionary = candidate_data.get("rules", {}) as Dictionary
	_validate_game_rules(candidate_rules)
	var candidate_lock_rules: Dictionary = candidate_data.get("lock_rules", {}) as Dictionary
	_validate_lock_rules(candidate_lock_rules)
	var candidate_tiers: Dictionary = candidate_data.get("tiers", {}) as Dictionary
	_validate_tiers(candidate_tiers)
	var candidate_selection: Dictionary = candidate_data.get("selection_rules", {}) as Dictionary
	_validate_selection_rules(candidate_selection)
	var candidate_templates: Array = candidate_data.get("templates", []) as Array
	_validate_templates(candidate_templates, candidate_lock_rules, candidate_tiers)

func _validate_game_rules(candidate_rules: Dictionary) -> void:
	if int(candidate_rules.get("die_sides", 0)) != 6:
		validation_errors.append("rules.die_sides must be 6")
	var bets: Array = candidate_rules.get("bet_options", []) as Array
	if bets.size() != 3 or int(bets[0]) != 10 or int(bets[1]) != 20 or int(bets[2]) != 50:
		validation_errors.append("rules.bet_options must be [10, 20, 50]")
	if not bool(candidate_rules.get("allow_discard", false)):
		validation_errors.append("rules.allow_discard must be true")
	if bool(candidate_rules.get("locked_dice_movable", true)):
		validation_errors.append("rules.locked_dice_movable must be false")
	if not bool(candidate_rules.get("auto_discard_if_no_valid_lock", false)):
		validation_errors.append("rules.auto_discard_if_no_valid_lock must be true")
	if str(candidate_rules.get("reward_rounding", "")) != "floor":
		validation_errors.append("rules.reward_rounding must be floor")

func _validate_lock_rules(candidate_lock_rules: Dictionary) -> void:
	var expected_names: Array[String] = ["low", "high", "odd", "even", "edge", "exact"]
	for rule_name: String in expected_names:
		if not candidate_lock_rules.get(rule_name) is Dictionary:
			validation_errors.append("lock rule %s is missing" % rule_name)
			continue
		var definition: Dictionary = candidate_lock_rules.get(rule_name, {}) as Dictionary
		if rule_name == "exact":
			if str(definition.get("mode", "")) != "exact":
				validation_errors.append("lock rule exact must use exact mode")
			continue
		if not definition.get("accepted_faces") is Array:
			validation_errors.append("lock rule %s needs accepted_faces" % rule_name)
			continue
		var accepted_faces: Array = definition.get("accepted_faces", []) as Array
		if accepted_faces.is_empty():
			validation_errors.append("lock rule %s has no accepted faces" % rule_name)
		for face_value: Variant in accepted_faces:
			if not _is_integer_number(face_value) or int(face_value) < 1 or int(face_value) > 6:
				validation_errors.append("lock rule %s contains an invalid face" % rule_name)

func _validate_tiers(candidate_tiers: Dictionary) -> void:
	for tier: String in VALID_TIERS:
		if not candidate_tiers.get(tier) is Dictionary:
			validation_errors.append("tier %s is missing" % tier)
			continue
		var config: Dictionary = candidate_tiers.get(tier, {}) as Dictionary
		var expected: Dictionary = EXPECTED_TIER_CONFIGS.get(tier, {}) as Dictionary
		if int(config.get("lock_count", 0)) != int(expected.get("lock_count", 0)):
			validation_errors.append("tier %s has an invalid lock_count" % tier)
		if int(config.get("max_rolls", 0)) != int(expected.get("max_rolls", 0)):
			validation_errors.append("tier %s has an invalid max_rolls" % tier)
		if not _is_number(config.get("payout_multiplier")) or not is_equal_approx(float(config.get("payout_multiplier", 0.0)), float(expected.get("payout_multiplier", 0.0))):
			validation_errors.append("tier %s has an invalid payout_multiplier" % tier)
		if str(config.get("first_template", "")) != str(expected.get("first_template", "")):
			validation_errors.append("tier %s has an invalid first_template" % tier)
		if not config.get("unlock") is Dictionary:
			validation_errors.append("tier %s needs an unlock rule" % tier)
	if candidate_tiers.size() != VALID_TIERS.size():
		validation_errors.append("tiers must contain exactly bronze, silver, gold, and black")
	var black: Dictionary = candidate_tiers.get("black", {}) as Dictionary
	if not bool(black.get("exact_only", false)):
		validation_errors.append("black tier must be exact_only")
	if not black.get("special_spawn") is Dictionary:
		validation_errors.append("black tier needs special_spawn")
	else:
		var spawn: Dictionary = black.get("special_spawn", {}) as Dictionary
		if not _is_number(spawn.get("base_chance")) or not is_equal_approx(float(spawn.get("base_chance", 0.0)), 0.15):
			validation_errors.append("black base_chance must be 0.15")
		if int(spawn.get("guaranteed_after_eligible_games", 0)) != 7:
			validation_errors.append("black guaranteed ceiling must be 7")
		if int(spawn.get("cooldown_games_after_attempt", 0)) != 2:
			validation_errors.append("black cooldown must be 2")

func _validate_selection_rules(candidate_selection: Dictionary) -> void:
	if int(candidate_selection.get("recent_template_exclusion", 0)) != 2:
		validation_errors.append("recent template exclusion must be 2")
	if int(candidate_selection.get("max_same_structure_in_a_row", 0)) != 2:
		validation_errors.append("same-structure limit must be 2")
	if not _is_number(candidate_selection.get("default_weight")) or float(candidate_selection.get("default_weight", 0.0)) <= 0.0:
		validation_errors.append("default_weight must be positive")

func _validate_templates(candidate_templates: Array, candidate_lock_rules: Dictionary, candidate_tiers: Dictionary) -> void:
	if candidate_templates.size() != 30:
		validation_errors.append("templates must contain exactly 30 entries")
	var seen_ids: Dictionary = {}
	var tier_counts := {"bronze": 0, "silver": 0, "gold": 0, "black": 0}
	var tier_by_id: Dictionary = {}
	for index: int in candidate_templates.size():
		var template_value: Variant = candidate_templates[index]
		if not template_value is Dictionary:
			validation_errors.append("template %d must be a Dictionary" % index)
			continue
		var template: Dictionary = template_value as Dictionary
		var template_id := str(template.get("id", ""))
		var tier := str(template.get("tier", ""))
		if template_id.is_empty():
			validation_errors.append("template %d has no id" % index)
		elif seen_ids.has(template_id):
			validation_errors.append("duplicate template id %s" % template_id)
		else:
			seen_ids[template_id] = true
			tier_by_id[template_id] = tier
		if tier not in VALID_TIERS:
			validation_errors.append("template %s has invalid tier %s" % [template_id, tier])
			continue
		tier_counts[tier] = int(tier_counts.get(tier, 0)) + 1
		if str(template.get("structure_group", "")).is_empty():
			validation_errors.append("template %s has no structure_group" % template_id)
		if not _is_number(template.get("weight")) or float(template.get("weight", 0.0)) <= 0.0:
			validation_errors.append("template %s weight must be positive" % template_id)
		if not template.get("locks") is Array:
			validation_errors.append("template %s locks must be an Array" % template_id)
			continue
		var locks: Array = template.get("locks", []) as Array
		var max_rolls := int(template.get("max_rolls", 0))
		if max_rolls < locks.size():
			validation_errors.append("template %s max_rolls is below its lock count" % template_id)
		var config: Dictionary = candidate_tiers.get(tier, {}) as Dictionary
		if locks.size() != int(config.get("lock_count", -1)):
			validation_errors.append("template %s lock count disagrees with its tier" % template_id)
		if max_rolls != int(config.get("max_rolls", -1)):
			validation_errors.append("template %s max_rolls disagrees with its tier" % template_id)
		for lock_index: int in locks.size():
			_validate_lock(template_id, lock_index, locks[lock_index], tier, candidate_lock_rules)
		_validate_balance(template_id, template.get("balance"))

	for tier: String in VALID_TIERS:
		if int(tier_counts.get(tier, 0)) != int(EXPECTED_TIER_COUNTS.get(tier, 0)):
			validation_errors.append("tier %s has an invalid template count" % tier)
		var config: Dictionary = candidate_tiers.get(tier, {}) as Dictionary
		var first_template := str(config.get("first_template", ""))
		if not tier_by_id.has(first_template):
			validation_errors.append("tier %s first_template does not exist" % tier)
		elif str(tier_by_id.get(first_template, "")) != tier:
			validation_errors.append("tier %s first_template belongs to another tier" % tier)

func _validate_lock(template_id: String, lock_index: int, lock_value: Variant, tier: String, candidate_lock_rules: Dictionary) -> void:
	if not lock_value is Dictionary:
		validation_errors.append("template %s lock %d must be a Dictionary" % [template_id, lock_index])
		return
	var lock: Dictionary = lock_value as Dictionary
	var rule_name := str(lock.get("rule", ""))
	if not candidate_lock_rules.has(rule_name):
		validation_errors.append("template %s lock %d uses unknown rule %s" % [template_id, lock_index, rule_name])
		return
	if tier == "black" and rule_name != "exact":
		validation_errors.append("black template %s must contain only exact locks" % template_id)
	if rule_name == "exact":
		var value: Variant = lock.get("value")
		if not _is_integer_number(value) or int(value) < 1 or int(value) > 6:
			validation_errors.append("template %s lock %d has an invalid exact value" % [template_id, lock_index])
	elif lock.has("value"):
		validation_errors.append("template %s lock %d has an unnecessary value" % [template_id, lock_index])

func _validate_balance(template_id: String, balance_value: Variant) -> void:
	if not balance_value is Dictionary:
		validation_errors.append("template %s needs balance metadata" % template_id)
		return
	var balance: Dictionary = balance_value as Dictionary
	var success_rate: Variant = balance.get("optimal_success_rate")
	var reference_rtp: Variant = balance.get("reference_rtp")
	if not _is_number(success_rate) or float(success_rate) < 0.0 or float(success_rate) > 1.0:
		validation_errors.append("template %s has an invalid optimal_success_rate" % template_id)
	if not _is_number(reference_rtp) or float(reference_rtp) < 0.0 or float(reference_rtp) > 1.5:
		validation_errors.append("template %s has an invalid reference_rtp" % template_id)

func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func _is_integer_number(value: Variant) -> bool:
	if not _is_number(value):
		return false
	return is_equal_approx(float(value), float(int(value)))
