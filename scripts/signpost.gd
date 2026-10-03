class_name Signpost
extends Interactable
## "CAUTION: WET FLOOR". The hero reads it, scoffs, and slips.

var splashed := false

func _ready() -> void:
	super._ready()
	prompt = "Read sign"
	message = "Sign: \"CAUTION: WET FLOOR.\" (The NPC would never ignore a sign. The hero would.)"
	add_solid(Vector2(12, 12))

func splash() -> void:
	splashed = true
	queue_redraw()

func reset() -> void:
	splashed = false
	queue_redraw()

func _draw() -> void:
	if splashed:
		DrawUtil.ellipse(self, Vector2(0, 18), 24, 8, Color(0.4, 0.7, 1.0, 0.7))
		DrawUtil.ellipse(self, Vector2(-6, 16), 7, 2.5, Color(1, 1, 1, 0.5))
	DrawUtil.ellipse(self, Vector2(0, 12), 10, 3, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-2, -4, 4, 16), Color(0.45, 0.3, 0.18))
	draw_rect(Rect2(-12, -20, 24, 16), Color(0.95, 0.85, 0.3))
	draw_rect(Rect2(-12, -20, 24, 16), Color(0.3, 0.2, 0.1), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(6, -7), Vector2(-6, -7)]), Color(0.15, 0.1, 0.1))
	draw_rect(Rect2(-1, -14, 2, 4), Color(0.95, 0.85, 0.3))
	draw_circle(Vector2(0, -8.5), 1.0, Color(0.95, 0.85, 0.3))
