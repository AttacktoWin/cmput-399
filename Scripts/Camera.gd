extends Camera2D


var intensity = 0.0
var power = 2
var amount = 0.0

var decay = 0.8
var max_offset = Vector2(36, 64)
var max_roll = 0.1

onready var hit_sound = $HitSound


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (intensity):
		intensity = max(intensity - decay * delta, 0)
		rough_shake()
		
func rough_shake():
	amount = pow(intensity, power)
	rotation = max_roll * amount * rand_range(-1, 1)
	offset.x = max_offset.x * amount * rand_range(-1, 1)
	offset.y = max_offset.y * amount * rand_range(-1, 1)
	
func set_shake(add_intensity = 0.5):
	intensity = min(intensity + add_intensity, 1.0)
	hit_sound.play()
	
