class_name Cell
extends Area2D

signal cell_hovered(x, y)

enum state { default, threatened, movement }
export (state) var current_state = state.default setget _state_changed
export var threatened: bool setget _set_threatened

enum directions { down = 0, left = 1, up = 2, right = 3 }

export var x: int
export var y: int
var nbrs: Array

onready var sprite = $AnimatedSprite
onready var tween = $Tween

var ghost : Unit = null

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite.material = sprite.material.duplicate(true)
	self.nbrs = [
		[self.x, self.y - 1],
		[self.x + 1, self.y],
		[self.x, self.y + 1],
		[self.x - 1, self.y]
	]
	self.position.x = self.x * 100 + 400
	self.position.y = self.y * 100 + 200
	connect("mouse_entered", self, "_on_mouse_entered")
	var state = get_parent()
	if (is_instance_valid(state)):
		state.connect("unit_selected", self, "_on_unit_selected")
		state.connect("unit_deselected", self, "_on_unit_deselected")
		

func _state_changed(new_state):
	match new_state:
		state.default:
			sprite.animation = "default"
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
		for child in $CanvasLayer.get_children():
			child.queue_free()
		ghost = null
		
func _on_cell_hovered(cell_x: int, cell_y: int):
	if (!(cell_x == self.x && cell_y == self.y) && !([cell_x, cell_y] in self.nbrs)):
		for child in $CanvasLayer.get_children():
			child.queue_free()
		ghost = null
		if (State.selected_unit != null && [State.selected_unit.x, State.selected_unit.y] in self.nbrs):
			var changed := false
			for unit in State.get_player_units():
				if (unit.x == self.x && unit.y == self.y):
					self.current_state = state.default
					self.threatened = false
					return
			self.current_state = state.movement
			self.threatened = false
		else:
			self.current_state = state.default
			self.threatened = false
			return
		
	var enemies = State.get_enemy_units()
		
	if (cell_x == self.x && cell_y == self.y):
		var possibilities := []
		for enemy in enemies:
			if (enemy.x == cell_x && enemy.y == cell_y):
				self.threatened = true
				possibilities.append("{i}. Battle if {name} does not move".format({
					"i": len(possibilities) + 1,
					"name": enemy.unit_name
				}))
				continue
			if ([enemy.x, enemy.y] in self.nbrs):
				self.threatened = true
				possibilities.append("{i}. Battle if {name} moves {direction}".format({
					"i": len(possibilities) + 1,
					"name": enemy.unit_name,
					"direction": str(directions.keys()[self.nbrs.find([enemy.x, enemy.y])])
				}))
				
		if (len(possibilities) == 0):
			self.threatened = false
			possibilities.append("No battles.")
		State.possibilities = possibilities
	elif ([cell_x, cell_y] in self.nbrs):
		for child in $CanvasLayer.get_children():
			child.queue_free()
		ghost = null
		for enemy in enemies:
			if (enemy.x == cell_x && enemy.y == cell_y):
				# enemy is neighbour
				self.threatened = true
				return
			
		if (State.selected_unit != null && [State.selected_unit.x, State.selected_unit.y] in self.nbrs):
			self.threatened = false
			for unit in State.get_player_units():
				if (unit.x == self.x && unit.y == self.y):
					self.current_state = state.default
					return
				self.current_state = state.movement
		else:
			self.threatened = false
			self.current_state = state.default
			
	if (self.current_state == state.movement && cell_x == self.x && cell_y == self.y):
		self.ghost = State.selected_unit.duplicate()
		$CanvasLayer.add_child(ghost)
		self.ghost.coordinate_vector = Vector2(self.x, self.y)
		call_deferred("_set_ghost_transparency")
	else:
		for child in $CanvasLayer.get_children():
			child.queue_free()
		ghost = null
			
func _set_ghost_transparency():
	ghost.sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
		
func _set_threatened(is_threatened: bool):
	threatened = is_threatened
	sprite.material.set_shader_param("shader_on", is_threatened)
		
func _on_mouse_entered():
	if (State.current_phase != State.phase_enum.select_unit && State.current_phase != State.phase_enum.select_cell):
		return
	emit_signal("cell_hovered", self.x, self.y)
