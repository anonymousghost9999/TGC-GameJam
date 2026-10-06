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
	var bob := -absf(sin(_t * 14.0)) * 3.0 if moving else sin(_t * 3.0) * 0.6
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	DrawUtil.ellipse(self, Vector2(0, 5), 13 if not demon else 18, 4, Color(0, 0, 0, 0.35))
	if demon:   # a dark aura around the Demon Lord
		DrawUtil.glow(self, Vector2(0, -26), 40.0 + 3.0 * sin(_t * 4.0), Color(1.0, 0.1, 0.1, 0.45), 5)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(_facing, 1.0))
	Sprites.draw_at_foot(self, Sprites.DEMON if demon else Sprites.NPC, Vector2(0, 6), 4.0 if demon else 3.0)
	# the invert-colour lantern: glows purple while inverting, dim while recharging
	if inversion != null and inversion.unlocked:
		var inv_on := inversion.active
		var ready := inversion.ready_to_use()
		var glass := Color(0.8, 0.5, 1.0) if inv_on else (Color.WHITE if ready else Color(0.45, 0.45, 0.5))
		if inv_on or ready:
			DrawUtil.glow(self, Vector2(17, -16), 20.0, Color(0.85, 0.6, 1.0, 0.7) if inv_on else Color(1.0, 0.85, 0.5, 0.45), 4)
		draw_line(Vector2(10, -14), Vector2(17, -27), Color(0.35, 0.25, 0.15), 2.0)
		Sprites.draw_lantern(self, Vector2(17, -16), 1.0, glass)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _use_flash > 0.0:
		# a spark from the NPC's hand to the lamp: it is the NPC who switches lamps, never the hero
		var from := Vector2(12.0 * _facing, -20.0 + bob)
		var to := _beam_to - global_position
		draw_line(from, to, Color(_beam_color.r, _beam_color.g, _beam_color.b, 0.35 * _use_flash), 6.0)
		draw_line(from, to, Color(1, 1, 1, 0.9 * _use_flash), 2.0)
		draw_arc(from, 8.0 + 14.0 * (1.0 - _use_flash), 0.0, TAU, 14, Color(1, 1, 1, _use_flash), 2.0)
