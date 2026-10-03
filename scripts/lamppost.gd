class_name Lamppost
extends Interactable
## An environmental light the guide can switch on or off (E). A lit lamppost
## reveals hidden things in its radius and lures the hero, like the lantern.

var lit := false
var radius := 120.0
var daynight: DayNight

var _glow: PointLight2D
var _t := 0.0

func _ready() -> void:
	super._ready()
	prompt = "Switch lamppost"
	reach = 50.0
	add_solid(Vector2(8, 8))
	_glow = DrawUtil.make_point_light(radius, Color(1.0, 0.85, 0.5))
	_glow.position = Vector2(0, -26)
	add_child(_glow)

func get_prompt() -> String:
	return "Switch lamppost %s" % ("OFF" if lit else "ON")

func interact(_player: Node) -> void:
	lit = not lit

func reset() -> void:
	lit = false

func _process(delta: float) -> void:
	_t += delta
	var night := daynight.blend if daynight != null else 0.0
	_glow.energy = (1.0 if lit else 0.0) * (0.2 + 0.8 * night)
	queue_redraw()

func _draw() -> void:
	DrawUtil.ellipse(self, Vector2(0, 12), 9, 3, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-2, -22, 4, 34), Color(0.2, 0.2, 0.25))
	draw_rect(Rect2(-7, -34, 14, 12), Color(0.25, 0.25, 0.3))
	var c := Color(1.0, 0.9, 0.5) if lit else Color(0.4, 0.4, 0.45)
	draw_rect(Rect2(-5, -32, 10, 8), c)
	if lit:
		DrawUtil.glow(self, Vector2(0, -28), radius * 0.45, Color(1.0, 0.85, 0.4, 0.35))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1.0, 0.9, 0.5, 0.2), 1.5)
