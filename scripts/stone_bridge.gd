class_name StoneBridge
extends Node2D
## The river and its stepping stones. The stones only surface at NIGHT (moonlit);
## by day the river is just water. The hero falls in if he steps off a stone.

var daynight: DayNight
var water_rect := Rect2()
var stones: Array[Rect2] = []

var _t := 0.0

func setup(dn: DayNight, water: Rect2, tiles: Array[Rect2]) -> void:
	daynight = dn
	water_rect = water
	stones = tiles

func in_water(p: Vector2) -> bool:
	return water_rect.has_point(p)

func is_solid_at(p: Vector2) -> bool:
	if not daynight.is_night:
		return false
	for r in stones:
		if r.grow(1.0).has_point(p):
			return true
	return false

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var night := daynight.blend
	draw_rect(water_rect, Color(0.2, 0.45, 0.75))
	draw_rect(water_rect.grow(-6), Color(0.25, 0.52, 0.82))
	for i in 40:   # drifting wave marks
		var y := water_rect.position.y + fmod(i * 97.0 + _t * 14.0, water_rect.size.y)
		var x := water_rect.position.x + 10.0 + fmod(i * 53.0, water_rect.size.x - 20.0)
		draw_line(Vector2(x, y), Vector2(x + 12, y), Color(1, 1, 1, 0.25), 1.5)
	draw_rect(water_rect, Color(0.12, 0.3, 0.5), false, 3.0)
	for r in stones:
		var c := r.get_center()
		draw_arc(c, 13.0, 0, TAU, 14, Color(1, 1, 1, 0.18 * (1.0 - night)), 1.5)   # ripple hint by day
		if night > 0.02:
			DrawUtil.glow(self, c, 30.0, Color(0.7, 0.85, 1.0, 0.55 * night))
			DrawUtil.ellipse(self, c, 14.0, 11.0, Color(0.72, 0.78, 0.92, night))
			DrawUtil.ellipse(self, c + Vector2(0, -2), 10.0, 7.0, Color(0.88, 0.92, 1.0, night))
			draw_arc(c, 5.0, PI * 0.2, PI * 1.5, 8, Color(0.4, 0.45, 0.65, night), 1.5)   # moon glyph
