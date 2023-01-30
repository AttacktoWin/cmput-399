extends Node2D


var coordinate_vector: Vector2 setget _coordinate_vector_changed
onready var tween = $Tween

func _coordinate_vector_changed(new_vector: Vector2):
	coordinate_vector = new_vector
	if (is_instance_valid(tween)):
		tween.interpolate_property(self, "position", self.position, coordinate_vector * 100, 0.1)
		tween.start()
	else:
		self.position = coordinate_vector * 100
		
func _input(event):
	if (event.is_action_pressed("up")):
		if (self.coordinate_vector.y != 0):
			self.coordinate_vector = self.coordinate_vector + Vector2(0, -1)
	if (event.is_action_pressed("right")):
		if (self.coordinate_vector.x != 2):
			self.coordinate_vector = self.coordinate_vector + Vector2(1, 0)
	if (event.is_action_pressed("down")):
		if (self.coordinate_vector.y != 2):
			self.coordinate_vector = self.coordinate_vector + Vector2(0, 1)
	if (event.is_action_pressed("left")):
		if (self.coordinate_vector.x != 0):
			self.coordinate_vector = self.coordinate_vector + Vector2(-1, 0)
