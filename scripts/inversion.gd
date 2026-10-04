class_name Inversion
extends Node
## The NPC's invert-colour lantern: ACTIVE for 5 s, then a 10 s cooldown.
## While active, every lamp shows AND behaves as its complementary colour.

signal activated
signal ended

const ACTIVE_TIME := 5.0
const COOLDOWN_TIME := 10.0

var manager: LampManager
var unlocked := false
var active := false
var remaining := 0.0
var cooldown := 0.0

func reset() -> void:
	active = false
	remaining = 0.0
	cooldown = 0.0
	if manager != null:
		manager.set_inverted(false)

func ready_to_use() -> bool:
	return unlocked and not active and cooldown <= 0.0

func try_activate() -> bool:
	if not ready_to_use():
		return false
	active = true
	remaining = ACTIVE_TIME
	manager.set_inverted(true)
	activated.emit()
	return true

func _process(delta: float) -> void:
	if active:
		remaining -= delta
		if remaining <= 0.0:
			active = false
			remaining = 0.0
			cooldown = COOLDOWN_TIME
			manager.set_inverted(false)   # original colours AND behaviours return
			ended.emit()
	elif cooldown > 0.0:
		cooldown = maxf(cooldown - delta, 0.0)
