class_name OpenWorld
extends Node2D
## The open map: a village in the west, a river, then a forest and a shrine.
##   region 0 village | 1 meadow + river | 2 forest | 3 shrine
## Collision layers: 1 = solid for everyone (trees, houses, map edge),
## 2 = hero only (fence, gate, log). The imaginary guide floats over water/fences.

signal message(text: String)
signal ambush_cleared

const TILE := 32
const COLS := 64
const ROWS := 36
const PATH_ROWS := Vector2i(16, 20)   # the main east-west road (inclusive)

# Where the hero wanders to in each region (tile coordinates).
const SPOTS := {
	0: [Vector2i(4, 15), Vector2i(10, 20), Vector2i(15, 16), Vector2i(18, 22), Vector2i(7, 19), Vector2i(19, 13), Vector2i(3, 20)],
	1: [Vector2i(24, 10), Vector2i(27, 14), Vector2i(25, 21), Vector2i(28, 26), Vector2i(24, 29), Vector2i(27, 6)],
	2: [Vector2i(36, 22), Vector2i(40, 15), Vector2i(44, 23), Vector2i(38, 12), Vector2i(43, 27), Vector2i(36, 14)],
	3: [],
}
const HOUSES: Array[Rect2i] = [
	Rect2i(3, 3, 5, 4), Rect2i(11, 3, 4, 4), Rect2i(16, 4, 4, 4), Rect2i(2, 25, 5, 4), Rect2i(10, 26, 4, 4),
]

var light: LightController
var daynight: DayNight
var hero: Node2D            # set by the manager; used for the werewolf trigger
var player_start := Vector2.ZERO
var hero_start := Vector2.ZERO
var exit_pos := Vector2.ZERO
var barrel: Barrel
var slime: Slime
var pedestal: Pedestal
var signpost: Signpost
var statue: Statue
var chest: Chest
var gate: Obstacle
var log_obstacle: Obstacle
var river: StoneBridge
var items: Array[Item] = []
var lampposts: Array[Lamppost] = []
var wolves: Array[Werewolf] = []
var ambush_spawned := false
var ambush_done := false

var _trees: Array[Vector2] = []
var _tree_scale: Array[float] = []
var _reserved := {}
var _flowers: Array[Vector3] = []
var _amb_timer := 0.0
var _rng := RandomNumberGenerator.new()

func tile_pos(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)

func region_at(p: Vector2) -> int:
	var tx := int(p.x / TILE)
	if tx < 22:
		return 0
	if tx < 34:
		return 1
	if tx < 48:
		return 2
	return 3

func wolves_active() -> bool:
	for w in wolves:
		if is_instance_valid(w) and not w.burning:
			return true
	return false

## Test helper: wall the hero in so the stuck-failsafe has to rescue him.
func add_block_for_test() -> void:
	_add_block(Rect2(5 * TILE, 2 * TILE, TILE, 32 * TILE), 3)

func reset_actors() -> void:
	barrel.reset()
	slime.reset()
	pedestal.reset()
	signpost.reset()
	statue.reset()
	chest.reset()
	gate.reset()
	log_obstacle.reset()
	for l in lampposts:
		l.reset()

# ------------------------------------------------------------------ building

func _reserve(c: Vector2i, margin := 1) -> void:
	for dx in range(-margin, margin + 1):
		for dy in range(-margin, margin + 1):
			_reserved[Vector2i(c.x + dx, c.y + dy)] = true

