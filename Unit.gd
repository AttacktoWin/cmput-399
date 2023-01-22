class_name Unit
extends Node2D


enum unit_type_enum { rock, paper, scissors}
export (unit_type_enum) var unit_type setget _set_unit_type

enum alligence_enum { player, enemy }
export (alligence_enum) var alligence


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _set_unit_type(new_type):
	assert(typeof(new_type) == typeof(unit_type_enum))
	# TODO: assign the unit's sprite the correct texture
	unit_type = new_type
