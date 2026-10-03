class_name Hero
extends CharacterBody2D
## The Chosen One: an autonomous, easily distracted, hopelessly incompetent hero.
##
## He is NOT scripted and NOT controlled by the player. He wanders to random
## spots, grabs random junk, messes with random props (each ends in a blunder),
## and only eventually remembers the quest. The player is an imaginary guide who
## can only influence him indirectly:
##   * he is drawn to anything lit by the lantern or a lamppost ("Ooh, shiny!")
##   * the guide POINTS at items/obstacles; he sometimes listens, often ignores
##   * day/night: night surfaces the river's stepping stones, day burns werewolves
## Quest chain: gate (needs KEY) -> river (needs NIGHT) -> log (needs AXE) -> lamp -> exit.
## He uses whatever he is holding on the problem in front of him, so he usually
## tries the wrong item first and fails.

signal milestone(id: String)

enum State { IDLE, WALK, ACT, LOOK, WAIT, FALL, RECOVER, DONE, SCRIPTED, STUN, PANIC }

const SPEED := 85.0
const PANIC_SPEED := 78.0
const QUEST_TIMEOUT := 70.0
const POINT_COOLDOWN := 2.5

const FAIL_LINES := {
	"fish": ["Behold: the Master Fish!", "SPLAT! ...The %s is unimpressed."],
	"bucket": ["Water opens all doors!", "SPLOOSH! ...I am now the wet one."],
	"hammer": ["Hammer time!", "The hammer head flew off and hit me."],
	"broom": ["Open sesame, magic broom!", "It is just a broom. A sad broom."],
	"pan": ["CLANG goes the frying pan!", "BONK! It bounced off the %s... into my face."],
	"key": ["Aha, a key! ...to what?", "It doesn't even have a keyhole!"],
	"axe": ["Time to chop!", "The axe is stuck! And so is my pride."],
	"": ["Bare hands never fail!", "OW! My hands. My poor, expensive hands."],
}

var room: OpenWorld
var light: LightController
var daynight: DayNight
var state := State.IDLE
var mood := "normal"   # normal happy panic confused smug dizzy sad
var falls := 0
var bubble: Bubble
var running := false
var carrying_lantern := false   # only used by the ending recap
var pointing := false           # only used by the ending recap
var rng := RandomNumberGenerator.new()
var visited := {}       # id -> true, distractions already "done"
var task := {}          # current task
var held := ""          # kind of item in his hand ("" = nothing)
var held_item: Item
var guide: Node2D                  # the imaginary guide (the player); only used for the log
var guide_log: Array[Dictionary] = []   # everything he says TO the guide, replayed by the ending

var _region := 0
var _done_here := 0
var _want_here := 2
var _region_time := 0.0
var _quest_unlocked := false
var _t := 0.0
var _stage := 0
var _target := Vector2.ZERO
var _best_dist := INF
var _stuck_t := 0.0
var _swing := 0.0
var _anim := 0.0
var _facing := 1.0
var _fall_spin := 0.0
var _point_cd := 0.0
var _inv := 0.0
var _use_ok := false
var _pois := {}
var _quest := {}

func _ready() -> void:
	rng.randomize()
	bubble = Bubble.new()
	bubble.rise = 54
	add_child(bubble)
	var t := room.tile_pos
	_pois = {
		0: [
			{"kind": "barrel", "id": "barrel", "pos": t.call(7, 24)},
			{"kind": "sign", "id": "sign", "pos": t.call(12, 15)},
			{"kind": "statue", "id": "statue", "pos": t.call(9, 16)},
		],
		1: [
			{"kind": "chest", "id": "chest", "pos": t.call(26, 13)},
			{"kind": "slime", "id": "slime", "pos": t.call(26, 22)},
		],
		2: [],
		3: [],
	}
	for it in room.items:
		if it.kind in ["fish", "bucket", "hammer", "broom", "pan"]:
			_pois[it.region].append({"kind": "grab", "id": "grab_" + it.kind, "pos": it.global_position, "item": it})
	_quest = {
		0: {"kind": "obstacle", "id": "q0", "obs": room.gate, "pos": t.call(21, 18)},
		1: {"kind": "river", "id": "q1", "pos": t.call(29, 18)},
		2: {"kind": "obstacle", "id": "q2", "obs": room.log_obstacle, "pos": t.call(45, 18)},
		3: {"kind": "lamp", "id": "q3", "pos": t.call(56, 17)},
	}
	_want_here = rng.randi_range(2, 3)

