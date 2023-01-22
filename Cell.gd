class_name Cell
extends Area2D

enum state { none, threatened, movement }
export (state) var current_state = state.none

var x: int
var y: int
var nbrs: Array

onready var sprite = $AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _init(x: int, y: int):
	self.x = x
	self.y = y
	self.nbrs = [
		[self.x, self.y + 1],
		[self.x + 1, self.y],
		[self.x, self.y - 1],
		[self.x - 1, self.y]
	]

func state_changed():
	match self.current_state:
		state.none:
			sprite.animation = "default"
		state.threatened:
			sprite.animation = "threatened"
		state.movement:
			sprite.animation = "movement"

func _on_unit_select(unit_x: int, unit_y: int):
	if ([unit_x, unit_y] in self.nbrs):
		self.current_state = state.threatened
		self.state_changed()
