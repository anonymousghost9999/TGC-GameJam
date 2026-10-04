extends SceneTree
## Brute-force: how many SIMPLE strategies kill the hero in the final trial?
## Tries every single lamp switch, and every ordered pair of switches, at times 0.5 .. 11.5 s.
##   LEVEL=l9k godot --headless --path . --fixed-fps 60 -s tools/fuzz_trial.gd
func _initialize() -> void:
	var data: Dictionary = LevelData.by_id(OS.get_environment("LEVEL") if OS.get_environment("LEVEL") != "" else "l9k")
	var n_lamps := 4
	var acts: Array = []
	for t in 12:
		for l in n_lamps:
			acts.append([0.5 + t, "sw", l])
		acts.append([0.5 + t, "inv"])
	var kills1 := 0
	var total1 := 0
	for a in acts:
		var r := await LevelSim.run(self, data, [a], 24.0)
		total1 += 1
		if r.result.begins_with("DIED"):
			kills1 += 1
			print("  1-action kill: ", a)
	print("single switches: %d / %d kill him" % [kills1, total1])
	var kills2 := 0
	var total2 := 0
	for i in acts.size():
		for j in range(i, acts.size()):
			var a: Array = acts[i]
			var b: Array = acts[j]
			if float(b[0]) < float(a[0]):
				continue
			var r := await LevelSim.run(self, data, [a, b], 24.0)
			total2 += 1
			if r.result.begins_with("DIED"):
				kills2 += 1
				if kills2 <= 12:
					print("  2-action kill: ", a, " + ", b)
	print("pairs of switches: %d / %d kill him" % [kills2, total2])
	quit()
