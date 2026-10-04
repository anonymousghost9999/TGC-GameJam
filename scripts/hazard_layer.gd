class_name HazardLayer
extends Node2D
## Animated hazards (spikes, fire, timed spikes, sprung traps), drawn above the floor.

var level: Level

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := level.clock
	for c: Vector2i in level.hazards:
		var kind: String = level.hazards[c]
		var r := Rect2(c.x * Level.TILE, c.y * Level.TILE, Level.TILE, Level.TILE)
		var o := r.position
		match kind:
			"^":
				_spikes(o, 1.0)
			"~":
				for i in 3:
					var h := 10.0 + 6.0 * sin(t * 7.0 + c.x + i * 2.0)
					var fx := o.x + 7.0 + i * 9.0
					draw_colored_polygon(PackedVector2Array([Vector2(fx - 6, o.y + 28), Vector2(fx + 6, o.y + 28), Vector2(fx, o.y + 28 - h - 8)]), Color(1.0, 0.45, 0.1, 0.95))
					draw_colored_polygon(PackedVector2Array([Vector2(fx - 3, o.y + 28), Vector2(fx + 3, o.y + 28), Vector2(fx, o.y + 28 - h)]), Color(1.0, 0.85, 0.3, 0.95))
			"t", "u":
				draw_rect(r.grow(-4), Color(0.12, 0.1, 0.14))
				if level.timed_active(kind):
					_spikes(o, 1.0)
				elif level.timed_warning(kind):
					_spikes(o + Vector2(sin(t * 60.0) * 1.5, 0), 0.55)   # twitching: about to come out
				else:
					_spikes(o, 0.18)   # retracted: just the tips
			"x":
				if level.sprung.has(c):
					_spikes(o, 1.0)

func _spikes(o: Vector2, k: float) -> void:
	draw_rect(Rect2(o + Vector2(3, 3), Vector2(Level.TILE - 6, Level.TILE - 6)), Color(0.1, 0.08, 0.12))
	for i in 3:
		for j in 3:
			var bx := o.x + 7.0 + i * 9.0
			var by := o.y + 11.0 + j * 9.0
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, by + 4), Vector2(bx + 4, by + 4), Vector2(bx, by + 4 - 12.0 * k)]), Color(0.82, 0.84, 0.9))
