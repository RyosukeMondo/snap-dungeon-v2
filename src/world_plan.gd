class_name WorldPlan
extends RefCounted

enum WorldType { NORMAL, ARENA }
enum LevelType { DUNGEON, ESCAPE, END, ARENA }


class LevelPlan:
	var id: String
	var type: LevelType
	var depth: int
	var up_destination: String
	var down_destination: String
	var has_amulet: bool = false

	func _init(
		p_id: String,
		p_type: LevelType,
		p_depth: int,
		p_up: String = "",
		p_down: String = "",
		p_has_amulet: bool = false
	) -> void:
		id = p_id
		type = p_type
		depth = p_depth
		up_destination = p_up
		down_destination = p_down
		has_amulet = p_has_amulet

	func _to_string() -> String:
		var type_str: String = LevelType.keys()[type]
		return (
			"LevelPlan<%s>: type=%s depth=%d up=%s down=%s amulet=%s"
			% [
				id,
				type_str,
				depth,
				up_destination if up_destination else "none",
				down_destination if down_destination else "none",
				has_amulet
			]
		)


var levels: Array[LevelPlan]


func _init(world_type: WorldType = WorldType.NORMAL) -> void:
	levels = []

	match world_type:
		WorldType.NORMAL:
			# Create a 5-floor daily dungeon
			for i in range(1, Constants.MAX_FLOORS + 1):
				var up_dest := World.ESCAPE_LEVEL if i == 1 else "level_%d" % (i - 1)
				var down_dest := "" if i == Constants.MAX_FLOORS else "level_%d" % (i + 1)
				var has_amulet := i == Constants.MAX_FLOORS
				levels.append(
					LevelPlan.new("level_%d" % i, LevelType.DUNGEON, i, up_dest, down_dest, has_amulet)
				)

		WorldType.ARENA:
			# Create a simple arena
			levels.append(LevelPlan.new("arena", LevelType.ARENA, 1, "", "", false))


func _to_string() -> String:
	var output := "WorldPlan[\n"
	for level in levels:
		output += level._to_string() + "\n"
	output += "]"
	return output


func get_first_level_plan() -> LevelPlan:
	return levels[0]


func get_level_plan(level_id: String) -> LevelPlan:
	for level in levels:
		if level.id == level_id:
			return level
	return null
