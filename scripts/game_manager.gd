class_name GameManager
extends Node
## Game flow: title -> prologue (outside the dungeon) -> 9 levels -> final lock ->
## Demon Lord reveal -> kill phase -> ending. Each level is rebuilt from data.
## Dying restarts the level instantly. R restarts the current level; Esc pauses.

enum GS { TITLE, STORY, INTRO, PLAYING, DEAD, COMPLETE, PAUSED, ENDING }

const HERO_SCENE := preload("res://scenes/hero.tscn")
const NPC_SCENE := preload("res://scenes/npc.tscn")
const HINT_PROMPT := "[H] hint"
const HINT_SECONDS := 9.0

var gs := GS.TITLE
var levels: Array[Dictionary] = []
var level_index := 0
var data: Dictionary = {}
var world: Node2D
var level: Level
var lamp_manager: LampManager
var inversion: Inversion
var hero: Hero
var npc: Npc
var hud: Hud
var audio: Audio
var level_time := 0.0
var deaths := 0                  # deaths on the current level
var total_deaths := 0
var results := {}                # level id -> {deaths, flawless}
var kill_phase := false
var debug_keys := true

var _skip := false
var hint_left := 0.0               # seconds the on-demand hint is still shown (press H)
var _level_hint := ""
var _f1_at := -100000          # for the debug chord F1 then 0
var _token := 0                  # invalidates stale coroutines after a retry
var _line_cd := 0.0
var _credit_cd := 0.0
var _npc_hazard_noted := false
var _awaiting_continue := false
var _cards_shown := {}           # new-lamp cards already shown this session
var _end_card_shown := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	levels = LevelData.playable()
	hud = Hud.new()
	add_child(hud)
	audio = Audio.new()
	add_child(audio)
	_show_title()

# ------------------------------------------------------------------ setup

func _setup_input() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "invert": [KEY_Q], "confirm": [KEY_ENTER, KEY_KP_ENTER],
		"pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R], "mute": [KEY_M], "hint": [KEY_H], "controls": [KEY_TAB],
	}
	for action: String in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)

## Build the world for one level definition.
func _load_level(d: Dictionary) -> void:
	data = d
	level_time = 0.0
	if world != null:
		world.queue_free()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	lamp_manager = LampManager.new()
	lamp_manager.global_mode = d.get("global", false)
	world.add_child(lamp_manager)
	inversion = Inversion.new()
	inversion.manager = lamp_manager
	inversion.unlocked = d.get("invert", false)
	world.add_child(inversion)
	level = Level.new()
	level.setup(d, lamp_manager)
	world.add_child(level)
	hero = HERO_SCENE.instantiate()
	hero.level = level
	hero.lamps = lamp_manager
	world.add_child(hero)
	npc = NPC_SCENE.instantiate()
	npc.lamps = lamp_manager
	npc.inversion = inversion
	world.add_child(npc)
	await get_tree().process_frame   # let Level._ready() build the map
	hero.place(level.hero_start)
	npc.place(level.npc_start)
	hero.died.connect(_on_hero_died)
	hero.reached_exit.connect(_on_hero_exit)
	hero.behavior_changed.connect(_on_behavior)
	lamp_manager.lamp_switched.connect(_on_lamp_switched)
	npc.target_changed.connect(_on_npc_target)
	inversion.activated.connect(func() -> void: audio.play("invert_on"))
	inversion.ended.connect(func() -> void: audio.play("invert_off"))
	hud.set_prompt("")

func _reset_level_state() -> void:
	lamp_manager.reset_states()
	inversion.reset()
	level.reset()
	hero.place(level.hero_start)
	npc.place(level.npc_start)
	level_time = 0.0

# ------------------------------------------------------------------ helpers

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

