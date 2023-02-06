extends ColorRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var text = $Text

# Called when the node enters the scene tree for the first time.
func _ready():
	text.connect("resized", self, "_on_Text_resized")


func _on_possibilities_changed(possibilities: Array):
	text.text = "Possibilites:\n" + "\n\n".join(possibilities)
	

func _on_Text_resized():
	self.rect_size.y = text.rect_size.y
