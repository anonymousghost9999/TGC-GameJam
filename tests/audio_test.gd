extends SceneTree
## Audio comes from CC0 files: check every effect loads and the music loops.
## Run: godot --headless --path . -s tests/audio_test.gd
var failures := 0
func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func _initialize() -> void:
	var a := Audio.new()
	root.add_child(a)
	await process_frame
	check(a.is_built, "audio is ready immediately")
	for n in Audio.SFX:
		var s: AudioStream = a._sfx.get(n)
		check(s != null and s.get_length() > 0.005, "sfx '%s' loads (%.2f s)" % [n, s.get_length() if s != null else 0.0])
	for m in Audio.MUSIC:
		var s: AudioStreamOggVorbis = a._music.get(m)
		check(s != null and s.loop and s.get_length() > 10.0, "music '%s' is a loop (%.0f s)" % [m, s.get_length() if s != null else 0.0])
	check(a.toggle_mute() and a.muted and not a.toggle_mute(), "M toggles mute")
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