## One line of dialogue as a speech bubble. E skips.
func _say(who: String, text: String, secs := -1.0) -> void:
	var node: Node = hero if who == "H" else npc
	if not is_instance_valid(node):
		return
	var dur := secs if secs > 0.0 else clampf(1.1 + text.length() * 0.05, 1.8, 5.5)
	node.say(text, dur + 0.3)
	audio.play("blip_h" if who == "H" else "blip_n")
	var t := 0.0
	_skip = false
	while t < dur and not _skip and is_instance_valid(node):
		await get_tree().process_frame
		t += get_process_delta_time()
	if is_instance_valid(node):
		node.bubble.hush()

func _say_all(lines: Array) -> void:
	for l in lines:
		await _say(l[0], l[1])

func _walk(node: Node2D, to: Vector2, speed: float) -> void:
	if node.has_method("face"):
		node.face(to)
	while is_instance_valid(node) and node.global_position.distance_to(to) > 2.0:
		node.global_position = node.global_position.move_toward(to, speed * get_process_delta_time())
		await get_tree().process_frame
	if is_instance_valid(node):
		node.global_position = to

func _wait_continue() -> void:
	_awaiting_continue = true
	_skip = false
	while not _skip:
		await get_tree().process_frame
	_awaiting_continue = false

# -------------------------------------------------------------------- title

func _show_title() -> void:
	gs = GS.TITLE
	hud.show_game_ui(false)
	hud.show_title(true)
	audio.music("adventure")

func _start_game() -> void:
	hud.show_title(false)
	audio.music("adventure")
	gs = GS.STORY
	await _play_prologue()
	_begin_level(0)

# ----------------------------------------------------------------- prologue

func _play_prologue() -> void:
	await _load_level(LevelData.by_id("prologue"))
	hud.show_game_ui(false)
	hud.letterbox(true, 0.4)
	hero.place(level.cell_center(Vector2i(12, 8)))
	npc.place(level.cell_center(Vector2i(2, 8)))
	hero.mood = "happy"
	await hud.fade_to(0.0, 0.01)
	var lines: Array = Dialogue.PROLOGUE
	await _say(lines[0][0], lines[0][1])
	await _walk(npc, level.cell_center(Vector2i(9, 8)), 110.0)
	for i in range(1, lines.size()):
		hero.face(npc.global_position)
		npc.face(hero.global_position)
		await _say(lines[i][0], lines[i][1])
	hud.letterbox(false, 0.4)
	await _walk(npc, level.exit_pos + Vector2(-34, 0), 120.0)
	_walk(hero, level.exit_pos + Vector2(-60, 0), 90.0)
	await hud.fade_to(1.0, 0.7)

# ------------------------------------------------------------------- levels

func _begin_level(i: int) -> void:
	level_index = i
	kill_phase = false
	hud.show_title(false)
	await _load_level(levels[i])
	deaths = 0
	level_time = 0.0
	_npc_hazard_noted = false
	_intro_level(levels[i])

func _intro_level(d: Dictionary) -> void:
	gs = GS.INTRO
	hero.mood = "normal"
	hud.show_game_ui(true)
	hud.set_level(d.num)
	_level_hint = d.hint
	hint_left = 0.0
	hud.set_hint(HINT_PROMPT)
	hud.set_deaths(0)
	hud.set_invert(false, false, 0.0, 0.0)
	var tok := _token
	await hud.fade_to(0.0, 0.5)
	hud.banner(d.num)
	await _wait(1.4)
	if tok != _token:
		return
	for kind: String in d.get("cards", []):
		# something new in this level: a card with a little demo, before anyone talks about it
		if _cards_shown.has(kind):
			continue
		_cards_shown[kind] = true
		hud.show_card(kind)
		await _wait(0.4)
		await _wait_continue()
		hud.hide_cards()
		if tok != _token:
			return
	await _say_all(d.intro)
	if tok != _token:
		return
	_begin_play()

func _begin_play() -> void:
	level.reset()   # the timed spikes' clock starts NOW (the moment the hero starts), not when the level loaded
	gs = GS.PLAYING
	hero.start()
	npc.active = true

