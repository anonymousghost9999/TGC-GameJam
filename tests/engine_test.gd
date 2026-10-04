extends SceneTree
## Rule tests for the lamp/hero engine, straight from the design plan (checklist
## section "Hero", "Lamps", "Inversion").
## Run: godot --headless --path . --fixed-fps 60 -s tests/engine_test.gd

var failures := 0

func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await physics_frame

## Blank 30x17 room with a border; `put` maps "x,y" -> char.
func room(put: Dictionary) -> Dictionary:
	var rows: Array[String] = []
	for y in 17:
		var s := ""
		for x in 30:
			var ch := "."
			if x == 0 or y == 0 or x == 29 or y == 16:
				ch = "#"
			var k := "%d,%d" % [x, y]
			if put.has(k):
				ch = put[k]
			s += ch
		rows.append(s)
	return {"name": "test", "map": rows, "exit_on": false}

var _holder: Node

## Builds Level + LampManager + Hero (+ Inversion) and returns them.
func build(put: Dictionary, global := false, hero_tile := Vector2i(5, 8), seed_v := 1) -> Dictionary:
	if _holder != null:
		_holder.queue_free()
	_holder = Node2D.new()
	root.add_child(_holder)
	var lm := LampManager.new()
	lm.global_mode = global
	_holder.add_child(lm)
	var inv := Inversion.new()
	inv.manager = lm
	inv.unlocked = true
	_holder.add_child(inv)
	var lvl := Level.new()
	lvl.setup(room(put), lm)
	_holder.add_child(lvl)
	var hero: Hero = (load("res://scenes/hero.tscn") as PackedScene).instantiate()
	hero.level = lvl
	hero.lamps = lm
	_holder.add_child(hero)
	hero.rng.seed = seed_v
	hero.place(lvl.cell_center(hero_tile))
	hero.start()
	await frames(2)
	return {"lvl": lvl, "lm": lm, "hero": hero, "inv": inv}

func lamps_of(lm: LampManager, color: int) -> Array[Lamp]:
	var out: Array[Lamp] = []
	for l in lm.lamps:
		if l.original == color:
			out.append(l)
	return out

