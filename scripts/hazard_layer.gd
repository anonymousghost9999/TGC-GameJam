class_name HazardLayer
extends Node2D
## Animated hazards (spikes, fire, timed spikes, sprung traps) and the sleeping ogre,
## drawn above the floor. Spikes and the ogre are CC0 sprites (see sprites.gd).

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
				if level.timed_active(kind):
					_spikes(o, 1.0)
				elif level.timed_warning(kind):
					_spikes(o + Vector2(sin(t * 60.0) * 1.5, 0), 0.7)   # twitching: about to come out
				else:
					_spikes(o, 0.3)   # retracted: a dim plate
			"x":
				if level.sprung.has(c):
					_spikes(o, 1.0)
	for d in level.dragons:   # Gerald the ogre, asleep, and the zone where fast steps wake him
		var breath := 0.5 + 0.5 * sin(t * 1.6)
		draw_circle(d, Level.DRAGON_RADIUS, Color(0.55, 0.1, 0.35, 0.12 + 0.04 * breath))   # his hearing
		for k in 28:   # a soft dotted ring at the edge of his hearing
			var a := TAU * k / 28.0 + t * 0.05
			draw_circle(d + Vector2.from_angle(a) * Level.DRAGON_RADIUS, 2.2, Color(1.0, 0.7, 0.85, 0.45 + 0.25 * breath))
		DrawUtil.ellipse(self, d + Vector2(0, 14), 30, 8, Color(0, 0, 0, 0.35))
		Sprites.draw_ogre(self, d + Vector2(0, 16), 4.0, breath)
		for i in 3:   # floating Zs
			var z := fposmod(t * 0.45 + i / 3.0, 1.0)
			draw_string(UiFont.TITLE, d + Vector2(20 + z * 16 + i * 2, -24 - z * 34), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16 + int(z * 10), Color(0.9, 0.9, 1.0, 0.85 * (1.0 - z)))

## Spikes: the tileset's spike plate. k < 1 dims it (retracted / about to come out).
func _spikes(o: Vector2, k: float) -> void:
	var m := level.tint() * Color(k, k, k)
	Sprites.draw_cell(self, Sprites.SPIKES, Rect2(o, Vector2(Level.TILE, Level.TILE)), m)
