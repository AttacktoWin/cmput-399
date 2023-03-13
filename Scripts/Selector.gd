extends Node2D

signal cell_hovered(cell_x, cell_y)

var coordinate_vector: Vector2 setget _coordinate_vector_changed
onready var tween = $Tween

func _coordinate_vector_changed(new_vector: Vector2):
	coordinate_vector = new_vector
	if (is_instance_valid(tween)):
		tween.interpolate_property(self, "position", self.position, Vector2(coordinate_vector.x, 2 - coordinate_vector.y) * 100 + Vector2(400, 200), 0.1)
		tween.start()
	else:
		self.position = Vector2(coordinate_vector.x, 2 - coordinate_vector.y) * 100 + Vector2(400, 200)
		
	emit_signal("cell_hovered", new_vector.x, new_vector.y)
		
func _input(event):
	if (State.current_phase != State.phase_enum.select_unit && State.current_phase != State.phase_enum.select_cell):
		return
	if (event.is_action_pressed("up")):
		if (self.coordinate_vector.y != 0):
			self.coordinate_vector = self.coordinate_vector + Vector2(0, 1)
	if (event.is_action_pressed("right")):
		if (self.coordinate_vector.x != 2):
			self.coordinate_vector = self.coordinate_vector + Vector2(1, 0)
	if (event.is_action_pressed("down")):
		if (self.coordinate_vector.y != 2):
			self.coordinate_vector = self.coordinate_vector + Vector2(0, -1)
	if (event.is_action_pressed("left")):
		if (self.coordinate_vector.x != 0):
			self.coordinate_vector = self.coordinate_vector + Vector2(-1, 0)
