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
	# the exit lamp hangs ABOVE its door (drawn by the level), so its light never hides the door
	var p := Vector2(0, -66) if is_exit else Vector2(0, -20)
	if on:
		DrawUtil.glow(self, p, (34.0 if is_exit else 54.0) + 6.0 * pulse, Color(c.r, c.g, c.b, 0.68), 6)
		if not is_exit:
			DrawUtil.glow(self, Vector2.ZERO, 110.0, Color(c.r, c.g, c.b, 0.11), 5)   # soft ambient colour only
	if _flash > 0.0:
		draw_circle(p, 14.0 + 22.0 * (1.0 - _flash), Color(1, 1, 1, 0.5 * _flash))
	if is_exit:   # a bracket on the door frame
		draw_line(p + Vector2(0, 10), p + Vector2(0, 16), Color(0.28, 0.26, 0.32), 3.0)
	else:   # a brass stand; a band of the ORIGINAL colour at its foot stays visible, even while inverted
		DrawUtil.ellipse(self, Vector2(0, 13), 13, 4, Color(0, 0, 0, 0.35))
		Sprites.draw_stand(self, Vector2(0, -14), 2.0)
		draw_rect(Rect2(-10, 9, 20, 4), LampColors.rgb(original))
	draw_bulb(self, p, Color(c.r, c.g, c.b), cur, on)

## A lamp's bulb with its behaviour glyph (readable without relying on colour alone).
## Also used by the title screen and the invert-lantern card. `k` scales it.
static func draw_bulb(ci: CanvasItem, p: Vector2, c: Color, cur: int, lit: bool, k := 1.0) -> void:
	# the oil lamp's glass, tinted the lamp's colour (dim when off), with the behaviour glyph on its belly
	var glass := c.lightened(0.2) if lit else c.darkened(0.7)
	Sprites.draw_lantern(ci, p + Vector2(0, -2) * k, 1.55 * k, glass)
	var gp := p + Vector2(0, 4) * k
	ci.draw_circle(gp, 6.5 * k, c.lightened(0.55) if lit else c.darkened(0.5))   # a pale disc so the glyph reads on any colour
	var g := Color(0.06, 0.07, 0.1, 0.95 if lit else 0.55)
	var q := func(pts: Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		for v: Vector2 in pts:
			out.append(gp + v * k * 0.8)
		return out
	match cur:
		LampColors.C.GREEN:   # arrows pointing in: come here
			ci.draw_colored_polygon(q.call([Vector2(-8, -4), Vector2(-8, 4), Vector2(-2, 0)]), g)
			ci.draw_colored_polygon(q.call([Vector2(8, -4), Vector2(8, 4), Vector2(2, 0)]), g)
		LampColors.C.RED:   # arrows pointing out: go away
			ci.draw_colored_polygon(q.call([Vector2(-2, -4), Vector2(-2, 4), Vector2(-8, 0)]), g)
			ci.draw_colored_polygon(q.call([Vector2(2, -4), Vector2(2, 4), Vector2(8, 0)]), g)
		LampColors.C.ORANGE:   # one small arrow: slowly this way
			ci.draw_colored_polygon(q.call([Vector2(-6, -4), Vector2(-6, 4), Vector2(1, 0)]), g)
			ci.draw_circle(gp + Vector2(5, 0) * k * 0.8, 1.6 * k, g)
		_:   # two bars: pause
			ci.draw_rect(Rect2(gp + Vector2(-5, -5) * k * 0.8, Vector2(3, 10) * k * 0.8), g)
			ci.draw_rect(Rect2(gp + Vector2(2, -5) * k * 0.8, Vector2(3, 10) * k * 0.8), g)
