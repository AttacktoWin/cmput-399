extends Node2D

signal unit_selected(unit_x, unit_y)
signal unit_deselected
signal possibilities_changed(possibilities)
signal tooltips_changed(tooltips)
signal primary_unit_updated(unit)
signal secondary_unit_updated(unit)
signal shake_screen

const Unit = preload("res://Scripts/Unit.gd")

export var max_games := 3
var current_game := 1
var strategy_select_mode = 0
export var survey_url := "https://google.com"

onready var units_node = $Units

var selected_unit: Unit setget _set_selected_unit
var selected_direction: String

var possibilities := [] setget _set_possibilities
var tooltips := [] setget _set_tooltips

onready var _client := $Client

enum phase_enum { connecting, waiting, select_unit, select_cell, movement, win }
export(phase_enum) var current_phase = phase_enum.connecting setget _set_current_phase

onready var selector = $Selector
onready var selected_indicator = $SelectedIndicator
onready var possibilities_panel = $PossibilitiesPanel
onready var help_panel = $HelpPanel
onready var primary_unit_panel = $UnitPanel
onready var secondary_unit_panel = $UnitPanel2
onready var camera = $Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if (self.units_node.get_child_count() == 0):
		_generate_potential_units()
		
	for child in self.get_children():
		if child is Cell:
			child.connect("cell_hovered", self, "_on_cell_hovered")
			child.connect("cell_hovered", primary_unit_panel, "_on_cell_hovered")
			child.connect("cell_hovered", secondary_unit_panel, "_on_cell_hovered")
			# Change cell hovered using keyboard controls
			selector.connect("cell_hovered", child, "_on_cell_hovered")
	selector.connect("cell_hovered", primary_unit_panel, "_on_cell_hovered")
	selector.connect("cell_hovered", secondary_unit_panel, "_on_cell_hovered")
	self._client.connect("packet_data", self, "_update_state_from_packet")
	self._client.connect("client_connected", self, "_on_client_connected")
	connect("tooltips_changed", self.help_panel, "_on_tooltips_changed")
	connect("possibilities_changed", self.possibilities_panel, "_on_possibilities_changed")
	connect("primary_unit_updated", self.primary_unit_panel, "_display_unit_info")
	connect("secondary_unit_updated", self.secondary_unit_panel, "_display_unit_info")
	connect("shake_screen", self.camera, "set_shake")

func _input(event):
	if (event.is_action_pressed("accept")):
		if (_client.study_id == ""):
			return
		match self.current_phase:
			phase_enum.select_unit:
				for unit in self.get_player_units():
					if (unit.x == selector.coordinate_vector.x && unit.y == selector.coordinate_vector.y):
						self.selected_unit = unit
						self.current_phase = phase_enum.select_cell
						break
			phase_enum.select_cell:
				for unit in self.get_player_units():
					if (unit.x == selector.coordinate_vector.x && unit.y == selector.coordinate_vector.y):
						# Don't allow the player to fight themselves
						return
				match self.selected_unit.coordinate_vector - self.selector.coordinate_vector:
					Vector2(0, 1):
						self.selected_direction = "s"
					Vector2(-1, 0):
						self.selected_direction = "d"
					Vector2(0, -1):
						self.selected_direction = "w"
					Vector2(1, 0):
						self.selected_direction = "a"
					_:
						return
				self._client._send_packet(self.units_node.get_children(), self.get_player_units().find(selected_unit), self.selected_direction, self.strategy_select_mode)
				self.current_phase = phase_enum.movement
	if (event.is_action_pressed("cancel")):
		match self.current_phase:
			phase_enum.select_cell:
				self.current_phase = phase_enum.select_unit
			
	
func _set_study_id(id: String):
	self._client.study_id = id
	if (self.current_phase == phase_enum.waiting):
		self.current_phase = phase_enum.select_unit
		
func _generate_study_id():
	var numbers = ''
	for i in range(10):
		numbers += String(randi() % 10)
	
	_set_study_id(numbers)
		
func _on_client_connected():
	selector.coordinate_vector = Vector2(0, 0)
	if (self._client.study_id != ''):
		self.current_phase = phase_enum.select_unit
	else:
		self.current_phase = phase_enum.waiting
	$CanvasLayer.hide()
	
