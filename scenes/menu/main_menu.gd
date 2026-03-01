extends Control

var _selected_role: Roles.Type = Roles.Type.KNIGHT
var _selected_slug: StringName = &"knight"

@onready var class_label: Label = %ClassLabel
@onready var daily_button: Button = %DailyButton


func _ready() -> void:
	_update_class_label()


func _update_class_label() -> void:
	if class_label:
		class_label.text = Roles.get_role_data(_selected_role).name


func _on_daily_button_pressed() -> void:
	World.start_daily_run(_selected_role, _selected_slug)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_class_prev_pressed() -> void:
	var types := [Roles.Type.KNIGHT, Roles.Type.MONK, Roles.Type.VALKYRIE]
	var slugs: Array[StringName] = [&"knight", &"knight", &"knight"]
	var idx := types.find(_selected_role)
	idx = (idx - 1 + types.size()) % types.size()
	_selected_role = types[idx]
	_selected_slug = slugs[idx]
	_update_class_label()


func _on_class_next_pressed() -> void:
	var types := [Roles.Type.KNIGHT, Roles.Type.MONK, Roles.Type.VALKYRIE]
	var slugs: Array[StringName] = [&"knight", &"knight", &"knight"]
	var idx := types.find(_selected_role)
	idx = (idx + 1) % types.size()
	_selected_role = types[idx]
	_selected_slug = slugs[idx]
	_update_class_label()
