extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var survey_id = $CanvasLayer/ColorRect/SurveyId

# Called when the node enters the scene tree for the first time.
func _ready():
	State.visible = false
	survey_id.text = State._client.study_id

func _on_Copy_pressed():
	OS.clipboard = State._client.study_id


func _on_TakeSurvey_pressed():
	OS.shell_open(State.survey_url)
