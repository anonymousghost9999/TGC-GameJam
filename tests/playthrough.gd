extends SceneTree
## Headless bot that plays the real game with real input events and real physics.
## Run:  godot --headless --path . --fixed-fps 60 -s tests/playthrough.gd
## Exits 0 if every check passes, 1 otherwise. The hero is seeded, so it is repeatable.

var failures := 0
var finished := false
var sim_time := 0.0
var game: GameManager

func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func frame() -> void:
	await process_frame
	sim_time += root.get_process_delta_time()

func wait_until(cond: Callable, timeout_s: float) -> bool:
	var start := sim_time
	while sim_time - start < timeout_s:
		if cond.call():
			return true
		await frame()
	return cond.call()

func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await frame()
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await frame()

func boot() -> void:
	if game != null:
		game.queue_free()
		await frame()
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game   # like a real launch, so restart can reload it
	await frame()
	await frame()

func walk_player_to(p: Vector2, timeout_s := 20.0) -> bool:
	var pl := game.player
	var start := sim_time
	while sim_time - start < timeout_s:
		var d := p - pl.global_position
		if d.length() < 6.0:
			break
		for a in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(a)
		if d.x > 4.0: Input.action_press("move_right")
		if d.x < -4.0: Input.action_press("move_left")
		if d.y > 4.0: Input.action_press("move_down")
		if d.y < -4.0: Input.action_press("move_up")
		await frame()
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	return pl.global_position.distance_to(p) < 12.0

func item(kind: String) -> Item:
	for it in game.room.items:
		if it.kind == kind:
			return it
	return null

