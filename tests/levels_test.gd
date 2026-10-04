extends SceneTree
## Proves every level is solvable and that its known mistakes really fail, using
## the real hero physics. Also checks the par time is achievable and that every level
## has the green exit lamp and a start for both characters.
## Run: godot --headless --path . --fixed-fps 60 -s tests/levels_test.gd

var failures := 0

func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func _initialize() -> void:
	await run()
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)

func run() -> void:
	var all: Array[Dictionary] = []
	for id in ["l1", "l2", "l3", "l4", "l5", "l6", "l7", "l8", "l9", "l9k"]:
		var d := LevelData.by_id(id)
		check(not d.is_empty(), "level %s exists" % id)
		all.append(d)
	for d in all:
		var id: String = d.id
		var sol: Array = d.solution
		var r := await LevelSim.run(self, d, sol, 120.0, 1, id != "l9k")
		if id == "l9k":
			check(r.result.begins_with("DIED"), "%s: the kill schedule kills the hero (%s at %.1fs)" % [id, r.result, r.time])
		else:
			check(r.result == "EXIT", "%s: the verified solution reaches the exit (%s at %.1fs)" % [id, r.result, r.time])
			var par := float(d.par)
			if r.result == "EXIT" and par > 0.0:
				check(r.time <= par and r.time >= par - 5.0, "%s: par %ds = fastest solve (%.2fs, walking NPC) + 4s" % [id, int(par), r.time])
		for m: Dictionary in d.mistakes:
			var rm := await LevelSim.run(self, d, m.schedule, 90.0)
			var ok := false
			match m.expect:
				"DIED": ok = rm.result.begins_with("DIED")
				"EXIT": ok = rm.result == "EXIT"
				"SURVIVES": ok = not rm.result.begins_with("DIED")   # stays alive (e.g. stuck): the strategy does not kill him
				"NOEXIT": ok = rm.result != "EXIT"   # died or simply never arrived
			check(ok, "%s mistake: %s -> %s (expected %s)" % [id, m.name, rm.result, m.expect])
		if id == "l9k":
			# The final trial must be a puzzle, not a one-press trap. Only the RED lamp can ever kill him with a lone press, and
			# only in a narrow (~1 s) window: every other single switch (any lamp, any time) and the invert lantern never kill.
			var other_kills := 0
			var red_kills := 0
			var red_samples := 0
			for t in 12:
				for l in 3:
					if l == 1:
						continue   # lamp 1 is the red lamp, measured separately below
					var rs := await LevelSim.run(self, d, [[0.5 + t, "sw", l]], 24.0)
					if rs.result.begins_with("DIED"):
						other_kills += 1
				var ri := await LevelSim.run(self, d, [[0.5 + t, "inv"]], 24.0)
				if ri.result.begins_with("DIED"):
					other_kills += 1
			var tt := 0.5
			while tt < 12.0:
				var rr := await LevelSim.run(self, d, [[tt, "sw", 1]], 24.0)
				red_samples += 1
				if rr.result.begins_with("DIED"):
					red_kills += 1
				tt += 0.25
			check(other_kills == 0, "%s: no lone green switch, blue-less switch or inversion ever kills him (%d found)" % [id, other_kills])
			check(red_kills * 0.25 <= 1.5, "%s: a lone red press kills him only in a narrow window (%d of %d presses = %.2f s of 12 s)" % [id, red_kills, red_samples, red_kills * 0.25])
		# structure
		var lvl := Level.new()
		var lm := LampManager.new()
		lvl.setup(d, lm)
		root.add_child(lm)
		root.add_child(lvl)
		await process_frame
		var exit_lamps := 0
		for l in lm.lamps:
			if l.is_exit:
				exit_lamps += 1
		check(exit_lamps == 1 and lm.lamps.size() >= 1, "%s: has exactly one green exit lamp (%d lamps total)" % [id, lm.lamps.size()])
		var exit_lamp: Lamp = null
		for l in lm.lamps:
			if l.is_exit:
				exit_lamp = l
		check(exit_lamp != null and exit_lamp.original == LampColors.C.GREEN, "%s: the exit lamp is green" % id)
		check(lvl.hero_start != Vector2.ZERO and lvl.npc_start != Vector2.ZERO, "%s: hero and NPC starts exist" % id)
		# plan rule 13: all lamps of the same colour share ONE ON/OFF state, in every level
		check(d.get("global", false) == true, "%s: same-colour lamps share one state (global mode is on)" % id)
		var consistent := true
		for c in 4:
			var seen := []
			for l in lm.lamps:
				if l.original == c:
					seen.append(l.start_on)
			for v in seen:
				if v != seen[0]:
					consistent = false
		check(consistent, "%s: no two lamps of the same colour start in different states" % id)
		lvl.queue_free()
		lm.queue_free()
