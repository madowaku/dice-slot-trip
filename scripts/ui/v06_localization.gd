class_name V06Localization
extends RefCounted

const DEFAULT_LOCALE := "ja"
const SUPPORTED_LOCALES := ["ja", "en"]


static func normalize_locale(locale: String) -> String:
	var normalized := locale.strip_edges().to_lower().replace("_", "-")
	if normalized.begins_with("en"):
		return "en"
	return DEFAULT_LOCALE


static func set_locale(locale: String) -> String:
	var normalized := normalize_locale(locale)
	TranslationServer.set_locale(normalized)
	return normalized


static func text(key: StringName) -> String:
	return str(TranslationServer.translate(key))