func _retry() -> void:
	_token += 1
	hint_left = 0.0
	_reset_level_state()
	hud.hide_overlay()
	hero.bubble.hush()
	npc.bubble.hush()
	gs = GS.INTRO
	var tok := _token
	await _wait(0.35)
	if tok != _token:
		return
	_begin_play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		audio.toggle_mute()
		return
	if event.is_action_pressed("controls"):
		hud.toggle_controls()
		return
	if debug_keys and OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if _debug_key((event as InputEventKey).physical_keycode):
			return
	var confirm := event.is_action_pressed("interact") or event.is_action_pressed("confirm")
	if confirm:
		_skip = true
	match gs:
		GS.TITLE:
			if confirm:
				_start_game()
		GS.PLAYING, GS.DEAD:
			if event.is_action_pressed("hint") and gs == GS.PLAYING:
				hint_left = HINT_SECONDS
				audio.play("blip_n")
			elif event.is_action_pressed("restart") and not kill_phase:
				_retry()
			elif event.is_action_pressed("pause") and gs == GS.PLAYING:
				_set_paused(true)
		GS.PAUSED:
			if event.is_action_pressed("pause"):
				_set_paused(false)
			elif event.is_action_pressed("restart"):
				_set_paused(false)
				_retry()
		GS.ENDING:
			if _end_card_shown and (confirm or event.is_action_pressed("restart")):
				_back_to_title()

func _set_paused(on: bool) -> void:
	get_tree().paused = on
	gs = GS.PAUSED if on else GS.PLAYING
	if on:
		hud.show_overlay("[center][font_size=40]PAUSED[/font_size]\n\n[color=gold]Esc[/color] resume      [color=gold]R[/color] restart level[/center]")
	else:
		hud.hide_overlay()

## Debug builds only (running from the editor), usable from ANY screen:
##   1-9        jump to that level;  Shift+0..5  levels 10-15
##   F1 then 0  jump straight to the finale: the Demon Lord's trial (hold F1 and press 0, or tap F1 then 0 within 3 s)
## Returns true if the key was a debug command.
func _debug_key(key: int) -> bool:
	var now := Time.get_ticks_msec()
	if key == KEY_F1:
		_f1_at = now
		return true
	if key == KEY_0 and (Input.is_physical_key_pressed(KEY_F1) or now - _f1_at < 3000):
		_f1_at = -100000
		_debug_reset()
		_begin_kill_debug()
		return true
	if Input.is_key_pressed(KEY_SHIFT) and key >= KEY_0 and key <= KEY_5:   # Shift+0..5: levels 10-15
		_debug_reset()
		_begin_level(9 + key - KEY_0)
		return true
	if key >= KEY_1 and key <= KEY_9:
		_debug_reset()
		_begin_level(key - KEY_1)
		return true
	return false

## Drop whatever is happening (pause, overlays, cutscene coroutines) before a debug jump.
func _debug_reset() -> void:
	_token += 1
	_skip = true
	get_tree().paused = false
	hud.hide_overlay()
	hud.show_title(false)
	hud.hide_cards()
	hud.letterbox(false, 0.01)
	hud.show_game_ui(true)
	gs = GS.STORY

func _begin_kill_debug() -> void:
	# a jump straight into the final trial: the Demon Lord is already revealed
	await _begin_kill()

func _process(delta: float) -> void:
	_line_cd = maxf(_line_cd - delta, 0.0)
	_credit_cd = maxf(_credit_cd - delta, 0.0)
	if gs == GS.PLAYING:
		level_time += delta
	if gs == GS.PLAYING or gs == GS.DEAD:
		hint_left = maxf(hint_left - delta, 0.0)
		hud.set_hint(((_kill_hint() if kill_phase else _level_hint) if hint_left > 0.0 else HINT_PROMPT))
	if gs == GS.PLAYING or gs == GS.INTRO or gs == GS.DEAD:
		hud.set_invert(inversion.unlocked, inversion.active, inversion.remaining, inversion.cooldown)
		hud.set_deaths(deaths)
		_npc_hazard_check()

