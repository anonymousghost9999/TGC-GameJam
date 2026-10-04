class_name Bubble
extends Label
## Speech bubble that floats above its parent. Text wraps to at most 3 lines, and the
## bubble is kept fully on screen (and clear of the HUD bars); if there is no room
## above the speaker it drops below them.

const SCREEN := Rect2(6, 50, 948, 462)   # the area a bubble may occupy (clear of the top and bottom bars)
const MAX_W := 250.0
const FONT_SIZE := 13
const PAD := 16.0

@export var rise := 44.0
var _time_left := 0.0

func _init() -> void:
	visible = false
	top_level = true   # ignore the parent's rotation/scale (pratfalls, falling)
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_OFF   # we wrap by hand (deterministic size)
	add_theme_font_size_override("font_size", FONT_SIZE)
	add_theme_color_override("font_color", Color(0.1, 0.08, 0.15))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 0.95, 0.96)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.1, 0.08, 0.15)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	add_theme_stylebox_override("normal", sb)

## Greedy word-wrap of `line` into lines no wider than `inner` px, using the real font metrics.
func _wrap(line: String, inner: float) -> PackedStringArray:
	var font := get_theme_default_font()
	var lines := PackedStringArray()
	var cur := ""
	for word in line.split(" ", false):
		var trial := word if cur == "" else cur + " " + word
		if cur != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > inner:
			lines.append(cur)
			cur = word
		else:
			cur = trial
	if cur != "":
		lines.append(cur)
	return lines

func say(line: String, seconds := 2.6) -> void:
	_time_left = seconds
	var font := get_theme_default_font()
	var one_line := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var wrapped := PackedStringArray([line])
	if one_line > MAX_W - PAD:
		var w := MAX_W - PAD   # try the usual width first, then widen until it fits in 3 lines
		wrapped = _wrap(line, w)
		while wrapped.size() > 3 and w < 420.0:
			w += 16.0
			wrapped = _wrap(line, w)
	text = "\n".join(wrapped)
	var widest := 0.0
	for l in wrapped:
		widest = maxf(widest, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	var width := maxf(widest + PAD, 56.0)
	var height := wrapped.size() * font.get_height(FONT_SIZE) + 8.0   # + the stylebox's top/bottom margins
	custom_minimum_size = Vector2(width, height)
	size = Vector2(width, height)
	visible = true
	_reposition()

func hush() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		visible = false
		return
	_reposition()

func _reposition() -> void:
	var anchor := get_parent() as Node2D
	if anchor == null:
		return
	var a := anchor.global_position
	var x := a.x - size.x * 0.5
	var y := a.y - rise - size.y
	if y < SCREEN.position.y:
		y = a.y + 12.0   # no room above: drop below the speaker
	x = clampf(x, SCREEN.position.x, SCREEN.end.x - size.x)
	y = clampf(y, SCREEN.position.y, SCREEN.end.y - size.y)
	global_position = Vector2(x, y)
