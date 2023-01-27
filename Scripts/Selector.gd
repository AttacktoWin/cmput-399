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
