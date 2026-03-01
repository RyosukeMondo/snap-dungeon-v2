class_name FloorTransitionUI
extends ColorRect


var _label: Label


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchors_preset = Control.PRESET_FULL_RECT
	_label.anchor_right = 1.0
	_label.anchor_bottom = 1.0
	add_child(_label)

	World.show_floor_transition.connect(_on_show_floor_transition)


func _on_show_floor_transition(floor_number: int) -> void:
	_label.text = "Floor %d" % floor_number
	mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(self, "color", Color(0, 0, 0, 0.8), 0.3)
	tween.tween_interval(0.5)
	tween.tween_property(self, "color", Color(0, 0, 0, 0), 0.3)
	tween.finished.connect(func() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE)
