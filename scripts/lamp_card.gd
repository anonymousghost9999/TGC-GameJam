class_name LampCard
extends Control
## The pop-up shown when a level introduces a new lamp or rule: a title, one line, and a little
## looping demo of the hero obeying it (so it is seen, not just read). Kinds: green, red, orange,
## blue, nearest, linked, swap. (The invert lantern has its own card, invert_card.gd.)

const W := 960.0
const H := 544.0
const LOOP := 4.0
const STAGE := Rect2(210, 190, 540, 150)   # the demo strip
const INFO := {
	"green": ["NEW LAMP: GREEN", "He walks to it."],
	"red": ["NEW LAMP: RED", "He runs away from it."],
	"orange": ["NEW LAMP: ORANGE", "He creeps to it, slowly and quietly."],
	"blue": ["NEW LAMP: BLUE", "He freezes on the spot."],
	"nearest": ["ONLY THE NEAREST LAMP", "Several lamps lit? He obeys only the NEAREST one."],
	"linked": ["LINKED COLOURS", "Same colour, same switch: E flips EVERY lamp of that colour."],
	"swap": ["SWAP", "One lit, one dark? E makes them trade places."],
}

var kind := "green"
var _t := 0.0

func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func show_kind(k: String) -> void:
	kind = k
	_t = 0.0
	visible = true

func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var font: Font = UiFont.MAIN
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.01, 0.06, 0.88))
	var panel := Rect2(170, 60, 620, 420)
	draw_rect(panel, Color(0.1, 0.08, 0.16))
	draw_rect(panel, Color(1.0, 0.85, 0.4), false, 3.0)
	var info: Array = INFO.get(kind, ["", ""])
	_centered(font, info[0], 112.0, 30, Color(1.0, 0.9, 0.5))
	_centered(font, info[1], 150.0, 18, Color(0.92, 0.9, 1.0))
	# the stage: a strip of dungeon floor
	for i in int(STAGE.size.x / 30.0):
		Sprites.draw_cell(self, Sprites.FLOOR, Rect2(STAGE.position + Vector2(i * 30.0, 0), Vector2(30, STAGE.size.y)), Color(0.55, 0.5, 0.6))
	draw_rect(STAGE, Color(0.9, 0.85, 1.0, 0.5), false, 2.0)
	var p := fposmod(_t, LOOP)
	var floor_y := STAGE.position.y + 110.0
	call("_demo_" + kind, p, floor_y)
	_centered(font, "Press  E  to continue", 450.0, 18, Color(1.0, 0.95, 0.6, 0.55 + 0.45 * sin(_t * 4.0)))

# ------------------------------------------------------------------ demos (p = 0..LOOP)

func _demo_green(p: float, y: float) -> void:
	var lamp_x := STAGE.end.x - 70.0
	var on := p > 0.5
	_lamp(Vector2(lamp_x, y), LampColors.C.GREEN, on)
	var x := STAGE.position.x + 60.0 + clampf((p - 0.7) * 150.0, 0.0, lamp_x - 40.0 - (STAGE.position.x + 60.0))
	_hero(Vector2(x, y), p > 0.7 and x < lamp_x - 41.0)

func _demo_red(p: float, y: float) -> void:
	var lamp_x := STAGE.position.x + 200.0
	_lamp(Vector2(lamp_x, y), LampColors.C.RED, p > 0.5)
	var x := lamp_x + 50.0 + clampf((p - 0.7) * 150.0, 0.0, 230.0)
	_hero(Vector2(x, y), p > 0.7 and p < 2.2, -1.0 if p < 0.7 else 1.0)

func _demo_orange(p: float, y: float) -> void:
	var lamp_x := STAGE.end.x - 70.0
	_lamp(Vector2(lamp_x, y), LampColors.C.ORANGE, p > 0.4)
	var x := STAGE.position.x + 220.0 + clampf((p - 0.6) * 45.0, 0.0, 200.0)
	_hero(Vector2(x, y), p > 0.6, 1.0, true)

func _demo_blue(p: float, y: float) -> void:
	var lamp_x := STAGE.position.x + 270.0
	var on := p > 1.4 and p < 3.0
	_lamp(Vector2(lamp_x, y - 50.0), LampColors.C.BLUE, on)
	# he walks right; frozen while the blue is lit
	var walked := minf(p, 1.4) + maxf(p - 3.0, 0.0)
	var x := STAGE.position.x + 40.0 + walked * 110.0
	_hero(Vector2(x, y), not on, 1.0, false, on)

