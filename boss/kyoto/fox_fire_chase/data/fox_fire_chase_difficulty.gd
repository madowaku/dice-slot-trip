class_name FoxFireChaseDifficulty
extends Resource

@export_range(1, 8, 1) var level: int = 1
@export_range(1.0, 1.5, 0.01) var roll_speed_scale: float = 1.0
@export_range(1, 999, 1) var minimum_lap: int = 1
@export_range(0, 999, 1) var maximum_lap: int = 3 # Zero means no upper bound.


func _init(
	difficulty_level: int = 1,
	speed_scale: float = 1.0,
	first_lap: int = 1,
	last_lap: int = 3
) -> void:
	level = clampi(difficulty_level, 1, 8)
	roll_speed_scale = clampf(speed_scale, 1.0, 1.5)
	minimum_lap = maxi(first_lap, 1)
	maximum_lap = maxi(last_lap, 0)


func includes_lap(lap: int) -> bool:
	return lap >= minimum_lap and (maximum_lap == 0 or lap <= maximum_lap)


func to_dictionary() -> Dictionary:
	return {
		"level": level,
		"roll_speed_scale": roll_speed_scale,
		"minimum_lap": minimum_lap,
		"maximum_lap": maximum_lap,
	}


static func for_lap(lap: int) -> FoxFireChaseDifficulty:
	var safe_lap := maxi(lap, 1)
	if safe_lap <= 3:
		return FoxFireChaseDifficulty.new(1, 1.00, 1, 3)
	if safe_lap <= 6:
		return FoxFireChaseDifficulty.new(2, 1.06, 4, 6)
	if safe_lap <= 10:
		return FoxFireChaseDifficulty.new(3, 1.12, 7, 10)
	if safe_lap <= 15:
		return FoxFireChaseDifficulty.new(4, 1.18, 11, 15)
	if safe_lap <= 20:
		return FoxFireChaseDifficulty.new(5, 1.24, 16, 20)
	if safe_lap <= 25:
		return FoxFireChaseDifficulty.new(6, 1.30, 21, 25)
	if safe_lap <= 30:
		return FoxFireChaseDifficulty.new(7, 1.36, 26, 30)
	return FoxFireChaseDifficulty.new(8, 1.42, 31, 0)