func _initialize() -> void:
	Engine.time_scale = 4.0
	await run()
	if not finished:
		print("FAIL  run aborted before the last step (script error?)")
		failures += 1
	Engine.time_scale = 1.0
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func run() -> void:
	await boot()
	var room := game.room
	var hero := game.hero
	var player := game.player
	var light := game.light
	var dn := game.daynight
	var t := room.tile_pos
	hero.rng.seed = 7

	# ---- boot / intro
	check(game.gs == GameManager.GS.INTRO, "starts in INTRO")
	await wait_until(func(): return false, 1.0)
	check(hero.state == Hero.State.IDLE, "hero does not move before the game starts")

	# ---- the guide is a ghost: floats through the fence and river, but not houses
	player.active = true
	player.global_position = t.call(20, 5)
	check(await walk_player_to(t.call(25, 5)), "guide floats through the village fence")
	check(await walk_player_to(t.call(35, 5), 30.0), "guide floats over the river")
	player.global_position = t.call(15, 5)
	Input.action_press("move_right")
	await wait_until(func(): return false, 2.0)
	Input.action_release("move_right")
	check(player.global_position.x < 16 * 32, "guide is blocked by a house (x=%.0f)" % player.global_position.x)

	# ---- interaction range + environmental lights
	player.global_position = t.call(10, 22)
	await frame(); await frame()
	check(player.target == null and player.point_target == null, "no E or Q target when out of range")
	player.global_position = room.lampposts[0].global_position + Vector2(24, 0)
	await frame(); await frame()
	check(player.target == room.lampposts[0], "lamppost targeted when in range")
	await press("interact")
	check(room.lampposts[0].lit and light.is_lit(room.lampposts[0].global_position + Vector2(80, 0)), "E switches the lamppost on; its light counts as lit")
	await press("interact")
	check(not room.lampposts[0].lit, "E switches it off again")
	await press("point")
	check(not room.lampposts[0].lit, "Q does not switch lampposts (E and Q are separate)")
	player.global_position = room.player_start
	for i in 21:
		await press("light")
	check(not light.lantern_on, "21 rapid lantern toggles leave a consistent state")
	light.set_lantern(true)

	# ---- start, pause
	await press("interact")
	check(game.gs == GameManager.GS.PLAYING, "E starts the game")
	await press("pause")
	check(paused and game.gs == GameManager.GS.PAUSED, "Esc pauses")
	var hx := hero.global_position
	await wait_until(func(): return false, 1.0)
	check(hero.global_position.distance_to(hx) < 0.5, "hero frozen while paused")
	await press("pause")
	check(not paused and game.gs == GameManager.GS.PLAYING, "Esc resumes")

	# ---- day / night magic
	check(not dn.is_night, "the game starts at day")
	await press("magic")
	check(dn.is_night, "F switches to night")
	await press("magic")
	check(dn.is_night, "F again during the cooldown does nothing (no spam)")
	dn._cd = 0.0
	await press("magic")
	check(not dn.is_night, "after the cooldown, F switches back to day")
	dn._cd = 0.0

	# ---- hidden things: key shows only at night, axe only in light
	var key := item("key")
	var axe := item("axe")
	await frame(); await frame()
	check(not key.is_revealed() and not key.enabled, "by day the key is hidden and cannot be pointed at")
	dn.set_night(true)
	await frame(); await frame()
	check(key.is_revealed() and key.enabled, "at night the key is revealed (fireflies)")
	dn.set_night(false)
	player.global_position = t.call(3, 21)
	await frame(); await frame()
	check(not axe.is_revealed(), "the axe is hidden without light")
	player.global_position = axe.global_position + Vector2(0, 50)
	await frame(); await frame()
	check(axe.is_revealed(), "lantern light reveals the axe in the hollow tree")
	player.global_position = t.call(3, 21)

	# ---- guidance: light lures him; pointing is sometimes followed, sometimes ignored
	hero.visited = {}
	player.global_position = item("fish").global_position
	await frame(); await frame()
	var fish_picks := 0
	for i in 60:
		var n0 := hero.pick_next()
		if light.is_lit(n0.pos):
			fish_picks += 1
	check(fish_picks >= 45, "lantern light lures him: he chooses something lit %d/60 times" % fish_picks)
	light.set_lantern(false)
	var unlit_fish := 0
	for i in 60:
		var n := hero.pick_next()
		if n.kind == "grab" and n.item == item("fish"):
			unlit_fish += 1
	check(unlit_fish < fish_picks / 2, "unlit, he has no special interest in that spot (fish %d/60)" % unlit_fish)
	light.set_lantern(true)
	player.global_position = t.call(3, 21)
	await frame()
	var heard := 0
	var ignored := 0
	for i in 40:
		hero._point_cd = 0.0
		hero.state = Hero.State.LOOK
		hero.task = {"kind": "wander", "id": "wander", "pos": t.call(5, 5)}
		hero.hear_point(item("hammer"))
		if hero.task.kind == "fetch":
			heard += 1
		else:
			ignored += 1
	check(heard > 0 and ignored > 0, "pointing is sometimes followed (%d) and sometimes ignored (%d)" % [heard, ignored])
	hero._point_cd = 0.0
	hero.state = Hero.State.WALK
	hero.hear_point(axe)
	check(hero.task.kind != "fetch", "pointing at something in another region is deflected")

	# ---- the hero blunders on his own
	hero._start_task(hero.pick_next())
	check(await wait_until(func(): return hero.visited.size() >= 1 or game.blunders >= 1, 90.0), "he wanders, grabs or messes with things on his own")

	# ---- gate: wrong item fails, then pointing at the real key works
	var hammer := item("hammer")
	hero.held = ""
	hero._take(hammer)
	hero.global_position = t.call(18, 18)
	hero._start_task(hero._quest[0])
	check(await wait_until(func(): return hero.state == Hero.State.WAIT and hero.task.kind == "obstacle", 40.0), "holding a hammer, he reaches the locked gate and fails")
	check(not room.gate.solved and hammer.broken and hero.held == "", "the wrong item breaks and the gate stays locked")
	dn.set_night(true)
	player.global_position = key.global_position + Vector2(0, -30)
	await frame(); await frame()
	check(player.point_target == key and player.target != key, "at night the guide can target the hidden key with Q (not E)")
	var fetched := false
	for i in 12:
		await press("point")
		hero._point_cd = 0.0
		if hero.task.kind == "fetch":
			fetched = true
			break
		await wait_until(func(): return false, 0.3)
	check(fetched, "pointing at the key (Q) sends him to fetch it")
	check(await wait_until(func(): return room.gate.solved, 60.0), "with the key he opens the gate (and takes the credit)")
	check(await wait_until(func(): return hero._region == 1, 20.0), "he walks through the opened gate")

	# ---- river: no stones by day => he falls; night => stones; day mid-cross => splash
	dn.set_night(false)
	check(await wait_until(func(): return hero.state == Hero.State.WAIT and hero.task.kind == "river", 90.0), "he reaches the river")
	check(await wait_until(func(): return hero.falls >= 1, 40.0), "by day there are no stones, so he falls in")
	check(await wait_until(func(): return hero.state == Hero.State.WAIT, 20.0), "he is fished out and tries again")
	dn.set_night(true)
	check(await wait_until(func(): return hero.state == Hero.State.WALK and hero.global_position.x > 31 * 32, 15.0), "at night the stones appear and he steps onto them")
	var falls_before := hero.falls
	dn.set_night(false)
	check(await wait_until(func(): return hero.falls > falls_before, 5.0), "day mid-crossing: the stones vanish and he splashes")
	check(await wait_until(func(): return hero.state == Hero.State.WAIT, 20.0), "recovered at the west bank")
	dn.set_night(true)
	check(await wait_until(func(): return hero._region == 2, 30.0), "he crosses at night")

	# ---- werewolves: night brings them, day burns them
	check(await wait_until(func(): return room.ambush_spawned, 20.0), "night in the forest: werewolves ambush him")
	check(room.wolves_active(), "the werewolves are chasing")
	check(await wait_until(func(): return hero.state in [Hero.State.PANIC, Hero.State.STUN], 5.0), "the hero panics (or gets mauled)")
	dn.set_night(false)
	check(await wait_until(func(): return room.wolves.is_empty() and room.ambush_done, 6.0), "daylight burns the werewolves away")
	check(await wait_until(func(): return hero.state != Hero.State.PANIC and hero.state != Hero.State.STUN, 15.0), "he recovers and carries on")

	# ---- log: needs the axe from the hollow tree
	check(await wait_until(func(): return hero.state == Hero.State.WAIT and hero.task.kind == "obstacle" and hero._region == 2, 150.0), "he reaches the fallen log")
	check(not room.log_obstacle.solved, "the log blocks him until he has the axe")
	game.light.set_lantern(true)
	player.global_position = axe.global_position + Vector2(0, 45)
	await frame(); await frame()
	fetched = false
	for i in 14:
		await press("point")
		hero._point_cd = 0.0
		if hero.task.kind == "fetch":
			fetched = true
			break
		await wait_until(func(): return false, 0.3)
	check(fetched or room.log_obstacle.solved, "pointing at the axe sends him to fetch it")
	check(await wait_until(func(): return room.log_obstacle.solved, 80.0), "he chops through the log")

	# ---- finish
	check(await wait_until(func(): return room.pedestal.lamp_present == false, 90.0), "he takes the Sacred Lamp (and drops it on his foot)")
	check(await wait_until(func(): return game.gs == GameManager.GS.COMPLETE, 60.0), "quest complete state reached")
	await press("interact")
	check(game.gs == GameManager.GS.TWIST, "E starts the villagers' ending")
	check(await wait_until(func(): return game.gs == GameManager.GS.END, 200.0), "the ending plays through to the end card")
	var said := {}
	for e in hero.guide_log:
		said[e.text] = true
	var replay_ok := game.twist_lines.size() >= 6
	var foreign := ""
	for line in game.twist_lines:
		if not said.has(line):
			replay_ok = false
			foreign = line
	check(replay_ok, "every line the hero speaks in the ending is one he said in the game (%d replayed%s)" % [game.twist_lines.size(), ", foreign: " + foreign if foreign != "" else ""])

	# ---- restart + stuck failsafe
	await press("restart")
	await wait_until(func(): return false, 0.5)
	await frame()
	var g2: GameManager = current_scene as GameManager
	check(g2 != null and g2 != game, "restart reloads a fresh scene")
	game = g2
	check(game.gs == GameManager.GS.INTRO and not game.room.gate.solved and game.room.pedestal.lamp_present and not game.daynight.is_night, "fresh scene is in its initial state")
	game.room.add_block_for_test()
	game.hero.rng.seed = 3
	game.player.active = false
	await press("interact")
	check(await wait_until(func(): return game.hero.visited.size() >= 1 or game.blunders >= 1 or game.hero.state == Hero.State.LOOK, 90.0), "hero walled off from his first goal still gets places (failsafe)")
	finished = true
