extends CharacterBody2D

@export var speed: float = 120.0
@export var run_multiplier: float = 1.8
@export var bullet_scene: PackedScene

@onready var animated_sprite = $AnimatedSprite2D

var last_direction := "down"

func _ready():
	animated_sprite.play("idle_down")

func _physics_process(delta):
	var input_vec = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	var is_running = Input.is_action_pressed("shift") and input_vec != Vector2.ZERO
	var current_speed = speed * (run_multiplier if is_running else 1.0)

	if input_vec != Vector2.ZERO:
		velocity = input_vec.normalized() * current_speed

		if abs(input_vec.x) > abs(input_vec.y):
			last_direction = "right" if input_vec.x > 0 else "left"
		else:
			last_direction = "down" if input_vec.y > 0 else "up"

		if is_running:
			animated_sprite.play("run_%s" % last_direction)
		else:
			animated_sprite.play("walk_%s" % last_direction)

	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		if velocity == Vector2.ZERO:
			animated_sprite.play("idle_%s" % last_direction)

	if Input.is_action_just_pressed("ui_accept"):
		shoot()

	move_and_slide()

func shoot():
	if bullet_scene == null:
		print("Bullet scene not assigned")
		return

	var bullet = bullet_scene.instantiate()
	if bullet == null:
		print("Failed to instantiate bullet")
		return

	match last_direction:
		"right": bullet.direction = Vector2(1, 0)
		"left": bullet.direction = Vector2(-1, 0)
		"up": bullet.direction = Vector2(0, -1)
		"down": bullet.direction = Vector2(0, 1)

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
