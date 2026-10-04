extends SceneTree
## Audio is synthesised in code: check it builds quickly, every effect exists, and the music loops.
## Run: godot --headless --path . -s tests/audio_test.gd
var failures := 0
func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var a := Audio.new()
	root.add_child(a)
	if not a.is_built:
		await a.built
	var ms := Time.get_ticks_msec() - t0
	check(ms < 4000, "all sound is synthesised in the background in %d ms total (budget 4000)" % ms)
	for n in ["switch", "on", "off", "invert_on", "invert_off", "freeze", "death_spike", "death_fire", "death_trap", "death_dragon", "win", "lock", "reveal", "blip_h", "blip_n"]:
		var s: AudioStreamWAV = a._sfx.get(n)
		check(s != null and s.data.size() > 400, "sfx '%s' exists (%d bytes)" % [n, s.data.size() if s != null else 0])
	for m in ["adventure", "demon"]:
		var s: AudioStreamWAV = a._music.get(m)
		check(s != null and s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.data.size() > 100000, "music '%s' is a loop (%d KB)" % [m, s.data.size() / 1024 if s != null else 0])
	check(a.toggle_mute() and a.muted and not a.toggle_mute(), "M toggles mute")
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