# ------------------------------------------------------------------ public

func begin() -> void:
	running = true
	state = State.IDLE
	_t = 0.0
	_stage = 0

func say(line: String, seconds := 2.6) -> void:
	bubble.say(line, seconds)

## A line spoken to the guide. It is also recorded (with where he stood and where
## the guide was), so the ending can replay it word for word to an empty spot.
func say_guide(line: String, seconds := 2.6, kind := "talk") -> void:
	bubble.say(line, seconds)
	guide_log.append({
		"text": line, "kind": kind, "region": _region, "pos": global_position,
		"guide_pos": guide.global_position if guide != null else Vector2.ZERO,
	})

func swing() -> void:
	_swing = 0.4

func face(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_facing = signf(point.x - global_position.x)

## Slapstick: topple over for a moment, then get back up.
func pratfall(seconds := 1.2) -> void:
	mood = "dizzy"
	var tw := create_tween()
	tw.tween_property(self, "rotation", -PI * 0.5 * _facing, 0.15)
	tw.tween_interval(seconds)
	tw.tween_property(self, "rotation", 0.0, 0.25)

## Ending recap helpers: move/act without the state machine.
func walk_to_async(dest: Vector2, speed := SPEED) -> void:
	state = State.SCRIPTED
	running = true
	collision_mask = 0
	while global_position.distance_to(dest) > 2.0:
		var step := speed * get_process_delta_time()
		face(dest)
		global_position = global_position.move_toward(dest, step)
		await get_tree().process_frame
	global_position = dest

func hold(kind: String) -> void:
	held = kind

## Debug only: jump the hero to the start of a region (see MANUAL_TEST.md).
func debug_warp(region: int) -> void:
	var spots := {0: room.tile_pos(18, 18), 1: room.tile_pos(26, 18), 2: room.tile_pos(40, 18), 3: room.tile_pos(50, 18)}
	global_position = spots[region]
	rotation = 0.0
	scale = Vector2.ONE
	_region = region
	_new_region(0)
	_start_task(_quest[region])

## The guide points at something. He sometimes listens and often ignores it.
func hear_point(target: Node2D) -> void:
	if not running or _point_cd > 0.0:
		return
	if not state in [State.WALK, State.LOOK, State.WAIT, State.ACT]:
		return
	_point_cd = POINT_COOLDOWN
	face(target.global_position)
	if room.region_at(target.global_position) != _region:
		say_guide("That's... way over there. Later!", 2.0, "point")
		return
	if state == State.ACT:
		say_guide("One sec, guide! I'm mid-blunder!", 1.8, "point")
		return
	if rng.randf() < 0.65:
		mood = "happy"
		if target is Item:
			var it := target as Item
			if not it.available():
				return
			var lines := ["Ah! THAT thing! Good eye, guide!", "Right, right! I was just about to!", "Fine, fine! Fetching!"]
			say_guide(lines[rng.randi() % lines.size()], 2.0, "point")
			_start_task({"kind": "fetch", "id": "fetch", "pos": it.global_position, "item": it})
		elif target is Obstacle:
			if (target as Obstacle).solved:
				return
			say_guide("Yes yes, the obstacle! My next move exactly!", 2.0, "point")
			_start_task(_quest[_region])
		return
	var ignore := ["Not now, I'm busy!", "I KNOW what I'm doing!", "Shh! Hero thinking.", "Who asked you?", "(pretends not to hear)"]
	say_guide(ignore[rng.randi() % ignore.size()], 2.0, "point")
	mood = "confused"
	if state in [State.WALK, State.LOOK] and rng.randf() < 0.5:
		_start_task({"kind": "wander", "id": "wander", "pos": _random_spot()})   # spite

func get_mauled(_w: Node) -> void:
	if _inv > 0.0 or state in [State.STUN, State.FALL, State.RECOVER, State.SCRIPTED, State.DONE]:
		return
	state = State.STUN
	_t = 0.0
	_inv = 4.0
	velocity = Vector2.ZERO
	say("AAAAH! DOGGY! BIG DOGGY!", 2.0)
	pratfall(1.4)
	milestone.emit("mauled")

# ------------------------------------------------------------ decision making

func _random_spot() -> Vector2:
	var list: Array = OpenWorld.SPOTS[_region]
	var c: Vector2i = list[rng.randi() % list.size()]
	return room.tile_pos(c.x, c.y)

func _quest_ready() -> bool:
	return _quest_unlocked or _done_here >= _want_here or _region_time >= QUEST_TIMEOUT

## Choose what to do next. Pure apart from the RNG, so it can be tested.
func pick_next() -> Dictionary:
	var q: Dictionary = _quest[_region]
	if _region == 3 or _region_time >= QUEST_TIMEOUT or _quest_unlocked:
		return q
	var options: Array[Dictionary] = []
	for poi: Dictionary in _pois[_region]:
		if visited.has(poi.id):
			continue
		if poi.kind == "grab":
			var it: Item = poi.item
			if not it.available() or not it.is_revealed():
				continue
		options.append(poi)
	if (_region != 0 and _region != 1) or options.is_empty() or rng.randf() < 0.3:
		if OpenWorld.SPOTS[_region].size() > 0:
			options.append({"kind": "wander", "id": "wander", "pos": _random_spot()})
	if _quest_ready():
		options.append(q)
		options.append(q)
	if options.is_empty():
		return q
	# Light guidance: he is drawn to whatever light is shining on.
	if light != null:
		var lit: Array[Dictionary] = []
		for o in options:
			if light.is_lit(o.pos):
				lit.append(o)
		if not lit.is_empty() and rng.randf() < 0.85:
			return lit[rng.randi() % lit.size()]
	return options[rng.randi() % options.size()]

func _choose_next() -> void:
	var o := pick_next()
	if not o.kind in ["wander", "obstacle", "river", "lamp"] and light != null and light.is_lit(o.pos):
		say("Ooh, shiny!", 1.4)
		mood = "happy"
	_start_task(o)

func _start_task(t: Dictionary) -> void:
	task = t
	_target = t.pos
	state = State.WALK
	_t = 0.0
	_stage = 0
	_stuck_t = 0.0
	_best_dist = INF
	pointing = false
	if mood != "happy":
		mood = "normal"

func _task_done() -> void:
	if task.kind in ["barrel", "sign", "statue", "chest", "slime", "grab"]:
		visited[task.id] = true
		_done_here += 1
	if task.kind == "lamp":
		_start_task({"kind": "exit", "id": "exit", "pos": room.exit_pos})
		return
	_choose_next()

func _take(item: Item) -> void:
	if held_item != null and held != "":
		held_item.drop_at(global_position + Vector2(_facing * 18.0, 14.0))   # dropped on the ground
	item.take()
	held_item = item
	held = item.kind

func _consume_held() -> void:
	if held_item != null:
		held_item.broken = true
		held_item.take()
	held_item = null
	held = ""

# ------------------------------------------------------------ state machine

func _physics_process(delta: float) -> void:
	_anim += delta
	_swing = maxf(_swing - delta, 0.0)
	_point_cd = maxf(_point_cd - delta, 0.0)
	_inv = maxf(_inv - delta, 0.0)
	if running:
		if state != State.IDLE and state != State.SCRIPTED:
			_region_time += delta
		if room.wolves_active() and not state in [State.PANIC, State.STUN, State.FALL, State.RECOVER, State.SCRIPTED, State.DONE]:
			state = State.PANIC
			mood = "panic"
			say("WOLVES! BIG DOGGY WOLVES!", 2.0)
		match state:
			State.IDLE: _do_idle(delta)
			State.WALK: _do_walk(delta)
			State.ACT: _do_act(delta)
			State.LOOK: _do_look(delta)
			State.WAIT: _do_wait(delta)
			State.FALL: _do_fall(delta)
			State.RECOVER: _do_recover(delta)
			State.STUN: _do_stun(delta)
			State.PANIC: _do_panic(delta)
	queue_redraw()

## true exactly once, when _t passes `time` and earlier beats have fired
func _beat(stage: int, time: float) -> bool:
	if _stage == stage and _t >= time:
		_stage += 1
		return true
	return false

func _do_idle(delta: float) -> void:
	_t += delta
	if _beat(0, 0.3):
		mood = "happy"
		say("Behold! The Chosen One has arrived!", 2.4)
	if _beat(1, 2.6):
		say_guide("Where to, guide? ...Ignore that, I decide!", 2.4)
	if _beat(2, 5.0):
		_choose_next()

func _do_walk(delta: float) -> void:
	var to := _target - global_position
	if to.length() <= 3.0:
		_arrive()
		return
	var dir := to.normalized()
	velocity = dir * SPEED
	face(_target)
	move_and_slide()
	if room.river.in_water(global_position) and not room.river.is_solid_at(global_position):
		_start_fall()
		return
	# Failsafe: if we made no progress toward the goal for 1.2s (stuck on a
	# tree), pop straight to the goal so the run can never soft-lock.
	_stuck_t += delta
	if _stuck_t >= 1.2:
		var d := global_position.distance_to(_target)
		if d > _best_dist - 6.0:
			global_position = _target
		_best_dist = minf(_best_dist, d)
		_stuck_t = 0.0

func _arrive() -> void:
	velocity = Vector2.ZERO
	_t = 0.0
	_stage = 0
	match task.kind:
		"wander":
			state = State.LOOK
		"barrel", "slime", "sign", "statue", "chest", "lamp":
			state = State.ACT
		"grab":
			var it: Item = task.item
			if it.available():
				_take(it)
				mood = "happy"
				say("Ooh, a %s! Surely useful!" % it.kind, 2.0)
				milestone.emit("grab")
			_task_done_after_grab()
		"fetch":
			var it2: Item = task.item
			if it2.available():
				_take(it2)
				mood = "smug"
				say_guide("Got the %s! Obviously my idea." % it2.kind, 2.2)
				milestone.emit("fetched_" + it2.kind)
			var q: Dictionary = _quest[_region]
			if q.kind == "obstacle" and held == (q.obs as Obstacle).need and not (q.obs as Obstacle).solved:
				_start_task(q)
			else:
				_choose_next()
		"obstacle":
			state = State.ACT
			_quest_unlocked = true
			milestone.emit("at_" + (task.obs as Obstacle).kind)
		"river":
			state = State.WAIT
			_quest_unlocked = true
			milestone.emit("at_river")
		"cross":
			_region = 2
			_new_region(1)
			milestone.emit("crossed")
			_choose_next()
		"pass":
			_region = task.to
			_new_region(1 if _region != 3 else 0)
			_choose_next()
		"exit":
			state = State.DONE
			mood = "happy"
			say_guide("Quest complete! Couldn't have done it without you, guide!", 3.4)
			milestone.emit("finished")

func _new_region(want: int) -> void:
	_done_here = 0
	_want_here = want
	_region_time = 0.0
	_quest_unlocked = false

func _task_done_after_grab() -> void:
	visited[task.id] = true
	_done_here += 1
	if _quest_unlocked:
		_start_task(_quest[_region])
	else:
		_choose_next()

func _do_look(delta: float) -> void:
	_t += delta
	if _beat(0, 0.3):
		mood = "confused"
		var lines := ["Hmm. Nothing here.", "Was I supposed to be somewhere?", "Right? ...Right.", "You see it too, don't you, guide?", "Nice spot. Very... grass."]
		var l: String = lines[rng.randi() % lines.size()]
		if l in ["Right? ...Right.", "You see it too, don't you, guide?"]:
			say_guide(l, 2.0)
		else:
			say(l, 2.0)
	if _beat(1, 2.2):
		_choose_next()

func _do_act(delta: float) -> void:
	_t += delta
	match task.kind:
		"barrel":
			if _beat(0, 0.2):
				mood = "happy"
				say("A barrel! Surely full of gold!", 2.0)
			if _beat(1, 2.0):
				swing()
				room.barrel.smash()
			if _beat(2, 2.3):
				say("OW! A plank! Barrel started it!", 2.0)
				pratfall(1.4)
				milestone.emit("barrel")
			if _beat(3, 4.0):
				mood = "sad"
				say("...No gold. Terrible loot.", 2.0)
			if _beat(4, 5.6):
				_task_done()
		"slime":
			if _beat(0, 0.2):
				mood = "happy"
				say("A MONSTER! Have at thee, blob!", 2.0)
			if _beat(1, 2.0):
				swing()
				say("Hold still!", 1.0)
			if _beat(2, 3.0):
				swing()
				say("Coward! Fight me!", 1.2)
			if _beat(3, 4.0):
				swing()
				say("It is dodging with its WHOLE BODY!", 1.8)
			if _beat(4, 5.4):
				room.slime.boing()
				pratfall(1.4)
				say("...Slime wins the round.", 2.0)
				milestone.emit("slime")
			if _beat(5, 7.6):
				_task_done()
		"sign":
			if _beat(0, 0.2):
				mood = "smug"
				say("A sign! \"WET FLOOR\". Pfft. I'm not scared of water.", 2.4)
			if _beat(1, 2.6):
				room.signpost.splash()
				pratfall(1.4)
				say("WHOA-!", 1.0)
				milestone.emit("sign")
			if _beat(2, 4.4):
				mood = "sad"
				say("The floor started it.", 2.0)
			if _beat(3, 6.0):
				_task_done()
		"statue":
			if _beat(0, 0.2):
				mood = "happy"
				say("A fellow hero! Up top, buddy!", 2.0)
			if _beat(1, 2.0):
				swing()
				room.statue.drop_sword()
			if _beat(2, 2.4):
				say("OW! Rude! His sword fell on me!", 2.0)
				pratfall(1.4)
				milestone.emit("statue")
			if _beat(3, 4.4):
				mood = "sad"
				say("Statues have no respect.", 2.0)
			if _beat(4, 6.0):
				_task_done()
		"chest":
			if _beat(0, 0.2):
				mood = "happy"
				say("A CHEST! Finally, real gold!", 2.0)
			if _beat(1, 2.0):
				room.chest.open_lid()
			if _beat(2, 3.0):
				room.chest.slam()
				pratfall(1.4)
				say("IT BIT ME!", 1.4)
				milestone.emit("chest")
			if _beat(3, 5.0):
				mood = "sad"
				say("...It was empty anyway.", 2.0)
			if _beat(4, 6.6):
				_task_done()
		"lamp":
			if _beat(0, 0.2):
				mood = "happy"
				say("The Sacred Lamp! Plaque says \"mind your feet.\"", 2.4)
			if _beat(1, 2.6):
				room.pedestal.take_lamp()
				mood = "smug"
				say("Got it! Easy! ...Heavier than it looks.", 2.0)
			if _beat(2, 4.8):
				say("OWWW! MY FOOT!", 1.6)
				pratfall(1.4)
				milestone.emit("lamp")
			if _beat(3, 6.8):
				mood = "smug"
				say("Quest item acquired. Flawlessly.", 2.2)
			if _beat(4, 8.8):
				_task_done()
		"obstacle":
			_do_obstacle()

## Use whatever he is holding on the obstacle. Right item: success. Else: slapstick.
func _do_obstacle() -> void:
	var obs: Obstacle = task.obs
	if _beat(0, 0.2):
		_use_ok = held == obs.need
		mood = "happy"
		var held_name := held if held != "" else "my bare hands"
		say("Leave this to me! I'll use the %s!" % held_name, 2.0)
	if _use_ok:
		if _beat(1, 2.2):
			swing()
			obs.solve()
			_consume_held()
			milestone.emit("unlocked_" + obs.kind)
		if _beat(2, 3.2):
			mood = "happy"
			say_guide("YES! High five, guide!", 2.0)
		if _beat(3, 5.0):
			mood = "smug"
			say("Ha! Planned that all along. Obviously.", 2.4)
		if _beat(4, 7.0):
			if obs.kind == "gate":
				_start_task({"kind": "pass", "id": "pass", "pos": room.tile_pos(24, 18), "to": 1})
			else:
				_start_task({"kind": "pass", "id": "pass", "pos": room.tile_pos(49, 18), "to": 3})
	else:
		var lines: Array = FAIL_LINES.get(held, FAIL_LINES[""])
		if _beat(1, 2.2):
			say(lines[0], 1.8)
		if _beat(2, 3.6):
			swing()
			var l2: String = lines[1]
			say(l2 % obs.kind if "%s" in l2 else l2, 2.2)
			pratfall(1.6)
			if held_item != null:
				_consume_held()
			milestone.emit("fail")
		if _beat(3, 6.0):
			mood = "confused"
			say_guide("Hm. Guide? ...Any ideas?", 2.0)
			state = State.WAIT
			_t = 0.0
			_stage = 0

func _do_wait(delta: float) -> void:
	_t += delta
	match task.kind:
		"obstacle":
			var obs: Obstacle = task.obs
			if obs.solved:
				return
			if _beat(0, 2.0):
				mood = "confused"
				say_guide("It's stuck. Guide? ...Guide?", 2.4)
			if _beat(1, 5.0):
				swing()
				mood = "dizzy"
				say("BONK! ...Maybe it's a pull door.", 2.2)
			if _beat(2, 9.0):
				# sometimes he decides to try ANOTHER random item himself
				var junk := _available_junk()
				if junk != null and rng.randf() < 0.7:
					mood = "happy"
					say("Ooh! Maybe THAT opens it!", 2.0)
					_start_task({"kind": "grab", "id": "grab_" + junk.kind, "pos": junk.global_position, "item": junk})
				else:
					_t = 2.0
					_stage = 1   # loop the bonking until the guide helps
		"river":
			if daynight.is_night:
				mood = "happy"
				say_guide("Stepping stones! I knew they'd appear!", 2.0)
				_start_task({"kind": "cross", "id": "cross", "pos": room.tile_pos(35, 18)})
				return
			if _beat(0, 1.5):
				mood = "confused"
				say("A river. No bridge. Rude.", 2.4)
			if _beat(1, 4.5):
				say_guide("Maybe if I wish hard enough, guide...", 2.4)
			if _beat(2, 7.5):
				mood = "happy"
				say_guide("Watch this, guide! I can walk on water!", 2.0)
			if _beat(3, 9.0):
				_start_task({"kind": "cross", "id": "cross", "pos": room.tile_pos(35, 18)})   # gravity wins

func _available_junk() -> Item:
	for poi: Dictionary in _pois[_region]:
		if poi.kind == "grab" and not visited.has(poi.id):
			var it: Item = poi.item
			if it.available() and it.is_revealed():
				return it
	return null

func _start_fall() -> void:
	state = State.FALL
	_t = 0.0
	_fall_spin = 0.0
	falls += 1
	mood = "panic"
	velocity = Vector2.ZERO
	say("SPLASH-WAAAAH!", 1.4)
	milestone.emit("fell")

func _do_fall(delta: float) -> void:
	_t += delta
	_fall_spin += delta * 14.0
	rotation = _fall_spin
	scale = Vector2.ONE * lerpf(1.0, 0.05, clampf(_t / 0.9, 0.0, 1.0))
	if _t >= 1.1:
		state = State.RECOVER
		_t = 0.0
		rotation = 0.0
		scale = Vector2.ONE
		global_position = room.tile_pos(29, 18)   # fished out at the west bank
		mood = "dizzy"
		var lines := ["Blub. Ow.", "Blub. Again?!", "I meant to do that."]
		say(lines[mini(falls - 1, lines.size() - 1)], 2.2)

func _do_recover(delta: float) -> void:
	_t += delta
	if _t >= 2.4:
		_region = 1
		task = _quest[1]
		state = State.WAIT
		_t = 0.0
		_stage = 0
		mood = "confused"
		milestone.emit("at_river")

func _do_stun(delta: float) -> void:
	_t += delta
	if _t >= 1.2 and _t < 1.3:
		global_position = room.tile_pos(36, 18)   # flung back to the near bank
		_t = 1.3
	if _t >= 2.4:
		mood = "confused"
		state = State.WALK
		_start_task(task if not task.is_empty() else _quest[_region])

func _do_panic(delta: float) -> void:
	var nearest: Node2D = null
	var best := INF
	for w in room.wolves:
		if is_instance_valid(w) and not w.burning:
			var d := global_position.distance_to(w.global_position)
			if d < best:
				best = d
				nearest = w
	if nearest == null:
		mood = "smug"
		say("Ha! Burned 'em with my glare!", 2.4)
		milestone.emit("wolves")
		_choose_next()
		return
	var flee := (global_position - nearest.global_position).normalized()
	flee = flee.rotated(sin(_anim * 3.0) * 0.6)   # panicked zig-zag
	velocity = flee * PANIC_SPEED
	face(global_position + flee * 10.0)
	move_and_slide()
	if global_position.x < 35 * OpenWorld.TILE or global_position.x > 46 * OpenWorld.TILE:
		global_position.x = clampf(global_position.x, 35 * OpenWorld.TILE, 46 * OpenWorld.TILE)

# ----------------------------------------------------------------- drawing

func _draw() -> void:
	var walking := state == State.WALK or state == State.SCRIPTED
	var bob := sin(_anim * 10.0) * 1.5 if walking else sin(_anim * 3.0) * 0.8
	var cape := Color(0.85, 0.15, 0.2)
	var tunic := Color(0.2, 0.45, 0.85)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.ellipse(self, Vector2(0, 5), 13, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(_facing, 1.0))
	# cape, legs, body
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -26), Vector2(8, -26), Vector2(15, 1), Vector2(-15, 1)]), cape)
	var lw := sin(_anim * 10.0) * 3.0 if walking else 0.0
	draw_rect(Rect2(-7, -6, 5, 10 + lw * 0.3), Color(0.4, 0.25, 0.15))
	draw_rect(Rect2(2, -6, 5, 10 - lw * 0.3), Color(0.4, 0.25, 0.15))
	draw_rect(Rect2(-9, -27, 18, 22), tunic)
	draw_rect(Rect2(-9, -13, 18, 4), Color(1.0, 0.8, 0.25))
	# head, helmet, plume
	draw_circle(Vector2(0, -35), 11.0, Color(1.0, 0.8, 0.65))
	var helm := PackedVector2Array()
	for k in 11:
		var a := PI + PI * k / 10.0
		helm.append(Vector2(0, -36) + Vector2(cos(a), sin(a)) * 12.0)
	draw_colored_polygon(helm, Color(0.95, 0.8, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -47), Vector2(3, -47), Vector2(10, -56), Vector2(0, -52)]), Color(0.9, 0.2, 0.25))
	_draw_face()
	# sword
	var ang := -0.6
	if _swing > 0.0:
		ang = lerpf(-2.0, 1.2, 1.0 - _swing / 0.4)
	var hand := Vector2(10, -17)
	var tip := hand + Vector2.from_angle(ang) * 24.0
	draw_line(hand, tip, Color(0.85, 0.9, 0.95), 3.0)
	draw_line(hand + Vector2.from_angle(ang + PI * 0.5) * 4.0, hand + Vector2.from_angle(ang - PI * 0.5) * 4.0, Color(1, 0.8, 0.3), 3.0)
	draw_circle(hand, 3.0, Color(1.0, 0.8, 0.65))
	if held != "":
		draw_set_transform(Vector2(0, bob) + hand * Vector2(_facing, 1.0), 0.0, Vector2(_facing, 1.0))
		Item.draw_icon(self, held, 0.8, 1.0)
		draw_set_transform(Vector2(0, bob), 0.0, Vector2(_facing, 1.0))
	if pointing:   # an arm raised towards "the guide"
		draw_line(hand, hand + Vector2(14, -14), Color(1.0, 0.8, 0.65), 4.0)
		draw_circle(hand + Vector2(14, -14), 3.0, Color(1.0, 0.8, 0.65))
	if carrying_lantern:   # ending recap: he lights things himself
		DrawUtil.glow(self, Vector2(-14, -22), LightController.LANTERN_RADIUS, Color(1.0, 0.9, 0.5, 0.22), 8)
		draw_line(Vector2(-9, -16), Vector2(-14, -22), Color(0.5, 0.35, 0.2), 2.0)
		draw_rect(Rect2(-17, -29, 7, 8), Color(1.0, 0.9, 0.45))
		draw_rect(Rect2(-17, -29, 7, 8), Color(0.3, 0.2, 0.1), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mood == "dizzy":
		for k in 3:
			var a := _anim * 6.0 + k * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -54 + sin(a) * 3.0), 2.0, Color(1, 0.9, 0.2))

