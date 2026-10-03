class_name Hud
extends CanvasLayer
## All UI is built in code: objective, status row (blunders, hero's item, time of
## day, lantern), interaction prompt, toasts, captions, overlays, letterbox bars,
## and an arrow pointing at the hero when he wanders off-screen.

const W := 960.0
const H := 544.0

var _objective: Label
var _status: Array[Label] = []
var _prompt: Label
var _toast: Label
var _caption: Label
var _overlay: ColorRect
var _overlay_text: RichTextLabel
var _bar_top: ColorRect
var _bar_bot: ColorRect
var _fade: ColorRect
var _toast_left := 0.0
var _game_ui: Array[Control] = []
var _arrow: Control
var _arrow_pos := Vector2.ZERO
var _arrow_ang := 0.0
var _arrow_on := false

func _ready() -> void:
	layer = 10
	_arrow = Control.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)
	_game_ui.append(_arrow)
	_game_ui.append(_rect(Vector2(0, 0), Vector2(W, 46), Color(0, 0, 0, 0.62)))
	_game_ui.append(_rect(Vector2(0, H - 26), Vector2(W, 26), Color(0, 0, 0, 0.62)))
	_objective = _label(Vector2(10, 3), 14, Color(1.0, 0.95, 0.7), 0)
	_game_ui.append(_objective)
	for i in 4:
		var l := _label(Vector2(10 + i * 235, 25), 13, Color.WHITE, 0)
		_status.append(l)
		_game_ui.append(l)
	set_blunders(0)
	set_held("")
	set_time(false, 0.0)
	set_lantern(true)
	var controls := _label(Vector2(0, H - 22), 12, Color(0.85, 0.85, 0.95), 0)
	controls.size = Vector2(W, 20)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.text = "WASD move   E interact   Q point   SPACE lantern   F day-night magic   ESC pause   R restart"
	_game_ui.append(controls)
	_prompt = _label(Vector2(0, H - 60), 16, Color(1.0, 0.85, 0.35), 4)
	_prompt.size = Vector2(W, 24)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_ui.append(_prompt)
	_toast = _label(Vector2((W - 700) / 2.0, 56), 17, Color.WHITE, 5)
	_toast.custom_minimum_size = Vector2(700, 0)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.16, 0.85)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_toast.add_theme_stylebox_override("normal", sb)
	_toast.visible = false
	_caption = _label(Vector2((W - 800) / 2.0, H - 118), 20, Color(1, 1, 1), 5)
	_caption.custom_minimum_size = Vector2(800, 0)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.visible = false
	_bar_top = _rect(Vector2(0, -60), Vector2(W, 60), Color.BLACK)
	_bar_bot = _rect(Vector2(0, H), Vector2(W, 60), Color.BLACK)
	_fade = _rect(Vector2.ZERO, Vector2(W, H), Color(0, 0, 0, 0))
	_overlay = _rect(Vector2.ZERO, Vector2(W, H), Color(0.03, 0.02, 0.08, 0.84))
	_overlay_text = RichTextLabel.new()
	_overlay_text.bbcode_enabled = true
	_overlay_text.position = Vector2(80, 30)
	_overlay_text.size = Vector2(W - 160, H - 60)
	_overlay_text.add_theme_font_size_override("normal_font_size", 18)
	_overlay_text.add_theme_font_size_override("bold_font_size", 18)
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

func _label(pos: Vector2, font_size: int, col: Color, outline: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_toast.visible = false
	_arrow.queue_redraw()

func _draw_arrow() -> void:
	if not _arrow_on:
		return
	var p := _arrow_pos
	var d := Vector2.from_angle(_arrow_ang)
	var n := d.rotated(PI * 0.5)
	_arrow.draw_colored_polygon(PackedVector2Array([p + d * 14, p - d * 10 + n * 10, p - d * 10 - n * 10]), Color(1.0, 0.35, 0.3))
	_arrow.draw_string(ThemeDB.fallback_font, p - d * 30 + Vector2(-16, 4), "HERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))

# -------------------------------------------------------------------- API

## screen_pos is in HUD (960x544) space; pass off=false when the hero is visible.
func track_hero(off: bool, screen_pos := Vector2.ZERO, angle := 0.0) -> void:
	_arrow_on = off
	_arrow_pos = screen_pos
	_arrow_ang = angle

func set_objective(text: String) -> void:
	_objective.text = "OBJECTIVE: " + text

func set_blunders(n: int) -> void:
	_status[0].text = "HERO BLUNDERS: %d" % n
	_status[0].add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))

func set_held(kind: String) -> void:
	_status[1].text = "HERO HOLDS: %s" % (kind if kind != "" else "nothing")
	_status[1].add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))

func set_time(night: bool, cooldown: float) -> void:
	var t := "NIGHT" if night else "DAY"
	_status[2].text = "TIME: %s%s" % [t, "  (recharging %.0fs)" % ceilf(cooldown) if cooldown > 0.0 else "  [F to flip]"]
	_status[2].add_theme_color_override("font_color", Color(0.7, 0.8, 1.0) if night else Color(1.0, 0.9, 0.5))

func set_lantern(on: bool) -> void:
	_status[3].text = "LANTERN: ON" if on else "LANTERN: OFF"
	_status[3].add_theme_color_override("font_color", Color(1.0, 0.9, 0.4) if on else Color(0.6, 0.6, 0.65))

func set_prompts(e_text: String, q_text: String) -> void:
	var parts: Array[String] = []
	if e_text != "":
		parts.append("[E] " + e_text)
	if q_text != "":
		parts.append("[Q] " + q_text)
	_prompt.text = "      ".join(parts)

func toast(text: String, seconds := 3.5) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.reset_size()
	_toast.position.x = (W - _toast.size.x) / 2.0
	_toast_left = seconds

func caption(text: String) -> void:
	_caption.visible = text != ""
	_caption.text = text
	_caption.reset_size()
	_caption.position = Vector2((W - _caption.size.x) / 2.0, H - 70 - _caption.size.y)

func show_overlay(bbcode: String) -> void:
	_overlay_text.text = bbcode
	_overlay.visible = true

func hide_overlay() -> void:
	_overlay.visible = false

func show_game_ui(on: bool) -> void:
	for n in _game_ui:
		n.visible = on

func letterbox(on: bool, seconds := 0.6) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bar_top, "position:y", 0.0 if on else -60.0, seconds)
	tw.tween_property(_bar_bot, "position:y", H - 60.0 if on else H, seconds)

func fade_to(alpha: float, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, seconds)
	await tw.finished
