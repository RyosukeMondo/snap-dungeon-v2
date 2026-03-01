class_name TouchActionBar
extends HBoxContainer

signal action_pressed(action_name: StringName)

const BUTTON_SIZE := Vector2(44, 44)

var buttons: Dictionary = {}


func _ready() -> void:
	alignment = ALIGNMENT_CENTER
	add_theme_constant_override("separation", 4)

	_add_button(&"inventory", "Inv")
	_add_button(&"pickup", "Get")
	_add_button(&"wait", "Wait")
	_add_button(&"stairs", "Strs")


func _add_button(action_name: StringName, label: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = BUTTON_SIZE
	btn.pressed.connect(func() -> void: action_pressed.emit(action_name))
	add_child(btn)
	buttons[action_name] = btn
