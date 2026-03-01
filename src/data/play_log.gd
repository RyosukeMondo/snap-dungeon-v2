class_name PlayLog
extends Resource


@export var actions: Array[Dictionary] = []  # [{turn, type, data}]
@export var seed_used: int = 0
@export var player_class: String = "warrior"
@export var final_score: int = 0
@export var final_floor: int = 0


func record_action(turn: int, action_type: String, data: Dictionary = {}) -> void:
	actions.append({
		"turn": turn,
		"type": action_type,
		"data": data,
	})


func compute_hash() -> String:
	var content := "%d:%s:%d:%d:" % [seed_used, player_class, final_score, final_floor]
	for action: Dictionary in actions:
		content += "%d%s" % [action.turn, action.type]
	return content.sha256_text()


func to_dict() -> Dictionary:
	return {
		"seed": seed_used,
		"class": player_class,
		"score": final_score,
		"floor": final_floor,
		"action_count": actions.size(),
		"hash": compute_hash(),
	}
