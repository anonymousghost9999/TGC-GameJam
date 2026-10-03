class_name TwistSequence
extends Node
## The twist: the SAME events, seen by different villagers at different points of
## the journey. Everything the hero says here is a line he really said to the
## guide during the game (recorded in Hero.guide_log), at the spot where he said
## it, now facing the place where the guide was standing, which is empty.
## Only the villagers' reactions are new. No one explains it; the pattern builds.

const REACTIONS := {
	"baker": ["...Who is he talking to?", "He's asking the empty square for directions.", "Is he feeling alright?"],
	"child": ["Mum, the man is pointing at the grass.", "Who is he pointing at?", "He said 'good eye' to a bush."],
	"farmer": ["He's arguing with nobody.", "He keeps looking at that empty spot.", "Nobody's there. Nobody's ever there."],
	"woodcutter": ["He's high-fiving the air.", "That spot is empty. I checked.", "He talks to it like an old friend."],
}

# Used only if a region has no recorded lines (e.g. the guide never spoke there). All are real in-game lines.
const FALLBACK := {
	0: [{"text": "Where to, guide? ...Ignore that, I decide!", "kind": "talk", "tile": Vector2i(4, 18)},
		{"text": "Ah! THAT thing! Good eye, guide!", "kind": "point", "tile": Vector2i(13, 14)}],
	1: [{"text": "Watch this, guide! I can walk on water!", "kind": "talk", "tile": Vector2i(29, 18)}],
	2: [{"text": "YES! High five, guide!", "kind": "talk", "tile": Vector2i(45, 18)}],
	3: [{"text": "Quest complete! Couldn't have done it without you, guide!", "kind": "talk", "tile": Vector2i(57, 19)}],
}

# How far the replay camera zooms in (1.0 = the normal gameplay view). Kept low so the
# hero, the villager and the empty spot where the guide stood are all visible.
const REPLAY_ZOOM := 1.1

var _g: GameManager
var replayed: Array[String] = []   # every line the hero speaks in the ending (for tests)
var _shown := {}   # villager style -> reactions used

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _cam(pos: Vector2, zoom: float, seconds := 1.0) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_g.camera, "position", pos, seconds)
	tw.tween_property(_g.camera, "zoom", Vector2.ONE * zoom, seconds)

func _spawn(style: String) -> Villager:
	var v := Villager.new()
	v.style = style
	v.visible = false
	_g.world.add_child(v)
	return v

## Recorded lines for a region, spread out, always keeping the last one.
func _entries(region: int, max_n: int, skip := 0) -> Array[Dictionary]:
	var seen := {}
	var all: Array[Dictionary] = []
	for e: Dictionary in _g.hero.guide_log:
		if e.region == region and not seen.has(e.text):
			seen[e.text] = true
			all.append(e)
	if all.size() <= skip:
		all = []
	else:
		all = all.slice(skip)
	var out: Array[Dictionary] = []
	if all.size() <= max_n:
		out.assign(all)
	else:
		for i in max_n - 1:
			out.append(all[int(i * float(all.size() - 1) / float(max_n - 1))])
		out.append(all[all.size() - 1])
	if out.is_empty():
		for f: Dictionary in FALLBACK[region]:
			var p := _g.room.tile_pos(f.tile.x, f.tile.y)
			out.append({"text": f.text, "kind": f.kind, "pos": p, "guide_pos": Vector2.ZERO})
	return out

## A nearby spot that is not in the river, inside a house, or off the map.
func _free_spot(near: Vector2, prefer: Vector2) -> Vector2:
	var room := _g.room
	var offsets: Array[Vector2] = [prefer, Vector2(110, 55), Vector2(-110, 55), Vector2(110, -55), Vector2(-110, -55), Vector2(0, 95), Vector2(0, -95), Vector2(160, 0), Vector2(-160, 0), Vector2(60, 140), Vector2(-60, -140)]
	for o in offsets:
		var p := near + o
		if p.x < 100 or p.y < 100 or p.x > OpenWorld.COLS * OpenWorld.TILE - 100 or p.y > OpenWorld.ROWS * OpenWorld.TILE - 100:
			continue
		if room.river.water_rect.grow(24).has_point(p):
			continue
		var in_house := false
		for h: Rect2i in OpenWorld.HOUSES:
			if Rect2(h.position * OpenWorld.TILE, h.size * OpenWorld.TILE).grow(24).has_point(p):
				in_house = true
		if not in_house:
			return p
	return near + prefer

func _guide_spot(e: Dictionary) -> Vector2:
	var gp: Vector2 = e.guide_pos
	if gp == Vector2.ZERO or gp.distance_to(e.pos) < 20.0:
		return e.pos + Vector2(-70, 40)
	return gp

