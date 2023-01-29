extends Node

signal unit_selected(unit_x, unit_y)
signal unit_deselected
signal possibilities_changed(possibilities)

const Unit = preload("res://Scripts/Unit.gd")

var units := []
var player_units := []
var enemy_units := []

var selected_unit: Unit setget _set_selected_unit

var player_points := 0
var enemy_points := 0

var possibilities := [] setget _set_possibilities

onready var _client := $Client

enum phase_enum { select_unit, select_cell, movement, resolve }
export(phase_enum) var current_phase = phase_enum.select_unit

onready var selector = $Selector


# Called when the node enters the scene tree for the first time.
func _ready():
	if (len(self.units) == 0):
		_generate_potential_units()
		
	for child in self.get_children():
		if child is Cell:
			child.connect("cell_hovered", self, "_on_cell_hovered")
	self._client.connect("packet_data", self, "_update_state_from_packet")

func _input(event):
	if (event.is_action_pressed("ui_accept")):
		match self.current_phase:
			phase_enum.select_unit:
				for unit in self.player_units:
					if (unit.x == selector.coordinate_vector.x && unit.y == selector.coordinate_vector.y):
						self.selected_unit = unit
						self.current_phase = phase_enum.select_cell
						break
			phase_enum.select_cell:
				var direction = "w"
				match self.selected_unit.coordinate_vector - self.selector.coordinate_vector:
					Vector2(0, -1):
						direction = "w"
					Vector2(1, 0):
						direction = "d"
					Vector2(0, 1):
						direction = "s"
					Vector2(-1, 0):
						direction = "a"
					_:
						return
				self._client._send_packet(self.units, self.player_points, self.enemy_points, self.units.find(selected_unit), direction)
				self.current_phase = phase_enum.movement
				self.selector.visible = false
				self.selected_unit = null
	if (event.is_action_pressed("ui_cancel")):
		match self.current_phase:
			phase_enum.select_cell:
				self.selected_unit = null
				self.current_phase = phase_enum.select_unit
				
func _set_selected_unit(new_unit: Unit):
	selected_unit = new_unit
	if (is_instance_valid(new_unit)):
		emit_signal("unit_selected", new_unit.x, new_unit.y)
	else:
		emit_signal("unit_deselected")

func _generate_potential_units():
	self.player_units.append(Unit.make("Player Rock", 5, 2, 0, 0, 0))
	self.player_units.append(Unit.make("Player Paper", 5, 0, 0, 1, 0))
	self.player_units.append(Unit.make("Player Scissors", 5, 1, 0, 2, 0))
	self.units.append_array(self.player_units)
	self.enemy_units.append(Unit.make("Enemy Rock", 5, 2, 2, 0, 1))
	self.enemy_units.append(Unit.make("Enemy Paper", 5, 0, 2, 1, 1))
	self.enemy_units.append(Unit.make("Enemy Scissors", 5, 1, 2, 2, 1))
	self.units.append_array(self.enemy_units)
	for unit in self.units:
		add_child(unit)
	
func _set_possibilities(new_possibilities: Array):
	possibilities = new_possibilities
	emit_signal("possibilities_changed", new_possibilities)

func resolve_turn(chosen_unit: String, direction: String):
	var chosen_index := -1
	for i in range(len(self.units)):
		if self.units[i].name == chosen_unit:
			chosen_index = i
			break
	self._client._send_packet(self.units, self.player_points, self.enemy_points, chosen_index, direction)
	
func _update_state_from_packet(enemy_unit: Array, player_unit: Array):
	var enemy: Unit
	var player: Unit
	for u in self.units:
		if (u.name == enemy_unit[0]):
			enemy = u as Unit
			break
		if (u.name == player_unit[0]):
			player = u as Unit
			break
	# TODO: play a cool animation
	enemy.hp = int(enemy_unit[1])
	enemy.x = int(enemy_unit[2])
	enemy.y = int(enemy_unit[3])
	player.hp = int(player_unit[1])
	player.x = int(player_unit[2])
	player.y = int(player_unit[3])

func _on_cell_hovered(x: int, y: int):
	selector.coordinate_vector = Vector2(x, y)
