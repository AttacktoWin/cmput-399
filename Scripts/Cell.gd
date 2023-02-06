class_name Cell
extends Area2D

signal cell_hovered(x, y)

enum state { default, threatened, movement }
export (state) var current_state = state.default setget _state_changed

enum directions { down = 0, left = 1, up = 2, right = 3 }

export var x: int
export var y: int
var nbrs: Array

onready var sprite = $AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	self.nbrs = [
		[self.x, self.y - 1],
		[self.x + 1, self.y],
		[self.x, self.y + 1],
		[self.x - 1, self.y]
	]
	self.position.x = self.x * 100
	self.position.y = self.y * 100
	connect("mouse_entered", self, "_on_mouse_entered")
	var state = get_parent()
	if (is_instance_valid(state)):
		state.connect("unit_selected", self, "_on_unit_selected")
		state.connect("unit_deselected", self, "_on_unit_deselected")
		

func _state_changed(new_state):
	match new_state:
		state.default:
			sprite.animation = "default"
		state.threatened:
			sprite.animation = "threatened"
		state.movement:
			sprite.animation = "movement"
	current_state = new_state

func _on_unit_selected(unit_x: int, unit_y: int):
	var player_units := []
	var state_node := get_parent()
	if is_instance_valid(state_node):
		player_units = state_node.get_player_units()
	if ([unit_x, unit_y] in self.nbrs):
		for unit in player_units:
			if (unit.x == self.x && unit.y == self.y):
				return
		self.current_state = state.movement
		
func _on_unit_deselected():
	if (self.current_state == state.movement):
		self.current_state = state.default
		
func _on_cell_hovered(cell_x: int, cell_y: int):
	if (!(cell_x == self.x && cell_y == self.y) && !([cell_x, cell_y] in self.nbrs)):
		if (self.current_state == state.threatened):
			self.current_state = state.default
		return
	var enemies := []
	var state_node := get_parent()
	if is_instance_valid(state_node):
		enemies = state_node.get_enemy_units()
		
	if (cell_x == self.x && cell_y == self.y):
		var possibilities := []
		for enemy in enemies:
			if (enemy.x == cell_x && enemy.y == cell_y):
				self.current_state = state.threatened
				possibilities.append("{i}. Battle if {name} does not move".format({
					"i": len(possibilities) + 1,
					"name": enemy.unit_name
				}))
				continue
			if ([enemy.x, enemy.y] in self.nbrs):
				self.current_state = state.threatened
				possibilities.append("{i}. Battle if {name} moves {direction}".format({
					"i": len(possibilities) + 1,
					"name": enemy.unit_name,
					"direction": str(directions.keys()[self.nbrs.find([enemy.x, enemy.y])])
				}))
				
		if (len(possibilities) == 0):
			possibilities.append("No battles.")
		if is_instance_valid(state_node):
			state_node.possibilities = possibilities
	else:
		for enemy in enemies:
			if (enemy.x == cell_x && enemy.y == cell_y):
				# enemy is neighbour
				self.current_state = state.threatened
				return
				
		self.current_state = state.default
		
		
func _on_mouse_entered():
	emit_signal("cell_hovered", self.x, self.y)
