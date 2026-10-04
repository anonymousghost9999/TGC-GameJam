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
signal behavior_changed(color: int)   # -1 = no influence

enum State { IDLE, ACTIVE, DEAD, WON, STORY }

const SPEED := 80.0
const ORANGE_FACTOR := 0.4
const WANDER_SPEED := 56.0
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
var _swing := 0.0

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
	_swing = maxf(_swing - delta, 0.0)
	if state == State.DEAD:
		_death_t += delta
	elif state == State.WON:
		_win_t += delta
	elif state == State.ACTIVE:
		_think(delta)
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
	if level.stealth_violation(global_position, speed_now):
		die("dragon")
		return
	if level.at_exit(global_position):
		reached_exit.emit()

# ----------------------------------------------------------------- drawing

func _draw() -> void:
	var walking := state == State.ACTIVE and speed_now > 8.0
	var frozen := state == State.ACTIVE and behavior == LampColors.C.BLUE
	var bob := sin(_anim * 10.0) * 1.5 if walking else sin(_anim * 3.0) * 0.8
	if behavior == LampColors.C.ORANGE and walking:
		bob = sin(_anim * 4.0) * 2.5   # tiptoeing
	var cape := Color(0.85, 0.15, 0.2)
	var tunic := Color(0.2, 0.45, 0.85)
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
	DrawUtil.ellipse(self, Vector2(0, 5), 13, 4, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, bob + lift) + off, 0.0, Vector2(_facing, squash))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -26), Vector2(8, -26), Vector2(15, 1), Vector2(-15, 1)]), cape)
	var lw := sin(_anim * 10.0) * 3.0 if walking else 0.0
	draw_rect(Rect2(-7, -6, 5, 10 + lw * 0.3), Color(0.4, 0.25, 0.15))
	draw_rect(Rect2(2, -6, 5, 10 - lw * 0.3), Color(0.4, 0.25, 0.15))
	draw_rect(Rect2(-9, -27, 18, 22), tunic)
	draw_rect(Rect2(-9, -13, 18, 4), Color(1.0, 0.8, 0.25))
	draw_circle(Vector2(0, -35), 11.0, Color(1.0, 0.8, 0.65))
	var helm := PackedVector2Array()
	for k in 11:
		var a := PI + PI * k / 10.0
		helm.append(Vector2(0, -36) + Vector2(cos(a), sin(a)) * 12.0)
	draw_colored_polygon(helm, Color(0.95, 0.8, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -47), Vector2(3, -47), Vector2(10, -56), Vector2(0, -52)]), Color(0.9, 0.2, 0.25))
	_draw_face()
	var ang := -0.6 if _swing <= 0.0 else lerpf(-2.0, 1.2, 1.0 - _swing / 0.4)
	var hand := Vector2(10, -17)
	draw_line(hand, hand + Vector2.from_angle(ang) * 24.0, Color(0.85, 0.9, 0.95), 3.0)
	draw_line(hand + Vector2.from_angle(ang + PI * 0.5) * 4.0, hand + Vector2.from_angle(ang - PI * 0.5) * 4.0, Color(1, 0.8, 0.3), 3.0)
	draw_circle(hand, 3.0, Color(1.0, 0.8, 0.65))
	if frozen:   # ice: he is frozen solid
		draw_rect(Rect2(-14, -52, 28, 58), Color(0.6, 0.8, 1.0, 0.35))
		draw_rect(Rect2(-14, -52, 28, 58), Color(0.85, 0.95, 1.0, 0.8), false, 2.0)
		for i in 3:
			draw_colored_polygon(PackedVector2Array([Vector2(-14 + i * 12, -52), Vector2(-9 + i * 12, -52), Vector2(-11.5 + i * 12, -60)]), Color(0.85, 0.95, 1.0, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if mood == "dizzy":
		for k in 3:
			var a2 := _anim * 6.0 + k * TAU / 3.0
			draw_circle(Vector2(cos(a2) * 12.0, -54 + sin(a2) * 3.0), 2.0, Color(1, 0.9, 0.2))
	if state == State.ACTIVE and behavior == -1 and _confuse_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -62), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))

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