func _set_current_phase(new_phase: int):
	match current_phase:
		phase_enum.select_unit:
			match new_phase:
				phase_enum.select_cell:
					self.selected_indicator.rect_position = Vector2(100 * selected_unit.x, 100 * (2 - selected_unit.y)) + Vector2(378, 121)
					self.selected_indicator.visible = true
					$Tween.interpolate_property(primary_unit_panel, "rect_position", primary_unit_panel.rect_position, primary_unit_panel.rect_position - Vector2(219, 0), 0.15)
					$Tween.interpolate_property(secondary_unit_panel, "rect_position", secondary_unit_panel.rect_position, secondary_unit_panel.rect_position - Vector2(0, 118), 0.15)
					$Tween.start()
					self.tooltips = [
						'Move the selector using WASD or Arrow Keys.', 
						'Select a [color=#8ae8ff]Blue[/color] space using Spacebar, Enter, or Left-Click to move your unit there.'
					]
		phase_enum.select_cell:
			match new_phase:
				phase_enum.select_unit:
					self.selected_unit = null
					self.selected_indicator.visible = false
					self.tooltips = [
						'Move the selector using WASD, Arrow Keys, or with the mouse.', 
						'Hover over a space to see if it is [color=#e21e15]Threatened[/color] by an enemy.',
						'Hover over a unit to see its health.',
						'Select one of your units using Spacebar, Enter, or Left-Click to move.'
					]
					$Tween.interpolate_property(primary_unit_panel, "rect_position", primary_unit_panel.rect_position, primary_unit_panel.rect_position + Vector2(219, 0), 0.15)
					$Tween.interpolate_property(secondary_unit_panel, "rect_position", secondary_unit_panel.rect_position, secondary_unit_panel.rect_position + Vector2(0, 118), 0.15)
					$Tween.start()
				phase_enum.movement:
					self.selector.visible = false
					self.tooltips = []
		phase_enum.movement:
			match new_phase:
				phase_enum.select_unit:
					self.selected_unit = null
					self.selected_indicator.visible = false
					self.selector.visible = true
					$Tween.interpolate_property(primary_unit_panel, "rect_position", primary_unit_panel.rect_position, primary_unit_panel.rect_position + Vector2(219, 0), 0.15)
					$Tween.interpolate_property(secondary_unit_panel, "rect_position", secondary_unit_panel.rect_position, secondary_unit_panel.rect_position + Vector2(0, 118), 0.15)
					$Tween.start()
					self.tooltips = [
						'Move the selector using WASD, Arrow Keys, or with the mouse.', 
						'Hover over a space to see if it is [color=#e21e15]Threatened[/color] by an enemy.',
						'Hover over a unit to see its health.',
						'Select one of your units using Spacebar, Enter, or Left-Click to move.'
					]
				phase_enum.win:
					self.selected_indicator.visible = false
					self.selector.visible = false
					self.tooltips = []
					if (self.current_game < self.max_games):
						var win_screen = preload("res://Scenes/Win.tscn").instance()
						win_screen.set_text("You Won!" if len(self.get_enemy_units()) == 0 else "You Lost...")
						add_child(win_screen)
		phase_enum.connecting:
			match new_phase:
				phase_enum.select_unit:
					$MusicLoop.play()
					self.tooltips = [
						'Move the selector using WASD, Arrow Keys, or with the mouse.', 
						'Hover over a space to see if it is [color=#e21e15]Threatened[/color] by an enemy.',
						'Hover over a unit to see its health.',
						'Select one of your units using Spacebar, Enter, or Left-Click to move.'
					]
		phase_enum.waiting:
			match new_phase:
				phase_enum.select_unit:
					$MusicLoop.play()					
					self.tooltips = [
						'Move the selector using WASD, Arrow Keys, or with the mouse.', 
						'Hover over a space to see if it is [color=#e21e15]Threatened[/color] by an enemy.',
						'Hover over a unit to see its health.',
						'Select one of your units using Spacebar, Enter, or Left-Click to move.'
					]
	current_phase = new_phase
				
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
	if (current_phase == phase_enum.waiting):
		$CanvasLayer.hide()
		self.current_phase = phase_enum.select_unit
	
