class_name InvertCard
extends Control
## Shown once, when the invert lantern (Q) is introduced: a picture of what swaps with what.
## The lamps on the card flip back and forth so the swap is seen, not just read.

const W := 960.0
const H := 544.0
const PAIRS := [[LampColors.C.GREEN, LampColors.C.RED], [LampColors.C.BLUE, LampColors.C.ORANGE]]
const DOES := {LampColors.C.GREEN: "walks to it", LampColors.C.RED: "runs away", LampColors.C.ORANGE: "creeps to it", LampColors.C.BLUE: "freezes"}

var _t := 0.0

func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var font: Font = UiFont.MAIN
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.88))
	var panel := Rect2(170, 60, 620, 420)
	draw_rect(panel, Color(0.12, 0.09, 0.2))
	draw_rect(panel, Color(0.75, 0.55, 1.0), false, 3.0)
	_centered(font, "NEW: THE INVERT LANTERN", 112.0, 30, Color(0.88, 0.7, 1.0))
	_centered(font, "Press  Q  and every lamp swaps to its opposite", 150.0, 19, Color(0.92, 0.9, 1.0))
	var swapped := fposmod(_t, 3.0) > 1.5   # the demo lamps flip every 1.5 s
	for row in 2:
		var y := 220.0 + row * 100.0
		for side in 2:
			var orig: int = PAIRS[row][side]
			var now: int = PAIRS[row][1 - side] if swapped else orig
			var p := Vector2(W * 0.5 + (side * 2 - 1) * 150.0, y)
			var c := LampColors.rgb(now)
			DrawUtil.glow(self, p, 44.0, Color(c.r, c.g, c.b, 0.5), 6)
			Lamp.draw_bulb(self, p, c, now, true, 1.6)
			_centered_at(font, DOES[now], p + Vector2(0, 44), 16, Color(0.85, 0.85, 0.9))
		# the swap arrows between the pair
		var mid := Vector2(W * 0.5, y)
		var ac := Color(0.88, 0.7, 1.0, 0.6 + 0.4 * sin(_t * 6.0))
		draw_line(mid + Vector2(-60, -6), mid + Vector2(60, -6), ac, 3.0)
		draw_colored_polygon(PackedVector2Array([mid + Vector2(60, -12), mid + Vector2(72, -6), mid + Vector2(60, 0)]), ac)
		draw_line(mid + Vector2(-60, 8), mid + Vector2(60, 8), ac, 3.0)
		draw_colored_polygon(PackedVector2Array([mid + Vector2(-60, 2), mid + Vector2(-72, 8), mid + Vector2(-60, 14)]), ac)
	# how long: 5 sec on, 5 sec to recharge
	var bar := Rect2(260, 400, 440, 16)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x / 2.0, bar.size.y)), Color(0.75, 0.45, 1.0))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x / 2.0, 0), Vector2(bar.size.x / 2.0, bar.size.y)), Color(0.35, 0.33, 0.42))
	draw_rect(bar, Color(0.9, 0.85, 1.0), false, 1.5)
	_centered_at(font, "5 sec swapped", bar.position + Vector2(bar.size.x / 4.0, -8), 14, Color(0.88, 0.7, 1.0))
	_centered_at(font, "5 sec to recharge", bar.position + Vector2(bar.size.x * 3.0 / 4.0, -8), 14, Color(0.7, 0.7, 0.8))
	_centered(font, "Press  E  to continue", 458.0, 18, Color(1.0, 0.95, 0.6, 0.55 + 0.45 * sin(_t * 4.0)))

func _centered(font: Font, s: String, y: float, fs: int, col: Color) -> void:
	_centered_at(font, s, Vector2(W * 0.5, y), fs, col)

func _centered_at(font: Font, s: String, at: Vector2, fs: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(at.x - w * 0.5, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
