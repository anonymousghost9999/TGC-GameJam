class_name Pedestal
extends Interactable
## Holds the "Sacred Lamp" (the quest item). The hero grabs it, badly.

var lamp_present := true

var _t := 0.0

func _ready() -> void:
	super._ready()
	prompt = "Read plaque"
	_refresh_message()

func _refresh_message() -> void:
	if lamp_present:
		message = "Plaque: \"SACRED LAMP. Lift with both hands. Mind your feet.\""
	else:
		message = "The plaque remains. So does a suspicious dent in the floor."

func take_lamp() -> void:
	lamp_present = false
	_refresh_message()
	queue_redraw()

func reset() -> void:
	lamp_present = true
	_refresh_message()
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	DrawUtil.ellipse(self, Vector2(0, 14), 17, 5, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-12, -2, 24, 16), Color(0.6, 0.58, 0.66))
	draw_rect(Rect2(-15, -6, 30, 6), Color(0.72, 0.7, 0.8))
	draw_rect(Rect2(-6, 5, 12, 6), Color(0.95, 0.9, 0.7))   # plaque
	if lamp_present:
		DrawUtil.glow(self, Vector2(0, -16), 46.0, Color(1.0, 0.7, 0.25, 0.55 + 0.1 * sin(_t * 3.0)))
		draw_rect(Rect2(-5, -12, 10, 6), Color(0.4, 0.3, 0.2))
		draw_circle(Vector2(0, -17), 7.0, Color(1.0, 0.85, 0.4))
		draw_circle(Vector2(0, -17), 3.5, Color(1.0, 1.0, 0.85))
