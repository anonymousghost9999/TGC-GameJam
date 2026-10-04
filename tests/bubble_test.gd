extends SceneTree
## Speech bubbles must stay on screen and wrap to at most 3 lines, wherever the speaker stands.
## Run: godot --headless --path . -s tests/bubble_test.gd
var failures := 0
func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func _initialize() -> void:
	var texts := [
		"Hi.",
		"Only I can touch the lamps. He simply walks to the nearest lit one.",
		"The lock is broken, and the dungeon is mine again. Now: let us see how well you walk among MY lamps.",
		"Thank you. Truly. Four thousand years I waited for someone foolish enough, and here you are, in my dungeon, breaking my lock.",
	]
	var spots := [Vector2(20, 60), Vector2(940, 60), Vector2(20, 500), Vector2(940, 500), Vector2(480, 70), Vector2(480, 300), Vector2(60, 280), Vector2(900, 280)]
	var bad := 0
	var worst_lines := 0
	for text: String in texts:
		for p: Vector2 in spots:
			var holder := Node2D.new()
			holder.position = p
			root.add_child(holder)
			var b := Bubble.new()
			b.rise = 58.0
			holder.add_child(b)
			b.say(text, 5.0)
			await process_frame
			await process_frame
			var r := Rect2(b.global_position, b.size)
			var inside := r.position.x >= 0.0 and r.end.x <= 960.0 and r.position.y >= 46.0 and r.end.y <= 520.0
			if not inside:
				bad += 1
				print("   off-screen: '%s...' at %s -> %s" % [text.left(24), p, r])
			worst_lines = maxi(worst_lines, b.text.count("\n") + 1)
			holder.queue_free()
	check(bad == 0, "every bubble stays fully on screen and clear of the HUD bars (32 placements)")
	check(worst_lines <= 3, "no bubble needs more than 3 lines (worst case %d)" % worst_lines)
	print("\nRESULT: %d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
