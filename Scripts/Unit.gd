class_name Unit
extends Node2D

signal unit_killed(unit_name)

enum weapon_enum { rock = 0, paper = 1, scissors = 2}
export (weapon_enum) var weapon setget _set_weapon

enum allegiance_enum { player = 0, enemy = 1 }
export (allegiance_enum) var allegiance

var unit_name: String
var hp: int
var x: int
var y: int
var move_range: int = 1

var coordinate_vector: Vector2 setget _coordinate_vector_changed

onready var sprite = $Sprite
var texture: String
onready var tween = $Tween

func _ready():
	sprite.animation = texture
	if (self.allegiance == allegiance_enum.enemy):
		sprite.modulate = Color(1, 0.5, 0.5)

static func make(unit_name: String, hp: int, x: int, y: int, weapon: int, allegiance: int) -> Unit:
	var node = load("res://Scenes/Classes/Unit.tscn").instance()
	
	node.unit_name = unit_name
	node.hp = hp
	node.coordinate_vector = Vector2(x, y)
	node.weapon = weapon
	node.allegiance = allegiance
	return node

func _coordinate_vector_changed(new_vector: Vector2):
	coordinate_vector = new_vector
	self.x = coordinate_vector.x
	self.y = coordinate_vector.y
	if (is_instance_valid(tween)):
		tween.interpolate_property(self, "position", self.position, Vector2(coordinate_vector.x, 2 - coordinate_vector.y) * 100 + Vector2(400, 200), 0.3)
		tween.start()
	else:
		self.position = Vector2(coordinate_vector.x, 2 - coordinate_vector.y) * 100 + Vector2(400, 200)

func _set_weapon(new_weapon):
	match new_weapon:
		weapon_enum.rock:
			self.texture = "rock"
		weapon_enum.paper:
			self.texture = "paper"
		weapon_enum.scissors:
			self.texture = "scissors"
	weapon = new_weapon
		
func kill_unit():
	tween.interpolate_property(self, "modulate", self.modulate, Color(1, 0, 0), 0.2)
	tween.interpolate_property(self, "modulate", Color(1, 0, 0), Color(0, 0, 0), 0.1, 0, Tween.EASE_OUT, 0.2)
	tween.interpolate_callback(self, 0.3, "queue_free")
	tween.start()
