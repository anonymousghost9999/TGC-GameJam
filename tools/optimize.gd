extends SceneTree
## Finds the FASTEST solve of a level that a real (walking) NPC can achieve, by coordinate descent on the
## timing parameters of a seed schedule. Usage:
##   LEVEL=l5 [SEED='[[...]]'] godot --headless --path . --fixed-fps 60 -s tools/optimize.gd
## Prints the best schedule, its completion time and the actual press times.
## Tunable parameters: absolute times (trigger >= 0) and the tile row/column of position triggers (-2/-3/-4).

var data: Dictionary
var best_t := INF

func params_of(sched: Array) -> Array:
	var out: Array = []
	for i in sched.size():
		var e: Array = sched[i]
		var trig := float(e[0])
		if trig >= 0.0:
			out.append([i, 0])
		elif trig in [-2.0, -3.0, -4.0]:
			out.append([i, 3])
	return out

func evaluate(sched: Array, limit: float) -> Dictionary:
	var r := await LevelSim.run(self, data, sched, minf(limit, 120.0), 1, true)
	return r

func _initialize() -> void:
	var id := OS.get_environment("LEVEL")
	data = LevelData.by_id(id)
	var seed_sched: Array = data.solution.duplicate(true)
	if OS.get_environment("SEED") != "":
		seed_sched = JSON.parse_string(OS.get_environment("SEED"))
	var cur: Array = seed_sched
	var r := await evaluate(cur, 90.0)
	var is_kill := id == "l9k"
	var ok := func(res: Dictionary) -> bool: return res.result.begins_with("DIED") if is_kill else res.result == "EXIT"
	if not ok.call(r):
		print("SEED FAILS: %s at %.1fs" % [r.result, r.time])
		quit()
		return
	best_t = r.time
	print("seed: %.2fs" % best_t)
	var ps := params_of(cur)
	for step in [2.0, 1.0, 0.5, 0.25, 0.1]:
		var improved := true
		var rounds := 0
		while improved and rounds < 12:
			improved = false
			rounds += 1
			for p: Array in ps:
				for dir in [-1.0, 1.0]:
					var trial := cur.duplicate(true)
					var e: Array = trial[p[0]]
					var v: float = float(e[p[1]]) + dir * step
					if p[1] == 3:
						if absf(step) < 1.0:
							continue   # tile rows/columns only move in whole tiles
						v = roundf(v)
						if v < 1.0:
							continue
					elif v < 0.0:
						continue
					e[p[1]] = v if p[1] == 0 else int(v)
					var rr := await evaluate(trial, best_t + 4.0)
					if ok.call(rr) and rr.time < best_t - 0.001:
						best_t = rr.time
						cur = trial
						improved = true
	var fin := await evaluate(cur, 120.0)
	print("BEST %s: %.2fs  schedule=%s" % [id, fin.time, JSON.stringify(cur)])
	print("PRESSES %s" % str(fin.presses))
	quit()
