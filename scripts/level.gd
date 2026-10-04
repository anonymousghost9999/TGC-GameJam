class_name Level
extends Node2D
## Builds one puzzle room from a data dictionary (see level_data.gd): walls,
## hazards, lamps, dragons, start positions and the exit. Provides the hazard
## queries the hero uses. Coordinates are 32px tiles on a 30x17 grid.
##
## Map legend:
##   # wall   . floor   H hero start   N NPC start   X exit (with a green exit lamp)
##   ^ spikes   ~ fire   x hidden trap floor   t / u timed spikes (two opposite phases)
##   D sleeping dragon (wakes if the hero moves fast nearby)
##   g r o b  lamps (OFF)     G R O B  lamps (ON)     (green red orange blue)

const TILE := 32
const COLS := 30
const ROWS := 17
const TIMED_PERIOD := 4.0   # each phase lasts half of this
const DRAGON_RADIUS := 104.0
const DRAGON_MAX_SPEED := 44.0   # faster than this near a dragon wakes it

var data: Dictionary
var lamp_manager: LampManager
var hazards := {}       # Vector2i -> char
var walls := {}
var dragons: Array[Vector2] = []
var hero_start := Vector2.ZERO
var npc_start := Vector2.ZERO
var exit_pos := Vector2.ZERO
var clock := 0.0
var sprung := {}        # trap floors that have been triggered
var palette := 0        # 0 dungeon, 1 outdoors, 2 demon lord's (final) dungeon
var _hazard_layer: HazardLayer
var _floor_tex: ImageTexture   # must be kept alive, or the renderer loses it
var _floor_pal := -1

func setup(d: Dictionary, lm: LampManager) -> void:
	data = d
	lamp_manager = lm

func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + TILE * 0.5)

func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TILE)), int(floor(p.y / TILE)))

func _ready() -> void:
	palette = data.get("palette", 0)
	var rows: Array = data.map
	var exit_on: bool = data.get("exit_on", true)
	for y in ROWS:
		var row: String = rows[y]
		assert(row.length() == COLS, "level %s row %d has width %d" % [data.get("id", "?"), y, row.length()])
		for x in COLS:
			var ch := row[x]
			var c := Vector2i(x, y)
			match ch:
				"#": walls[c] = true
				"^", "~", "x", "t", "u": hazards[c] = ch
				"D":
					dragons.append(cell_center(c))
					walls[c] = true
				"H": hero_start = cell_center(c)
				"N": npc_start = cell_center(c)
				"X":
					exit_pos = cell_center(c)
					var ex := _add_lamp(c, LampColors.C.GREEN, exit_on)
					ex.is_exit = true
				"g", "r", "o", "b":
					_add_lamp(c, LampColors.from_char(ch), false)
				"G", "R", "O", "B":
					_add_lamp(c, LampColors.from_char(ch), true)
	_build_colliders()
	_hazard_layer = HazardLayer.new()
	_hazard_layer.level = self
	add_child(_hazard_layer)
	queue_redraw()

func _add_lamp(c: Vector2i, color: int, on: bool) -> Lamp:
	var l := Lamp.new()
	l.original = color
	l.start_on = on
	l.on = on
	l.position = cell_center(c)
	lamp_manager.register(l)
	add_child(l)
	return l

func _build_colliders() -> void:
	for y in ROWS:
		var x := 0
		while x < COLS:
			if walls.has(Vector2i(x, y)):
				var x0 := x
				while x < COLS and walls.has(Vector2i(x, y)):
					x += 1
				var body := StaticBody2D.new()
				body.collision_layer = 1
				body.position = Vector2((x0 + x) * 0.5 * TILE, y * TILE + TILE * 0.5)
				var cs := CollisionShape2D.new()
				var sh := RectangleShape2D.new()
				sh.size = Vector2((x - x0) * TILE, TILE)
				cs.shape = sh
				body.add_child(cs)
				add_child(body)
			else:
				x += 1

# ------------------------------------------------------------------ queries

## Timed spikes: 't' are OUT during the first half of each cycle, 'u' during the second.
func timed_active(kind: String) -> bool:
	var t := fposmod(clock, TIMED_PERIOD)
	return t < TIMED_PERIOD * 0.5 if kind == "t" else t >= TIMED_PERIOD * 0.5

## True during the last 0.4s before the spikes come out (they twitch as a warning).
func timed_warning(kind: String) -> bool:
	var t := fposmod(clock, TIMED_PERIOD)
	var start := 0.0 if kind == "t" else TIMED_PERIOD * 0.5
	var until := fposmod(start - t, TIMED_PERIOD)
	return not timed_active(kind) and until <= 0.5

func _inner(p: Vector2, c: Vector2i) -> bool:
	var l := p - Vector2(c.x * TILE, c.y * TILE)
	return l.x >= 1.5 and l.x <= TILE - 1.5 and l.y >= 1.5 and l.y <= TILE - 1.5   # tiny forgiveness only

## "" when safe, else the hazard kind that kills a hero standing at p.
func hazard_at(p: Vector2) -> String:
	var c := cell_of(p)
	if not hazards.has(c) or not _inner(p, c):
		return ""
	match hazards[c]:
		"^": return "spike"
		"~": return "fire"
		"x":
			sprung[c] = true
			return "trap"
		"t", "u": return "spike" if timed_active(hazards[c]) else ""
	return ""

