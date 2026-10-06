class_name Hero
extends CharacterBody2D
## The hero is AUTONOMOUS. He never takes player input. Every physics frame he
## looks for the closest ACTIVE lamp (anywhere; lamps have no radius) and obeys its
## CURRENT colour:
##   GREEN  moves toward the lamp           RED  moves away from it
##   ORANGE moves slowly toward the lamp    BLUE freezes completely
## With NO active lamp at all he wanders randomly (after a brief, visible
## moment of confusion), which is how he ends up in spikes, fire and traps.
## Comedy (reactions, dialogue) never changes this movement.

signal died(kind: String)
signal reached_exit
signal ogre_woke
signal behavior_changed(color: int)   # -1 = no influence

enum State { IDLE, ACTIVE, DEAD, WON, STORY }

const SPEED := 80.0
const ORANGE_FACTOR := 0.4
const WANDER_SPEED := 56.0
const RUN_SCALE := 1.25   # speed multiplier while an ogre is chasing him
const CONFUSE_TIME := 0.6
const ARRIVE_DIST := 6.0     # for the exit lamp: he really walks onto it
const STAND_OFF := 28.0      # for every other lamp he stops BESIDE it, so the lamp stays visible

var level: Level
var lamps: LampManager
var rng := RandomNumberGenerator.new()
var state := State.IDLE
var influence: Lamp = null
var behavior := -1            # current effective colour obeyed, -1 = none
var mood := "normal"
var death_kind := ""
var speed_now := 0.0
var bubble: Bubble
var trace: Array[Vector2] = []   # optional path recording (tests/tools)
var record_trace := false

var _anim := 0.0
var _facing := 1.0
var _confuse_t := 0.0
var _wander_dir := Vector2.ZERO
var _wander_t := 0.0
var _death_t := 0.0
var _win_t := 0.0

func _ready() -> void:
	bubble = Bubble.new()
	bubble.rise = 54
	add_child(bubble)
	rng.randomize()

func place(p: Vector2) -> void:
	global_position = p
	velocity = Vector2.ZERO
	state = State.IDLE
	death_kind = ""
	mood = "normal"
	behavior = -1
	influence = null
	_confuse_t = 0.0
	_wander_t = 0.0
	_death_t = 0.0
	_win_t = 0.0
	rotation = 0.0
	scale = Vector2.ONE
	trace.clear()

func start() -> void:
	level.ogre_idx = -1
	state = State.ACTIVE

func say(line: String, seconds := 2.6) -> void:
	bubble.say(line, seconds)

