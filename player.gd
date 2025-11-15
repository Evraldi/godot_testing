extends CharacterBody2D
@export var speed: float = 200.0
@export var bullet_scene: PackedScene
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
	
	if Input.is_action_just_pressed("ui_accept"):
		shoot()
	
	move_and_slide()

func shoot():
	if bullet_scene == null:
		print("Bullet scene not assigned!")
		return
	
	var bullet = bullet_scene.instantiate()
	
	if bullet == null:
		print("Failed to instantiate bullet!")
		return
	
	match last_direction:
		"right":
			bullet.direction = Vector2(1, 0)
		"left":
			bullet.direction = Vector2(-1, 0)
		"down":
			bullet.direction = Vector2(1, 0)

	get_tree().current_scene.add_child(bullet)
	
	bullet.global_position = global_position
