class_name FoxFireDifficultyConfig
extends Resource

@export_range(1, 99, 1) var level: int = 1
@export_range(0, 99, 1) var attack_interval: int = 0
@export_range(1, 99, 1) var first_attack_turn: int = 1
@export_range(0, 3, 1) var initial_white_fire_count: int = 0
@export var smart_targeting: bool = false
@export_range(0.0, 1.0, 0.01) var smart_target_rate: float = 0.0
@export_range(1, 2, 1) var candidate_count: int = 1
@export var enable_line_cut: bool = false
@export_range(0, 99, 1) var maximum_line_cuts: int = 0
@export var enable_special_tiles: bool = false
@export_range(0, 2, 1) var special_tile_count: int = 0
@export var enable_block_seal_bonus: bool = false
@export_range(1, 99, 1) var line_cut_interval: int = 3
@export_range(1, 999, 1) var minimum_lap: int = 1
@export_range(0, 999, 1) var maximum_lap: int = 1 # Zero means no upper bound.


func _init(
	difficulty_level: int = 1,
	interval: int = 0,
	first_lap: int = 1,
	last_lap: int = 1
) -> void:
	level = maxi(difficulty_level, 1)
	attack_interval = maxi(interval, 0)
	minimum_lap = maxi(first_lap, 1)
	maximum_lap = maxi(last_lap, 0)


func includes_lap(lap: int) -> bool:
	return lap >= minimum_lap and (maximum_lap == 0 or lap <= maximum_lap)


func duplicate_config() -> FoxFireDifficultyConfig:
	var copy := FoxFireDifficultyConfig.new(level, attack_interval, minimum_lap, maximum_lap)
	copy.smart_targeting = smart_targeting
	copy.smart_target_rate = smart_target_rate
	copy.candidate_count = candidate_count
	copy.first_attack_turn = first_attack_turn
	copy.initial_white_fire_count = initial_white_fire_count
	copy.enable_line_cut = enable_line_cut
	copy.maximum_line_cuts = maximum_line_cuts
	copy.enable_special_tiles = enable_special_tiles
	copy.special_tile_count = special_tile_count
	copy.enable_block_seal_bonus = enable_block_seal_bonus
	copy.line_cut_interval = line_cut_interval
	return copy


func to_snapshot() -> Dictionary:
	return {
		"level": level,
		"attack_interval": attack_interval,
		"first_attack_turn": first_attack_turn,
		"initial_white_fire_count": initial_white_fire_count,
		"smart_targeting": smart_targeting,
		"smart_target_rate": smart_target_rate,
		"candidate_count": candidate_count,
		"enable_line_cut": enable_line_cut,
		"maximum_line_cuts": maximum_line_cuts,
		"enable_special_tiles": enable_special_tiles,
		"special_tile_count": special_tile_count,
		"enable_block_seal_bonus": enable_block_seal_bonus,
		"line_cut_interval": line_cut_interval,
		"minimum_lap": minimum_lap,
		"maximum_lap": maximum_lap,
	}


static func from_snapshot(data: Dictionary) -> FoxFireDifficultyConfig:
	var config := FoxFireDifficultyConfig.new(
		maxi(int(data.get("level", 1)), 1),
		maxi(int(data.get("attack_interval", 0)), 0),
		maxi(int(data.get("minimum_lap", 1)), 1),
		maxi(int(data.get("maximum_lap", 0)), 0)
	)
	config.smart_targeting = bool(data.get("smart_targeting", false))
	config.smart_target_rate = clampf(float(data.get("smart_target_rate", 1.0 if config.smart_targeting else 0.0)), 0.0, 1.0)
	config.candidate_count = clampi(int(data.get("candidate_count", 1)), 1, 2)
	config.first_attack_turn = maxi(int(data.get("first_attack_turn", 1)), 1)
	config.initial_white_fire_count = clampi(int(data.get("initial_white_fire_count", 0)), 0, 3)
	config.enable_line_cut = bool(data.get("enable_line_cut", false))
	config.maximum_line_cuts = maxi(int(data.get("maximum_line_cuts", 99 if config.enable_line_cut else 0)), 0)
	config.enable_special_tiles = bool(data.get("enable_special_tiles", false))
	config.special_tile_count = clampi(int(data.get("special_tile_count", 2 if config.enable_special_tiles else 0)), 0, 2)
	config.enable_block_seal_bonus = bool(data.get("enable_block_seal_bonus", false))
	config.line_cut_interval = maxi(int(data.get("line_cut_interval", 3)), 1)
	return config
