class_name SeedFactory
extends RefCounted


static func daily_seed() -> int:
	var now := Time.get_datetime_dict_from_system(true)
	var date_str := "%04d%02d%02d" % [now.year, now.month, now.day]
	return date_str.hash()


static func floor_seed(base_seed: int, floor_number: int) -> int:
	var combined := "%d_%d" % [base_seed, floor_number]
	return combined.hash()


static func create_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
