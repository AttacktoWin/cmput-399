extends Node2D


export var pages := []
var current_page := 0 setget _set_current_page

onready var content = $CanvasLayer/ColorRect/Content
onready var previous = $CanvasLayer/ColorRect/Previous
onready var next = $CanvasLayer/ColorRect/Next
onready var check = $CanvasLayer/ColorRect/CheckBox

# Called when the node enters the scene tree for the first time.
func _ready():
	previous.visible = false
	check.visible = false
	content.text = "\n\n".join(pages[0])


func _set_current_page(new_page: int):
	current_page = new_page
	content.text = "\n\n".join(pages[current_page % len(pages)])
	if (current_page == 0):
		previous.visible = false
	else:
		previous.visible = true
	
	if (current_page == len(pages) - 1):
		next.text = "Start"
		check.visible = true
		next.disabled = !check.pressed
	else:
		next.text = "Next"
		next.disabled = false
		check.visible = false


func _on_Next_pressed():
	if (self.current_page == len(self.pages) - 1):
		State._set_study_id('test')
		State.visible = true
		self.queue_free()
	else:
		self.current_page += 1


func _on_Previous_pressed():
	self.current_page -= 1


func _on_CheckBox_pressed():
	next.disabled = !check.pressed
