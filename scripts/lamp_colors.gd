class_name LampColors
extends RefCounted
## The four lamp colors, their familiar meaning, and the inversion mapping.
##   GREEN  go      -> hero moves TOWARD the lamp
##   RED    stop    -> hero moves AWAY from the lamp
##   ORANGE caution -> hero moves SLOWLY toward the lamp
##   BLUE   freeze  -> hero freezes
## Inversion: GREEN <-> RED, BLUE <-> ORANGE.

enum C { GREEN, RED, ORANGE, BLUE }

const NAMES := ["GREEN", "RED", "ORANGE", "BLUE"]
const RGB := [Color(0.20, 0.90, 0.35), Color(0.96, 0.18, 0.22), Color(1.0, 0.62, 0.10), Color(0.28, 0.58, 1.0)]

static func invert(c: int) -> int:
	match c:
		C.GREEN: return C.RED
		C.RED: return C.GREEN
		C.ORANGE: return C.BLUE
		_: return C.ORANGE

static func rgb(c: int) -> Color:
	return RGB[c]

static func label(c: int) -> String:
	return NAMES[c]

## Map letters: g r o b (off) / G R O B (on).
static func from_char(ch: String) -> int:
	match ch.to_lower():
		"g": return C.GREEN
		"r": return C.RED
		"o": return C.ORANGE
		_: return C.BLUE