func _reserve_rect(r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			_reserved[Vector2i(x, y)] = true

func _add_block(rect: Rect2, layer: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	return body

func _prop(node: Interactable, tx: int, ty: int) -> Interactable:
	node.position = tile_pos(tx, ty)
	node.said.connect(message.emit)
	add_child(node)
	_reserve(Vector2i(tx, ty))
	return node

func _item(kind: String, tx: int, ty: int, reveal := "always") -> Item:
	var it := Item.new()
	it.kind = kind
	it.reveal = reveal
	it.daynight = daynight
	it.light = light
	it.position = tile_pos(tx, ty)
	it.region = region_at(it.position)
	add_child(it)
	items.append(it)
	_reserve(Vector2i(tx, ty))
	return it

func _ready() -> void:
	_rng.seed = 20260503
	player_start = tile_pos(4, 20)
	hero_start = tile_pos(3, 18)
	exit_pos = tile_pos(60, 19)

	# reserved clearings so trees never block roads, spots, or props
	_reserve_rect(Rect2i(0, PATH_ROWS.x, COLS, PATH_ROWS.y - PATH_ROWS.x + 1))
	_reserve_rect(Rect2i(30, 0, 4, ROWS))                 # river
	_reserve_rect(Rect2i(22, 0, 1, ROWS))                 # fence line
	_reserve_rect(Rect2i(50, 11, 13, 14))                 # shrine clearing
	_reserve_rect(Rect2i(15, 27, 5, 5))                   # key garden
	_reserve_rect(Rect2i(39, 4, 5, 5))                    # hollow tree clearing
	for r: Rect2i in HOUSES:
		_reserve_rect(r)
		_add_block(Rect2(r.position.x * TILE, r.position.y * TILE, r.size.x * TILE, r.size.y * TILE), 1)
	for region: int in SPOTS:
		for c: Vector2i in SPOTS[region]:
			_reserve(c)

	# map edge: solid walls just inside the decorative tree border
	var w := COLS * TILE
	var h := ROWS * TILE
	_add_block(Rect2(0, 0, w, 2 * TILE), 1)
	_add_block(Rect2(0, h - 2 * TILE, w, 2 * TILE), 1)
	_add_block(Rect2(0, 0, 2 * TILE, h), 1)
	_add_block(Rect2(w - 2 * TILE, 0, 2 * TILE, h), 1)

	# river + stepping stones (surface at night)
	var stone_rects: Array[Rect2] = []
	for x in range(30, 34):
		stone_rects.append(Rect2(x * TILE, 18 * TILE, TILE, TILE))
	river = StoneBridge.new()
	river.setup(daynight, Rect2(30 * TILE, 0, 4 * TILE, h), stone_rects)
	add_child(river)

	# fence line (hero only) with the gate in the middle
	_add_block(Rect2(22 * TILE, 2 * TILE, TILE, 15 * TILE), 2)
	_add_block(Rect2(22 * TILE, 20 * TILE, TILE, 14 * TILE), 2)
	gate = Obstacle.new()
	gate.kind = "gate"
	gate.need = "key"
	gate.region = 0
	gate.hint = "The village gate is locked. It needs a KEY, hidden somewhere in the village. Some things only show themselves at night (F)."
	gate.position = tile_pos(22, 18) + Vector2(0, 0)
	gate.said.connect(message.emit)
	add_child(gate)
	# a wall of trees with a single opening where the fallen log lies
	log_obstacle = Obstacle.new()
	log_obstacle.kind = "log"
	log_obstacle.need = "axe"
	log_obstacle.region = 2
	log_obstacle.hint = "A huge fallen log. It needs an AXE. Something glints in a dark hollow tree up north (keep the lantern on)."
	log_obstacle.position = tile_pos(47, 18)
	log_obstacle.said.connect(message.emit)
	add_child(log_obstacle)

	# props the hero blunders with
	barrel = _prop(Barrel.new(), 8, 24) as Barrel
	signpost = _prop(Signpost.new(), 12, 14) as Signpost
	statue = _prop(Statue.new(), 9, 15) as Statue
	chest = _prop(Chest.new(), 26, 12) as Chest
	slime = _prop(Slime.new(), 26, 24) as Slime
	pedestal = _prop(Pedestal.new(), 56, 16) as Pedestal
	_reserve(Vector2i(8, 25))
	_reserve(Vector2i(7, 24))
	_reserve(Vector2i(26, 22))
	_reserve(Vector2i(12, 15))
	_reserve(Vector2i(9, 16))
	_reserve(Vector2i(26, 13))
	_reserve(Vector2i(56, 17))

	# pickable items (junk everywhere; the real ones are hidden)
	_item("fish", 14, 12)
	_item("bucket", 6, 13)
	_item("hammer", 8, 27)
	_item("broom", 38, 26)
	_item("pan", 42, 11)
	_item("key", 17, 29, "night")
	_item("axe", 41, 7, "lantern")

	# environmental lights the guide can switch on
	for c in [Vector2i(13, 15), Vector2i(26, 15), Vector2i(44, 14)]:
		var lp := Lamppost.new()
		lp.daynight = daynight
		lp.position = tile_pos(c.x, c.y)
		add_child(lp)
		light.register(lp)
		lampposts.append(lp)
		_reserve(c)

	_build_trees()
	_build_flowers()
	daynight.time_changed.connect(_on_time_changed)
	queue_redraw()

func _build_trees() -> void:
	var forced: Array[Vector2i] = []
	# tree wall around the log: only rows 17..19 are open at x = 47
	for y in range(2, 34):
		if y < 17 or y > 19:
			forced.append(Vector2i(47, y))
	for y in range(0, ROWS):
		for x in range(0, COLS):
			var c := Vector2i(x, y)
			var border := x < 2 or x >= COLS - 2 or y < 2 or y >= ROWS - 2
			var is_forced := forced.has(c)
			if _reserved.has(c) and not is_forced:
				continue
			var p := 0.04
			if border:
				p = 0.9
			elif x >= 48:
				p = 0.10
			elif x >= 34:
				p = 0.17
			if is_forced:
				p = 1.0
			if _rng.randf() < p:
				var pos := tile_pos(x, y) + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-6, 6))
				_trees.append(pos)
				_tree_scale.append(_rng.randf_range(0.85, 1.25))
				if not border:
					var body := StaticBody2D.new()
					body.collision_layer = 1
					body.position = pos + Vector2(0, 8)
					var cs := CollisionShape2D.new()
					var sh := CircleShape2D.new()
					sh.radius = 10.0
					cs.shape = sh
					body.add_child(cs)
					add_child(body)
	# the hollow tree that hides the axe
	_add_block(Rect2(tile_pos(41, 6).x - 26, tile_pos(41, 6).y - 24, 52, 36), 1)

