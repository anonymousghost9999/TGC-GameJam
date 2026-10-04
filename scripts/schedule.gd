class_name Schedule
extends RefCounted
## A scripted sequence of lamp switches ("a perfect guide"), used by tools and tests.
## Entries are [trigger, action, ...]:
##   trigger >= 0   absolute time in seconds since the level started
##   -1 near [-1,act,idx,lamp]    hero within 22px of lamp
##   -5 arrived [-5,act,idx,lamp] hero has stopped beside the lamp (within 34px)
##   -2 below [-2,act,idx,row]    hero below tile row      -4 above  hero above tile row
##   -3 right [-3,act,idx,col]    hero right of tile column
## Actions: "sw" (switch, global-aware), "on", "off" (single lamp), "inv" (invert lantern).
## Lamps are numbered in row-major scan order of the map.

var entries: Array = []
var done := {}

func _init(e: Array = []) -> void:
	entries = e

## Is the trigger of entry `e` satisfied right now?
static func trigger_ok(e: Array, t: float, hero: Hero, lm: LampManager) -> bool:
	var hp := hero.global_position
	var trig := float(e[0])
	if trig >= 0.0:
		return t >= trig
	if trig == -1.0:
		return hp.distance_to(lm.lamps[int(e[3])].global_position) < 22.0
	if trig == -5.0:
		return hp.distance_to(lm.lamps[int(e[3])].global_position) < 34.0
	if trig == -2.0:
		return hp.y > float(e[3]) * 32.0
	if trig == -4.0:
		return hp.y < float(e[3]) * 32.0
	if trig == -3.0:
		return hp.x > float(e[3]) * 32.0
	return false

func step(t: float, hero: Hero, lm: LampManager, inv: Inversion) -> void:
	for i in entries.size():
		if done.has(i):
			continue
		var e: Array = entries[i]
		if not Schedule.trigger_ok(e, t, hero, lm):
			continue
		done[i] = true
		match str(e[1]):
			"sw": lm.switch_lamp(lm.lamps[int(e[2])])
			"on": lm.lamps[int(e[2])].set_on(true)
			"off": lm.lamps[int(e[2])].set_on(false)
			"inv": inv.try_activate()
