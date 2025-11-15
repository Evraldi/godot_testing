extends CharacterBody2D
@export var speed: float = 200.0
@onready var animated_sprite = $AnimatedSprite2D
var last_direction = "down"

func _ready():
	animated_sprite.play("idle")
	last_direction = "down"

func _physics_process(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = direction * speed
		
		if direction > 0:
			animated_sprite.play("walk_right")
			animated_sprite.flip_h = false
			last_direction = "right"
		else:
			animated_sprite.play("walk_left")
			animated_sprite.flip_h = false
			last_direction = "left"
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
		if velocity.x == 0:
			match last_direction:
				"left":
					animated_sprite.play("idle_left")
				"right":
					animated_sprite.play("idle_right")
				"down":
					animated_sprite.play("idle")
	
	# Apply movement
	move_and_slide()
