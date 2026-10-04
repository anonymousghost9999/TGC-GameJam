class_name Hud
extends CanvasLayer
## Minimal HUD: level + timer + deaths, one hint line, the lamp prompt, the
## invert-lantern meter, plus overlays (cards), death flash, fade and letterbox.

const W := 960.0
const H := 544.0

var _title: Label
var _timer: Label
var _deaths: Label
var _hint: Label
var _invert: Label
var _prompt: Label
var _controls: Label
var _top_bar: ColorRect
var _bottom_bar: ColorRect
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
	_bottom_bar = _rect(Vector2(0, H - 24), Vector2(W, 24), Color(0, 0, 0, 0.62))
	_title = _label(Vector2(10, 3), 15, Color(1.0, 0.95, 0.7))
	_timer = _label(Vector2(0, 3), 15, Color.WHITE)
	_timer.size = Vector2(W, 20)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deaths = _label(Vector2(W - 150, 3), 15, Color(1.0, 0.6, 0.5))
	_hint = _label(Vector2(10, 24), 13, Color(0.85, 0.9, 1.0))
	_invert = _label(Vector2(W - 260, 24), 13, Color(0.8, 0.7, 1.0))
	_invert.size = Vector2(250, 18)
	_invert.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_controls = _label(Vector2(0, H - 20), 12, Color(0.85, 0.85, 0.95))
	_controls.size = Vector2(W, 18)
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls.text = "WASD move    E switch lamp    Q invert lantern    H hint    Esc pause    R restart level    M mute"
	_prompt = _label(Vector2(0, H - 58), 17, Color(1.0, 0.9, 0.4), 4)
	_prompt.size = Vector2(W, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_ui = [_top_bar, _bottom_bar, _title, _timer, _deaths, _hint, _invert, _controls, _prompt]
	_flash = _rect(Vector2.ZERO, Vector2(W, H), Color(1, 0.1, 0.1, 0))
	_bar_top = _rect(Vector2(0, -60), Vector2(W, 60), Color.BLACK)
	_bar_bot = _rect(Vector2(0, H), Vector2(W, 60), Color.BLACK)
	_fade = _rect(Vector2.ZERO, Vector2(W, H), Color(0, 0, 0, 0))
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

func _rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _label(pos: Vector2, font_size: int, col: Color, outline := 0) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

# -------------------------------------------------------------------- API

func set_level(num: int, title: String) -> void:
	_title.text = "LEVEL %d  %s" % [num, title] if num > 0 else title

func set_hint(text: String) -> void:
	_hint.text = text
	_hint.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0) if text != "[H] hint" else Color(0.55, 0.6, 0.7))

func hint_text() -> String:
	return _hint.text

static func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%d:%02d" % [s / 60, s % 60]

func set_timer(t: float, par: float) -> void:
	if par > 0.0:
		_timer.text = "TIME %s  /  PAR %s" % [fmt_time(t), fmt_time(par)]
		_timer.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if t <= par else Color(1.0, 0.7, 0.4))
	else:
		_timer.text = ""

func set_deaths(n: int) -> void:
	_deaths.text = "DEATHS %d" % n

func set_invert(unlocked: bool, active: bool, remaining: float, cooldown: float) -> void:
	if not unlocked:
		_invert.text = ""
	elif active:
		_invert.text = "INVERT ACTIVE  %.1fs" % remaining
		_invert.add_theme_color_override("font_color", Color(0.85, 0.6, 1.0))
	elif cooldown > 0.0:
		_invert.text = "INVERT recharging  %.0fs" % ceilf(cooldown)
		_invert.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	else:
		_invert.text = "INVERT READY  [Q]"
		_invert.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))

func set_prompt(text: String) -> void:
	_prompt.text = text

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
