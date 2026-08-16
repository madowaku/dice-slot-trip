class_name FoxFireDifficultyTable
extends Resource

@export var entries: Array[FoxFireDifficultyConfig] = []


func config_for_lap(lap: int) -> FoxFireDifficultyConfig:
	for config: FoxFireDifficultyConfig in entries:
		if config != null and config.includes_lap(lap):
			return _with_lap_targeting(config.duplicate_config(), lap)
	if not entries.is_empty() and entries.back() != null:
		return _with_lap_targeting(entries.back().duplicate_config(), lap)
	return FoxFireDifficultyConfig.new()


func _with_lap_targeting(config: FoxFireDifficultyConfig, lap: int) -> FoxFireDifficultyConfig:
	# The rules remain stable while the fox gets a little more deliberate every
	# lap. The target is locked before the player rolls, so higher intelligence
	# increases readable pressure rather than enabling a post-roll counterpick.
	config.smart_targeting = true
	config.smart_target_rate = minf(0.30 + float(maxi(lap, 1) - 1) * 0.02, 0.85)
	return config


static func create_default() -> FoxFireDifficultyTable:
	var table := FoxFireDifficultyTable.new()
	var lv1 := FoxFireDifficultyConfig.new(1, 2, 1, 1)
	lv1.first_attack_turn = 2
	lv1.initial_white_fire_count = 1
	var lv2 := FoxFireDifficultyConfig.new(2, 2, 2, 4)
	lv2.first_attack_turn = 2
	lv2.initial_white_fire_count = 1
	var lv3 := FoxFireDifficultyConfig.new(3, 1, 5, 8)
	lv3.first_attack_turn = 3
	lv3.initial_white_fire_count = 2
	var lv4 := FoxFireDifficultyConfig.new(4, 1, 9, 12)
	lv4.first_attack_turn = 2
	lv4.initial_white_fire_count = 2
	var lv5 := FoxFireDifficultyConfig.new(5, 1, 13, 16)
	lv5.first_attack_turn = 1
	lv5.initial_white_fire_count = 2
	lv5.enable_line_cut = true
	lv5.maximum_line_cuts = 1
	var lv6 := FoxFireDifficultyConfig.new(6, 1, 17, 0)
	lv6.maximum_lap = 20
	lv6.first_attack_turn = 1
	lv6.initial_white_fire_count = 3
	lv6.candidate_count = 2
	lv6.enable_line_cut = true
	lv6.maximum_line_cuts = 1
	var lv7 := FoxFireDifficultyConfig.new(7, 1, 21, 24)
	lv7.first_attack_turn = 1
	lv7.initial_white_fire_count = 3
	lv7.candidate_count = 2
	lv7.enable_line_cut = true
	lv7.maximum_line_cuts = 2
	lv7.enable_special_tiles = true
	lv7.special_tile_count = 1
	var lv8 := FoxFireDifficultyConfig.new(8, 1, 25, 0)
	lv8.first_attack_turn = 1
	lv8.initial_white_fire_count = 3
	lv8.candidate_count = 2
	lv8.enable_line_cut = true
	lv8.maximum_line_cuts = 2
	lv8.enable_special_tiles = true
	lv8.special_tile_count = 2
	table.entries = [lv1, lv2, lv3, lv4, lv5, lv6, lv7, lv8]
	return table