func _initialize() -> void:
	# the hero must be unable to change lamp state: only the NPC (player) switches lamps
	var src := FileAccess.get_file_as_string("res://scripts/hero.gd")
	var forbidden := ["switch_lamp", "set_on(", ".on =", "start_on", "reset_states"]
	var hits: Array[String] = []
	for f: String in forbidden:
		if src.contains(f):
			hits.append(f)
	check(hits.is_empty(), "the hero's script never changes a lamp (only reads them): forbidden calls found: %s" % str(hits))
	var npc_src := FileAccess.get_file_as_string("res://scripts/npc.gd")
	check(npc_src.contains("switch_lamp"), "the NPC's script is what switches lamps")
	await run()
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func run() -> void:
	# ---- green: toward, and stops at the lamp
	var w := await build({"10,8": "G"})
	var h: Hero = w.hero
	var x0 := h.global_position.x
	await frames(30)
	check(h.global_position.x > x0 + 20.0, "green: hero moves toward the lamp")
	await frames(240)
	var d_stop := h.global_position.distance_to(w.lm.lamps[0].global_position)
	check(d_stop < Hero.STAND_OFF + 3.0 and d_stop > Hero.STAND_OFF - 6.0 and h.speed_now < 1.0, "green: hero walks up to the lamp and stops BESIDE it (%.0f px away), so the lamp stays visible" % d_stop)
	var sp_green := 0.0
	w = await build({"10,8": "G"})
	await frames(20)
	sp_green = w.hero.speed_now

	# ---- red: away
	w = await build({"6,8": "R"}, false, Vector2i(7, 8))
	h = w.hero
	x0 = h.global_position.x
	await frames(30)
	check(h.global_position.x > x0 + 20.0, "red: hero moves away from the lamp")

	# ---- orange: slowly toward (0.4x speed)
	w = await build({"10,8": "O"})
	await frames(20)
	var sp_orange: float = w.hero.speed_now
	check(w.hero.global_position.x > 5 * 32 + 16 and absf(sp_orange - Hero.SPEED * Hero.ORANGE_FACTOR) < 3.0 and sp_green > sp_orange * 2.0, "orange: hero moves slowly toward the lamp (%.0f vs green %.0f px/s)" % [sp_orange, sp_green])

	# ---- blue: freezes completely
	w = await build({"9,8": "B"})
	h = w.hero
	var p0 := h.global_position
	await frames(120)
	check(h.global_position.distance_to(p0) < 0.5, "blue: hero freezes completely")

	# ---- no influence: random wandering after a confused beat
	w = await build({"20,3": "g"})   # the only lamp is OFF: nothing influences him
	h = w.hero
	p0 = h.global_position
	await frames(20)
	check(h.global_position.distance_to(p0) < 0.5 and h.mood == "confused", "no lamp: hero first stands confused")
	await frames(120)
	check(h.global_position.distance_to(p0) > 15.0, "no lamp: hero then wanders randomly")

	# ---- no radius: the nearest active lamp influences him from anywhere
	w = await build({"26,14": "G"}, false, Vector2i(3, 2))
	check(w.lm.nearest_active(w.hero.global_position) != null, "lamps have no radius: a far-away active lamp still influences him")
	var px_far: float = w.hero.global_position.x
	await frames(30)
	check(w.hero.global_position.x > px_far + 20.0, "...and he walks toward it")
	w = await build({"26,14": "G", "4,8": "G"}, false, Vector2i(3, 2))
	check(w.lm.nearest_active(w.hero.global_position).global_position.x < 200.0, "the nearer of two active lamps wins")
	w = await build({"3,3": "R"}, false, Vector2i(26, 14))
	check(w.lm.nearest_active(w.hero.global_position) != null, "a red lamp pushes him from anywhere; he never falls back to random while it is ON")
	await frames(60)
	check(w.hero.mood != "confused", "...so he is not 'lost' while any lamp is active")

	# ---- closest active lamp wins
	w = await build({"3,8": "R", "10,8": "G"}, false, Vector2i(5, 8))   # red is 2 tiles away, green 5
	check(w.lm.nearest_active(w.hero.global_position) == w.lm.lamps[0], "closest active lamp is selected (red, 2 tiles, beats green, 5 tiles)")
	await frames(30)
	check(w.hero.global_position.x > 5 * 32 + 16 + 15.0, "hero obeys the closest lamp (runs from red, not to green)")

	# ---- OFF lamps do nothing
	w = await build({"9,8": "g"})
	check(w.lm.nearest_active(w.hero.global_position) == null, "an OFF lamp has no influence")

	# ---- hazards kill; random walk can trigger them
	var box := {}
	for x in range(1, 29):
		for y in range(1, 16):
			if not (x == 14 and y == 8):
				box["%d,%d" % [x, y]] = "^"
	w = await build(box, false, Vector2i(14, 8), 3)
	h = w.hero
	await frames(400)
	check(h.state == Hero.State.DEAD and h.death_kind == "spike", "random movement walks into spikes and he dies")
	w = await build({"6,8": "~"}, false, Vector2i(5, 8))
	w.hero.global_position = w.lvl.cell_center(Vector2i(6, 8))
	await frames(3)
	check(w.hero.state == Hero.State.DEAD and w.hero.death_kind == "fire", "fire kills")
	w = await build({"6,8": "x"}, false, Vector2i(5, 8))
	w.hero.global_position = w.lvl.cell_center(Vector2i(6, 8))
	await frames(3)
	check(w.hero.state == Hero.State.DEAD and w.hero.death_kind == "trap", "a hidden trap floor kills")

	# ---- global same-colour state (lamps found by colour, not by scan order)
	w = await build({"8,3": "g", "20,12": "g", "8,12": "r"}, true)
	var lm: LampManager = w.lm
	var greens := lamps_of(lm, LampColors.C.GREEN)
	var red: Lamp = lamps_of(lm, LampColors.C.RED)[0]
	lm.switch_lamp(greens[0])
	check(greens[0].on and greens[1].on and not red.on, "global mode: switching one green lamp turns ALL green lamps on (red untouched)")
	lm.switch_lamp(greens[1])
	check(not greens[0].on and not greens[1].on, "global mode: switching it again turns them all off")
	w = await build({"8,3": "g", "20,12": "g"}, false)
	greens = lamps_of(w.lm, LampColors.C.GREEN)
	w.lm.switch_lamp(greens[0])
	check(greens[0].on and not greens[1].on, "independent mode: only the switched lamp changes")

	# ---- inversion
	w = await build({"12,8": "G", "3,3": "r", "3,13": "o", "25,3": "b"})
	lm = w.lm
	var inv: Inversion = w.inv
	var h2: Hero = w.hero
	var g := lamps_of(lm, LampColors.C.GREEN)[0]
	var r := lamps_of(lm, LampColors.C.RED)[0]
	var o := lamps_of(lm, LampColors.C.ORANGE)[0]
	var b := lamps_of(lm, LampColors.C.BLUE)[0]
	check(g.current_color() == LampColors.C.GREEN, "before inversion: green lamp is green")
	check(inv.try_activate(), "inversion activates when ready")
	check(g.current_color() == LampColors.C.RED and r.current_color() == LampColors.C.GREEN and o.current_color() == LampColors.C.BLUE and b.current_color() == LampColors.C.ORANGE, "inversion: green->red, red->green, orange->blue, blue->orange (visible colour and behaviour)")
	var px := h2.global_position.x
	await frames(30)
	check(h2.global_position.x < px - 15.0, "inverted green lamp now repels the hero (behaviour follows the colour)")
	check(not inv.try_activate(), "cannot re-activate while active")
	await frames(300)   # 5 s
	check(not inv.active and g.current_color() == LampColors.C.GREEN and b.current_color() == LampColors.C.BLUE, "after 5 s the original colours and behaviours return")
	check(inv.cooldown > 9.0 and not inv.try_activate(), "10 s cooldown starts and blocks activation")
	await frames(540)
	check(inv.cooldown > 0.5 and not inv.try_activate(), "still cooling down after ~9 s")
	await frames(90)
	check(inv.cooldown == 0.0 and inv.try_activate(), "usable again after the 10 s cooldown")
	# toggling a lamp during inversion groups by its ORIGINAL colour
	w = await build({"8,3": "g", "20,12": "g", "8,12": "r"}, true)
	w.inv.try_activate()
	greens = lamps_of(w.lm, LampColors.C.GREEN)
	w.lm.switch_lamp(greens[0])
	check(greens[0].on and greens[1].on and not lamps_of(w.lm, LampColors.C.RED)[0].on, "inverted + global: switching groups by ORIGINAL colour")