# ----------------------------------------------------------------- reactions

## Stage-by-stage advice for the final trial, based on what the hero is doing right now.
func _kill_hint() -> String:
	var gap_x := 13.0 * Level.TILE
	var hp := hero.global_position
	if hero.behavior == LampColors.C.RED:
		if hp.y > 7.0 * Level.TILE:
			return "RED is pushing him north. Keep it on until he is near the top."
		return "He is high up. Switch RED off now: the chamber's green lamp is his nearest green."
	if hp.x < gap_x:
		return "He heads for the exit lamp in the south-east. Run to the RED lamp in the south and switch it on once he is through the gap."
	if hp.y < 7.0 * Level.TILE and hp.x < 23.0 * Level.TILE:
		return "He is walking toward the chamber's lamp. Let him go in."
	return "Greens pull, reds push, and he always obeys the NEAREST active lamp. The spike chamber is the only deadly place."

func _on_behavior(color: int) -> void:
	if gs == GS.PLAYING and color == LampColors.C.BLUE:
		audio.play("freeze")
	if gs != GS.PLAYING or _line_cd > 0.0 or randf() > 0.55:
		return
	var pool: Array = Dialogue.AMBIENT[color]
	hero.say(pool[randi() % pool.size()], 2.0)
	_line_cd = 4.0

func _on_lamp_switched(lamp: Lamp) -> void:
	audio.play("switch", [1.0, 0.84, 1.12, 1.26][lamp.original])
	audio.play("on" if lamp.on else "off", 1.0, -6.0)
	if gs == GS.PLAYING and _credit_cd <= 0.0 and randf() < 0.18 and _line_cd <= 0.0:
		hero.say(Dialogue.CREDIT_GRAB[randi() % Dialogue.CREDIT_GRAB.size()], 2.2)
		_credit_cd = 12.0
		_line_cd = 3.0

func _on_npc_target(lamp: Lamp) -> void:
	if lamp == null:
		hud.set_prompt("")
	else:
		hud.set_prompt("[E] Switch %s lamp %s" % [LampColors.label(lamp.original), "OFF" if lamp.on else "ON"])

## Subtle foreshadowing: the NPC strolls over hazards without a scratch.
func _npc_hazard_check() -> void:
	if _npc_hazard_noted or gs != GS.PLAYING or level_index < 2 or kill_phase:
		return
	if level.hazard_at(npc.global_position) != "":
		_npc_hazard_noted = true
		npc.say("Light feet.", 2.0)
		hero.say("How are you not dying?!", 2.2)

func _on_hero_died(kind: String) -> void:
	if gs != GS.PLAYING:
		return
	gs = GS.DEAD
	npc.active = false
	var tok := _token
	audio.play("death_" + kind if kind in ["spike", "fire", "trap", "dragon"] else "death_spike")
	hud.flash(Color(1, 0.1, 0.1))
	if kill_phase:
		_kill_success()
		return
	deaths += 1
	total_deaths += 1
	var pool: Array = Dialogue.DEATH.get(kind, ["Ow."])
	hero.say(pool[randi() % pool.size()], 1.8)
	await _wait(1.0)
	if tok != _token:
		return
	if randf() < 0.5:
		npc.say(Dialogue.NPC_DEATH[randi() % Dialogue.NPC_DEATH.size()], 1.4)
	await _wait(0.9)
	if tok != _token:
		return
	_retry()

func _on_hero_exit() -> void:
	if gs != GS.PLAYING:
		return
	if kill_phase:
		_kill_escape()
	elif data.get("exit_kind", "door") == "lock":
		_final_sequence()
	else:
		_complete_level()

