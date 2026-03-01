class_name RunState
extends Resource


@export var current_floor: int = 1
@export var score: int = 0
@export var turns_taken: int = 0
@export var kills: int = 0
@export var daily_seed: int = 0
@export var is_active: bool = false
@export var player_hp: int = 0
@export var player_class: String = "warrior"


func start(seed_value: int) -> void:
	daily_seed = seed_value
	current_floor = 1
	score = 0
	turns_taken = 0
	kills = 0
	is_active = true


func advance_floor() -> void:
	current_floor += 1


func add_kill(points: int) -> void:
	kills += 1
	score += points


func add_turn() -> void:
	turns_taken += 1


func end_run() -> void:
	is_active = false