func _set_possibilities(new_possibilities: Array):
	possibilities = new_possibilities
	emit_signal("possibilities_changed", new_possibilities)
	
	
func _set_tooltips(new_tooltips: Array):
	tooltips = new_tooltips
	emit_signal("tooltips_changed", new_tooltips)
	
func get_units():
	return units_node.get_children()

func get_player_units():
	var players := []
	for unit in units_node.get_children():
		if (unit.allegiance == 0 && unit.hp > 0):
			players.append(unit)
	return players
	
func get_enemy_units():
	var enemies := []
	for unit in units_node.get_children():
		if (unit.allegiance == 1 && unit.hp > 0):
			enemies.append(unit)
	return enemies
	
func _update_state_from_packet(enemy_name: String, enemy_direction: String):
	var enemy_unit: Unit
	var units = get_enemy_units()
	for u in units:
		if u.unit_name == enemy_name:
			enemy_unit = u
			emit_signal("secondary_unit_updated", u)
			break
	
	self.selected_unit.move(self.selected_direction)
	enemy_unit.move(enemy_direction)
	_resolve_state()
	
func _resolve_state():
	var players = get_player_units()
	var enemies = get_enemy_units()
	
	var primary_unit := selected_unit
	var secondary_unit: Unit
	
	var delay := 0.0
	
	for unit in players:
		for p in players:
			if unit.coordinate_vector == p.coordinate_vector && unit.unit_name != p.unit_name:
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "primary_unit_updated", unit)
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "secondary_unit_updated", p)
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "shake_screen")
				$Tween.interpolate_deferred_callback(p, delay, "attack", unit)
				$Tween.interpolate_deferred_callback(unit, delay, "attack", p)
				$Tween.interpolate_deferred_callback(p, delay + 0.4, "move", unit.last)
				$Tween.interpolate_deferred_callback(unit, delay + 0.4, "reverse", unit.last)
				$Tween.interpolate_deferred_callback(self, delay + 0.4, "emit_signal", "primary_unit_updated", unit)
				$Tween.interpolate_deferred_callback(self, delay + 0.4, "emit_signal", "secondary_unit_updated", p)
				delay += 0.75
		for e in enemies:
			if unit.coordinate_vector == e.coordinate_vector:
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "primary_unit_updated", unit)
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "secondary_unit_updated", e)
				$Tween.interpolate_deferred_callback(self, delay, "emit_signal", "shake_screen")
				$Tween.interpolate_deferred_callback(e, delay, "attack", unit)
				$Tween.interpolate_deferred_callback(unit, delay, "attack", e)
				$Tween.interpolate_deferred_callback(e, delay + 0.4, "move", unit.last)
				$Tween.interpolate_deferred_callback(unit, delay + 0.4, "reverse", unit.last)
				$Tween.interpolate_deferred_callback(self, delay + 0.4, "emit_signal", "primary_unit_updated", unit)
				$Tween.interpolate_deferred_callback(self, delay + 0.4, "emit_signal", "secondary_unit_updated", e)
				delay += 0.75
		
		$Tween.interpolate_deferred_callback(self, delay + 0.3, "_check_win")
		$Tween.start()
	
	

func _check_win():
	if (len(get_player_units()) == 0):
		self.current_phase = phase_enum.win
		return
	if (len(get_enemy_units()) == 0):
		self.current_phase = phase_enum.win
		return
	self.current_phase = phase_enum.select_unit

func _reset_state():
	$CanvasLayer/ConnectingText/Text.bbcode_text = "[center]Loading next game...[/center]"
	$CanvasLayer.show()
	self.current_game += 1
	if (self._client.study_id == 'tutorial'):
		self._generate_study_id()
	else:
		self.strategy_select_mode = 1
	self.possibilities = []
	self.selected_unit = null
	primary_unit_panel.rect_position = Vector2(351, 488)
	secondary_unit_panel.rect_position = Vector2(529, 606)
	selector.coordinate_vector = Vector2(0, 0)
	selector.visible = true
	selected_indicator.visible = false
	for unit in units_node.get_children():
		unit.queue_free()
	call_deferred("_generate_potential_units")
	self.current_phase = phase_enum.waiting

func _on_cell_hovered(x: int, y: int):
	selector.coordinate_vector = Vector2(x, y)
