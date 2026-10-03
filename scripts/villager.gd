class_name Villager
extends Node2D
## A villager who happened to see the hero. Different looks per witness.

var style := "baker"   # baker | farmer | woodcutter | child
var bubble: Bubble

var _anim := 0.0

func _ready() -> void:
	bubble = Bubble.new()
	bubble.rise = 58 if style != "child" else 44
	add_child(bubble)

func say(line: String, seconds := 2.8) -> void:
	bubble.say(line, seconds)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var s := 0.75 if style == "child" else 1.0
	DrawUtil.ellipse(self, Vector2(0, 5), 12 * s, 4 * s, Color(0, 0, 0, 0.3))
	var bob := sin(_anim * 3.0) * 0.8
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(s, s))
	var coat := Color(0.9, 0.9, 0.85)
	var hat := Color(0.9, 0.9, 0.85)
	match style:
		"farmer":
			coat = Color(0.35, 0.5, 0.7)
			hat = Color(0.9, 0.78, 0.4)
		"woodcutter":
			coat = Color(0.7, 0.25, 0.2)
			hat = Color(0.25, 0.3, 0.25)
		"child":
			coat = Color(0.9, 0.6, 0.3)
			hat = Color(0.4, 0.3, 0.2)
	draw_rect(Rect2(-6, -8, 5, 12), Color(0.3, 0.25, 0.25))
	draw_rect(Rect2(1, -8, 5, 12), Color(0.3, 0.25, 0.25))
	draw_rect(Rect2(-9, -28, 18, 22), coat)
	if style == "baker":
		draw_rect(Rect2(-8, -22, 16, 16), Color(1, 1, 1))   # apron
	if style == "woodcutter":
		for i in 3:
			draw_line(Vector2(-9, -26 + i * 7), Vector2(9, -26 + i * 7), Color(0.2, 0.1, 0.1), 1.5)
	draw_circle(Vector2(0, -35), 9.0, Color(0.95, 0.8, 0.7))
	match style:
		"baker":
			draw_rect(Rect2(-8, -50, 16, 12), hat)                       # tall white hat
			draw_circle(Vector2(0, -50), 9.0, hat)
		"farmer":
			draw_rect(Rect2(-14, -42, 28, 4), hat)                       # straw brim
			draw_rect(Rect2(-7, -48, 14, 8), hat)
		"woodcutter":
			draw_rect(Rect2(-9, -45, 18, 7), hat)
			draw_colored_polygon(PackedVector2Array([Vector2(-8, -29), Vector2(8, -29), Vector2(5, -20), Vector2(-5, -20)]), Color(0.45, 0.3, 0.2))   # beard
		"child":
			draw_circle(Vector2(0, -41), 9.0, hat)                       # messy hair
	draw_circle(Vector2(-3, -35), 1.3, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(3, -35), 1.3, Color(0.1, 0.1, 0.15))
	draw_arc(Vector2(0, -30), 3.0, 0.2, PI - 0.2, 6, Color(0.3, 0.15, 0.15), 1.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
