class_name Unit
extends Node2D

signal unit_killed(unit_name)

enum weapon_enum { rock = 0, paper = 1, scissors = 2}
export (weapon_enum) var weapon setget _set_weapon

enum alligence_enum { player, enemy }
export (alligence_enum) var alligence

var unit_name: String
var hp: int
var x: int
var y: int
var move_range: int = 1
var last: String = "ws"


func _init(unit_name: String, hp: int, x: int, y: int, weapon: int):
	self.unit_name = unit_name
	self.hp = hp
	self.x = x 
	self.y = y
	self.weapon = weapon

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func distance(x: int, y: int) -> int:
	return int(abs(self.x - x) + abs(self.y - y))
	
func distance_unti(u: Unit) -> int:
	return int(abs(self.x - u.x) + abs(self.y - u.y))
	
func same_team(u: Unit) -> bool:
	return u.alligence == self.alligence
	
func get_move(x: int, y: int) -> PoolIntArray:
	return PoolIntArray([x - self.x, y - self.y])
	
func get_point(x: int, y: int) -> PoolIntArray:
	return PoolIntArray([x + self.x, y + self.y])
	
func valid_move(x_move: int, y_move: int) -> bool:
	var point = self.get_point(x_move, y_move)
	x = point[0]
	y = point[1]
	return (self.distance(x, y) <= self.move_range) && (x >= 0) && (y >= 0) && (x <= 3) && (y <= 3)
	
func move(direction: String) -> int:
	self.last = direction
	if (direction == "w"):
		self.y += 1
		if (self.y > 3):
			self.y = 3
	if (direction == "a"):
		self.x -= 1
		if (self.x < 0):
			self.x = 0
	if (direction == "s"):
		self.y -= 1
		if (self.y < 0):
			self.y = 0
	if (direction == "d"):
		self.x += 1
		if (self.x > 3):
			self.x = 3
			
	if (self.alligence == 0 && self.x == 0 && self.y == 3):
		self.hp = 0
		emit_signal("unit_killed", self.unit_name)
		return 1
	elif (self.alligence == 1 && self.x == 3 && self.y == 0):
		self.hp = 0
		emit_signal("unit_killed", self.unit_name)
		return 1
	return 0
	
func reverse(direction: String):
	if (direction == "w"):
		self.move("s")
	if (direction == "a"):
		self.move("d")
	if (direction == "s"):
		self.move("w")
	if (direction == "d"):
		self.move("a")
			
func attack(u: Unit):
	u.hp -= ((self.weapon as int) - (u.weapon as int) + 4) % 3
	if (u.hp <= 0):
		emit_signal("unit_killed", u.unit_name)
		
func _set_weapon(new_weapon):
	assert(typeof(new_weapon) == typeof(weapon_enum))
	# TODO: assign the unit's sprite the correct texture
	weapon = new_weapon
		
func _on_unit_killed(unit_name: String):
	if (self.unit_name == unit_name && self.hp <= 0):
		# Change this to add in animations/indicators
		self.queue_free()
