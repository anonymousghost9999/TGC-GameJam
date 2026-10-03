class_name Player
extends CharacterBody2D
## The imaginary guide NPC. It floats over water and fences (it is not really
## there) but still bumps into trees and houses. E examines / switches things,
## Q points at items and obstacles, Space toggles the lantern. It cannot touch the hero.

signal targets_changed

const SPEED := 150.0

var light: LightController
var daynight: DayNight
var active := false
var target: Interactable = null         # E: examine / switch
var point_target: Interactable = null   # Q: point at
var bubble: Bubble

var _facing := 1.0
var _t := 0.0
var _glow: PointLight2D

func _ready() -> void:
	bubble = Bubble.new()
	bubble.rise = 46
	add_child(bubble)
	_glow = DrawUtil.make_point_light(LightController.LANTERN_RADIUS, Color(1.0, 0.9, 0.6))
	add_child(_glow)

func _physics_process(delta: float) -> void:
	_t += delta
	var dir := Vector2.ZERO
	if active:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()
	if absf(dir.x) > 0.1:
		_facing = signf(dir.x)
	if light != null:
		light.lantern_pos = global_position
		var night := daynight.blend if daynight != null else 0.0
		_glow.energy = (1.0 if light.lantern_on else 0.0) * (0.2 + 0.9 * night)
	_update_target()
	queue_redraw()

func _update_target() -> void:
	var best: Interactable = null
	var best_d := INF
	var best_p: Interactable = null
	var best_pd := INF
	if active:
		for n in get_tree().get_nodes_in_group("interactable"):
			var it := n as Interactable
			if it == null or not it.enabled:
				continue
			var d := global_position.distance_to(it.global_position)
			if d > it.reach:
				continue
			if it.pointable:
				if d < best_pd:
					best_p = it
					best_pd = d
			elif d < best_d:
				best = it
				best_d = d
	if best != target or best_p != point_target:
		target = best
		point_target = best_p
		targets_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("interact") and target != null:
		target.interact(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("point") and point_target != null:
		point_target.interact(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("light") and light != null:
		light.toggle_lantern()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	var moving := velocity.length() > 5.0
	var bob := sin(_t * 12.0) * 1.5 if moving else sin(_t * 3.0) * 0.6
	var lit := light != null and light.lantern_on
	if lit:   # lantern radius, so the player can SEE what is lured/revealed
		DrawUtil.glow(self, Vector2.ZERO, LightController.LANTERN_RADIUS, Color(1.0, 0.9, 0.5, 0.12), 6)
		draw_arc(Vector2.ZERO, LightController.LANTERN_RADIUS, 0.0, TAU, 48, Color(1.0, 0.9, 0.5, 0.3), 1.5)
	var a := 0.82   # slightly see-through: the guide is not quite real
	draw_set_transform(Vector2(0, bob - 4.0 + sin(_t * 2.0) * 2.0), 0.0, Vector2(_facing, 1.0))   # hovers
	DrawUtil.ellipse(self, Vector2(0, 10), 10, 3, Color(0, 0, 0, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 5), Vector2(9, 5), Vector2(6, -16), Vector2(-6, -16)]), Color(0.2, 0.7, 0.7, a))
	draw_rect(Rect2(-7, -8, 14, 3), Color(0.9, 0.8, 0.4, a))
	draw_circle(Vector2(0, -23), 9.0, Color(0.15, 0.5, 0.55, a))
	draw_circle(Vector2(1, -22), 6.5, Color(0.98, 0.84, 0.7, a))
	draw_circle(Vector2(-1, -23), 1.2, Color(0.1, 0.1, 0.15, a))
	draw_circle(Vector2(4, -23), 1.2, Color(0.1, 0.1, 0.15, a))
	draw_line(Vector2(8, -8), Vector2(13, -20), Color(0.5, 0.35, 0.2, a), 2.0)
	var lc := Color(1.0, 0.9, 0.45) if lit else Color(0.35, 0.33, 0.3)
	if lit:
		DrawUtil.glow(self, Vector2(13, -22), 16.0, Color(1.0, 0.9, 0.4, 0.7))
	draw_rect(Rect2(10, -27, 7, 8), lc)
	draw_rect(Rect2(10, -27, 7, 8), Color(0.3, 0.2, 0.1), false, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
