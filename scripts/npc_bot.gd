class_name NpcBot
extends RefCounted
## A realistic scripted guide for tests and tools. It walks the NPC (at his real speed, with real
## collisions) to each lamp in turn and switches it only when (a) he is within reach and (b) the entry's
## trigger is satisfied (see schedule.gd). So its times include real travel time: a player cannot beat it
## by teleporting between lamps.

const WALK_UP_TO := 40.0

var entries: Array
var idx := 0
var presses: Array[float] = []   # when each entry was actually pressed

func _init(e: Array = []) -> void:
	entries = e

func is_done() -> bool:
	return idx >= entries.size()

func step(t: float, hero: Hero, lm: LampManager, inv: Inversion, npc: Npc) -> void:
	npc.bot_driven = true
	npc.bot_input = Vector2.ZERO
	if idx >= entries.size():
		return
	var e: Array = entries[idx]
	var ok := Schedule.trigger_ok(e, t, hero, lm)
	var kind := str(e[1])
	if kind == "inv":
		if ok and inv.try_activate():
			presses.append(t)
			idx += 1
		return
	var lamp := lm.lamps[int(e[2])]
	var to := lamp.global_position - npc.global_position
	var in_reach := to.length() <= WALK_UP_TO and lm.nearest_lamp(npc.global_position, Npc.REACH) == lamp
	if not in_reach:
		npc.bot_input = to.normalized()   # keep walking toward the lamp
		return
	if ok:
		match kind:
			"sw": lm.switch_lamp(lamp)
			"on": lamp.set_on(true)
			"off": lamp.set_on(false)
		presses.append(t)
		idx += 1
