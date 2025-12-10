extends Node


@export var main_theme: AudioStream 

var _player: AudioStreamPlayer

func _ready() -> void:
	# Create the audio player  
	_player = AudioStreamPlayer.new()
	add_child(_player)

	_player.bus = "Music"

	# Loop the track
	_player.stream = main_theme
	_player.autoplay = false
	_player.finished.connect(_on_track_finished)

	# Start playing immediately
	if main_theme:
		_player.play()

func _on_track_finished() -> void:
	# Simple looping
	_player.play()

func play() -> void:
	if _player and not _player.playing:
		_player.play()

func stop() -> void:
	if _player and _player.playing:
		_player.stop()

func set_volume(db: float) -> void:
	if _player:
		_player.volume_db = db
