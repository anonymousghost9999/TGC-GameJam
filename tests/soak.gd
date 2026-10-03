extends SceneTree
## Plays the whole game with a "perfect guide" bot over several random seeds:
## finds the hidden key at night and points, holds night while he crosses, flips
## to day when werewolves appear, lights the hollow tree and points at the axe.
## Fails if the hero ever gets stuck.
## Run: godot --headless --path . --fixed-fps 60 -s tests/soak.gd
var sim := 0.0

func frame() -> void:
	await process_frame
	sim += root.get_process_delta_time()

func _initialize() -> void:
	Engine.time_scale = 6.0
	var bad := 0
	for seed_i in [1, 2, 3, 4, 5, 6]:
		var game: GameManager = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(game)
		current_scene = game
		await frame(); await frame()
		game.hero.rng.seed = seed_i
		game._start_game()
		var start := sim
		var room := game.room
		var hero := game.hero
		var dn := game.daynight
		var pl := game.player
		var key: Item = null
		var axe: Item = null
		for it in room.items:
			if it.kind == "key": key = it
			if it.kind == "axe": axe = it
		var point_cd := 0.0
		while game.gs == GameManager.GS.PLAYING and sim - start < 900.0:
			point_cd = maxf(point_cd - 0.1, 0.0)
			var kind: String = hero.task.get("kind", "")
			var waiting: bool = hero.state == Hero.State.WAIT
			if room.wolves_active():
				dn.set_night(false)
			elif waiting and kind == "river":
				dn.set_night(true)
			if waiting and kind == "obstacle" and hero._region == 0:
				dn.set_night(true)
				pl.global_position = key.global_position + Vector2(0, -40)
				if point_cd <= 0.0 and key.available():
					key.interact(pl)
					point_cd = 3.0
			elif waiting and kind == "obstacle" and hero._region == 2:
				game.light.set_lantern(true)
				pl.global_position = axe.global_position + Vector2(0, 40)
				if point_cd <= 0.0 and axe.available():
					axe.interact(pl)
					point_cd = 3.0
			elif not (hero.state == Hero.State.WAIT and kind == "river") and kind != "cross":
				pl.global_position = room.tile_pos(3, 21)
			await frame()
		var ok := game.gs == GameManager.GS.COMPLETE
		print("seed %d: %s in %.0fs  falls=%d blunders=%d" % [seed_i, "FINISHED" if ok else "STUCK", sim - start, hero.falls, game.blunders])
		if not ok:
			bad += 1
			print("   stuck at region=%d state=%d task=%s held=%s night=%s" % [hero._region, hero.state, hero.task.get("kind", "?"), hero.held, dn.is_night])
		game.queue_free()
		await frame()
	print("SOAK RESULT: %d stuck" % bad)
	quit(bad)