func _demo_nearest(p: float, y: float) -> void:
	var left := STAGE.position.x + 70.0
	var right := STAGE.end.x - 40.0
	var start := STAGE.position.x + 210.0
	_lamp(Vector2(left, y), LampColors.C.GREEN, true)
	_lamp(Vector2(right, y), LampColors.C.GREEN, true)
	var x := start - clampf((p - 0.8) * 140.0, 0.0, start - left - 40.0)
	_hero(Vector2(x, y), p > 0.8 and x > left + 41.0, -1.0)
	if p < 0.8:   # measure both distances: the shorter one wins
		draw_dashed_line(Vector2(left + 14, y - 60), Vector2(start - 14, y - 60), Color(0.5, 1.0, 0.6, 0.9), 2.0, 6.0)
		draw_dashed_line(Vector2(start + 14, y - 60), Vector2(right - 14, y - 60), Color(1.0, 1.0, 1.0, 0.35), 2.0, 6.0)

func _demo_linked(p: float, y: float) -> void:
	var a := STAGE.position.x + 110.0
	var b := STAGE.end.x - 90.0
	var on := p > 1.0 and p < 3.0
	_lamp(Vector2(a, y), LampColors.C.GREEN, on)
	_lamp(Vector2(b, y), LampColors.C.GREEN, on)
	_npc_press(Vector2(a + 40.0, y), Vector2(a, y - 20.0), p, [1.0, 3.0])
	if on:
		draw_dashed_line(Vector2(a + 16, y - 20), Vector2(b - 16, y - 20), Color(0.5, 1.0, 0.6, 0.6), 2.0, 8.0)

func _demo_swap(p: float, y: float) -> void:
	var a := STAGE.position.x + 110.0
	var b := STAGE.end.x - 90.0
	var flipped := p > 1.5
	_lamp(Vector2(a, y), LampColors.C.GREEN, not flipped)
	_lamp(Vector2(b, y), LampColors.C.GREEN, flipped)
	_npc_press(Vector2(b + 40.0, y), Vector2(b, y - 20.0), p, [1.5])
	draw_line(Vector2(a + 16, y - 20), Vector2(b - 16, y - 20), Color(1, 1, 1, 0.25), 2.0)

# ------------------------------------------------------------------ pieces

func _lamp(at: Vector2, color: int, on: bool) -> void:
	var c := LampColors.rgb(color)
	if on:
		DrawUtil.glow(self, at + Vector2(0, -20), 44.0, Color(c.r, c.g, c.b, 0.55), 6)
	DrawUtil.ellipse(self, at + Vector2(0, 13), 13, 4, Color(0, 0, 0, 0.35))
	Sprites.draw_stand(self, at + Vector2(0, -14), 2.0)
	Lamp.draw_bulb(self, at + Vector2(0, -20), c, color, on)

func _hero(foot: Vector2, walking: bool, facing := 1.0, tiptoe := false, frozen := false) -> void:
	var bob := 0.0
	if walking:
		bob = -absf(sin(_t * (5.0 if tiptoe else 10.0))) * (4.0 if tiptoe else 3.0)
	DrawUtil.ellipse(self, foot + Vector2(0, 2), 14, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(foot + Vector2(0, bob), 0.0, Vector2(facing, 1.0))
	Sprites.draw_at_foot(self, Sprites.HERO, Vector2.ZERO, 3.0)
	if frozen:
		draw_rect(Rect2(-22, -50, 44, 50), Color(0.6, 0.8, 1.0, 0.35))
		draw_rect(Rect2(-22, -50, 44, 50), Color(0.85, 0.95, 1.0, 0.8), false, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## The NPC beside a lamp, with a spark at each press time.
func _npc_press(foot: Vector2, bulb: Vector2, p: float, presses: Array) -> void:
	DrawUtil.ellipse(self, foot + Vector2(0, 2), 13, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(foot, 0.0, Vector2(-1, 1))
	Sprites.draw_at_foot(self, Sprites.NPC, Vector2.ZERO, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for at in presses:
		var k := 1.0 - (p - float(at)) / 0.4
		if k > 0.0 and k <= 1.0:
			var from := foot + Vector2(-12, -24)
			draw_line(from, bulb, Color(1, 1, 1, 0.9 * k), 2.0)
			draw_arc(from, 8.0 + 14.0 * (1.0 - k), 0.0, TAU, 14, Color(1, 1, 1, k), 2.0)
			_centered_at(UiFont.MAIN, "E", from + Vector2(0, -16), 18, Color(1.0, 0.95, 0.6, k))

func _centered(font: Font, s: String, y: float, fs: int, col: Color) -> void:
	_centered_at(font, s, Vector2(W * 0.5, y), fs, col)

func _centered_at(font: Font, s: String, at: Vector2, fs: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(at.x - w * 0.5, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
