extends Node

const RUN_SAVE_PATH := "user://save/run_state.tres"
const PROFILE_SAVE_PATH := "user://save/profile.tres"
const SAVE_DIR := "user://save"

var profile: PlayerProfile


func _ready() -> void:
	_ensure_save_dir()
	profile = load_profile()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# --- Run state persistence (between floors, not mid-floor) ---

func save_run(run_state: RunState) -> void:
	ResourceSaver.save(run_state, RUN_SAVE_PATH)


func load_run() -> RunState:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return null
	var loaded := ResourceLoader.load(RUN_SAVE_PATH)
	if loaded is RunState:
		return loaded as RunState
	return null


func has_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


func clear_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)


# --- Player profile persistence ---

func save_profile() -> void:
	ResourceSaver.save(profile, PROFILE_SAVE_PATH)


func load_profile() -> PlayerProfile:
	if FileAccess.file_exists(PROFILE_SAVE_PATH):
		var loaded := ResourceLoader.load(PROFILE_SAVE_PATH)
		if loaded is PlayerProfile:
			return loaded as PlayerProfile
	return PlayerProfile.new()


func get_today_str() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [now.year, now.month, now.day]
