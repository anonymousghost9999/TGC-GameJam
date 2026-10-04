extends SceneTree
## Dev tool: run a level with a lamp-switch schedule and print the hero's path.
##   LEVEL=l3 SCHEDULE='[[1.0,"on",0],[-2,"off",0,12]]' MAXT=40 \
##     godot --headless --path . --fixed-fps 60 -s tools/trace.gd
## (schedule format: see scripts/level_sim.gd). Omit SCHEDULE to use the level's stored solution.

func _initialize() -> void:
	var data: Dictionary = LevelData.by_id(OS.get_environment("LEVEL"))
	var sched: Array = data.get("solution", [])
	if OS.get_environment("SCHEDULE") != "":
		sched = JSON.parse_string(OS.get_environment("SCHEDULE"))
	var max_t := float(OS.get_environment("MAXT")) if OS.get_environment("MAXT") != "" else 60.0
	var walk := OS.get_environment("WALK") == "1"   # WALK=1: use the realistic walking NPC
	var r := await LevelSim.run(self, data, sched, max_t, 1, walk)
	var rows: Array = data.map
	var grid: Array = []
	for y in 17:
		grid.append(Array((rows[y] as String).split("")))
	var lamps: Array = r.lamps
	for i in lamps.size():
		var c := (r.level as Level).cell_of((lamps[i] as Lamp).position)
		grid[c.y][c.x] = str(i)
	var n := 0
	for p: Vector2 in r.trace:
		n += 1
		if n % 12 != 0:
			continue
		var c2 := (r.level as Level).cell_of(p)
		if grid[c2.y][c2.x] in [".", "H", "N"]:
			grid[c2.y][c2.x] = "*"
	for y in 17:
		print("".join(grid[y]))
	print("RESULT %s t=%.1f hero_cell=(%d,%d)" % [r.result, r.time, r.cell.x, r.cell.y])
	if walk:
		print("PRESSES ", str(r.presses))
	quit()
