class_name Hud
extends CanvasLayer
## Minimal HUD: level name + deaths, one hint line, the lamp prompt, the invert-lantern
## meter, plus the title screen, the level-name banner, the controls panel ([Tab]),
## the invert-lantern card, overlays (cards), death flash, fade and letterbox.

const W := 960.0
const H := 544.0
const CONTROLS := [
	["WASD / Arrows", "move"], ["E", "switch the nearest lamp / continue"], ["Q", "invert lantern"],
	["H", "hint"], ["Esc / P", "pause"], ["R", "restart level"], ["M", "mute"], ["Tab", "show / hide this list"],
]
const RULES := [
	[LampColors.C.GREEN, "he walks to it"], [LampColors.C.RED, "he runs away from it"],
	[LampColors.C.ORANGE, "he creeps slowly to it"], [LampColors.C.BLUE, "he freezes"],
]

var _title: Label
var _deaths: Label
var _hint: Label
var _invert: Label
var _prompt: Label
var _controls_tip: Label
var _top_bar: ColorRect
var _banner: Label
var _controls: PanelContainer
var _title_screen: TitleScreen
var _invert_card: InvertCard
var _lamp_card: LampCard
var _overlay: ColorRect
var _overlay_text: RichTextLabel
var _flash: ColorRect
var _fade: ColorRect
var _bar_top: ColorRect
var _bar_bot: ColorRect
var _game_ui: Array[CanvasItem] = []

func _ready() -> void:
	layer = 10
	_top_bar = _rect(Vector2(0, 0), Vector2(W, 46), Color(0, 0, 0, 0.62))
	_title = _label(Vector2(10, 4), 18, Color(1.0, 0.95, 0.7))
	_deaths = _label(Vector2(W - 150, 4), 18, Color(1.0, 0.6, 0.5))
	_hint = _label(Vector2(10, 25), 15, Color(0.85, 0.9, 1.0))
	_invert = _label(Vector2(W - 330, 25), 15, Color(0.8, 0.7, 1.0))
	_invert.size = Vector2(320, 18)
	_invert.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_controls_tip = _label(Vector2(W - 170, H - 22), 15, Color(0.85, 0.85, 0.95, 0.75), 3)
	_controls_tip.text = "[Tab] controls"
	_prompt = _label(Vector2(0, H - 60), 20, Color(1.0, 0.9, 0.4), 4)
	_prompt.size = Vector2(W, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner = _label(Vector2(0, 200), 44, Color(1.0, 0.92, 0.6), 10)
	_banner.size = Vector2(W, 120)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	_game_ui = [_top_bar, _title, _deaths, _hint, _invert, _controls_tip, _prompt]
	_title_screen = TitleScreen.new()
	_title_screen.visible = false
	add_child(_title_screen)
	_overlay = _rect(Vector2.ZERO, Vector2(W, H), Color(0.03, 0.02, 0.08, 0.86))
	_overlay_text = RichTextLabel.new()
	_overlay_text.bbcode_enabled = true
	_overlay_text.position = Vector2(80, 36)
	_overlay_text.size = Vector2(W - 160, H - 72)
	_overlay_text.add_theme_font_size_override("normal_font_size", 19)
	_overlay_text.add_theme_font_size_override("bold_font_size", 19)
	_overlay_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_overlay_text)
	_overlay.visible = false
	_invert_card = InvertCard.new()
	add_child(_invert_card)
	_lamp_card = LampCard.new()
	add_child(_lamp_card)
	_controls = _build_controls()
	_flash = _rect(Vector2.ZERO, Vector2(W, H), Color(1, 0.1, 0.1, 0))
	_bar_top = _rect(Vector2(0, -60), Vector2(W, 60), Color.BLACK)
	_bar_bot = _rect(Vector2(0, H), Vector2(W, 60), Color.BLACK)
	_fade = _rect(Vector2.ZERO, Vector2(W, H), Color(0, 0, 0, 0))

func _rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _label(pos: Vector2, font_size: int, col: Color, outline := 0, parent: Node = null) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(l)
	return l

## The [Tab] panel: one key cap and what it does per row.
func _build_controls() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.14, 0.96)
	sb.border_color = Color(1.0, 0.85, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 36)
	panel.add_child(cols)
	# left: the keys
	var keys := _section(cols, "CONTROLS")
	var cap := StyleBoxFlat.new()
	cap.bg_color = Color(0.85, 0.82, 0.9)
	cap.set_corner_radius_all(5)
	cap.border_color = Color(0.45, 0.42, 0.55)
	cap.border_width_bottom = 3
	cap.set_content_margin_all(4)
	cap.content_margin_left = 10
	cap.content_margin_right = 10
	for row in CONTROLS:
		var k := _label(Vector2.ZERO, 14, Color(0.1, 0.08, 0.15), 0, keys)
		k.text = row[0]
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		k.add_theme_stylebox_override("normal", cap)
		_row_text(keys, row[1])
	# right: what the lamps and the lantern do
	var rules := _section(cols, "LAMPS")
	var near := LampIcon.new()
	near.color = LampColors.C.GREEN
	near.nearest = true
	rules.add_child(near)
	_row_text(rules, "he obeys only the NEAREST\nlit lamp, nothing else")
	for row in RULES:
		var icon := LampIcon.new()
		icon.color = row[0]
		rules.add_child(icon)
		_row_text(rules, row[1])
	var lin := LampIcon.new()
	lin.color = LampColors.C.GREEN
	lin.pair = true
	rules.add_child(lin)
	_row_text(rules, "same colour = linked:\nE swaps every one of them")
	var lantern := LanternIcon.new()
	rules.add_child(lantern)
	_row_text(rules, "Q: lamps swap to their opposite\n5 sec on, then 5 sec to recharge")
	panel.visible = false
	add_child(panel)
	panel.reset_size()
	panel.position = (Vector2(W, H) - panel.size) * 0.5
	return panel

