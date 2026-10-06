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
const OGRE_SPEED := 200.0       # 2.5x the hero's walking speed (80 px/s)
const OGRE_WAKE := 0.45         # a short, visible wake-up before he moves
const OGRE_CATCH := 22.0
const DRAGON_MAX_SPEED := 44.0   # faster than this near a dragon wakes it

var data: Dictionary
var lamp_manager: LampManager
var hazards := {}       # Vector2i -> char
var walls := {}
var dragons: Array[Vector2] = []
var ogre_idx := -1              # which ogre is awake and chasing (-1: all asleep)
var ogre_pos := Vector2.ZERO
var ogre_t := 0.0
var hero_start := Vector2.ZERO
var npc_start := Vector2.ZERO
var exit_pos := Vector2.ZERO
var clock := 0.0
var sprung := {}        # trap floors that have been triggered
var palette := 0        # 0 dungeon, 1 outdoors, 2 demon lord's (final) dungeon
var _hazard_layer: HazardLayer
var _floor_tex: ImageTexture   # must be kept alive, or the renderer loses it
var _floor_pal := -1
var _exit_lamp: Lamp
var _door_open := false

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
					_exit_lamp = _add_lamp(c, LampColors.C.GREEN, exit_on)
					_exit_lamp.is_exit = true
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

## A hero moving fast near a sleeping dragon wakes it. Returns the dragon's index, or -1.
func stealth_violation(p: Vector2, speed: float) -> int:
	for i in dragons.size():
		if p.distance_to(dragons[i]) < DRAGON_RADIUS and speed > DRAGON_MAX_SPEED:
			return i
	return -1

## The woken ogre: he blinks awake (OGRE_WAKE seconds), then chases the hero at 3x his speed.
func wake_ogre(i: int) -> void:
	if ogre_idx >= 0:
		return
	ogre_idx = i
	ogre_pos = dragons[i]
	ogre_t = 0.0

## Advances the chase; true once he has caught the hero.
func step_ogre(delta: float, hero_pos: Vector2) -> bool:
	ogre_t += delta
	if ogre_t < OGRE_WAKE:
		return false
	ogre_pos = ogre_pos.move_toward(hero_pos, OGRE_SPEED * delta)
	return ogre_pos.distance_to(hero_pos) < OGRE_CATCH

func at_exit(p: Vector2) -> bool:
	return exit_pos != Vector2.ZERO and p.distance_to(exit_pos) < 14.0

func reset() -> void:
	ogre_idx = -1
	clock = 0.0
	sprung.clear()

func _process(delta: float) -> void:
	clock += delta
	if _exit_lamp != null and _exit_lamp.on != _door_open:
		queue_redraw()   # the exit door opens and shuts with its lamp
	if _hazard_layer != null:
		_hazard_layer.queue_redraw()

# ------------------------------------------------------------------ drawing

## Floor colour tint per palette: 0 dungeon, 1 outdoors (prologue), 2 the Demon Lord's dungeon.
func tint() -> Color:
	match palette:
		1: return Color(0.95, 1.0, 0.9)
		2: return Color(0.62, 0.32, 0.38)
	return Color(0.14, 0.28, 0.7)   # a navy night dungeon, so the lamps' light stands out

## The floor and walls are baked into ONE image (16 px per tile, Kenney "Tiny Dungeon")
## and drawn scaled up with nearest filtering: a single draw call.
func _tile_texture() -> ImageTexture:
	var sheet := Sprites.SHEET.get_image()
	sheet.convert(Image.FORMAT_RGBA8)
	var S := Sprites.CELL
	var img := Image.create(COLS * S, ROWS * S, false, Image.FORMAT_RGBA8)
	for y in ROWS:
		for x in COLS:
			var c := Vector2i(x, y)
			var at := Vector2i(x * S, y * S)
			var h := absi(hash(c)) % Sprites.FLOOR_ALT.size()
			var floor_i: int = (Sprites.FLOOR_OUT_ALT if h == 3 else Sprites.FLOOR_OUT) if palette == 1 else Sprites.FLOOR_ALT[h]
			img.blit_rect(sheet, Sprites.region(floor_i), at)
			if walls.has(c) and not _is_dragon_cell(c):
				img.blit_rect(sheet, Sprites.region(Sprites.WALL), at)
				if walls.has(c + Vector2i(0, 1)) or y == ROWS - 1:   # wall tops (not facing the room) are darker: depth
					for py in S:
						for px in S:
							img.set_pixel(at.x + px, at.y + py, img.get_pixel(at.x + px, at.y + py).darkened(0.35))
	return ImageTexture.create_from_image(img)

func _is_dragon_cell(c: Vector2i) -> bool:
	return dragons.has(cell_center(c))

func _draw() -> void:
	if _floor_tex == null or _floor_pal != palette:
		_floor_tex = _tile_texture()
		_floor_pal = palette
	draw_texture_rect(_floor_tex, Rect2(0, 0, COLS * TILE, ROWS * TILE), false, tint())
	for c: Vector2i in hazards:
		if hazards[c] == "x":   # a subtly cracked tile: the hero cannot see it
			var o := Vector2(c.x * TILE, c.y * TILE)
			draw_polyline(PackedVector2Array([o + Vector2(7, 12), o + Vector2(13, 15), o + Vector2(17, 13), o + Vector2(24, 19)]), Color(0, 0, 0, 0.13), 1.0)
	_draw_exit()

## The exit: a big door in the floor's far end. The exit lamp hangs ABOVE the door (see lamp.gd),
## so the light never hides the door. Open while the exit lamp is on, shut while it is off.
func _draw_exit() -> void:
	if exit_pos == Vector2.ZERO:
		return
	var e := exit_pos
	var foot := e + Vector2(0, TILE * 0.5)
	_door_open = _exit_lamp != null and _exit_lamp.on
	DrawUtil.ellipse(self, foot + Vector2(0, -2), 34, 9, Color(0.4, 1.0, 0.5, 0.45 if _door_open else 0.15))
	var kind: String = data.get("exit_kind", "door")
	Sprites.draw_at_foot(self, Sprites.DOOR_OPEN if _door_open and kind != "lock" else Sprites.DOOR_CLOSED, foot, 4.0)
	if kind == "lock":   # a heavy padlock on the final door
		var p := foot + Vector2(0, -24)
		draw_arc(p + Vector2(0, -6), 7.0, PI, TAU, 10, Color(0.75, 0.75, 0.8), 3.0)
		draw_rect(Rect2(p + Vector2(-9, -6), Vector2(18, 14)), Color(0.95, 0.75, 0.2))
		draw_rect(Rect2(p + Vector2(-9, -6), Vector2(18, 14)), Color(0.3, 0.2, 0.05), false, 1.5)
		draw_circle(p + Vector2(0, 0), 2.0, Color(0.2, 0.12, 0.05))
