class_name LightController
extends Node
## Single source of truth for light. The guide's lantern is one source (toggle
## with Space); switched-on lampposts register as extra sources. Things that
## react to light ask is_lit(point), a clear state check.

signal lantern_toggled(is_on: bool)

const LANTERN_RADIUS := 150.0

var lantern_on := true
var lantern_pos := Vector2.ZERO
var extra: Array[Node2D] = []   # lampposts: need `lit: bool` and `radius: float`

func toggle_lantern() -> void:
	set_lantern(not lantern_on)

func set_lantern(on: bool) -> void:
	if on == lantern_on:
		return
	lantern_on = on
	lantern_toggled.emit(on)

func register(source: Node2D) -> void:
	extra.append(source)

func is_lit(point: Vector2) -> bool:
	if lantern_on and point.distance_to(lantern_pos) <= LANTERN_RADIUS:
		return true
	for s in extra:
		if s.lit and point.distance_to(s.global_position) <= s.radius:
			return true
	return false
