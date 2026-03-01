extends Node

const SFX_POOL_SIZE := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer

var _sfx_streams: Dictionary = {}   # Dictionary[String, AudioStream]
var _music_streams: Dictionary = {} # Dictionary[String, AudioStream]

var sfx_volume_db: float = 0.0
var music_volume_db: float = -6.0


func _ready() -> void:
	_create_audio_players()
	_load_streams()
	World.effect_occurred.connect(_on_effect)
	World.game_ended.connect(func() -> void: play_music("gameover"))
	World.map_changed.connect(func(_m: Map) -> void: play_music("dungeon"))


func _create_audio_players() -> void:
	for i: int in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Master"
	add_child(_music_player)


func _load_streams() -> void:
	var sfx_names := ["move", "attack", "damage", "death", "pickup", "door_open", "stairs", "ui_click"]
	for sfx_name: String in sfx_names:
		var path := "res://assets/audio/sfx/%s.wav" % sfx_name
		if ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)

	var music_names := ["menu", "dungeon", "gameover"]
	for track: String in music_names:
		var path := "res://assets/audio/music/%s.ogg" % track
		if ResourceLoader.exists(path):
			var stream: Variant = load(path)
			if stream is AudioStream:
				_music_streams[track] = stream


func _on_effect(effect: ActionEffect) -> void:
	if effect is MoveEffect:
		play_sfx("move")
	elif effect is AttackEffect:
		play_sfx("attack")
	elif effect is HitEffect:
		play_sfx("damage")
	elif effect is DeathEffect:
		play_sfx("death")


func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var player := _sfx_players[_sfx_index]
	player.stream = _sfx_streams[sfx_name]
	player.volume_db = sfx_volume_db
	player.play()
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE


func play_music(track: String) -> void:
	if not _music_streams.has(track):
		return
	if _music_player.stream == _music_streams[track] and _music_player.playing:
		return
	_music_player.stream = _music_streams[track]
	_music_player.volume_db = music_volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_sfx_volume(db: float) -> void:
	sfx_volume_db = db


func set_music_volume(db: float) -> void:
	music_volume_db = db
	if _music_player.playing:
		_music_player.volume_db = db
