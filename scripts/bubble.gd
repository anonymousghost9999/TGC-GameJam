class_name Bubble
extends Label
## Speech bubble that floats above its parent and hides itself after a while.

@export var rise := 44.0
var _time_left := 0.0

func _init() -> void:
	visible = false
	top_level = true   # ignore the parent's rotation/scale (pratfalls, falling)
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 13)
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

func say(line: String, seconds := 2.6) -> void:
	text = line
	_time_left = seconds
	visible = true
	reset_size()
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
	if anchor != null:
		global_position = anchor.global_position + Vector2(-size.x * 0.5, -rise - size.y)
