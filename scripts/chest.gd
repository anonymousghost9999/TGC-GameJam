class_name Chest
extends Interactable
## A treasure chest. Empty, and the lid slams on the hero's head.

var _lid := 0.0   # 0 closed .. 1 open

func _ready() -> void:
	super._ready()
	prompt = "Inspect chest"
	message = "A treasure chest. The hinge looks spring-loaded. Ominous."
	add_solid(Vector2(26, 20))

func open_lid() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_lid", 1.0, 0.3)

func slam() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_lid", 0.0, 0.07)

func reset() -> void:
	_lid = 0.0
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	DrawUtil.ellipse(self, Vector2(0, 12), 17, 5, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-14, -2, 28, 14), Color(0.55, 0.35, 0.18))
	draw_rect(Rect2(-14, -2, 28, 14), Color(0.25, 0.15, 0.1), false, 2.0)
	draw_rect(Rect2(-14, 3, 28, 3), Color(1.0, 0.8, 0.3))
	# lid: hinge at the back (top), swings up when open
	var h := lerpf(8.0, 22.0, _lid)
	var lid := PackedVector2Array([Vector2(-14, -2), Vector2(14, -2), Vector2(12, -2 - h), Vector2(-12, -2 - h)])
	draw_colored_polygon(lid, Color(0.65, 0.42, 0.22))
	draw_polyline(lid + PackedVector2Array([lid[0]]), Color(0.25, 0.15, 0.1), 2.0)
	if _lid > 0.5:
		draw_rect(Rect2(-12, -1, 24, 4), Color(0.12, 0.08, 0.1))   # empty inside
	else:
		draw_circle(Vector2(0, 2), 2.0, Color(1.0, 0.85, 0.3))
