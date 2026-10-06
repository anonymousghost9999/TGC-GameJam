class_name Sprites
extends RefCounted
## CC0 pixel art (see CREDITS.md): Kenney "Tiny Dungeon" (16x16 tiles, 12 per row),
## Kenney "Tiny Creatures" (the ogre) and an oil lamp / candle-stand sheet (the lantern
## and the lamp stands). Helpers to draw them into any CanvasItem.

const SHEET := preload("res://assets/sprites/tiny_dungeon.png")
const CREATURES := preload("res://assets/sprites/tiny_creatures.png")
const LAMPS := preload("res://assets/sprites/lamps.png")
const OGRE_RECT := Rect2(32, 64, 16, 16)        # Tiny Creatures #42: the ogre (10 per row)
const LANTERN_RECT := Rect2(56, 3, 16, 22)      # the oil lamp's glass and flame (no stand)
const STAND_RECT := Rect2(93, 27, 14, 14)       # a slim brass stand (the candle removed)
const CELL := 16
const COLS := 12

# tile indices in tiny_dungeon.png
const FLOOR := 48
const FLOOR_ALT := [48, 48, 49, 48, 48, 48, 48]
const FLOOR_OUT := 0      # prologue: dirt outside the dungeon
const FLOOR_OUT_ALT := 12
const WALL := 40
const SPIKES := 41
const DOOR_CLOSED := 45
const DOOR_OPEN := 21
const HERO := 96          # knight
const NPC := 84           # wizard
const DEMON := 110        # the Demon Lord's true form

static func region(i: int) -> Rect2:
	return Rect2((i % COLS) * CELL, (i / COLS) * CELL, CELL, CELL)

## Draw sheet cell `i` scaled `k` times, its bottom-centre at `foot` (characters, props).
static func draw_at_foot(ci: CanvasItem, i: int, foot: Vector2, k: float, mod := Color.WHITE) -> void:
	var s := CELL * k
	ci.draw_texture_rect_region(SHEET, Rect2(foot.x - s * 0.5, foot.y - s, s, s), region(i), mod)

## Draw sheet cell `i` filling `rect` (tiles).
static func draw_cell(ci: CanvasItem, i: int, rect: Rect2, mod := Color.WHITE) -> void:
	ci.draw_texture_rect_region(SHEET, rect, region(i), mod)

## The sleeping ogre, feet at `foot`; `breath` (0..1) swells his chest a little.
static func draw_ogre(ci: CanvasItem, foot: Vector2, k: float, breath: float, mod := Color.WHITE) -> void:
	var s := 16.0 * k
	var sw := s * (1.0 + 0.05 * breath)
	var sh := s * (1.0 - 0.03 * breath)
	ci.draw_texture_rect_region(CREATURES, Rect2(foot.x - sw * 0.5, foot.y - sh, sw, sh), OGRE_RECT, mod)

## The NPC's hand lantern, its glass tinted by `glass` (white = as drawn).
static func draw_lantern(ci: CanvasItem, center: Vector2, k: float, glass := Color.WHITE) -> void:
	var sz := LANTERN_RECT.size * k
	ci.draw_texture_rect_region(LAMPS, Rect2(center - sz * 0.5, sz), LANTERN_RECT, glass)

## A lamp's brass stand, its top at `top`.
static func draw_stand(ci: CanvasItem, top: Vector2, k: float, mod := Color.WHITE) -> void:
	var sz := STAND_RECT.size * k
	ci.draw_texture_rect_region(LAMPS, Rect2(top.x - sz.x * 0.5, top.y, sz.x, sz.y), STAND_RECT, mod)
