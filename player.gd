extends CharacterBody2D

const PickupScript = preload("res://pickup.gd")

@export var speed: float = 160.0
@export var run_multiplier: float = 1.8
@export var max_health: int = 3
@export var bullet_scene: PackedScene
@export var fire_cooldown: float = 0.3

signal health_changed(current: int, maximum: int)
signal died

@onready var animated_sprite = $AnimatedSprite2D

var last_direction := "down"
var health: int
var damage := 1
var base_shots := 1
var shots_per_fire := 1
var invincible := false
var speed_multiplier := 1.0
var speed_timer := 0.0
var multishot_timer := 0.0
var cooldown_left := 0.0

func _ready():
	add_to_group("player")
	health = max_health
	animated_sprite.play("idle_down")
	health_changed.emit(health, max_health)

func _physics_process(delta):
	cooldown_left = max(0.0, cooldown_left - delta)

	if speed_timer > 0.0:
		speed_timer -= delta
		if speed_timer <= 0.0:
			speed_multiplier = 1.0

	if multishot_timer > 0.0:
		multishot_timer -= delta
		if multishot_timer <= 0.0:
			shots_per_fire = base_shots

	var input_vec = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	var is_running = Input.is_action_pressed("shift") and input_vec != Vector2.ZERO
	var current_speed = speed * speed_multiplier * (run_multiplier if is_running else 1.0)

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

	if Input.is_action_pressed("ui_accept"):
		shoot()

	move_and_slide()

func shoot():
	if cooldown_left > 0.0 or bullet_scene == null:
		return

	cooldown_left = fire_cooldown
	for dir in _fire_directions():
		var bullet = bullet_scene.instantiate()
		bullet.direction = dir
		bullet.damage = damage
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position

func _fire_directions() -> Array[Vector2]:
	var base: Vector2
	match last_direction:
		"right": base = Vector2(1, 0)
		"left": base = Vector2(-1, 0)
		"up": base = Vector2(0, -1)
		_: base = Vector2(0, 1)

	if shots_per_fire <= 1:
		return [base]

	var dirs: Array[Vector2] = []
	var spread := 0.25
	for i in range(shots_per_fire):
		var t = i - (shots_per_fire - 1) / 2.0
		dirs.append((base.rotated(t * spread)).normalized())
	return dirs

func take_damage(amount: int = 1):
	if invincible or health <= 0:
		return

	health = max(0, health - amount)
	health_changed.emit(health, max_health)

	if health <= 0:
		die()
	else:
		_stun_flash()

func _stun_flash():
	invincible = true
	for i in range(5):
		visible = not visible
		await get_tree().create_timer(0.1).timeout
		if health <= 0 or not is_inside_tree():
			return
	visible = true
	invincible = false

func collect_pickup(type: int, amount: int, duration: float):
	match type:
		PickupScript.PickupType.HEALTH:
			health = min(max_health, health + amount)
			health_changed.emit(health, max_health)
		PickupScript.PickupType.SPEED:
			speed_multiplier = 1.5
			speed_timer = duration
		PickupScript.PickupType.MULTISHOT:
			shots_per_fire = 3
			multishot_timer = duration

func die():
	set_physics_process(false)
	died.emit()