## A titled two-column grid inside `parent`.
func _section(parent: Node, title: String) -> GridContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	var head := _label(Vector2.ZERO, 22, Color(1.0, 0.9, 0.5), 0, box)
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 9)
	box.add_child(grid)
	return grid

func _row_text(grid: GridContainer, text: String) -> void:
	var a := _label(Vector2.ZERO, 15, Color(0.92, 0.9, 1.0), 0, grid)
	a.text = text
	a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

## A small lit lamp bulb for the [Tab] panel (two linked bulbs when `pair`).
class LampIcon extends Control:
	var color := 0
	var pair := false
	var nearest := false
	func _init() -> void:
		custom_minimum_size = Vector2(56, 30)
	func _draw() -> void:
		var c := LampColors.rgb(color)
		if nearest:   # a near lit lamp (bright) beats a far one (dim)
			DrawUtil.glow(self, Vector2(10, 15), 14.0, Color(c.r, c.g, c.b, 0.6), 4)
			Lamp.draw_bulb(self, Vector2(10, 15), c, color, true, 0.75)
			draw_circle(Vector2(26, 15), 3.0, Color.WHITE)
			Lamp.draw_bulb(self, Vector2(48, 15), c.darkened(0.4), color, true, 0.6)
		elif pair:
			draw_line(Vector2(14, 15), Vector2(42, 15), Color(1, 1, 1, 0.6), 2.0)
			Lamp.draw_bulb(self, Vector2(14, 15), c, color, true, 0.9)
			Lamp.draw_bulb(self, Vector2(42, 15), c, color, false, 0.9)
		else:
			DrawUtil.glow(self, Vector2(28, 15), 18.0, Color(c.r, c.g, c.b, 0.5), 4)
			Lamp.draw_bulb(self, Vector2(28, 15), c, color, true, 1.0)

class LanternIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(56, 36)
	func _draw() -> void:
		DrawUtil.glow(self, Vector2(28, 18), 18.0, Color(0.85, 0.6, 1.0, 0.6), 4)
		Sprites.draw_lantern(self, Vector2(28, 18), 1.5, Color(0.85, 0.6, 1.0))

# -------------------------------------------------------------------- API

func set_level(num: int, title := "") -> void:
	_title.text = "LEVEL %d" % num if num > 0 else title

func set_hint(text: String) -> void:
	_hint.text = text
	_hint.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0) if text != "[H] hint" else Color(0.55, 0.6, 0.7))

func hint_text() -> String:
	return _hint.text

func set_deaths(n: int) -> void:
	_deaths.text = "DEATHS %d" % n

func set_invert(unlocked: bool, active: bool, remaining: float, cooldown: float) -> void:
	if not unlocked:
		_invert.text = ""
	elif active:
		_invert.text = "LANTERN LIT  %d SEC" % ceili(remaining)
		_invert.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	elif cooldown > 0.0:
		_invert.text = "LANTERN RECHARGING  %d SEC" % ceili(cooldown)
		_invert.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	else:
		_invert.text = "LANTERN  [Q]"
		_invert.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))

func set_prompt(text: String) -> void:
	_prompt.text = text

## The level's name, big, for a moment (no description: the level teaches itself).
func banner(num: int, title := "", seconds := 1.6) -> void:
	_banner.text = ("LEVEL %d" % num) if num > 0 else title
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)

func show_title(on: bool) -> void:
	_title_screen.visible = on

## The pop-up for a new lamp or rule ("invert" is the lantern's own card).
func show_card(kind: String) -> void:
	if kind == "invert":
		_invert_card.visible = true
	else:
		_lamp_card.show_kind(kind)

func hide_cards() -> void:
	_invert_card.visible = false
	_lamp_card.visible = false

func card_visible() -> bool:
	return _invert_card.visible or _lamp_card.visible

func toggle_controls() -> void:
	_controls.visible = not _controls.visible

func controls_visible() -> bool:
	return _controls.visible

func show_overlay(bbcode: String) -> void:
	_overlay_text.text = bbcode
	_overlay.visible = true

func hide_overlay() -> void:
	_overlay.visible = false

func show_game_ui(on: bool) -> void:
	for n in _game_ui:
		n.visible = on

func letterbox(on: bool, seconds := 0.5) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bar_top, "position:y", 0.0 if on else -60.0, seconds)
	tw.tween_property(_bar_bot, "position:y", H - 60.0 if on else H, seconds)

func fade_to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, seconds)
	await tw.finished

func flash(color: Color, seconds := 0.6) -> void:
	_flash.color = Color(color.r, color.g, color.b, 0.55)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, seconds)
