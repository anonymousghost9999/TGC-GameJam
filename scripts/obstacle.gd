class_name Obstacle
extends Interactable
## Something the hero can't get past without the right item: a locked village
## gate (needs the KEY) or a fallen log (needs the AXE). Solid for the hero only
## (the imaginary guide can float through). The guide can point at it.

signal pointed(o: Obstacle)

@export var kind := "gate"   # gate | log
@export var need := "key"
var region := 0
var solved := false
var span := Vector2(32, 96)
var hint := ""

var _body: StaticBody2D
var _open := 0.0
var _t := 0.0

func _ready() -> void:
	super._ready()
	reach = 90.0
	pointable = true
	_body = add_solid(span)
	_body.collision_layer = 2   # hero-only layer
	prompt = "Point at the %s" % kind

func interact(_player: Node) -> void:
	pointed.emit(self)
	said.emit(hint)

func solve() -> void:
	if solved:
		return
	solved = true
	enabled = false
	_body.collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "_open", 1.0, 1.0)

func is_passable() -> bool:
	return solved and _open >= 0.7

func reset() -> void:
	solved = false
	enabled = true
	_open = 0.0
	_body.collision_layer = 2
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var w := span.x
	var h := span.y
	if kind == "gate":
		draw_rect(Rect2(-w * 0.5 - 4, -h * 0.5 - 8, 8, h + 8), Color(0.4, 0.28, 0.16))
		draw_rect(Rect2(w * 0.5 - 4, -h * 0.5 - 8, 8, h + 8), Color(0.4, 0.28, 0.16))
		var door_h := h * (1.0 - _open)
		if door_h > 1.0:
			draw_rect(Rect2(-w * 0.5, -h * 0.5, w, door_h), Color(0.6, 0.42, 0.22))
			for i in 4:
				draw_line(Vector2(-w * 0.5 + 4 + i * 8, -h * 0.5), Vector2(-w * 0.5 + 4 + i * 8, -h * 0.5 + door_h), Color(0.35, 0.22, 0.12), 2.0)
			if not solved:   # padlock
				draw_rect(Rect2(-6, -4, 12, 10), Color(1.0, 0.82, 0.25))
				draw_arc(Vector2(0, -4), 5, PI, TAU, 8, Color(1.0, 0.82, 0.25), 2.0)
		if not solved:
			var c := Color(1.0, 0.82, 0.25, 0.5 + 0.3 * sin(_t * 4.0))
			draw_arc(Vector2(0, 2), 12, 0, TAU, 16, c, 1.5)
	else:
		var gap := _open * 38.0
		var col := Color(0.5, 0.32, 0.17)
		draw_rect(Rect2(-w * 0.5 - 2, -h * 0.5 - gap, w + 4, h * 0.5), col)
		draw_rect(Rect2(-w * 0.5 - 2, gap, w + 4, h * 0.5), col)
		for i in 5:
			draw_arc(Vector2(0, -h * 0.5 + 12 + i * 16 + (-gap if i < 3 else gap)), 8, 0, TAU, 8, Color(0.35, 0.2, 0.1), 1.5)
		draw_rect(Rect2(-w * 0.5 - 2, -h * 0.5 - gap, w + 4, h * 0.5), Color(0.3, 0.18, 0.1), false, 2.0)
		draw_rect(Rect2(-w * 0.5 - 2, gap, w + 4, h * 0.5), Color(0.3, 0.18, 0.1), false, 2.0)
