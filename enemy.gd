extends CharacterBody2D

const SPEED = 100.0
const MAX_HEALTH = 3
const PATROL_DISTANCE = 200.0

var direction = 1
var health = MAX_HEALTH
var is_dead = false
var start_position = Vector2.ZERO
var distance_traveled = 0.0

func _enter_tree():
	add_to_group("enemy")

func _ready():
	start_position = position
	print("Enemy spawned! HP: ", health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	velocity.x = direction * SPEED
	velocity.y = 0
	
	move_and_slide()
	
	distance_traveled += abs(velocity.x * delta)

	if distance_traveled >= PATROL_DISTANCE:
		direction *= -1
		distance_traveled = 0.0

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			collider.take_damage(1)

func take_damage(amount: int = 1):
	if is_dead:
		return
	
	health -= amount
	print("Enemy hit! HP: ", max(0, health))
	
	$ColorRect.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	$ColorRect.modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	print("Enemy died!")
	queue_free()
