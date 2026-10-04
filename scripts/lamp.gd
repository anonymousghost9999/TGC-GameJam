class_name Lamp
extends Node2D
## A fixed, pre-placed lamp. It stores its ORIGINAL colour and whether it is ON
## (there is no influence radius: the hero obeys the nearest active lamp). Behaviour is always derived from the CURRENT colour
## (original colour, or its complement while inverted), so inversion needs no
## separate state.

var original := LampColors.C.GREEN
var on := false
var start_on := false
var index := 0
var is_exit := false
var manager: LampManager

var _shown := Color.WHITE
var _flash := 0.0
var _t := 0.0

func current_color() -> int:
	return manager.effective_color(original) if manager != null else original

func set_on(v: bool) -> void:
	if on != v:
		on = v
		_flash = 1.0

func snap_visuals() -> void:
	_shown = LampColors.rgb(current_color())
	_flash = 0.0

func _ready() -> void:
	snap_visuals()

func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta * 3.0, 0.0)
	_shown = _shown.lerp(LampColors.rgb(current_color()), minf(delta * 14.0, 1.0))   # visible colour transform
	queue_redraw()

func _draw() -> void:
	var c := _shown
	var cur := current_color()
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	if on:
		DrawUtil.glow(self, Vector2(0, -20), 54.0 + 6.0 * pulse, Color(c.r, c.g, c.b, 0.55), 6)
		DrawUtil.glow(self, Vector2.ZERO, 110.0, Color(c.r, c.g, c.b, 0.07), 5)   # soft ambient colour only
	if _flash > 0.0:
		draw_circle(Vector2(0, -20), 14.0 + 22.0 * (1.0 - _flash), Color(1, 1, 1, 0.5 * _flash))
	# base + post
	DrawUtil.ellipse(self, Vector2(0, 12), 12, 4, Color(0, 0, 0, 0.35))
	draw_rect(Rect2(-9, 4, 18, 8), Color(0.28, 0.26, 0.32))
	var base_c := LampColors.rgb(original)   # the group colour stays visible, even while inverted
	draw_rect(Rect2(-9, 4, 18, 3), base_c)
	draw_rect(Rect2(-2, -10, 4, 15), Color(0.28, 0.26, 0.32))
	# bulb
	var bulb := Color(c.r, c.g, c.b) if on else Color(c.r, c.g, c.b).darkened(0.62)
	if is_exit:
		draw_arc(Vector2(0, -20), 17.0, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 2.0)
	draw_circle(Vector2(0, -20), 12.0, bulb)
	draw_arc(Vector2(0, -20), 12.0, 0.0, TAU, 20, Color(0.1, 0.1, 0.12), 2.0)
	# glyph: the behaviour, readable without relying on colour alone
	var g := Color(0.06, 0.07, 0.1, 0.95 if on else 0.55)
	var p := Vector2(0, -20)
	match cur:
		LampColors.C.GREEN:   # arrows pointing in: come here
			draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -4), p + Vector2(-8, 4), p + Vector2(-2, 0)]), g)
			draw_colored_polygon(PackedVector2Array([p + Vector2(8, -4), p + Vector2(8, 4), p + Vector2(2, 0)]), g)
		LampColors.C.RED:   # arrows pointing out: go away
			draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -4), p + Vector2(-2, 4), p + Vector2(-8, 0)]), g)
			draw_colored_polygon(PackedVector2Array([p + Vector2(2, -4), p + Vector2(2, 4), p + Vector2(8, 0)]), g)
		LampColors.C.ORANGE:   # one small arrow: slowly this way
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -4), p + Vector2(-6, 4), p + Vector2(1, 0)]), g)
			draw_circle(p + Vector2(5, 0), 1.6, g)
		_:   # two bars: pause
			draw_rect(Rect2(p + Vector2(-5, -5), Vector2(3, 10)), g)
			draw_rect(Rect2(p + Vector2(2, -5), Vector2(3, 10)), g)
