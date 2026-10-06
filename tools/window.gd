extends SceneTree
## Dev tool: how forgiving is each step of a level's solution? For every tunable entry
## (absolute time, or the row/column of a position trigger) it nudges that one value up and
## down, keeping the rest, and reports the contiguous range that still reaches the exit.
##   LEVEL=l12 [SCHEDULE='[[...]]'] godot --headless --path . --fixed-fps 60 -s tools/window.gd
## Narrow windows = precise timing. (Presses are instant here; the walking-NPC check is levels_test.)

func ok(data: Dictionary, sched: Array) -> bool:
	var r := await LevelSim.run(self, data, sched, 90.0)
	return r.result.begins_with("DIED") if data.id == "l9k" else r.result == "EXIT"

func _initialize() -> void:
	var data: Dictionary = LevelData.by_id(OS.get_environment("LEVEL"))
	var sched: Array = data.solution.duplicate(true)
	if OS.get_environment("SCHEDULE") != "":
		sched = JSON.parse_string(OS.get_environment("SCHEDULE"))
	print("base: ", "OK" if await ok(data, sched) else "FAILS")
	for i in sched.size():
		var e: Array = sched[i]
		var trig := float(e[0])
		var field := -1
		var step := 0.05
		if trig >= 0.0:
			field = 0
		elif trig in [-2.0, -3.0, -4.0]:
			field = 3
			step = 0.1
		if field < 0:
			continue
		var base := float(e[field])
		var lo := base
		var hi := base
		for dir in [-1.0, 1.0]:
			var v := base
			for k in 60:
				v += dir * step
				if field == 0 and v < 0.0:
					break
				var s2: Array = sched.duplicate(true)
				s2[i][field] = v
				if not await ok(data, s2):
					break
				if dir < 0.0:
					lo = v
				else:
					hi = v
		var unit := "s" if field == 0 else (" rows" if trig != -3.0 else " cols")
		print("entry %d %s: %.2f, works from %.2f to %.2f  (window %.2f%s)" % [i, str(e), base, lo, hi, hi - lo, unit])
	quit()