## Replay one recorded line for one villager. The hero's text is exactly what he said in-game.
func _replay(e: Dictionary, v: Villager, style: String, caption: String, cut: bool) -> void:
	var hero := _g.hero
	var spot := _guide_spot(e)
	if cut:
		await _g.hud.fade_to(1.0, 0.5)
		hero.global_position = e.pos
		hero.rotation = 0.0
		_g.hud.caption(caption)
	else:
		await hero.walk_to_async(e.pos, 70.0)
	var side := 1.0 if e.pos.x < spot.x else -1.0
	v.global_position = _free_spot(e.pos, Vector2(-side * 110.0, 55.0))
	v.visible = true
	_cam((e.pos * 2.0 + spot + v.global_position) / 4.0 + Vector2(0, -35), REPLAY_ZOOM, 0.01 if cut else 0.8)
	if cut:
		await _g.hud.fade_to(0.0, 0.5)
	hero.face(spot)
	hero.pointing = e.kind == "point"
	hero.mood = "happy" if e.kind == "point" else "normal"
	hero.say(e.text, 2.8)
	replayed.append(e.text)
	await _wait(3.0)
	var list: Array = REACTIONS[style]
	var n: int = _shown.get(style, 0)
	v.say(list[n % list.size()], 2.6)
	_shown[style] = n + 1
	await _wait(2.9)
	hero.pointing = false

func play(g: GameManager) -> void:
	_g = g
	var hud := g.hud
	var hero := g.hero
	var room := g.room
	var player := g.player
	hero.bubble.hush()
	player.bubble.hush()

	await hud.fade_to(1.0, 0.8)
	hud.show_overlay("[center][font_size=34]THE VILLAGERS REMEMBER...[/font_size]\n\nA few people saw the Chosen One's journey.\nNone of them saw you.[/center]")
	await _wait(3.4)
	hud.hide_overlay()

	# the guide is gone from the world; the hero is alone
	player.visible = false
	player.set_physics_process(false)
	player.active = false
	g.light.set_lantern(false)
	for l in room.lampposts:
		l.lit = false
	g.daynight.set_night(false)
	g.daynight.blend = 0.0
	room.reset_actors()
	hero.state = Hero.State.SCRIPTED
	hero.running = true
	hero.held = ""
	hero.mood = "normal"
	hud.letterbox(true, 0.1)
	g.tint.color = Color(1.0, 0.97, 0.9)
	_g.camera.zoom = Vector2.ONE * REPLAY_ZOOM

	var baker := _spawn("baker")
	var child := _spawn("child")
	var farmer := _spawn("farmer")
	var woodcutter := _spawn("woodcutter")

	# ---- 1. the baker (village, morning) and 2. the baker's son (village, later)
	var village := _entries(0, 4)
	var first_half: Array[Dictionary] = village.slice(0, maxi(1, village.size() / 2))
	var second_half: Array[Dictionary] = village.slice(first_half.size())
	if second_half.is_empty():
		second_half = [village[village.size() - 1]]
	var first := true
	for e in first_half:
		await _replay(e, baker, "baker", "THE BAKER, Monday morning", first)
		first = false
	baker.visible = false
	first = true
	for e in second_half:
		await _replay(e, child, "child", "THE BAKER'S SON, an hour later", first)
		first = false
	child.visible = false

	# ---- 3. the farmer at the river
	first = true
	for e in _entries(1, 3):
		await _replay(e, farmer, "farmer", "THE FARMER, at the river", first)
		first = false
	farmer.say("It's ankle-deep. There's a ford right there.", 2.8)
	await hero.walk_to_async(room.tile_pos(35, 18), 55.0)
	await _wait(2.4)
	farmer.visible = false

	# ---- 4. the woodcutter in the forest
	first = true
	for e in _entries(2, 3):
		await _replay(e, woodcutter, "woodcutter", "THE WOODCUTTER, deep in the forest", first)
		first = false
	woodcutter.visible = false

	# ---- 5. everyone at the shrine: the last line he ever said to the guide
	var last := _entries(3, 1)[0]
	baker.visible = true
	child.visible = true
	farmer.visible = true
	woodcutter.visible = true
	await hud.fade_to(1.0, 0.5)
	hero.global_position = room.tile_pos(57, 19)
	baker.global_position = room.tile_pos(52, 20)
	child.global_position = room.tile_pos(53, 22)
	farmer.global_position = room.tile_pos(54, 21)
	woodcutter.global_position = room.tile_pos(55, 21)
	_cam(room.tile_pos(55, 19), REPLAY_ZOOM, 0.01)
	hud.caption("THE VILLAGERS, at the shrine")
	await hud.fade_to(0.0, 0.5)
	hero.mood = "happy"
	hero.face(room.tile_pos(52, 17))
	hero.say(last.text, 3.4)
	replayed.append(last.text)
	await _wait(3.6)
	baker.say("Nobody's there.", 2.2)
	await _wait(2.2)
	child.say("I think he's lonely.", 2.4)
	await _wait(2.6)
	farmer.say("He seems to be doing fine.", 2.4)
	await _wait(2.6)
	woodcutter.say("He's the happiest man I've ever seen.", 2.8)
	await _wait(3.4)
	hud.caption("")
	hud.letterbox(false, 0.6)
	await hud.fade_to(1.0, 0.9)
	g.tint.color = Color.WHITE
	g.camera.zoom = Vector2.ONE
	queue_free()
