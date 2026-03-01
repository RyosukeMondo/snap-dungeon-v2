class_name PlayerProfile
extends Resource


@export var streak_days: int = 0
@export var last_play_date: String = ""
@export var total_runs: int = 0
@export var best_score: int = 0
@export var unlocked_classes: PackedStringArray = ["warrior"]
@export var gem_balance: int = 0


func record_run(score: int, date_str: String) -> void:
	total_runs += 1
	if score > best_score:
		best_score = score
	_update_streak(date_str)


func _update_streak(date_str: String) -> void:
	if last_play_date.is_empty():
		streak_days = 1
	else:
		var last := _parse_date(last_play_date)
		var current := _parse_date(date_str)
		var diff := _day_difference(last, current)
		if diff == 1:
			streak_days += 1
		elif diff > 1:
			streak_days = 1
	last_play_date = date_str


func has_class(class_name_str: String) -> bool:
	return class_name_str in unlocked_classes


func unlock_class(class_name_str: String) -> void:
	if not has_class(class_name_str):
		unlocked_classes.append(class_name_str)


static func _parse_date(date_str: String) -> Dictionary:
	var parts := date_str.split("-")
	if parts.size() < 3:
		return {"year": 0, "month": 0, "day": 0}
	return {
		"year": parts[0].to_int(),
		"month": parts[1].to_int(),
		"day": parts[2].to_int(),
	}


static func _day_difference(a: Dictionary, b: Dictionary) -> int:
	var days_a: int = int(a.year) * 365 + int(a.month) * 30 + int(a.day)
	var days_b: int = int(b.year) * 365 + int(b.month) * 30 + int(b.day)
	return days_b - days_a
