class_name DayNight
extends Node
## The guide's magic: flip the world between day and night. Gameplay reads
## is_night (stepping stones, fireflies, werewolves); visuals read blend (0..1).

signal time_changed(is_night: bool)

const COOLDOWN := 3.0

var is_night := false
var blend := 0.0   # smooth 0 = day .. 1 = night, for tinting only
var _cd := 0.0

func cooldown_left() -> float:
	return _cd

## Returns false (and does nothing) while the magic is recharging.
func toggle() -> bool:
	if _cd > 0.0:
		return false
	set_night(not is_night)
	_cd = COOLDOWN
	return true

func set_night(on: bool) -> void:
	if on == is_night:
		return
	is_night = on
	time_changed.emit(on)

func _process(delta: float) -> void:
	_cd = maxf(_cd - delta, 0.0)
	blend = move_toward(blend, 1.0 if is_night else 0.0, delta / 1.2)
