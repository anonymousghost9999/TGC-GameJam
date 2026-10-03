class_name Barrel
extends Interactable
## A barrel the hero is convinced is full of gold. (It is not.)

var smashed := false

var _body: StaticBody2D

func _ready() -> void:
	super._ready()
	prompt = "Inspect barrel"
	message = "A barrel. Nothing in it but the hero's hopes."
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	cs.shape = shape
	_body.add_child(cs)
	add_child(_body)

func smash() -> void:
	if smashed:
		return
	smashed = true
	enabled = false
	_body.collision_layer = 0
	queue_redraw()

func reset() -> void:
	smashed = false
	enabled = true
	_body.collision_layer = 1
	queue_redraw()

func _draw() -> void:
	DrawUtil.ellipse(self, Vector2(0, 14), 16, 5, Color(0, 0, 0, 0.3))
	if smashed:
		for i in 7:
			var a := i * 0.9
			var p := Vector2(cos(a) * 12.0, sin(a * 1.7) * 6.0 + 8.0)
			draw_line(p, p + Vector2(cos(a * 2.0), sin(a * 2.0)) * 8.0, Color(0.6, 0.38, 0.2), 3.0)
		return
	draw_rect(Rect2(-14, -14, 28, 28), Color(0.62, 0.4, 0.22))
	DrawUtil.ellipse(self, Vector2(0, -14), 14, 5, Color(0.72, 0.5, 0.3))
	DrawUtil.ellipse(self, Vector2(0, 14), 14, 4, Color(0.5, 0.32, 0.18))
	draw_line(Vector2(-14, -6), Vector2(14, -6), Color(0.25, 0.2, 0.25), 3.0)
	draw_line(Vector2(-14, 8), Vector2(14, 8), Color(0.25, 0.2, 0.25), 3.0)
	# a hopeful gold glint painted on the lid (the hero sees "treasure")
	draw_circle(Vector2(-4, -15), 2.0, Color(1.0, 0.85, 0.3))
