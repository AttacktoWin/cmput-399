extends Container


const RADIUS = 27
const POSITION = Vector2(-12,-12)
onready var text = $Text

# Called when the node enters the scene tree for the first time.
func _ready():
	text.connect("resized", self, "_on_Text_resized")


func _on_tooltips_changed(tooltips: Array):
	text.bbcode_text = "[b]How to Play:[/b]\n" + "\n\n".join(tooltips)
	
func _on_Text_resized():
	self.rect_size.y = text.rect_size.y
	self.rect_size.x = 150

func _draw():
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(RADIUS)
	style_box.bg_color = Color(0, 0, 0)
	style_box.border_color = Color(1, 1, 1)
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_width_left = 3
	
	draw_style_box(style_box, Rect2(POSITION, self.rect_size + Vector2(24, 24)))
