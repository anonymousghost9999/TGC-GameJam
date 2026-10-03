class_name Statue
extends Interactable
## A stone knight. The hero tries to high-five it; its sword falls on him.

var sword_dropped := false
var _drop := 0.0   # 0..1 sword falling

func _ready() -> void:
	super._ready()
	prompt = "Examine statue"
	message = "A stone knight. He looks like he has seen a lot of heroes, and has opinions."
	add_solid(Vector2(22, 22))

func drop_sword() -> void:
	if sword_dropped:
		return
	sword_dropped = true
	var tw := create_tween()
	tw.tween_property(self, "_drop", 1.0, 0.25)

func reset() -> void:
	sword_dropped = false
	_drop = 0.0
	queue_redraw()

func _process(_delta: float) -> void:
	if sword_dropped:
		queue_redraw()

func _draw() -> void:
	var stone := Color(0.62, 0.64, 0.7)
	DrawUtil.ellipse(self, Vector2(0, 14), 15, 5, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-12, 8, 24, 6), Color(0.5, 0.52, 0.58))
	draw_rect(Rect2(-8, -12, 16, 22), stone)
	draw_circle(Vector2(0, -18), 8.0, stone)
	draw_rect(Rect2(-8, -20, 16, 4), Color(0.4, 0.42, 0.5))   # visor
	draw_rect(Rect2(-12, -10, 4, 14), stone)                   # arm
	draw_rect(Rect2(8, -10, 4, 14), stone)
	if sword_dropped:
		var p := Vector2(16, -8).lerp(Vector2(14, 14), _drop)
		draw_line(p, p + Vector2(-2, 14 * (1.0 - _drop) + 2), Color(0.8, 0.85, 0.9), 3.0)
		draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), Color(1, 0.8, 0.3), 3.0)
	else:
		draw_line(Vector2(12, -12), Vector2(12, 8), Color(0.8, 0.85, 0.9), 3.0)
		draw_line(Vector2(7, -4), Vector2(17, -4), Color(1, 0.8, 0.3), 3.0)
