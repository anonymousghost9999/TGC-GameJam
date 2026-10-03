class_name Outsider
extends Node2D
## The dungeon inspector used in the ending: an ordinary person who sees the
## hero talking to nobody.

var bubble: Bubble
var _facing := 1.0
var _anim := 0.0

func _ready() -> void:
	bubble = Bubble.new()
	bubble.rise = 56
	add_child(bubble)

func say(line: String, seconds := 2.8) -> void:
	bubble.say(line, seconds)

func walk_to_async(dest: Vector2, speed := 60.0) -> void:
	while global_position.distance_to(dest) > 2.0:
		if absf(dest.x - global_position.x) > 1.0:
			_facing = signf(dest.x - global_position.x)
		global_position = global_position.move_toward(dest, speed * get_process_delta_time())
		await get_tree().process_frame
	global_position = dest

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.ellipse(self, Vector2(0, 5), 12, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, sin(_anim * 3.0) * 0.8), 0.0, Vector2(_facing, 1.0))
	draw_rect(Rect2(-6, -8, 5, 12), Color(0.25, 0.25, 0.3))
	draw_rect(Rect2(1, -8, 5, 12), Color(0.25, 0.25, 0.3))
	draw_rect(Rect2(-9, -28, 18, 22), Color(0.55, 0.6, 0.55))        # coat
	draw_rect(Rect2(-9, -14, 18, 3), Color(0.3, 0.35, 0.3))
	draw_circle(Vector2(0, -35), 9.0, Color(0.95, 0.8, 0.7))
	draw_rect(Rect2(-10, -44, 20, 6), Color(0.3, 0.35, 0.4))        # flat cap
	draw_rect(Rect2(-3, -39, 12, 3), Color(0.3, 0.35, 0.4))
	draw_arc(Vector2(-3, -35), 3.0, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.2)   # glasses
	draw_arc(Vector2(4, -35), 3.0, 0.0, TAU, 10, Color(0.1, 0.1, 0.1), 1.2)
	draw_line(Vector2(-1, -35), Vector2(1, -35), Color(0.1, 0.1, 0.1), 1.0)
	draw_line(Vector2(-3, -29), Vector2(3, -29), Color(0.3, 0.15, 0.15), 1.5)
	draw_rect(Rect2(6, -24, 9, 12), Color(0.85, 0.75, 0.55))        # clipboard
	draw_rect(Rect2(8, -22, 5, 1), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(8, -19, 5, 1), Color(0.2, 0.2, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
