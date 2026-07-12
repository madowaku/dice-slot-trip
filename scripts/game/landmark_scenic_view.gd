class_name LandmarkScenicView
extends RefCounted

const SPICE_MARKET_TEXTURES: Array[Texture2D] = [
	preload("res://assets/art/landmarks/cairo/spice_market_lv0.png"),
	preload("res://assets/art/landmarks/cairo/spice_market_lv1.png"),
	preload("res://assets/art/landmarks/cairo/spice_market_lv2.png"),
	preload("res://assets/art/landmarks/cairo/spice_market_lv3.png"),
]
const SPICE_MARKET_PATHS: PackedStringArray = [
	"res://assets/art/landmarks/cairo/spice_market_lv0.png",
	"res://assets/art/landmarks/cairo/spice_market_lv1.png",
	"res://assets/art/landmarks/cairo/spice_market_lv2.png",
	"res://assets/art/landmarks/cairo/spice_market_lv3.png",
]

static func texture_for_level(value: int) -> Texture2D:
	return SPICE_MARKET_TEXTURES[clampi(value, 0, 3)]

static func asset_path_for_level(value: int) -> String:
	return SPICE_MARKET_PATHS[clampi(value, 0, 3)]
