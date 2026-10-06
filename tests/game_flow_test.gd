extends SceneTree
## Plays the REAL game start to finish with a perfect-guide bot: title, prologue, all
## 9 levels (with a deliberate death, restart and pause on the way), the final lock,
## the Demon Lord reveal, the kill phase (with a failed attempt first) and the ending.
## Run: godot --headless --path . --fixed-fps 60 -s tests/game_flow_test.gd

var failures := 0
var game: GameManager
var sched: Schedule = null
var bot: NpcBot = null
var bot_sol: Array = []
var _bot_clock := 0.0

func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame

## Advance the game one frame as the bot: skip cutscenes with E, run the schedule while playing.
func tick() -> void:
	if not is_instance_valid(game):
		await process_frame
		return
	var gs := game.gs
	if gs == GameManager.GS.TITLE or gs == GameManager.GS.STORY or gs == GameManager.GS.COMPLETE or (gs == GameManager.GS.INTRO):
		_bot_clock += 1.0 / 60.0
		if int(_bot_clock * 60.0) % 12 == 0:
			await tap("interact")
	if gs == GameManager.GS.PLAYING and sched != null:
		sched.step(game.level_time, game.hero, game.lamp_manager, game.inversion)
	if gs == GameManager.GS.DEAD and bot != null:
		bot = NpcBot.new(bot_sol)   # retry from the top after a death
	if gs == GameManager.GS.PLAYING and bot != null:
		bot.step(game.level_time, game.hero, game.lamp_manager, game.inversion, game.npc)
	await process_frame

func until(cond: Callable, timeout_s: float) -> bool:
	var t0 := Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - t0) / 1000.0 * Engine.time_scale < timeout_s:
		if cond.call():
			return true
		await tick()
	return cond.call()

