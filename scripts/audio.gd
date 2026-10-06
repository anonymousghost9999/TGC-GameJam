class_name Audio
extends Node
## Sound effects and music, all CC0 (see CREDITS.md): Kenney sound packs and two
## OpenGameArt music loops. Files live in res://assets/sfx and res://assets/music.
## play("name", pitch) / music("adventure" | "demon" | "") / toggle_mute().

const SFX := ["switch", "on", "off", "invert_on", "invert_off", "freeze", "death_spike", "death_fire",
	"death_trap", "death_dragon", "win", "lock", "reveal", "blip_h", "blip_n", "deny", "door"]
const MUSIC := ["adventure", "demon"]
const MUSIC_DB := -10.0

signal built

var muted := false
var is_built := false
var _sfx := {}
var _music := {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _next := 0
var _wanted := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -1.0
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = MUSIC_DB
	add_child(_music_player)
	for n in SFX:
		_sfx[n] = load("res://assets/sfx/%s.ogg" % n)
	for m in MUSIC:
		var s: AudioStreamOggVorbis = load("res://assets/music/%s.ogg" % m)
		s.loop = true
		_music[m] = s
	is_built = true
	built.emit()

func play(sfx_name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if muted or not _sfx.has(sfx_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[sfx_name]
	p.pitch_scale = pitch
	p.volume_db = -1.0 + volume_db
	p.play()

func music(track: String) -> void:
	_wanted = track
	if track == "" or not _music.has(track):
		_music_player.stop()
		return
	if _music_player.stream == _music[track] and _music_player.playing:
		return
	_music_player.stream = _music[track]
	if not muted:
		_music_player.play()

func toggle_mute() -> bool:
	muted = not muted
	if muted:
		_music_player.stop()
	elif _music_player.stream != null:
		_music_player.play()
	return muted
