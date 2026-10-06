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
			"~":   # fire: scorched floor, a warm glow, and three flames out of step with each other
				var mid := o + Vector2(Level.TILE * 0.5, Level.TILE * 0.5)
				var pulse := 0.5 + 0.5 * sin(t * 6.0 + c.x * 1.7 + c.y)
				DrawUtil.ellipse(self, mid + Vector2(0, 8), 15, 7, Color(0.05, 0.02, 0.02, 0.55))
				DrawUtil.glow(self, mid, 30.0 + 4.0 * pulse, Color(1.0, 0.45, 0.1, 0.35), 5)
				var fr := int(t * 10.0) + c.x * 2 + c.y * 3
				Sprites.draw_flame(self, mid + Vector2(-8, 12), 1.15, fr)
				Sprites.draw_flame(self, mid + Vector2(8, 13), 1.15, fr + 3)
				Sprites.draw_flame(self, mid + Vector2(0, 15), 1.5, fr + 1)
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
	for i in level.dragons.size():   # Gerald the ogre, asleep, and the zone where fast steps wake him
		var d := level.dragons[i]
		var breath := 0.5 + 0.5 * sin(t * 1.6)
		var awake := level.ogre_idx == i
		if not awake:
			draw_circle(d, Level.DRAGON_RADIUS, Color(0.7, 0.12, 0.3, 0.2 + 0.05 * breath))   # his hearing
			for k in 28:   # a soft dotted ring at the edge of his hearing
				var a := TAU * k / 28.0 + t * 0.05
				draw_circle(d + Vector2.from_angle(a) * Level.DRAGON_RADIUS, 2.2, Color(1.0, 0.7, 0.85, 0.45 + 0.25 * breath))
			DrawUtil.ellipse(self, d + Vector2(0, 14), 30, 8, Color(0, 0, 0, 0.35))
			Sprites.draw_ogre(self, d + Vector2(0, 16), 4.0, breath)
			for j in 3:   # floating Zs
				var z := fposmod(t * 0.45 + j / 3.0, 1.0)
				draw_string(UiFont.TITLE, d + Vector2(20 + z * 16 + j * 2, -24 - z * 34), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 16 + int(z * 10), Color(0.9, 0.9, 1.0, 0.85 * (1.0 - z)))
		else:
			_awake_ogre(level.ogre_pos)

## The woken ogre: shakes and swells while he wakes (a red "!"), then charges, bobbing as he runs.
func _awake_ogre(p: Vector2) -> void:
	var w := level.ogre_t
	var waking := w < Level.OGRE_WAKE
	var shake := Vector2(sin(w * 70.0) * 3.0, 0.0) if waking else Vector2.ZERO
	var run_bob := 0.0 if waking else -absf(sin(w * 22.0)) * 6.0
	var swell := minf(w / Level.OGRE_WAKE, 1.0)
	DrawUtil.ellipse(self, p + Vector2(0, 14), 30, 8, Color(0, 0, 0, 0.35))
	Sprites.draw_ogre(self, p + Vector2(0, 16 + run_bob) + shake, 4.0, 1.0 if waking else swell * 1.0, Color(1.0, 0.75 + 0.25 * (1.0 - swell), 0.75 + 0.25 * (1.0 - swell)))
	if w < Level.OGRE_WAKE + 0.5:
		var pop := 1.0 + 0.25 * sin(minf(w * 14.0, PI))
		draw_string(UiFont.TITLE, p + Vector2(-8, -40), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(34 * pop), Color(1.0, 0.25, 0.2))

## Spikes: the tileset's spike plate. k < 1 dims it (retracted / about to come out).
func _spikes(o: Vector2, k: float) -> void:
	# dusky steel in the navy dungeon, so spikes never read as a blue (freeze) lamp
	var base := Color(0.72, 0.62, 0.8) if level.palette == 0 else level.tint()
	var m := base * Color(k, k, k)
	Sprites.draw_cell(self, Sprites.SPIKES, Rect2(o, Vector2(Level.TILE, Level.TILE)), m)
