extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


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
	# State._generate_study_id()
	State._set_study_id('tutorial')
	State.visible = true
	self.queue_free()


func _on_Quit_pressed():
	get_tree().quit()
