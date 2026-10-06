class_name TitleScreen
extends Control
## The launch screen: a little lamp-lit dungeon scene with the title, not a manual.
## The rules are taught level by level; the keys are behind [Tab].

const W := 960.0
const H := 544.0
const LAMPS := [LampColors.C.GREEN, LampColors.C.RED, LampColors.C.ORANGE, LampColors.C.BLUE]

var _t := 0.0

func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var font: Font = UiFont.MAIN
	# the dungeon: dim floor, a wall along the top and bottom
	for y in 17:
		for x in 30:
			var r := Rect2(x * 32, y * 32, 32, 32)
			var wall := y < 2 or y > 14
			Sprites.draw_cell(self, Sprites.WALL if wall else Sprites.FLOOR, r, Color(0.3, 0.27, 0.36) if wall else Color(0.36, 0.33, 0.42))
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.0, 0.06, 0.35))
	# four lamps, each lit in turn
	var lit := int(_t / 1.2) % 4
	for i in 4:
		var p := Vector2(W * 0.5 + (i - 1.5) * 120.0, 400.0)
		var c := LampColors.rgb(LAMPS[i])
		var on := i == lit or int(_t * 2.0) % 8 == 0
		if on:
			DrawUtil.glow(self, p + Vector2(0, -20), 70.0, Color(c.r, c.g, c.b, 0.6), 7)
		DrawUtil.ellipse(self, p + Vector2(0, 13), 13, 4, Color(0, 0, 0, 0.4))
		Sprites.draw_stand(self, p + Vector2(0, -14), 2.0)
		Lamp.draw_bulb(self, p + Vector2(0, -20), c, LAMPS[i], on)
	# the hero bumbles about on the left, the NPC waits on the right
	var hx := 150.0 + sin(_t * 0.8) * 40.0
	DrawUtil.ellipse(self, Vector2(hx, 410), 20, 6, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2(hx, 410 - absf(sin(_t * 9.0)) * 4.0), 0.0, Vector2(signf(cos(_t * 0.8)) if cos(_t * 0.8) != 0.0 else 1.0, 1.0))
	Sprites.draw_at_foot(self, Sprites.HERO, Vector2.ZERO, 5.0)
	draw_set_transform(Vector2(W - 150, 410 + sin(_t * 2.0) * 1.5), 0.0, Vector2(-1, 1))
	DrawUtil.glow(self, Vector2(-30, -40), 30.0, Color(0.85, 0.6, 1.0, 0.5), 5)
	Sprites.draw_at_foot(self, Sprites.NPC, Vector2.ZERO, 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the title
	var title := "THE NPC JOB"
	var tsz := 76
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsz).x
	var tp := Vector2((W - tw) * 0.5, 170.0 + sin(_t * 1.5) * 3.0)
	draw_string(font, tp + Vector2(4, 5), title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, Color(0, 0, 0, 0.6))
	draw_string_outline(font, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, 10, Color(0.15, 0.05, 0.1))
	draw_string(font, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, tsz, Color(1.0, 0.85, 0.35))
	_centered(font, "He can't see the traps.  He can only see the lamps.", 220.0, 20, Color(0.9, 0.88, 1.0))
	var blink := 0.55 + 0.45 * sin(_t * 4.0)
	_centered(font, "Press  E  to start", 300.0, 26, Color(1.0, 0.95, 0.6, blink), 6)
	draw_string(font, Vector2(W - 150, H - 14), "[Tab] controls", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.9, 0.8))

func _centered(font: Font, s: String, y: float, fs: int, col: Color, outline := 4) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2((W - w) * 0.5, y)
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, Color(0.05, 0.02, 0.08, col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