func _build_flowers() -> void:
	for i in 160:
		var x := _rng.randi_range(2, 29)
		var y := _rng.randi_range(2, 33)
		if not _reserved.has(Vector2i(x, y)) or (x >= 22 and x < 30):
			_flowers.append(Vector3(x * TILE + _rng.randf_range(2, 30), y * TILE + _rng.randf_range(2, 30), _rng.randi_range(0, 3)))

# -------------------------------------------------------------- night ambush

func _process(delta: float) -> void:
	if hero == null or ambush_spawned:
		return
	var hx := hero.global_position.x
	var in_zone := hx > 35 * TILE and hx < 46 * TILE
	if daynight.is_night and in_zone and hero.running and hero.state != Hero.State.SCRIPTED:
		_amb_timer += delta
		if _amb_timer > 1.5:
			_spawn_wolves()
	else:
		_amb_timer = 0.0

func _spawn_wolves() -> void:
	ambush_spawned = true
	var base: Vector2 = hero.global_position
	for i in 3:
		var wv := Werewolf.new()
		wv.target = hero
		wv.position = base + Vector2(220 + i * 40, (i - 1) * 90)
		wv.gone.connect(_on_wolf_gone)
		add_child(wv)
		wolves.append(wv)
	var first := wolves[0]
	var b := Bubble.new()
	b.rise = 40
	first.add_child(b)
	b.say("AWOOOOO!", 2.2)
	message.emit("Werewolves! They hate daylight. Switch to DAY (F)!")

func _on_time_changed(is_night: bool) -> void:
	if not is_night:
		for w in wolves:
			if is_instance_valid(w):
				w.burn()

func _on_wolf_gone(w: Werewolf) -> void:
	wolves.erase(w)
	if ambush_spawned and wolves.is_empty():
		ambush_done = true
		ambush_cleared.emit()

# ------------------------------------------------------------------- drawing

func _hash(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)