func face(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_facing = signf(point.x - global_position.x)

func celebrate() -> void:
	state = State.WON
	mood = "happy"
	_win_t = 0.0
	velocity = Vector2.ZERO

func die(kind: String) -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	death_kind = kind
	mood = "dizzy"
	velocity = Vector2.ZERO
	_death_t = 0.0
	died.emit(kind)

func _physics_process(delta: float) -> void:
	_anim += delta
	if state == State.DEAD:
		_death_t += delta
	elif state == State.WON:
		_win_t += delta
	elif state == State.ACTIVE:
		_think(delta)
		if level.ogre_idx >= 0:
			velocity *= RUN_SCALE   # the ogre is awake: he runs for his life (looks the part)
		move_and_slide()
		speed_now = get_real_velocity().length()
		if record_trace:
			trace.append(global_position)
		_check_world()
	queue_redraw()

## The whole decision model: closest active lamp in range, else random.
func _think(delta: float) -> void:
	var lamp := lamps.nearest_active(global_position)
	var new_behavior := lamp.current_color() if lamp != null else -1
	if new_behavior != behavior:
		behavior = new_behavior
		behavior_changed.emit(behavior)
	influence = lamp
	if lamp == null:
		_no_influence(delta)
		return
	_confuse_t = 0.0
	_wander_t = 0.0
	var to := lamp.global_position - global_position
	var dist := to.length()
	var stop := ARRIVE_DIST if lamp.is_exit else STAND_OFF
	match behavior:
		LampColors.C.GREEN:
			velocity = to.normalized() * SPEED if dist > stop else Vector2.ZERO
			mood = "happy"
		LampColors.C.RED:
			velocity = (-to).normalized() * SPEED if dist > 1.0 else Vector2.RIGHT * SPEED
			mood = "panic"
		LampColors.C.ORANGE:
			velocity = to.normalized() * SPEED * ORANGE_FACTOR if dist > stop else Vector2.ZERO
			mood = "smug"
		_:
			velocity = Vector2.ZERO   # BLUE: frozen solid
			mood = "normal"
	if velocity.length() > 1.0:
		face(global_position + velocity)

func _no_influence(delta: float) -> void:
	_confuse_t += delta
	if _confuse_t < CONFUSE_TIME:
		velocity = Vector2.ZERO   # a visible beat of confusion before he wanders
		mood = "confused"
		return
	mood = "confused"
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_dir = Vector2.from_angle(rng.randf() * TAU)
		_wander_t = rng.randf_range(0.7, 1.4)
	velocity = _wander_dir * WANDER_SPEED
	face(global_position + velocity)

func _check_world() -> void:
	var h := level.hazard_at(global_position)
	if h != "":
		die(h)
		return
	if level.at_exit(global_position):
		reached_exit.emit()
		return
	if level.ogre_idx < 0:
		var woke := level.stealth_violation(global_position, speed_now)
		if woke >= 0:
			level.wake_ogre(woke)   # he wakes: only the exit can save the hero now
			ogre_woke.emit()
	elif level.step_ogre(get_physics_process_delta_time(), global_position):
		die("dragon")

# ----------------------------------------------------------------- drawing

const SPRITE_SCALE := 3.0

func _draw() -> void:
	var walking := state == State.ACTIVE and speed_now > 8.0
	var frozen := state == State.ACTIVE and behavior == LampColors.C.BLUE
	var bob := -absf(sin(_anim * (14.0 if level.ogre_idx >= 0 else 10.0))) * 3.0 if walking else sin(_anim * 3.0) * 0.8
	if behavior == LampColors.C.ORANGE and walking:
		bob = -absf(sin(_anim * 4.0)) * 4.0   # tiptoeing
	var off := Vector2.ZERO
	if frozen:
		off = Vector2(sin(_anim * 50.0) * 0.8, 0)   # shivering
	var squash := 1.0
	var lift := 0.0
	if state == State.DEAD:
		squash = clampf(1.0 - _death_t * 2.0, 0.15, 1.0) if death_kind != "trap" else 1.0
		if death_kind == "trap":
			scale = Vector2.ONE * clampf(1.0 - _death_t * 1.2, 0.05, 1.0)
			rotation = _death_t * 9.0
	if state == State.WON:
		lift = -absf(sin(_win_t * 8.0)) * 10.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.ellipse(self, Vector2(0, 5), 14, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, bob + lift) + off, 0.0, Vector2(_facing, squash))
	var tint := Color(1.0, 0.75, 0.75) if state == State.DEAD else Color.WHITE
	Sprites.draw_at_foot(self, Sprites.HERO, Vector2(0, 6), SPRITE_SCALE, tint)
	if frozen:   # ice: he is frozen solid
		draw_rect(Rect2(-22, -44, 44, 50), Color(0.6, 0.8, 1.0, 0.35))
		draw_rect(Rect2(-22, -44, 44, 50), Color(0.85, 0.95, 1.0, 0.8), false, 2.0)
		for i in 3:
			draw_colored_polygon(PackedVector2Array([Vector2(-20 + i * 15, -44), Vector2(-13 + i * 15, -44), Vector2(-16.5 + i * 15, -53)]), Color(0.85, 0.95, 1.0, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mood == "dizzy":
		for k in 3:
			var a2 := _anim * 6.0 + k * TAU / 3.0
			draw_circle(Vector2(cos(a2) * 14.0, -48 + sin(a2) * 3.0), 2.5, Color(1, 0.9, 0.2))
	if state == State.ACTIVE and behavior == -1 and _confuse_t > 0.0:
		draw_string(UiFont.TITLE, Vector2(-5, -50), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.95))
