extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var text_box = $CanvasLayer/TextBox


# Called when the node enters the scene tree for the first time.
func _ready():
	var state = get_node("/root/State")
	if (is_instance_valid(state)):
		state.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _input(event):
	if (event is InputEventKey && event.scancode == KEY_ENTER):
		_on_Button_pressed()

func _on_Button_pressed():
	if (text_box.text.length() > 0):
		var state = get_node("/root/State")
		if (is_instance_valid(state)):
			state._set_study_id(text_box.text)
			state.visible = true
			self.queue_free()
