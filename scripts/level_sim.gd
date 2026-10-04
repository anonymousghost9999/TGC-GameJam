class_name LevelSim
extends RefCounted
## Headless simulation of a level using the REAL hero physics and lamp rules, driven
## by a schedule of lamp switches. Used by tools/trace.gd and tests/levels_test.gd to
## prove every level is solvable and that the known mistakes really fail.
##
## Schedules: see schedule.gd.

## with_npc: also walk the NPC to each lamp at his real speed (a player cannot teleport); the result then carries `presses`.
static func run(tree: SceneTree, data: Dictionary, schedule: Array, max_t := 60.0, seed_v := 1, with_npc := false) -> Dictionary:
	var holder := Node2D.new()
	tree.root.add_child(holder)
	var lm := LampManager.new()
	lm.global_mode = data.get("global", false)
	holder.add_child(lm)
	var inv := Inversion.new()
	inv.manager = lm
	inv.unlocked = data.get("invert", false)
	holder.add_child(inv)
	var lvl := Level.new()
	lvl.setup(data, lm)
	holder.add_child(lvl)
	var hero: Hero = (load("res://scenes/hero.tscn") as PackedScene).instantiate()
	hero.level = lvl
	hero.lamps = lm
	hero.record_trace = true
	holder.add_child(hero)
	var npc: Npc = null
	if with_npc:
		npc = (load("res://scenes/npc.tscn") as PackedScene).instantiate()
		npc.lamps = lm
		npc.inversion = inv
		holder.add_child(npc)
	await tree.process_frame   # Level._ready() builds the map
	if npc != null:
		npc.place(lvl.npc_start)
	hero.rng.seed = seed_v
	hero.place(lvl.hero_start)
	hero.start()
	var res := {"v": "TIMEOUT"}
	hero.died.connect(func(k: String) -> void: res.v = "DIED(" + k + ")")
	hero.reached_exit.connect(func() -> void: if res.v == "TIMEOUT": res.v = "EXIT")
	var t := 0.0
	var sch := Schedule.new(schedule)
	var bot := NpcBot.new(schedule)
	while t < max_t and res.v == "TIMEOUT":
		if with_npc:
			bot.step(t, hero, lm, inv, npc)
		else:
			sch.step(t, hero, lm, inv)
		await tree.physics_frame
		t += 1.0 / 60.0
	var out := {"result": res.v, "time": t, "presses": bot.presses.duplicate(), "cell": lvl.cell_of(hero.global_position), "trace": hero.trace.duplicate(), "lamps": lm.lamps.duplicate(), "level": lvl}
	holder.queue_free()
	return out
