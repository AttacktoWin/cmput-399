extends Node2D

var next_game_available := true

onready var color = $CanvasLayer/ColorRect
onready var tween = $Tween
onready var label = $CanvasLayer/ColorRect/Text
onready var main_button = $CanvasLayer/ColorRect/NextGame

var text := "[center]You Lost...[/center]"


# Called when the node enters the scene tree for the first time.
func _ready():
	tween.interpolate_property(color, "color", color.color, Color(0, 0, 0, 0.5), 1)
	tween.start()
	if (!next_game_available):
		main_button.text = "Continue"
	label.bbcode_text = self.text


func set_text(new_text: String):
	text = "[center]" + new_text + "[/center]"


func _on_NextGame_pressed():
	if (next_game_available):
		self.queue_free()
		State._reset_state()
	else:
		var debrief = preload("res://Scenes/Debrief.tscn").instance()
		get_tree().add_child(debrief)
		self.queue_free()


func _on_Exit_pressed():
	get_tree().quit()
