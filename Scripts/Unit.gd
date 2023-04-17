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
var last: String

var coordinate_vector: Vector2 setget _coordinate_vector_changed

onready var sprite = $Sprite
var texture: String
onready var tween = $Tween
onready var death_sound = $DeathSound

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
	
func attack(u: Unit):
	u.hp -= (self.weapon - u.weapon + 4) % 3
	if (u.hp <= 0):
		u.call_deferred("kill_unit")
		
	
func move(direction: String):
	self.last = direction
	var hurt = false
	match direction:
		"w":
			self.coordinate_vector.y += 1
			if (self.coordinate_vector.y > 2):
				self.coordinate_vector.y = 2
				hurt = true
		"a":
			self.coordinate_vector.x -= 1
			if (self.coordinate_vector.x < 0):
				self.coordinate_vector.x = 0
				hurt = true
		"s":
			self.coordinate_vector.y -= 1
			if (self.coordinate_vector.y < 0):
				self.coordinate_vector.y = 0
				hurt = true
		"d":
			self.coordinate_vector.x += 1
			if (self.coordinate_vector.x > 2):
				self.coordinate_vector.x = 2
				hurt = true
	if (hurt):
		self.hp -= 1
		if (self.hp <= 0):
			self.kill_unit()
		else:
			self.reverse(direction)

func reverse(direction: String):
	match direction:
		"w":
			self.move("s")
		"a":
			self.move("d")
		"s":
			self.move("w")
		"d":
			self.move("a")
		
func kill_unit():
	tween.interpolate_property(self, "modulate", self.modulate, Color(1, 0, 0), 0.2)
	tween.interpolate_property(self, "modulate", Color(1, 0, 0), Color(0, 0, 0), 0.1, 0, Tween.EASE_OUT, 0.2)
	tween.interpolate_callback(self, 0.3, "queue_free")
	tween.start()
	death_sound.play()

func bounce(direction: String):
	var reverse_point: Vector2
	match direction:
		"w":
			reverse_point = Vector2(self.coordinate_vector.x, 2 - (self.coordinate_vector.y + 1)) * 100 + Vector2(400, 200)
		"a":
			reverse_point = Vector2(self.coordinate_vector.x - 1, 2 - self.coordinate_vector.y) * 100 + Vector2(400, 200)
		"s":
			reverse_point = Vector2(self.coordinate_vector.x, 2 - (self.coordinate_vector.y - 1)) * 100 + Vector2(400, 200)
		"d":
			reverse_point = Vector2(self.coordinate_vector.x + 1, 2 - self.coordinate_vector.y) * 100 + Vector2(400, 200)
	tween.interpolate_property(self, "position", self.position, reverse_point, 0.3)
	tween.interpolate_property(self, "position", reverse_point, self.position, 0.15, 0.2)
	tween.start()