func _complete_level() -> void:
	gs = GS.COMPLETE
	npc.active = false
	hero.celebrate()
	audio.play("win")
	var flawless := deaths == 0
	results[data.id] = {"deaths": deaths, "flawless": flawless}
	await _say("H", Dialogue.CLEAR[randi() % Dialogue.CLEAR.size()], 1.8)
	await _say_all(data.outro)
	hud.show_overlay(
		"[center][font_size=38]LEVEL %d COMPLETE[/font_size]\n\n" % data.num +
		"Deaths  %d\n\n" % deaths +
		("[color=gold][font_size=30]FLAWLESS[/font_size][/color]\n\n" if flawless else "\n") +
		"Press [color=gold]E[/color] to continue[/center]")
	await _wait(0.4)
	await _wait_continue()
	hud.hide_overlay()
	await hud.fade_to(1.0, 0.4)
	_begin_level(level_index + 1)

# ----------------------------------------------------- finale: lock, reveal, kill

func _final_sequence() -> void:
	gs = GS.STORY
	npc.active = false
	results[data.id] = {"deaths": deaths, "flawless": deaths == 0}
	hud.letterbox(true, 0.4)
	hud.set_prompt("")
	await _say_all(Dialogue.LOCK)
	hero.celebrate()
	audio.play("lock")
	hud.flash(Color(1, 1, 1), 0.9)
	await _wait(0.8)
	await _demon_transform()
	await _say_all(Dialogue.REVEAL)
	hud.letterbox(false, 0.4)
	await hud.fade_to(1.0, 0.6)
	_begin_kill()

func _demon_transform() -> void:
	level.palette = 2
	level.queue_redraw()
	npc.demon = true
	audio.play("reveal")
	audio.music("")
	hud.flash(Color(1.0, 0.1, 0.1), 1.2)
	await _wait(1.0)

func _begin_kill() -> void:
	kill_phase = true
	audio.music("demon")
	var d := LevelData.by_id("l9k")
	await _load_level(d)
	npc.demon = true
	deaths = 0
	hud.show_game_ui(true)
	hud.set_level(0, "THE DEMON LORD'S TRIAL")
	_level_hint = ""
	hint_left = 0.0
	hud.set_hint(HINT_PROMPT)
	hud.set_invert(true, false, 0.0, 0.0)
	await hud.fade_to(0.0, 0.6)
	await _say("N", "Walk, little hero. The lamps are mine now.")
	_begin_play()

func _kill_escape() -> void:
	gs = GS.STORY
	npc.active = false
	hero.celebrate()
	await _say_all(Dialogue.ESCAPE)
	await hud.fade_to(1.0, 0.4)
	await _load_level(LevelData.by_id("l9k"))
	npc.demon = true
	await hud.fade_to(0.0, 0.4)
	_begin_play()

func _kill_success() -> void:
	gs = GS.ENDING
	await _wait(0.8)
	hud.letterbox(true, 0.4)
	await _say_all(Dialogue.DEATH_FINAL)
	await hud.fade_to(1.0, 1.0)
	var flawless := 0
	for k in results:
		if results[k].flawless:
			flawless += 1
	hud.show_game_ui(false)
	hud.show_overlay(
		"[center][font_size=44]THE END[/font_size]\n\n" +
		"The Demon Lord reclaimed his dungeon.\nThe lamps burned in his honour for a thousand years.\n\n" +
		"The hero never did find Maribel.\n\n" +
		"[color=gold]Flawless levels: %d / %d[/color]     Total deaths: %d\n\n" % [flawless, levels.size(), total_deaths] +
		"Thanks for playing!   Press [color=gold]E[/color] to return to the start[/center]")
	_end_card_shown = true
	var tok := _token
	await _wait(20.0)   # nobody pressed anything: back to the title screen by itself
	if tok == _token and gs == GS.ENDING:
		_back_to_title()

## From the end card: start over at the title screen.
func _back_to_title() -> void:
	_token += 1
	get_tree().paused = false
	get_tree().reload_current_scene()
