class_name DrawUtil
extends RefCounted
## Tiny helpers for the code-drawn placeholder art.

static func ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, color)

## Soft glow built from stacked translucent circles (cheap, no shaders).
static func glow(ci: CanvasItem, center: Vector2, radius: float, color: Color, steps := 6) -> void:
	for i in steps:
		var k := float(i + 1) / steps
		var c := color
		c.a = color.a / steps
		ci.draw_circle(center, radius * (1.0 - k * 0.75) + 2.0, c)

static var _light_tex: Texture2D

## Soft radial texture for PointLight2D (built once).
static func light_texture() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_light_tex = t
	return _light_tex

static func make_point_light(radius: float, color: Color) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.texture_scale = radius * 2.0 / 256.0
	l.color = color
	l.energy = 0.0
	return l
