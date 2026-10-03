class_name Werewolf
extends Node2D
## A night-only threat. It chases the hero. Daylight burns it away. If it
## catches the hero it flings him back across the river.

signal gone(w: Werewolf)

const SPEED := 85.0

var target: Node2D
var burning := false

var _burn_t := 0.0
var _anim := 0.0
var _facing := 1.0

func burn() -> void:
	burning = true

func _process(delta: float) -> void:
	_anim += delta
	if burning:
		_burn_t += delta
		if _burn_t >= 1.1:
			gone.emit(self)
			queue_free()
	elif target != null:
		var d := target.global_position - global_position
		if absf(d.x) > 1.0:
			_facing = signf(d.x)
		global_position += d.normalized() * SPEED * delta
		if d.length() < 20.0 and target.has_method("get_mauled"):
			target.get_mauled(self)
	queue_redraw()

func _draw() -> void:
	var fade := 1.0 - _burn_t / 1.1
	draw_set_transform(Vector2(0, sin(_anim * 12.0) * 1.5), 0.0, Vector2(_facing, 1.0))
	var fur := Color(0.22, 0.2, 0.26, fade)
	DrawUtil.ellipse(self, Vector2(0, 6), 14, 4, Color(0, 0, 0, 0.3 * fade))
	DrawUtil.ellipse(self, Vector2(0, -8), 12, 10, fur)           # body
	draw_circle(Vector2(8, -20), 8.0, fur)                       # head
	draw_colored_polygon(PackedVector2Array([Vector2(3, -25), Vector2(5, -34), Vector2(9, -26)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(10, -26), Vector2(14, -34), Vector2(14, -24)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(11, -20), Vector2(20, -17), Vector2(11, -15)]), fur)  # snout
	draw_circle(Vector2(8, -22), 1.8, Color(1.0, 0.2, 0.15, fade))
	draw_rect(Rect2(-8, -2, 4, 9), fur)
	draw_rect(Rect2(4, -2, 4, 9), fur)
	draw_line(Vector2(-12, -10), Vector2(-20, -4), fur, 4.0)      # tail
	if burning:
		for i in 6:
			var p := Vector2((i - 2.5) * 5.0, -12.0 - _burn_t * 20.0 - (i % 3) * 5.0)
			draw_circle(p, 5.0 * fade, Color(1.0, 0.6 - 0.1 * (i % 3), 0.1, 0.9 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