func _draw_face() -> void:
	var ink := Color(0.15, 0.1, 0.15)
	var eye_y := -35.0
	var eye_c := Color.WHITE
	var pupil := ink
	match mood:
		"panic":
			draw_circle(Vector2(-4.5, eye_y), 5.0, eye_c)
			draw_circle(Vector2(4.5, eye_y), 5.0, eye_c)
			draw_circle(Vector2(-4.5, eye_y), 1.2, pupil)
			draw_circle(Vector2(4.5, eye_y), 1.2, pupil)
			draw_circle(Vector2(0, -28), 3.2, ink)
		"happy":
			draw_circle(Vector2(-4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(-3.8, eye_y), 1.6, pupil)
			draw_circle(Vector2(5.2, eye_y), 1.6, pupil)
			draw_arc(Vector2(0, -31), 5.0, 0.15, PI - 0.15, 8, ink, 2.0)
		"confused":
			draw_circle(Vector2(-4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(4.5, eye_y + 1), 2.6, eye_c)
			draw_circle(Vector2(-4.0, eye_y), 1.4, pupil)
			draw_circle(Vector2(4.8, eye_y + 1), 1.2, pupil)
			draw_line(Vector2(-8, eye_y - 6), Vector2(-2, eye_y - 8), ink, 1.5)
			draw_line(Vector2(-4, -27), Vector2(0, -29), ink, 1.5)
			draw_line(Vector2(0, -29), Vector2(4, -27), ink, 1.5)
		"smug":
			draw_circle(Vector2(-4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(4.5, eye_y), 3.4, eye_c)
			draw_rect(Rect2(-8, eye_y - 3.6, 7, 3.6), Color(1.0, 0.8, 0.65))
			draw_rect(Rect2(1, eye_y - 3.6, 7, 3.6), Color(1.0, 0.8, 0.65))
			draw_circle(Vector2(-3.5, eye_y + 0.6), 1.3, pupil)
			draw_circle(Vector2(5.5, eye_y + 0.6), 1.3, pupil)
			draw_arc(Vector2(2, -30), 5.0, 0.3, 1.8, 8, ink, 2.0)
		"dizzy":
			for sx in [-4.5, 4.5]:
				draw_line(Vector2(sx - 2.5, eye_y - 2.5), Vector2(sx + 2.5, eye_y + 2.5), ink, 1.6)
				draw_line(Vector2(sx - 2.5, eye_y + 2.5), Vector2(sx + 2.5, eye_y - 2.5), ink, 1.6)
			draw_arc(Vector2(0, -26), 4.0, PI + 0.4, TAU - 0.4, 8, ink, 2.0)
		"sad":
			draw_circle(Vector2(-4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(-4.5, eye_y + 1), 1.5, pupil)
			draw_circle(Vector2(4.5, eye_y + 1), 1.5, pupil)
			draw_line(Vector2(-8, eye_y - 5), Vector2(-2, eye_y - 7), ink, 1.5)
			draw_line(Vector2(8, eye_y - 5), Vector2(2, eye_y - 7), ink, 1.5)
			draw_arc(Vector2(0, -25), 4.0, PI + 0.4, TAU - 0.4, 8, ink, 2.0)
		_:
			draw_circle(Vector2(-4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(4.5, eye_y), 3.4, eye_c)
			draw_circle(Vector2(-3.8, eye_y), 1.5, pupil)
			draw_circle(Vector2(5.2, eye_y), 1.5, pupil)
			draw_line(Vector2(-3, -28), Vector2(3, -28), ink, 1.8)
