class_name Interactable
extends Node2D
## Anything the player can use with E. Subclasses override interact()/get_prompt().
## Plain props just set `message`, which is shown as a toast.

signal said(text: String)

@export var prompt := "Examine"
@export var message := ""
@export var reach := 44.0
var enabled := true
var pointable := false   # true: used with Q (point); false: used with E (interact)

func _ready() -> void:
	add_to_group("interactable")

func get_prompt() -> String:
	return prompt

func interact(_player: Node) -> void:
	if message != "":
		said.emit(message)

## Optional solid footprint so the hero (and player) bump into the prop.
func add_solid(size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	return body
