class_name LampManager
extends Node
## Owns every lamp in the level. Responsible for:
##  - the ON/OFF switching rules (independent per lamp, or GLOBAL per colour group)
##  - the inversion transform (visible colour AND behaviour change together)
##  - finding the closest active lamp to a point (lamps have no radius)

signal lamp_switched(lamp: Lamp)
signal inversion_changed(active: bool)

var lamps: Array[Lamp] = []
var global_mode := false   # true from Level 7: all lamps of one colour share ON/OFF
var inverted := false

func register(l: Lamp) -> void:
	l.manager = self
	l.index = lamps.size()
	lamps.append(l)

func reset_states() -> void:
	inverted = false
	for l in lamps:
		l.on = l.start_on
		l.snap_visuals()

## The colour a lamp currently BEHAVES as (and shows). Derived from its original colour.
func effective_color(original: int) -> int:
	return LampColors.invert(original) if inverted else original

func set_inverted(on: bool) -> void:
	if inverted == on:
		return
	inverted = on
	inversion_changed.emit(on)

## The NPC flips a lamp. In global mode this flips the whole ORIGINAL-colour group.
func switch_lamp(l: Lamp) -> void:
	var target := not l.on
	if global_mode:
		for other in lamps:
			if other.original == l.original:
				other.set_on(target)
	else:
		l.set_on(target)
	lamp_switched.emit(l)

func state_of_group(original: int) -> bool:
	for l in lamps:
		if l.original == original:
			return l.on
	return false

## The closest ACTIVE lamp anywhere in the level (lamps have no radius), or null
## if every lamp is off. Ties: lowest index.
func nearest_active(pos: Vector2) -> Lamp:
	var best: Lamp = null
	var best_d := INF
	for l in lamps:
		if not l.on:
			continue
		var d := pos.distance_to(l.global_position)
		if d < best_d:
			best = l
			best_d = d
	return best

func nearest_lamp(pos: Vector2, max_dist: float) -> Lamp:
	var best: Lamp = null
	var best_d := max_dist
	for l in lamps:
		var d := pos.distance_to(l.global_position)
		if d <= best_d:
			best = l
			best_d = d
	return best
