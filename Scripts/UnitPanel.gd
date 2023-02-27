extends Container


const RADIUS = 45
const POSITION = Vector2(-12,-12)
const SIZE = Vector2(900, 300)

const ROCK = preload("res://Assets/Units/rock.png")
const PAPER = preload("res://Assets/Units/paper.png")
const SCISSORS = preload("res://Assets/Units/scissors.png")

enum UnitEnum { none, rock, paper, scissors }
export (UnitEnum) var displayed_unit setget _set_displayed_unit
onready var unit_display = $UnitDisplay
export(int, 1, 10) var max_health = 5
export var primary := false

var unit_name := "" setget _set_unit_name
onready var unit_name_label = $VBoxContainer/UnitName
var unit_health := 3 setget _set_unit_health
onready var health_bar = $VBoxContainer/HealthBarContainer/HealthBar

# Called when the node enters the scene tree for the first time.
func _ready():
	if (is_instance_valid(unit_display)):
		match self.displayed_unit:
			UnitEnum.none:
				unit_display.texture = null
			UnitEnum.rock:
				unit_display.texture = ROCK
			UnitEnum.paper:
				unit_display.texture = PAPER
			UnitEnum.scissors:
				unit_display.texture = SCISSORS
	update()


func _draw():
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(RADIUS)
	style_box.bg_color = Color(0, 0, 0)
	style_box.border_color = Color(1, 1, 1)
	style_box.border_width_top = 12
	style_box.border_width_right = 12
	style_box.border_width_bottom = 12
	style_box.border_width_left = 12
	
	draw_style_box(style_box, Rect2(POSITION, SIZE))
	
func _display_unit_info(unit: Unit):
	match unit.weapon:
		0:
			self.displayed_unit = UnitEnum.rock
		1:
			self.displayed_unit = UnitEnum.paper
		2:
			self.displayed_unit = UnitEnum.scissors
		_:
			self.displayed_unit = UnitEnum.none
	self.unit_name = unit.unit_name
	self.unit_health = unit.hp
	$VBoxContainer/HealthBarContainer.visible = true
	$VBoxContainer/HealthCount.visible = true

func _on_cell_hovered(cell_x: int, cell_y: int):
	if (primary && State.selected_unit != null):
		_display_unit_info(State.selected_unit)
		return
	var units = State.get_units()
	
	for unit in units:
		if (unit.x == cell_x && unit.y == cell_y):
			_display_unit_info(unit)
			return
	self.displayed_unit = UnitEnum.none
	self.unit_name = "Empty Cell"
	$VBoxContainer/HealthBarContainer.visible = false
	$VBoxContainer/HealthCount.visible = false

func _set_displayed_unit(new_unit):
	displayed_unit = new_unit
	if (is_instance_valid(unit_display)):
		match displayed_unit:
			UnitEnum.none:
				unit_display.texture = null
			UnitEnum.rock:
				unit_display.texture = ROCK
			UnitEnum.paper:
				unit_display.texture = PAPER
			UnitEnum.scissors:
				unit_display.texture = SCISSORS
				
				
func _set_unit_name(new_name: String):
	unit_name = new_name
	unit_name_label.text = unit_name

func _set_unit_health(new_health: int):
	unit_health = new_health
	$VBoxContainer/HealthCount.bbcode_text = "[right]{health}/{max_health}[/right]".format({
		"health": unit_health,
		"max_health": max_health
	})
	$Tween.interpolate_property(health_bar, "anchor_right", health_bar.anchor_right, float(unit_health) / max_health, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
