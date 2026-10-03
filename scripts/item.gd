class_name Item
extends Interactable
## A pickable object. The hero grabs junk at random and uses it on the wrong
## problem. The guide can POINT at items. Some are hidden until revealed by
## night (fireflies) or by lantern light, so the player has to explore.

signal pointed(item: Item)

@export var kind := "fish"
@export var reveal := "always"   # always | night | lantern
var taken := false
var broken := false
var region := 0
var daynight: DayNight
var light: LightController

var _alpha := 1.0
var _t := 0.0
var _marked_left := 0.0

func _ready() -> void:
	super._ready()
	reach = 60.0
	pointable = true

func is_revealed() -> bool:
	match reveal:
		"night":
			return daynight != null and daynight.is_night
		"lantern":
			return light != null and light.is_lit(global_position)
	return true

func is_marked() -> bool:
	return _marked_left > 0.0

func available() -> bool:
	return not taken and not broken

func get_prompt() -> String:
	return "Point at the %s" % kind

func interact(_player: Node) -> void:
	_marked_left = 10.0
	pointed.emit(self)

func take() -> void:
	taken = true
	enabled = false
	_marked_left = 0.0
	queue_redraw()

func drop_at(p: Vector2) -> void:
	global_position = p
	taken = false
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	_marked_left = maxf(_marked_left - delta, 0.0)
	var rev := is_revealed()
	_alpha = move_toward(_alpha, 1.0 if rev else 0.0, delta * 3.0)
	enabled = available() and (rev or is_marked())
	queue_redraw()

func _draw() -> void:
	if not available():
		return
	if reveal == "night" and _alpha > 0.02:
		for i in 6:   # fireflies hovering over the hidden thing
			var a := _t * 1.3 + i * TAU / 6.0
			var p := Vector2(cos(a), sin(a * 1.3)) * (14.0 + i * 2.0)
			DrawUtil.glow(self, p, 9.0, Color(1.0, 1.0, 0.5, 0.8 * _alpha), 3)
	if _alpha > 0.02:
		Item.draw_icon(self, kind, 1.0, _alpha)
	if is_marked():
		var bob := sin(_t * 8.0) * 3.0
		var c := Color(1.0, 0.3, 0.3)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -16 + bob), Vector2(-7, -28 + bob), Vector2(7, -28 + bob)]), c)
		draw_rect(Rect2(-2, -40 + bob, 4, 12), c)

static func _rs(x: float, y: float, w: float, h: float, s: float) -> Rect2:
	return Rect2(x * s, y * s, w * s, h * s)

## Shared by the world item and the hero's hand.
static func draw_icon(ci: CanvasItem, k: String, s: float, a: float) -> void:
	var m := Color(1, 1, 1, a)
	match k:
		"fish":
			DrawUtil.ellipse(ci, Vector2.ZERO, 11 * s, 6 * s, Color(0.55, 0.7, 0.85) * m)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(9, 0) * s, Vector2(17, -6) * s, Vector2(17, 6) * s]), Color(0.45, 0.6, 0.8) * m)
			ci.draw_circle(Vector2(-6, -1) * s, 1.6 * s, Color(0.1, 0.1, 0.15) * m)
		"bucket":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-9, -8) * s, Vector2(9, -8) * s, Vector2(7, 8) * s, Vector2(-7, 8) * s]), Color(0.55, 0.55, 0.62) * m)
			ci.draw_arc(Vector2(0, -8) * s, 9 * s, PI, TAU, 10, Color(0.3, 0.3, 0.35) * m, 2.0)
			DrawUtil.ellipse(ci, Vector2(0, -8) * s, 9 * s, 2.5 * s, Color(0.4, 0.65, 0.95) * m)
		"hammer":
			ci.draw_rect(_rs(-2, -8, 4, 20, s), Color(0.55, 0.38, 0.2) * m)
			ci.draw_rect(_rs(-9, -12, 18, 8, s), Color(0.5, 0.5, 0.58) * m)
		"broom":
			ci.draw_line(Vector2(0, -14) * s, Vector2(0, 4) * s, Color(0.55, 0.38, 0.2) * m, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, 4) * s, Vector2(3, 4) * s, Vector2(9, 15) * s, Vector2(-9, 15) * s]), Color(0.85, 0.7, 0.3) * m)
		"pan":
			ci.draw_circle(Vector2(-3, 0) * s, 9 * s, Color(0.25, 0.25, 0.3) * m)
			ci.draw_circle(Vector2(-3, 0) * s, 6 * s, Color(0.15, 0.15, 0.2) * m)
			ci.draw_rect(_rs(5, -2, 12, 4, s), Color(0.45, 0.3, 0.2) * m)
		"key":
			ci.draw_arc(Vector2(-6, 0) * s, 5 * s, 0.0, TAU, 12, Color(1.0, 0.82, 0.25) * m, 3.0)
			ci.draw_line(Vector2(-1, 0) * s, Vector2(13, 0) * s, Color(1.0, 0.82, 0.25) * m, 3.0)
			ci.draw_line(Vector2(9, 0) * s, Vector2(9, 5) * s, Color(1.0, 0.82, 0.25) * m, 3.0)
			ci.draw_line(Vector2(13, 0) * s, Vector2(13, 4) * s, Color(1.0, 0.82, 0.25) * m, 3.0)
		"axe":
			ci.draw_line(Vector2(0, -12) * s, Vector2(0, 12) * s, Color(0.55, 0.38, 0.2) * m, 3.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(1, -11) * s, Vector2(12, -14) * s, Vector2(12, -2) * s, Vector2(1, -5) * s]), Color(0.75, 0.78, 0.85) * m)
