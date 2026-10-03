class_name Slime
extends Interactable
## A bored slime. The hero swings at it and misses; the slime wins by boing.

var won := false   # true once it has boinged the hero over
var bubble: Bubble

var _t := 0.0
var _hop := 0.0   # 0..1 boing animation

func _ready() -> void:
	super._ready()
	prompt = "Say hi"
	message = "A slime. It looks bored. It has not noticed the hero is trying to kill it."
	bubble = Bubble.new()
	bubble.rise = 30
	add_child(bubble)

## Boing! (the hero gets knocked over by the "monster")
func boing() -> void:
	won = true
	var tw := create_tween()
	tw.tween_property(self, "_hop", 1.0, 0.18)
	tw.tween_property(self, "_hop", 0.0, 0.25)
	bubble.say("boing.", 1.6)

func reset() -> void:
	won = false
	_hop = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	DrawUtil.ellipse(self, Vector2(0, 11), 15, 4, Color(0, 0, 0, 0.3))
	var bob := sin(_t * 3.0) * 1.5 - _hop * 26.0
	var h := 17.0 + _hop * 4.0
	DrawUtil.ellipse(self, Vector2(0, 10 - h * 0.5 + bob), 15, h, Color(0.35, 0.85, 0.65, 0.95))
	DrawUtil.ellipse(self, Vector2(-5, 5 - h * 0.5 + bob), 4, 2.5, Color(1, 1, 1, 0.35))
	var ey := 8.0 - h * 0.5 + bob
	draw_circle(Vector2(-5, ey), 3.2, Color.WHITE)
	draw_circle(Vector2(5, ey), 3.2, Color.WHITE)
	draw_circle(Vector2(-5, ey + 0.5), 1.5, Color(0.1, 0.2, 0.2))
	draw_circle(Vector2(5, ey + 0.5), 1.5, Color(0.1, 0.2, 0.2))
	# half-lidded boredom
	draw_rect(Rect2(-8.5, ey - 3.6, 7, 3), Color(0.35, 0.85, 0.65))
	draw_rect(Rect2(1.5, ey - 3.6, 7, 3), Color(0.35, 0.85, 0.65))
	draw_line(Vector2(-3, ey + 6), Vector2(3, ey + 6), Color(0.1, 0.2, 0.2), 1.3)
