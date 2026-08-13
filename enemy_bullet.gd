extends Area2D

var speed = 240.0
var direction = Vector2(1, 0)

func _ready():
	add_to_group("enemy_bullet")

func _physics_process(delta):
	var motion: Vector2 = direction * speed * delta
	var space = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + motion)
	query.collision_mask = collision_mask
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var body = hit.collider
		if body and body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
		return
	global_position += motion

	if position.x > 1450 or position.x < -1100 or position.y > 1950 or position.y < 0:
		queue_free()
