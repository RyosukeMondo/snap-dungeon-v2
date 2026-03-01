class_name PlayerClassData
extends Resource


@export var class_name_id: String = "warrior"
@export var display_name: String = "Warrior"
@export var base_stats: StatsData


static func for_warrior() -> PlayerClassData:
	var data := PlayerClassData.new()
	data.class_name_id = "warrior"
	data.display_name = "Warrior"
	data.base_stats = StatsData.create(20, 4, 1)
	return data


static func for_rogue() -> PlayerClassData:
	var data := PlayerClassData.new()
	data.class_name_id = "rogue"
	data.display_name = "Rogue"
	data.base_stats = StatsData.create(14, 6, 0)
	return data


static func for_mage() -> PlayerClassData:
	var data := PlayerClassData.new()
	data.class_name_id = "mage"
	data.display_name = "Mage"
	data.base_stats = StatsData.create(12, 8, 0)
	return data


static func get_player_class(class_id: String) -> PlayerClassData:
	match class_id:
		"rogue": return for_rogue()
		"mage": return for_mage()
		_: return for_warrior()


static func all_class_ids() -> PackedStringArray:
	return PackedStringArray(["warrior", "rogue", "mage"])
