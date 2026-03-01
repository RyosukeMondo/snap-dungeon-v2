class_name ShareCardData
extends RefCounted


var score: int = 0
var floor_reached: int = 0
var turns_taken: int = 0
var kills: int = 0
var daily_seed: int = 0
var player_class: String = "warrior"
var rank_percentile: float = 0.0
var streak_days: int = 0
var victory: bool = false
var floor_outcomes: Array[String] = []  # e.g. ["clear", "clear", "death"]


static func from_run(run_state: RunState, profile: PlayerProfile) -> ShareCardData:
	var data := ShareCardData.new()
	data.score = run_state.score
	data.floor_reached = run_state.current_floor
	data.turns_taken = run_state.turns_taken
	data.kills = run_state.kills
	data.daily_seed = run_state.daily_seed
	data.player_class = run_state.player_class
	data.streak_days = profile.streak_days
	data.victory = run_state.current_floor > Constants.MAX_FLOORS
	return data
