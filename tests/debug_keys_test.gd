extends SceneTree
## The debug jumps: 1-9 load a level, and F1 then 0 jumps straight to the finale, from any screen.
## Run: godot --headless --path . --fixed-fps 60 -s tests/debug_keys_test.gd
var failures := 0
func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func wait_playing(game: GameManager, want_kill: bool, timeout_s: float) -> bool:
	var t := 0.0
	while t < timeout_s:
		game._skip = true   # skip any dialogue
		if game.gs == GameManager.GS.PLAYING and game.kill_phase == want_kill:
			return true
		await process_frame
		t += 1.0 / 60.0
	return false

func _initialize() -> void:
	var game: GameManager = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.gs == GameManager.GS.TITLE, "starts on the title screen")
	# F1 then 0, straight from the title screen
	game._debug_key(KEY_F1)
	check(game._debug_key(KEY_0), "F1 then 0 is recognised as the finale jump")
	check(await wait_playing(game, true, 20.0), "F1 + 0 from the title screen lands in the finale, ready to play")
	check(game.data.get("id", "") == "l9k" and game.kill_phase and game.npc.demon, "...it is the Demon Lord's trial with the NPC already revealed")
	check(game.hero.state == Hero.State.ACTIVE and game.npc.active, "...and the hero is moving and the NPC is controllable")
	# a lone 0 (no F1) must NOT jump anywhere
	game._debug_key(KEY_1)
	check(await wait_playing(game, false, 20.0) and game.data.id == "l1", "key 1 loads level 1 (also from inside the finale)")
	await create_timer(0.1).timeout
	game._f1_at = -100000
	check(not game._debug_key(KEY_0), "a lone 0 (without F1) does nothing")
	# jump while paused
	game._debug_key(KEY_3)
	check(await wait_playing(game, false, 20.0) and game.data.id == "l3", "key 3 loads level 3")
	game._set_paused(true)
	check(paused, "paused")
	game._debug_key(KEY_F1)
	game._debug_key(KEY_0)
	check(not paused, "a debug jump unpauses the game")
	check(await wait_playing(game, true, 20.0), "F1 + 0 also works from the pause screen")
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
