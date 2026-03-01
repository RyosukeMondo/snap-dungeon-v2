class_name LeaderboardEntry
extends RefCounted


var rank: int = 0
var player_name: String = ""
var score: int = 0
var floor_reached: int = 0
var turns_taken: int = 0
var kills: int = 0
var player_class: String = "warrior"


static func from_dict(data: Dictionary) -> LeaderboardEntry:
	var entry := LeaderboardEntry.new()
	entry.rank = data.get("rank", 0)
	entry.player_name = data.get("name", "Anonymous")
	entry.score = data.get("score", 0)
	entry.floor_reached = data.get("floor", 0)
	entry.turns_taken = data.get("turns", 0)
	entry.kills = data.get("kills", 0)
	entry.player_class = data.get("class", "warrior")
	return entry


func to_dict() -> Dictionary:
	return {
		"rank": rank,
		"name": player_name,
		"score": score,
		"floor": floor_reached,
		"turns": turns_taken,
		"kills": kills,
		"class": player_class,
	}
