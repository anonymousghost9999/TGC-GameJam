class_name Npc
extends CharacterBody2D
## The player's character: a real, physical guide who can walk around the dungeon
## (twice as fast as the hero), switch lamps (E) and use the invert-colour lantern
## (Q). He is not affected by hazards.

signal target_changed(lamp: Lamp)

const SPEED := 160.0   # 2x the hero
const REACH := 52.0

var lamps: LampManager
var inversion: Inversion
var active := false
var bot_driven := false          # tests/tools: move by `bot_input` instead of the keyboard
var bot_input := Vector2.ZERO
var target: Lamp = null
var demon := false         # the reveal
var bubble: Bubble

var _facing := 1.0
var _t := 0.0
var _use_flash := 0.0
var _beam_to := Vector2.ZERO     # world position of the lamp just switched
var _beam_color := Color.WHITE

func _ready() -> void:
	bubble = Bubble.new()
	bubble.rise = 58
	add_child(bubble)

func place(p: Vector2) -> void:
	global_position = p
	velocity = Vector2.ZERO
	target = null

func say(line: String, seconds := 2.6) -> void:
	bubble.say(line, seconds)

func face(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_facing = signf(point.x - global_position.x)

func _physics_process(delta: float) -> void:
	_t += delta
	_use_flash = maxf(_use_flash - delta * 3.0, 0.0)
	var dir := Vector2.ZERO
	if bot_driven:
		dir = bot_input
	elif active:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if absf(dir.x) > 0.1:
		_facing = signf(dir.x)
	var t: Lamp = lamps.nearest_lamp(global_position, REACH) if (active and lamps != null) else null
	if t != target:
		target = t
		target_changed.emit(target)
	queue_redraw()

func switch_nearest() -> bool:
	if target == null:
		return false
	_use_flash = 1.0
	face(target.global_position)
	_beam_to = target.global_position + Vector2(0, -20)   # the lamp's bulb
	lamps.switch_lamp(target)
	_beam_color = LampColors.rgb(target.current_color())
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact"):
		if switch_nearest():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("invert") and inversion != null:
		if inversion.try_activate():
			get_viewport().set_input_as_handled()

func _draw() -> void:
	var moving := velocity.length() > 5.0
	var bob := sin(_t * 14.0) * 1.8 if moving else sin(_t * 3.0) * 0.6
	var robe := Color(0.45, 0.28, 0.62) if not demon else Color(0.5, 0.05, 0.1)
	var trim := Color(0.95, 0.8, 0.4) if not demon else Color(0.9, 0.5, 0.1)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.ellipse(self, Vector2(0, 5), 12, 4, Color(0, 0, 0, 0.35))
	var s := 1.0 if not demon else 1.25
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(_facing * s, s))
	if demon:   # cape and horns
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -26), Vector2(10, -26), Vector2(20, 2), Vector2(-20, 2)]), Color(0.25, 0.02, 0.05))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 5), Vector2(9, 5), Vector2(6, -18), Vector2(-6, -18)]), robe)
	draw_rect(Rect2(-7, -10, 14, 3), trim)
	draw_circle(Vector2(0, -25), 10.0, robe.darkened(0.25))      # hood
	draw_circle(Vector2(1, -24), 6.8, Color(0.95, 0.82, 0.7) if not demon else Color(0.75, 0.3, 0.3))
	var eye := Color(0.1, 0.1, 0.15) if not demon else Color(1.0, 0.85, 0.2)
	draw_circle(Vector2(-1, -25), 1.4, eye)
	draw_circle(Vector2(4, -25), 1.4, eye)
	if demon:
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -30), Vector2(-12, -42), Vector2(-2, -32)]), Color(0.9, 0.85, 0.7))
		draw_colored_polygon(PackedVector2Array([Vector2(7, -30), Vector2(12, -42), Vector2(2, -32)]), Color(0.9, 0.85, 0.7))
		draw_arc(Vector2(2, -21), 3.0, 0.2, PI - 0.2, 6, Color(0.1, 0.0, 0.0), 1.5)
	# the invert-colour lantern
	var inv_on := inversion != null and inversion.active
	var lc := Color(0.7, 0.4, 1.0) if inv_on else (Color(1.0, 0.95, 0.7) if (inversion != null and inversion.ready_to_use()) else Color(0.4, 0.4, 0.45))
	draw_line(Vector2(8, -8), Vector2(14, -20), Color(0.5, 0.35, 0.2), 2.0)
	if inv_on or (inversion != null and inversion.ready_to_use()):
		DrawUtil.glow(self, Vector2(14, -22), 16.0, Color(lc.r, lc.g, lc.b, 0.7), 4)
	if inversion != null and inversion.unlocked:
		draw_rect(Rect2(11, -27, 7, 8), lc)
		draw_rect(Rect2(11, -27, 7, 8), Color(0.2, 0.1, 0.1), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _use_flash > 0.0:
		# a spark from the NPC's hand to the lamp: it is the NPC who switches lamps, never the hero
		var from := Vector2(12.0 * _facing, -20.0 + bob)
		var to := _beam_to - global_position
		draw_line(from, to, Color(_beam_color.r, _beam_color.g, _beam_color.b, 0.35 * _use_flash), 6.0)
		draw_line(from, to, Color(1, 1, 1, 0.9 * _use_flash), 2.0)
		draw_arc(from, 8.0 + 14.0 * (1.0 - _use_flash), 0.0, TAU, 14, Color(1, 1, 1, _use_flash), 2.0)
