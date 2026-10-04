class_name Audio
extends Node
## All sound is synthesised in code at startup (original; no audio files).
## Sound effects are short waveforms; the music is two tiny chiptune loops.
## play("name", pitch) / music("adventure" | "demon" | "") / toggle_mute().

const RATE := 22050
const MUSIC_RATE := 16000

signal built

var muted := false
var is_built := false
var _sfx := {}
var _music := {}
var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -15.0
	add_child(_music_player)
	_build_all()   # runs in the background, one sound per frame, so start-up never stalls

func _build_all() -> void:
	await _build_sfx()
	await _build_music()
	is_built = true
	built.emit()
	if _wanted != "":
		music(_wanted)   # the track was requested before it finished building

func play(sfx_name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if muted or not _sfx.has(sfx_name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[sfx_name]
	p.pitch_scale = pitch
	p.volume_db = -4.0 + volume_db
	p.play()

var _wanted := ""

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

# ------------------------------------------------------------------ synthesis

func _wav(samples: PackedFloat32Array, rate: int, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, clampi(int(samples[i] * 32767.0), -32768, 32767))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

static func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

## Mix a tone into `buf` starting at `t0` seconds. wave: 0 sine, 1 square, 2 triangle, 3 noise, 4 saw.
func _tone(buf: PackedFloat32Array, rate: int, t0: float, dur: float, f0: float, f1: float, wave: int, amp: float, attack := 0.005, release := 0.0) -> void:
	var n0 := int(t0 * rate)
	var n := int(dur * rate)
	var phase := 0.0
	var rel := release if release > 0.0 else dur * 0.5
	for i in n:
		if n0 + i >= buf.size():
			break
		var t := float(i) / rate
		var f := lerpf(f0, f1, float(i) / maxf(n, 1.0))
		phase += f / rate
		var ph := fposmod(phase, 1.0)
		var v := 0.0
		match wave:
			0: v = sin(TAU * phase)
			1: v = 1.0 if ph < 0.5 else -1.0
			2: v = 4.0 * absf(ph - 0.5) - 1.0
			3: v = randf() * 2.0 - 1.0
			4: v = 2.0 * ph - 1.0
		var env := minf(t / attack, 1.0) * clampf((dur - t) / rel, 0.0, 1.0)
		buf[n0 + i] += v * amp * env

func _buf(seconds: float, rate := RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * rate))
	return b

func _build_sfx() -> void:
	var b := _buf(0.14)
	_tone(b, RATE, 0.0, 0.03, 1800.0, 900.0, 3, 0.35)
	_tone(b, RATE, 0.0, 0.12, 520.0, 440.0, 1, 0.22, 0.002, 0.08)
	_sfx["switch"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.25)
	_tone(b, RATE, 0.0, 0.1, 660.0, 660.0, 1, 0.2)
	_tone(b, RATE, 0.1, 0.14, 990.0, 990.0, 1, 0.2)
	_sfx["on"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.25)
	_tone(b, RATE, 0.0, 0.1, 990.0, 990.0, 1, 0.2)
	_tone(b, RATE, 0.1, 0.14, 560.0, 560.0, 1, 0.2)
	_sfx["off"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.7)
	_tone(b, RATE, 0.0, 0.6, 200.0, 1400.0, 2, 0.3, 0.01, 0.2)
	_tone(b, RATE, 0.0, 0.6, 205.0, 1410.0, 1, 0.08, 0.01, 0.2)
	_sfx["invert_on"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.6)
	_tone(b, RATE, 0.0, 0.5, 1200.0, 160.0, 2, 0.3, 0.01, 0.2)
	_sfx["invert_off"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.7)
	_tone(b, RATE, 0.0, 0.6, 1760.0, 1760.0, 0, 0.25, 0.002, 0.55)
	_tone(b, RATE, 0.02, 0.6, 2349.0, 2349.0, 0, 0.18, 0.002, 0.55)
	_tone(b, RATE, 0.04, 0.5, 2960.0, 2960.0, 0, 0.1, 0.002, 0.45)
	_sfx["freeze"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.5)
	_tone(b, RATE, 0.0, 0.08, 1500.0, 300.0, 3, 0.45)
	_tone(b, RATE, 0.0, 0.45, 420.0, 90.0, 2, 0.4, 0.002, 0.3)
	_sfx["death_spike"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.8)
	_tone(b, RATE, 0.0, 0.7, 300.0, 120.0, 3, 0.3, 0.02, 0.5)
	_tone(b, RATE, 0.0, 0.7, 500.0, 80.0, 4, 0.18, 0.02, 0.5)
	_sfx["death_fire"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.7)
	_tone(b, RATE, 0.0, 0.65, 700.0, 60.0, 0, 0.4, 0.005, 0.4)
	_sfx["death_trap"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(1.0)
	_tone(b, RATE, 0.0, 0.9, 140.0, 55.0, 4, 0.35, 0.03, 0.6)
	_tone(b, RATE, 0.0, 0.9, 300.0, 100.0, 3, 0.25, 0.03, 0.6)
	_sfx["death_dragon"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.9)
	for k in 4:
		_tone(b, RATE, k * 0.1, 0.18, _hz(72.0 + [0, 4, 7, 12][k]), _hz(72.0 + [0, 4, 7, 12][k]), 1, 0.2, 0.003, 0.15)
	_tone(b, RATE, 0.4, 0.45, _hz(84.0), _hz(84.0), 0, 0.2, 0.01, 0.4)
	_sfx["win"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(1.2)
	_tone(b, RATE, 0.0, 0.25, 900.0, 80.0, 3, 0.6)
	_tone(b, RATE, 0.0, 1.0, 90.0, 40.0, 0, 0.55, 0.005, 0.8)
	_tone(b, RATE, 0.05, 0.5, 600.0, 200.0, 4, 0.2, 0.005, 0.4)
	_sfx["lock"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(3.0)
	_tone(b, RATE, 0.0, 2.8, 55.0, 41.0, 4, 0.3, 0.8, 1.0)
	_tone(b, RATE, 0.0, 2.8, 58.0, 43.0, 4, 0.25, 0.8, 1.0)
	_tone(b, RATE, 0.6, 2.2, _hz(60.0), _hz(60.0), 2, 0.15, 0.6, 1.0)
	_tone(b, RATE, 0.6, 2.2, _hz(66.0), _hz(66.0), 2, 0.15, 0.6, 1.0)
	_sfx["reveal"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.06)
	_tone(b, RATE, 0.0, 0.05, 700.0, 700.0, 1, 0.12, 0.002, 0.03)
	_sfx["blip_h"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.07)
	_tone(b, RATE, 0.0, 0.06, 340.0, 340.0, 1, 0.12, 0.002, 0.04)
	_sfx["blip_n"] = _wav(b, RATE)
	await get_tree().process_frame
	b = _buf(0.3)
	_tone(b, RATE, 0.0, 0.25, 220.0, 180.0, 1, 0.2, 0.002, 0.2)
	_sfx["deny"] = _wav(b, RATE)
	await get_tree().process_frame

## Chiptune loops: three voices (bass, arpeggio, melody) on an 8th-note grid.
func _build_music() -> void:
	# adventure: C major, bouncy and a little pompous
	var bass_a := [48, 0, 48, 0, 45, 0, 45, 0, 41, 0, 41, 0, 43, 0, 43, 0,
		48, 0, 48, 0, 45, 0, 45, 0, 41, 0, 43, 0, 43, 0, 43, 0]
	var arp_a := [60, 64, 67, 64, 57, 60, 64, 60, 53, 57, 60, 57, 55, 59, 62, 59,
		60, 64, 67, 64, 57, 60, 64, 60, 53, 57, 60, 62, 55, 59, 62, 67]
	var mel_a := [72, 0, 76, 0, 79, 0, 76, 74, 72, 0, 69, 0, 72, 0, 0, 0,
		77, 0, 76, 0, 74, 0, 72, 0, 71, 0, 74, 0, 79, 0, 0, 0]
	_music["adventure"] = _wav(_compose(bass_a, arp_a, mel_a, 0.28, 0.20), MUSIC_RATE, true)
	await get_tree().process_frame
	# demon: A minor, slow, with tritone stings
	var bass_d := [45, 0, 0, 45, 0, 0, 45, 0, 43, 0, 0, 43, 0, 0, 44, 0,
		45, 0, 0, 45, 0, 0, 45, 0, 41, 0, 0, 41, 0, 0, 44, 0]
	var arp_d := [57, 60, 64, 60, 57, 60, 64, 60, 55, 59, 62, 59, 56, 59, 62, 59,
		57, 60, 64, 60, 57, 60, 64, 60, 53, 57, 60, 57, 56, 59, 62, 59]
	var mel_d := [0, 0, 0, 0, 76, 0, 0, 0, 0, 0, 0, 0, 75, 0, 0, 0,
		0, 0, 0, 0, 72, 0, 71, 0, 0, 0, 0, 0, 68, 0, 0, 0]
	_music["demon"] = _wav(_compose(bass_d, arp_d, mel_d, 0.36, 0.20), MUSIC_RATE, true)
	await get_tree().process_frame

func _compose(bass: Array, arp: Array, mel: Array, step: float, amp: float) -> PackedFloat32Array:
	var buf := _buf(step * bass.size(), MUSIC_RATE)
	for i in bass.size():
		var t := i * step
		if bass[i] > 0:
			_tone(buf, MUSIC_RATE, t, step * 1.9, _hz(bass[i]), _hz(bass[i]), 2, amp * 1.2, 0.01, step)
		if arp[i] > 0:
			_tone(buf, MUSIC_RATE, t, step * 0.8, _hz(arp[i]), _hz(arp[i]), 1, amp * 0.28, 0.005, step * 0.6)
		if mel[i] > 0:
			_tone(buf, MUSIC_RATE, t, step * 1.7, _hz(mel[i]), _hz(mel[i]), 2, amp * 0.9, 0.01, step)
	return buf
