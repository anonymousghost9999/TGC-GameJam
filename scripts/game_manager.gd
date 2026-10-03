class_name GameManager
extends Node
## Owns game flow: intro -> playing (pause) -> quest complete -> villagers' ending.
## Builds the world from the scenes, wires signals between world, hero, player and
## HUD, runs the camera, and handles restart/pause. Restart reloads the scene.

enum GS { INTRO, PLAYING, PAUSED, COMPLETE, TWIST, END }

const WORLD_SCENE := preload("res://scenes/open_world.tscn")
const HERO_SCENE := preload("res://scenes/hero.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const NIGHT_TINT := Color(0.26, 0.32, 0.6)

const BLUNDER_TOASTS := {
	"barrel": "The hero attacked a barrel. The barrel won.",
	"slime": "The hero lost a fight to a slime.",
	"sign": "The hero ignored a WET FLOOR sign. The floor won.",
	"statue": "The hero tried to high-five a statue. The statue won.",
	"chest": "The hero was bitten by a chest. The chest won.",
	"lamp": "The hero dropped the Sacred Lamp on his own foot.",
	"fell": "SPLASH! The stepping stones vanished (or never came). Keep it NIGHT until he's across.",
	"fail": "The wrong item. Of course. He needs your guidance (Q to point).",
	"mauled": "The werewolves got him! Switch to DAY (F) to burn them off.",
}

var gs := GS.INTRO
var world: Node2D
var tint: CanvasModulate
var camera: Camera2D
var light: LightController
var daynight: DayNight
var room: OpenWorld
var hero: Hero
var player: Player
var hud: Hud
var blunders := 0
var follow_player := true
var twist_lines: Array[String] = []   # hero lines replayed in the ending (see TwistSequence)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # we must keep running while paused
	_setup_input()

	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	tint = CanvasModulate.new()
	world.add_child(tint)
	light = LightController.new()
	world.add_child(light)
	daynight = DayNight.new()
	world.add_child(daynight)

	room = WORLD_SCENE.instantiate()
	room.light = light
	room.daynight = daynight
	world.add_child(room)

	hero = HERO_SCENE.instantiate()
	hero.room = room
	hero.light = light
	hero.daynight = daynight
	hero.guide = null   # set below once the player exists
	hero.position = room.hero_start
	world.add_child(hero)
	room.hero = hero

	player = PLAYER_SCENE.instantiate()
	player.light = light
	player.daynight = daynight
	player.position = room.player_start
	world.add_child(player)
	hero.guide = player

	camera = Camera2D.new()
	camera.position = player.position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = OpenWorld.COLS * OpenWorld.TILE
	camera.limit_bottom = OpenWorld.ROWS * OpenWorld.TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	world.add_child(camera)

	hud = Hud.new()
	add_child(hud)

	room.message.connect(func(t: String) -> void: hud.toast(t, 4.5))
	hero.milestone.connect(_on_milestone)
	daynight.time_changed.connect(_on_time_changed)
	room.ambush_cleared.connect(func() -> void: hud.toast("The werewolves burn away in the sunlight!", 3.5))
	player.targets_changed.connect(_refresh_prompts)
	for it in room.items:
		it.pointed.connect(_on_pointed)
	room.gate.pointed.connect(_on_pointed)
	room.log_obstacle.pointed.connect(_on_pointed)

	hud.set_objective("Guide the hero WITHOUT touching him. Lantern lures him; Q points; F flips day/night.")
	_enter_intro()

func _refresh_prompts() -> void:
	hud.set_prompts(
		player.target.get_prompt() if player.target != null else "",
		player.point_target.get_prompt() if player.point_target != null else "")

func _process(_delta: float) -> void:
	tint.color = Color.WHITE.lerp(NIGHT_TINT, daynight.blend)
	hud.set_lantern(light.lantern_on)
	hud.set_time(daynight.is_night, daynight.cooldown_left())
	hud.set_held(hero.held)
	if follow_player:
		camera.position = player.global_position
	_track_hero()

func _track_hero() -> void:
	var xf := get_viewport().get_canvas_transform()
	var sp: Vector2 = xf * hero.global_position
	var vs := Vector2(Hud.W, Hud.H)
	var rect := Rect2(0, 46, vs.x, vs.y - 72)
	if rect.has_point(sp) or gs != GS.PLAYING:
		hud.track_hero(false)
		return
	var c := vs * 0.5
	var d := (sp - c).normalized()
	var p := c
	for i in 60:   # march from centre towards the hero until we leave the safe rect
		var q := p + d * 8.0
		if not rect.grow(-20).has_point(q):
			break
		p = q
	hud.track_hero(true, p, d.angle())

# ------------------------------------------------------------------ states

func _enter_intro() -> void:
	gs = GS.INTRO
	player.active = false
	hud.show_overlay(
		"[center][font_size=40]THE NPC JOB[/font_size]\n\n" +
		"You are the hero's [color=gold]imaginary guide[/color]. He wanders wherever he likes, grabs the wrong\n" +
		"things, and often ignores you. You can't touch him. You can only change the world.\n\n" +
		"[color=gold]SPACE[/color]  lantern on/off: lights hidden things and lures him ('Ooh, shiny!')\n" +
		"[color=gold]E[/color]  interact: examine things, switch lampposts\n" +
		"[color=gold]Q[/color]  point at items and obstacles (he may listen, or not)\n" +
		"[color=gold]F[/color]  magic: flip DAY and NIGHT (night shows hidden things; day burns werewolves)\n" +
		"[color=gold]WASD[/color] move     [color=gold]ESC[/color] pause     [color=gold]R[/color] restart\n\n" +
		"Press [color=gold]E[/color] to begin[/center]")

func _start_game() -> void:
	gs = GS.PLAYING
	hud.hide_overlay()
	player.active = true
	hero.begin()

func _set_paused(on: bool) -> void:
	get_tree().paused = on
	gs = GS.PAUSED if on else GS.PLAYING
	if on:
		hud.show_overlay("[center][font_size=40]PAUSED[/font_size]\n\n[color=gold]ESC[/color] resume      [color=gold]R[/color] restart[/center]")
	else:
		hud.hide_overlay()

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()
		return
	var confirm := event.is_action_pressed("interact") or event.is_action_pressed("confirm")
	match gs:
		GS.INTRO:
			if confirm:
				_start_game()
		GS.PLAYING:
			if event.is_action_pressed("pause"):
				_set_paused(true)
			elif event.is_action_pressed("magic"):
				_cast_magic()
			elif OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
				_debug_key((event as InputEventKey).physical_keycode)
		GS.PAUSED:
			if event.is_action_pressed("pause"):
				_set_paused(false)
		GS.COMPLETE:
			if confirm:
				_play_twist()

## Debug builds only (editor / debug export): F1-F4 warp the hero to a stage, F9 jumps to the ending.
func _debug_key(key: int) -> void:
	var stage := {KEY_F1: 0, KEY_F2: 1, KEY_F3: 2, KEY_F4: 3}.get(key, -1) as int
	if stage >= 1:
		room.gate.solve()
	if stage >= 3:
		room.log_obstacle.solve()
	if stage >= 0:
		hero.debug_warp(stage)
		player.global_position = hero.global_position + Vector2(-60, 40)
		hud.toast("DEBUG: hero warped to stage %d" % stage, 2.0)
	elif key == KEY_F9:
		hero.state = Hero.State.DONE
		_complete()

func _cast_magic() -> void:
	if not daynight.toggle():
		hud.toast("The magic is recharging...", 1.2)

func _on_time_changed(is_night: bool) -> void:
	if gs != GS.PLAYING:
		return
	if is_night:
		hud.toast("NIGHT falls. Hidden things glimmer... and the river's stepping stones surface.", 4.0)
	else:
		hud.toast("DAY breaks. Night-things burn away in the sunlight.", 3.5)

func _on_pointed(target: Node2D) -> void:
	if gs != GS.PLAYING:
		return
	player.bubble.say("Over there, hero!", 1.6)
	hero.hear_point(target)

func _on_milestone(id: String) -> void:
	if gs != GS.PLAYING:
		return
	if BLUNDER_TOASTS.has(id):
		blunders += 1
		hud.set_blunders(blunders)
		hud.toast(BLUNDER_TOASTS[id], 3.5)
	match id:
		"at_gate":
			hud.set_objective("The village gate is locked! Find the KEY (some things only show at night, F), then POINT at it (Q).")
		"unlocked_gate":
			hud.set_objective("He thinks the gate was his idea. Keep him moving east.")
		"at_river":
			hud.set_objective("He can't cross by day. Cast NIGHT (F) so the stepping stones surface. Keep it night until he's across!")
		"crossed":
			hud.set_objective("Across! Night brings werewolves. When they appear, switch to DAY (F) to burn them off.")
		"wolves":
			hud.set_objective("Werewolves gone. Head into the forest: a log blocks the road.")
		"at_log":
			hud.set_objective("A huge log! Find the AXE (a dark hollow, keep the lantern on) and POINT at it (Q).")
		"unlocked_log":
			hud.set_objective("The log is split. Guide him to the Sacred Lamp at the shrine.")
		"lamp":
			hud.set_objective("He dropped the lamp on his own foot. Just get him to the exit.")
		"finished":
			_complete()

func _complete() -> void:
	gs = GS.COMPLETE
	player.active = false
	await get_tree().create_timer(1.6).timeout
	if gs != GS.COMPLETE:
		return
	hud.show_overlay(
		"[center][font_size=40]QUEST COMPLETE![/font_size]\n\n" +
		"The Chosen One has triumphed. (Somehow.)\n" +
		"Blunders committed: " + str(blunders) + "\n" +
		"He thanked his guide the whole way.\n\n" +
		"Press [color=gold]E[/color] to hear what the villagers saw[/center]")

func _play_twist() -> void:
	gs = GS.TWIST
	hud.hide_overlay()
	hud.show_game_ui(false)
	follow_player = false
	var seq := TwistSequence.new()
	add_child(seq)
	twist_lines = seq.replayed
	await seq.play(self)
	gs = GS.END
	hud.show_overlay(
		"[center][font_size=40]THE NPC JOB[/font_size]\n\n" +
		"The villagers saw a man talking to empty air.\n" +
		"[color=gold]The guide who lit his way, pointed him to every key and axe,\n" +
		"and held back the night, was never really there.[/color]\n" +
		"He imagined you. Every instinct he thought was yours was his own.\n\n" +
		"Thanks for playing this vertical slice!\n\n" +
		"Press [color=gold]R[/color] to play again[/center]")

# ------------------------------------------------------------------- input

func _setup_input() -> void:
	var binds := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E], "point": [KEY_Q], "confirm": [KEY_ENTER, KEY_KP_ENTER],
		"light": [KEY_SPACE], "magic": [KEY_F],
		"pause": [KEY_ESCAPE, KEY_P], "restart": [KEY_R],
	}
	for action: String in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in binds[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)
