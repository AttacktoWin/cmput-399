extends Node2D

signal unit_selected(unit_x, unit_y)
signal unit_deselected
signal possibilities_changed(possibilities)

const Unit = preload("res://Scripts/Unit.gd")

onready var units_node = $Units

var selected_unit: Unit setget _set_selected_unit

var player_points := 0
var enemy_points := 0

var possibilities := [] setget _set_possibilities

onready var _client := $Client

enum phase_enum { connecting, select_unit, select_cell, movement, resolve, win }
export(phase_enum) var current_phase = phase_enum.connecting

onready var selector = $Selector
onready var selected_indicator = $SelectedIndicator
onready var panel = $Panel
onready var unit_panel = $UnitPanel


# Called when the node enters the scene tree for the first time.
func _ready():
	if (self.units_node.get_child_count() == 0):
		_generate_potential_units()
		
	for child in self.get_children():
		if child is Cell:
			child.connect("cell_hovered", self, "_on_cell_hovered")
			child.connect("cell_hovered", unit_panel, "_on_cell_hovered")
			# Change cell hovered using keyboard controls
			selector.connect("cell_hovered", child, "_on_cell_hovered")
	selector.connect("cell_hovered", unit_panel, "_on_cell_hovered")
	self._client.connect("packet_data", self, "_update_state_from_packet")
	self._client.connect("client_connected", self, "_on_client_connected")
	connect("possibilities_changed", self.panel, "_on_possibilities_changed")

func _input(event):
	if (event.is_action_pressed("accept")):
		match self.current_phase:
			phase_enum.select_unit:
				for unit in self.get_player_units():
					if (unit.x == selector.coordinate_vector.x && unit.y == selector.coordinate_vector.y):
						self.selected_unit = unit
						selected_indicator.rect_position = Vector2(100* unit.x - 32, 100 * unit.y - 96)
						selected_indicator.visible = true
						self.current_phase = phase_enum.select_cell
						break
			phase_enum.select_cell:
				for unit in self.get_player_units():
					if (unit.x == selector.coordinate_vector.x && unit.y == selector.coordinate_vector.y):
						# Don't allow the player to fight themselves
						return
				var direction = "w"
				match self.selected_unit.coordinate_vector - self.selector.coordinate_vector:
					Vector2(0, 1):
						direction = "w"
					Vector2(-1, 0):
						direction = "d"
					Vector2(0, -1):
						direction = "s"
					Vector2(1, 0):
						direction = "a"
					_:
						return
				print(direction)
				self._client._send_packet(self.units_node.get_children(), self.player_points, self.enemy_points, self.units_node.get_children().find(selected_unit), direction)
				self.current_phase = phase_enum.movement
				self.selector.visible = false
				self.selected_unit = null
	if (event.is_action_pressed("cancel")):
		match self.current_phase:
			phase_enum.select_cell:
				self.selected_unit = null
				self.selected_indicator.visible = false
				self.current_phase = phase_enum.select_unit
			
			
func _set_study_id(id: String):
	self._client.study_id = id
		
func _on_client_connected():
	self.current_phase = phase_enum.select_unit
	$ConnectingText.queue_free()
				
func _set_selected_unit(new_unit: Unit):
	selected_unit = new_unit
	if (is_instance_valid(new_unit)):
		emit_signal("unit_selected", new_unit.x, new_unit.y)
	else:
		emit_signal("unit_deselected")

func _generate_potential_units():
	units_node.add_child(Unit.make("Player Rock", 5, 2, 0, 0, 0))
	units_node.add_child(Unit.make("Player Paper", 5, 0, 0, 1, 0))
	units_node.add_child(Unit.make("Player Scissors", 5, 1, 0, 2, 0))
	units_node.add_child(Unit.make("Enemy Rock", 5, 2, 2, 0, 1))
	units_node.add_child(Unit.make("Enemy Paper", 5, 0, 2, 1, 1))
	units_node.add_child(Unit.make("Enemy Scissors", 5, 1, 2, 2, 1))
	
func _set_possibilities(new_possibilities: Array):
	possibilities = new_possibilities
	emit_signal("possibilities_changed", new_possibilities)

func resolve_turn(chosen_unit: String, direction: String):
	var units = self.units_node.get_children()
	var chosen_index := -1
	for i in range(len(units)):
		if units[i].unit_name == chosen_unit:
			chosen_index = i
			break
	self._client._send_packet(units, self.player_points, self.enemy_points, chosen_index, direction)
	
func get_units():
	return units_node.get_children()

func get_player_units():
	var players := []
	for unit in units_node.get_children():
		if (unit.allegiance == 0):
			players.append(unit)
	return players
	
func get_enemy_units():
	var enemies := []
	for unit in units_node.get_children():
		if (unit.allegiance == 1):
			enemies.append(unit)
	return enemies
	
func _update_state_from_packet(enemy_unit: Array, player_unit: Array):
	var units = self.units_node.get_children()
	var enemy_index := -1
	var player_index := -1
	for u in range(len(units)):
		if (player_index != -1 && enemy_index != -1):
			break
		if (units[u].unit_name == enemy_unit[0]):
			enemy_index = u
		if (units[u].unit_name == player_unit[0]):
			player_index = u
	# TODO: play a cool animation
	
	units[enemy_index].hp = int(enemy_unit[1])
	units[enemy_index].coordinate_vector.x = int(enemy_unit[2])
	units[enemy_index].coordinate_vector.y = int(enemy_unit[3])
	units[player_index].hp = int(player_unit[1])
	units[player_index].coordinate_vector.x = int(player_unit[2])
	units[player_index].coordinate_vector.y = int(player_unit[3])
	
	if (player_index > enemy_index):
		if (units[player_index].hp <= 0):
			units[player_index].queue_free()
		if (units[enemy_index].hp <= 0):
			units[enemy_index].queue_free()
	else:
		if (units[enemy_index].hp <= 0):
			units[enemy_index].queue_free()
		if (units[player_index].hp <= 0):
			units[player_index].queue_free()
	self.current_phase = phase_enum.select_unit
	self.selector.visible = true

func _on_cell_hovered(x: int, y: int):
	selector.coordinate_vector = Vector2(x, y)