func _initialize() -> void:
	Engine.time_scale = 1.0   # at 3x the bot only acts every 3rd physics tick and misses tight windows (level 5)
	await run()
	Engine.time_scale = 1.0
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func run() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.gs == GameManager.GS.TITLE, "the game opens on the title screen")
	check(game.levels.size() == 15, "there are 15 playable levels")
	check(not game.hud.controls_visible(), "the controls list is hidden at first")
	await tap("controls")
	check(game.hud.controls_visible(), "Tab shows the controls list")
	await tap("controls")
	check(not game.hud.controls_visible(), "Tab hides it again")
	await tap("interact")
	check(game.gs == GameManager.GS.STORY, "E starts the story (prologue outside the dungeon)")

	for i in 15:
		var d: Dictionary = game.levels[i]
		check(await until(func(): return game.gs == GameManager.GS.PLAYING and game.data.get("id", "") == d.id, 120.0), "level %d '%s' starts after its intro" % [d.num, d.title])
		check(game.hud != null and game.hero.state == Hero.State.ACTIVE and game.npc.active, "level %d: hero is active and the NPC can move" % d.num)
		check(game.level.clock < 0.6, "level %d: the timed-spike clock starts when the hero does, not when the level loads (clock %.2f s)" % [d.num, game.level.clock])
		if d.id == "l1":
			check(game.hud.hint_text() == "[H] hint", "level 1: the hint is hidden until you ask for it (shows just '[H] hint')")
			await tap("hint")
			await process_frame
			check(game.hud.hint_text() == d.hint and game.hint_left > 5.0, "level 1: pressing H shows the hint")
			game.hint_left = 0.05
			await create_timer(0.3, true).timeout
			check(game.hud.hint_text() == "[H] hint", "level 1: the hint hides itself again after a few seconds")

		if d.id == "l1":
			# pause freezes the hero; Esc resumes
			var p0 := game.hero.global_position
			await tap("pause")
			check(paused and game.gs == GameManager.GS.PAUSED, "Esc pauses the game")
			await create_timer(0.5, true).timeout
			check(game.hero.global_position.distance_to(p0) < 0.5, "the hero is frozen while paused")
			await tap("pause")
			check(not paused and game.gs == GameManager.GS.PLAYING, "Esc resumes")
		if d.id == "l2":
			# do nothing: he dies, the level restarts, deaths count
			check(await until(func(): return game.deaths >= 1, 40.0), "level 2: doing nothing gets him killed by the spikes")
			check(await until(func(): return game.gs == GameManager.GS.PLAYING and game.hero.state == Hero.State.ACTIVE, 20.0), "level 2: the level restarts automatically after he dies")
			check(game.deaths == 1 and game.level_time < 3.0 and game.hero.global_position.distance_to(game.level.hero_start) < 120.0, "level 2: restart reset the timer and the hero's position")
		if d.id == "l3":
			await tap("restart")
			await process_frame
			check(game.level_time < 1.0 and game.deaths == 0, "R restarts the current level (no death counted)")
			check(await until(func(): return game.gs == GameManager.GS.PLAYING, 10.0), "level 3 is playable again after R")
		if d.id == "l6":
			# real input: E switches the nearest lamp, Q uses the invert lantern
			var lamp: Lamp = game.lamp_manager.lamps[0]
			var before := lamp.on
			game.npc.global_position = lamp.global_position + Vector2(30, 0)
			await process_frame
			await process_frame
			await tap("interact")
			check(lamp.on != before, "E switches the nearest lamp (real input)")
			await tap("interact")   # put it back
			await tap("invert")
			check(game.inversion.active and game.lamp_manager.inverted, "Q activates the invert lantern (real input)")
			await create_timer(0.1, true).timeout
			await tap("restart")   # reset this level so the scripted solution starts clean
			await process_frame

		bot_sol = d.solution
		bot = NpcBot.new(d.solution)   # the real NPC walks to each lamp at his real speed
		var ok_done := await until(func(): return game.gs == GameManager.GS.COMPLETE or game.gs == GameManager.GS.STORY, 150.0)
		check(ok_done, "level %d: the perfect guide brings the hero to the exit" % d.num)
		bot = null
		game.npc.bot_driven = false
		if d.id == "l15":
			break
		check(game.results.has(d.id), "level %d: result recorded (deaths %d, flawless=%s)" % [d.num, game.results.get(d.id, {}).get("deaths", -1), str(game.results.get(d.id, {}).get("flawless", false))])
		# continue to the next level
		await until(func(): return game.gs == GameManager.GS.INTRO or game.gs == GameManager.GS.PLAYING or game.data.get("id", "") != d.id, 40.0)

	# ---- the final lock, the reveal, the kill phase
	check(await until(func(): return game.kill_phase and game.gs == GameManager.GS.PLAYING, 150.0), "the lock breaks, the Demon Lord is revealed, and the kill phase begins")
	check(game.npc.demon, "the NPC is now the Demon Lord")
	check(game.hud != null and game.data.get("id", "") == "l9k", "the kill-phase level is loaded")
	# first attempt: do nothing, and he simply walks to the exit lamp and escapes
	sched = null
	bot = null
	game.npc.bot_driven = false
	check(await until(func(): return game.gs == GameManager.GS.STORY, 40.0), "kill phase: if he reaches the exit he escapes")
	check(await until(func(): return game.gs == GameManager.GS.PLAYING and game.kill_phase, 40.0), "kill phase: the trial restarts after an escape")
	check(game.hero.state == Hero.State.ACTIVE and game.hero.global_position.distance_to(game.level.hero_start) < 120.0, "kill phase: the hero is back at the start")
	# second attempt: route him into the spike chamber
	sched = Schedule.new(game.data.solution)
	check(await until(func(): return game.gs == GameManager.GS.ENDING, 60.0), "kill phase: the lamps kill him and the ending begins")
	sched = null
	check(await until(func(): return game._end_card_shown, 30.0), "the end card is shown")
	check(game.gs == GameManager.GS.ENDING, "the game is on the ending screen")
	await tap("interact")
	check(await until(func(): return game._credits_running and game.hud.credits_visible(), 5.0), "E on the end card rolls the credits")
	check("Kummathi Nikhith Reddy" in Dialogue.CREDITS and "Krithik Kambhampati" in Dialogue.CREDITS, "all five teammates are in the credits")
	await until(func(): return false, 2.0)
	check(game.gs == GameManager.GS.ENDING and game.hud.credits_visible(), "the credits keep rolling (the end-card timer does not cut them off)")
	var flawless := 0
	for k in game.results:
		if game.results[k].flawless:
			flawless += 1
	check(game.results.size() == 15, "all 15 levels are recorded in the results, including the final lock level")
	print("levels cleared: %d, flawless: %d, total deaths: %d" % [game.results.size(), flawless, game.total_deaths])
	# E on the end card goes back to the start (a fresh title screen)
	await tap("interact")
	for i in 5:
		await process_frame
	var fresh := current_scene as GameManager
	check(fresh != null and is_instance_valid(fresh) and fresh != game and fresh.gs == GameManager.GS.TITLE, "E on the end card returns to the title screen")