func _draw() -> void:
	# ground
	for y in ROWS:
		for x in COLS:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			var hsh := _hash(x, y)
			var base := Color(0.36, 0.62, 0.30)
			if x >= 34:
				base = Color(0.24, 0.48, 0.24)
			draw_rect(r, base.darkened(hsh * 0.14))
			if hsh > 0.82:   # grass tufts
				draw_line(r.position + Vector2(8, 22), r.position + Vector2(10, 14), base.darkened(0.3), 1.5)
				draw_line(r.position + Vector2(13, 22), r.position + Vector2(13, 13), base.darkened(0.3), 1.5)
	# the road
	for x in range(1, COLS - 1):
		if x >= 30 and x < 34:
			continue
		for y in range(PATH_ROWS.x + 1, PATH_ROWS.y):
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(0.76, 0.64, 0.44).darkened(_hash(x, y) * 0.1))
	# village plaza
	for x in range(5, 14):
		for y in range(13, 24):
			if Vector2(x - 9.0, y - 18.0).length() < 4.6:
				draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(0.74, 0.7, 0.62).darkened(_hash(x, y) * 0.08))
	# shrine flagstones
	for x in range(52, 61):
		for y in range(13, 22):
			if Vector2(x - 56.0, y - 17.0).length() < 4.2:
				draw_rect(Rect2(x * TILE + 1, y * TILE + 1, TILE - 2, TILE - 2), Color(0.6, 0.6, 0.66).darkened(_hash(x, y) * 0.1))
	# flowers
	for f in _flowers:
		var cols := [Color(1, 0.4, 0.5), Color(1, 0.9, 0.4), Color(0.8, 0.5, 1.0), Color(1, 1, 1)]
		draw_circle(Vector2(f.x, f.y), 2.2, cols[int(f.z)])
	# key garden bed
	draw_rect(Rect2(15 * TILE, 27 * TILE, 5 * TILE, 4 * TILE), Color(0.45, 0.32, 0.2))
	for i in 12:
		draw_circle(Vector2(15 * TILE + 12 + (i % 6) * 24, 27 * TILE + 20 + (i / 6) * 40), 4, Color(0.3, 0.6, 0.3))
	# fence posts
	for y in range(2, 34):
		if y >= 17 and y <= 19:
			continue
		var p := Vector2(22 * TILE + 16, y * TILE + 16)
		draw_rect(Rect2(p.x - 3, p.y - 14, 6, 30), Color(0.55, 0.38, 0.2))
		draw_line(p + Vector2(-16, -6), p + Vector2(16, -6), Color(0.62, 0.44, 0.24), 3.0)
		draw_line(p + Vector2(-16, 6), p + Vector2(16, 6), Color(0.62, 0.44, 0.24), 3.0)
	# houses
	var roofs := [Color(0.75, 0.3, 0.25), Color(0.3, 0.45, 0.7), Color(0.6, 0.35, 0.2), Color(0.7, 0.5, 0.2), Color(0.45, 0.3, 0.55)]
	for i in HOUSES.size():
		var r := HOUSES[i]
		var rect := Rect2(r.position.x * TILE, r.position.y * TILE, r.size.x * TILE, r.size.y * TILE)
		draw_rect(Rect2(rect.position.x, rect.position.y + 24, rect.size.x, rect.size.y - 24), Color(0.92, 0.86, 0.72))
		draw_colored_polygon(PackedVector2Array([rect.position + Vector2(-8, 36), rect.position + Vector2(rect.size.x + 8, 36), rect.position + Vector2(rect.size.x - 14, -4), rect.position + Vector2(14, -4)]), roofs[i])
		draw_rect(Rect2(rect.position.x + rect.size.x * 0.5 - 8, rect.end.y - 28, 16, 28), Color(0.4, 0.25, 0.15))
		draw_rect(Rect2(rect.position.x + 14, rect.position.y + 50, 14, 14), Color(1.0, 0.9, 0.5))
		draw_rect(Rect2(rect.end.x - 28, rect.position.y + 50, 14, 14), Color(1.0, 0.9, 0.5))
	# well + market stall decor
	var well := tile_pos(5, 12)
	draw_circle(well, 16, Color(0.55, 0.55, 0.6))
	draw_circle(well, 10, Color(0.15, 0.3, 0.5))
	draw_rect(Rect2(tile_pos(14, 11).x - 22, tile_pos(14, 11).y - 18, 44, 14), Color(0.85, 0.3, 0.3))
	draw_rect(Rect2(tile_pos(14, 11).x - 20, tile_pos(14, 11).y - 4, 40, 8), Color(0.6, 0.42, 0.25))
	# exit arch
	var e := exit_pos
	draw_rect(Rect2(e + Vector2(-16, -12), Vector2(32, 30)), Color(0.12, 0.3, 0.2))
	draw_circle(e + Vector2(0, -12), 16.0, Color(0.12, 0.3, 0.2))
	draw_circle(e + Vector2(0, -12), 11.0, Color(0.5, 1.0, 0.7))
	draw_rect(Rect2(e + Vector2(-11, -12), Vector2(22, 30)), Color(0.5, 1.0, 0.7))
	draw_string(ThemeDB.fallback_font, e + Vector2(-30, 36), "QUEST EXIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 1.0, 0.85))
	# trees, sorted by y so they overlap naturally
	var order: Array[int] = []
	for i in _trees.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return _trees[a].y < _trees[b].y)
	for i in order:
		_draw_tree(_trees[i], _tree_scale[i])
	_draw_hollow_tree(tile_pos(41, 6))

func _draw_tree(p: Vector2, s: float) -> void:
	DrawUtil.ellipse(self, p + Vector2(0, 14), 16 * s, 6 * s, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p.x - 4 * s, p.y - 2 * s, 8 * s, 18 * s), Color(0.4, 0.27, 0.15))
	var dark := Color(0.14, 0.38, 0.2)
	var mid := Color(0.2, 0.5, 0.26)
	draw_circle(p + Vector2(0, -10 * s), 17 * s, dark)
	draw_circle(p + Vector2(-9 * s, -2 * s), 12 * s, dark)
	draw_circle(p + Vector2(9 * s, -2 * s), 12 * s, dark)
	draw_circle(p + Vector2(-3 * s, -14 * s), 11 * s, mid)
	draw_circle(p + Vector2(7 * s, -9 * s), 8 * s, mid)

func _draw_hollow_tree(p: Vector2) -> void:
	DrawUtil.ellipse(self, p + Vector2(0, 22), 36, 10, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(p.x - 26, p.y - 24, 52, 52), Color(0.42, 0.28, 0.16))
	draw_circle(p + Vector2(0, -34), 40, Color(0.14, 0.38, 0.2))
	draw_circle(p + Vector2(-26, -20), 24, Color(0.14, 0.38, 0.2))
	draw_circle(p + Vector2(26, -20), 24, Color(0.14, 0.38, 0.2))
	DrawUtil.ellipse(self, p + Vector2(0, 12), 16, 18, Color(0.05, 0.03, 0.04))   # the dark hollow
