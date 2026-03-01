class_name StatsData
extends Resource


@export var max_hp: int = 10
@export var attack: int = 3
@export var defense: int = 1


static func create(p_hp: int, p_atk: int, p_def: int) -> StatsData:
	var stats := StatsData.new()
	stats.max_hp = p_hp
	stats.attack = p_atk
	stats.defense = p_def
	return stats


static func for_enemy(enemy_type: String) -> StatsData:
	match enemy_type:
		"slime":
			return create(4, 2, 0)
		"bat":
			return create(3, 3, 0)
		"skeleton":
			return create(6, 3, 1)
		"mage":
			return create(5, 5, 0)
		"elite":
			return create(10, 4, 2)
		_:
			return create(4, 2, 0)


static func for_player(player_class: String = "warrior") -> StatsData:
	var class_data := PlayerClassData.get_player_class(player_class)
	return class_data.base_stats.duplicate()