## A hero moving fast near a sleeping dragon wakes it.
func stealth_violation(p: Vector2, speed: float) -> bool:
	for d in dragons:
		if p.distance_to(d) < DRAGON_RADIUS and speed > DRAGON_MAX_SPEED:
			return true
	return false

func at_exit(p: Vector2) -> bool:
	return exit_pos != Vector2.ZERO and p.distance_to(exit_pos) < 14.0

func reset() -> void:
	clock = 0.0
	sprung.clear()

func _process(delta: float) -> void:
	clock += delta
	if _hazard_layer != null:
		_hazard_layer.queue_redraw()

# ------------------------------------------------------------------ drawing

func _pal() -> Dictionary:
	match palette:
		1: return {"a": Color(0.36, 0.62, 0.30), "b": Color(0.33, 0.58, 0.28), "wall": Color(0.2, 0.4, 0.2), "face": Color(0.28, 0.5, 0.26)}
		2: return {"a": Color(0.20, 0.12, 0.17), "b": Color(0.17, 0.09, 0.14), "wall": Color(0.08, 0.04, 0.07), "face": Color(0.28, 0.1, 0.14)}
	return {"a": Color(0.30, 0.28, 0.38), "b": Color(0.27, 0.25, 0.35), "wall": Color(0.14, 0.12, 0.20), "face": Color(0.26, 0.22, 0.36)}

## The floor and walls are ONE tiny texture (1 pixel per tile) scaled up with nearest
## filtering: a single draw call. (Hundreds of separate rectangles hit a renderer
## glitch that dropped a sliver of one tile.)
func _tile_texture(p: Dictionary) -> ImageTexture:
	var img := Image.create(COLS, ROWS, false, Image.FORMAT_RGBA8)
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			var col: Color = p.wall if walls.has(c) else (p.a if (x + y) % 2 == 0 else p.b)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _draw() -> void:
	var p := _pal()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _floor_tex == null or _floor_pal != palette:
		_floor_tex = _tile_texture(p)
		_floor_pal = palette
	draw_texture_rect(_floor_tex, Rect2(0, 0, COLS * TILE, ROWS * TILE), false)
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if walls.has(c):
				if not walls.has(c + Vector2i(0, 1)):
					draw_rect(Rect2(r.position.x, r.position.y + TILE - 8, TILE, 8), p.face)
				draw_line(r.position + Vector2(0, 14), r.position + Vector2(TILE, 14), Color(0, 0, 0, 0.18), 1.0)
				draw_line(r.position + Vector2(16, 0), r.position + Vector2(16, 14), Color(0, 0, 0, 0.18), 1.0)
			elif hazards.get(c, "") == "x":   # a subtly cracked tile: the hero cannot see it
				draw_line(r.position + Vector2(8, 10), r.position + Vector2(22, 20), Color(0, 0, 0, 0.22), 1.5)
				draw_line(r.position + Vector2(22, 8), r.position + Vector2(12, 24), Color(0, 0, 0, 0.18), 1.5)
	# exit marker
	if exit_pos != Vector2.ZERO:
		var kind: String = data.get("exit_kind", "door")
		var e := exit_pos
		DrawUtil.glow(self, e, 46.0, Color(0.4, 1.0, 0.5, 0.35))
		if kind == "lock":
			draw_rect(Rect2(e + Vector2(-16, -2), Vector2(32, 26)), Color(0.5, 0.45, 0.2))
			draw_arc(e + Vector2(0, -2), 11.0, PI, TAU, 12, Color(0.8, 0.75, 0.3), 5.0)
			draw_circle(e + Vector2(0, 10), 3.0, Color(0.1, 0.1, 0.1))
		else:
			draw_rect(Rect2(e + Vector2(-16, -14), Vector2(32, 34)), Color(0.1, 0.25, 0.16))
			draw_circle(e + Vector2(0, -14), 16.0, Color(0.1, 0.25, 0.16))
			draw_rect(Rect2(e + Vector2(-11, -12), Vector2(22, 32)), Color(0.45, 1.0, 0.6, 0.35))
	for d in dragons:   # sleeping dragon + its "light sleeper" zone
		draw_arc(d, DRAGON_RADIUS, 0.0, TAU, 40, Color(1.0, 0.3, 0.2, 0.22), 1.5)
		DrawUtil.ellipse(self, d + Vector2(0, 6), 26, 14, Color(0.2, 0.5, 0.25))
		draw_circle(d + Vector2(-16, -2), 9.0, Color(0.25, 0.58, 0.3))
		draw_line(d + Vector2(-20, -1), d + Vector2(-12, -1), Color(0.05, 0.1, 0.05), 2.0)
		draw_colored_polygon(PackedVector2Array([d + Vector2(-4, -10), d + Vector2(0, -20), d + Vector2(4, -10)]), Color(0.7, 0.3, 0.25))
		draw_colored_polygon(PackedVector2Array([d + Vector2(8, -10), d + Vector2(12, -18), d + Vector2(16, -9)]), Color(0.7, 0.3, 0.25))
		draw_string(ThemeDB.fallback_font, d + Vector2(-10, -24), "zZz", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.7))
