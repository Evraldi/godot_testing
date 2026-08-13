extends CharacterBody2D

signal died(enemy_type: int)

enum Type { NORMAL, FAST, TANK, RANGED }

const SPEED = 100.0
const PATROL_DISTANCE = 200.0

@export var enemy_type: Type = Type.NORMAL
@export var chase_speed: float = 125.0
@export var detection_radius: float = 240.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var reaction_time: float = 0.5
@export var turn_speed: float = 120.0
@export var track_speed: float = 3.5
@export var remember_time: float = 1.2
@export var drop_scene: PackedScene

const ENEMY_BULLET = preload("res://enemy_bullet.tscn")

var direction = 1
var max_health := 3
var health: int
var is_dead = false
var start_position = Vector2.ZERO
var distance_traveled = 0.0
var attack_ready := true
var facing := Vector2.RIGHT
var was_chasing := false
var reaction_left := 0.0
var ranged_cooldown := 0.0
var patrol_speed := SPEED
var last_known := Vector2.ZERO
var remember_time_left := 0.0

@onready var color_rect = $ColorRect
@onready var hp_fill = $HPBarFill

func _enter_tree():
	add_to_group("enemy")

func _ready():
	start_position = position
	match enemy_type:
		Type.FAST:
			max_health = 1
			patrol_speed = 140.0
			chase_speed = 175.0
			detection_radius = 300.0
			reaction_time = 0.25
			turn_speed = 220.0
			track_speed = 6.0
			remember_time = 0.6
			attack_cooldown = 0.8
			scale *= 0.75
			color_rect.color = Color(0.95, 0.55, 0.1)
		Type.TANK:
			max_health = 6
			patrol_speed = 60.0
			chase_speed = 85.0
			detection_radius = 200.0
			attack_damage = 2
			attack_cooldown = 1.2
			reaction_time = 0.7
			turn_speed = 70.0
			track_speed = 1.8
			remember_time = 2.2
			scale *= 1.6
			color_rect.color = Color(0.8, 0.15, 0.15)
		Type.RANGED:
			max_health = 2
			patrol_speed = 80.0
			chase_speed = 100.0
			detection_radius = 280.0
			attack_cooldown = 1.6
			reaction_time = 0.5
			turn_speed = 110.0
			track_speed = 3.0
			remember_time = 1.5
			color_rect.color = Color(0.6, 0.3, 0.9)
		_:
			max_health = 3
	health = max_health
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	ranged_cooldown = max(0.0, ranged_cooldown - delta)

	var player = _find_player()
	var dist := INF
	if player:
		dist = global_position.distance_to(player.global_position)

	var can_see = player != null and dist <= detection_radius and _has_line_of_sight(player)

	if can_see:
		if not was_chasing:
			was_chasing = true
			reaction_left = reaction_time
			last_known = player.global_position
		remember_time_left = remember_time
		last_known = last_known.lerp(player.global_position, track_speed * delta)
	elif remember_time_left > 0.0:
		remember_time_left -= delta
		was_chasing = false
		reaction_left = 0.0
		if last_known.distance_to(global_position) < 40.0:
			remember_time_left = 0.0
	else:
		was_chasing = false
		reaction_left = 0.0

	if was_chasing or (remember_time_left > 0.0 and not can_see):
		if reaction_left > 0.0:
			reaction_left -= delta
			velocity = velocity.move_toward(Vector2.ZERO, SPEED * 2 * delta)
			_turn_toward(last_known, delta)
		elif enemy_type == Type.RANGED:
			var dist_to_aim = global_position.distance_to(last_known)
			_ranged_chase(last_known, dist_to_aim, can_see)
		else:
			_turn_toward(last_known, delta)
			velocity = facing * chase_speed
			if can_see and dist < 28.0 and attack_ready:
				_attack(player)
	else:
		_patrol(delta)

	move_and_slide()

func _patrol(delta: float) -> void:
	facing = Vector2.RIGHT if direction > 0 else Vector2.LEFT
	velocity.x = direction * patrol_speed
	velocity.y = 0

	distance_traveled += abs(velocity.x * delta)
	if distance_traveled >= PATROL_DISTANCE:
		direction *= -1
		distance_traveled = 0.0

func _ranged_chase(aim: Vector2, dist: float, can_fire: bool) -> void:
	var to_aim = aim - global_position
	var dir = to_aim.normalized()
	_turn_toward(aim, get_process_delta_time())
	if dist < 140.0:
		velocity = -dir * chase_speed
	elif dist > 260.0:
		velocity = dir * chase_speed
	else:
		velocity = facing.orthogonal() * chase_speed * 0.6
	if can_fire and dist < 300.0 and ranged_cooldown <= 0.0:
		_fire_ranged(dir)

func _fire_ranged(dir: Vector2) -> void:
	ranged_cooldown = attack_cooldown
	var bullet = ENEMY_BULLET.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + dir * 20.0
	bullet.direction = dir

func _turn_toward(target: Vector2, delta: float) -> void:
	var target_angle = (target - global_position).angle()
	var diff = wrapf(target_angle - facing.angle(), -PI, PI)
	var max_turn = deg_to_rad(turn_speed) * delta
	if abs(diff) <= max_turn:
		facing = Vector2.from_angle(target_angle)
	else:
		facing = Vector2.from_angle(facing.angle() + sign(diff) * max_turn)

func _has_line_of_sight(player) -> bool:
	var space = get_world_2d().direct_space_state
	var from = global_position + (player.global_position - global_position).normalized() * 20.0
	var query = PhysicsRayQueryParameters2D.create(from, player.global_position)
	query.collision_mask = 2
	return space.intersect_ray(query).is_empty()

func _find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return null
	return players[0]

func _attack(player):
	attack_ready = false
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

	color_rect.modulate = Color(2, 0.4, 0.4)
	await get_tree().create_timer(0.15).timeout
	if is_queued_for_deletion():
		return
	color_rect.modulate = Color.WHITE
	await get_tree().create_timer(attack_cooldown - 0.15).timeout
	if is_queued_for_deletion():
		return
	attack_ready = true

func take_damage(amount: int = 1):
	if is_dead:
		return

	health -= amount
	print("Enemy hit! HP: ", max(0, health))
	_update_hp_bar()

	color_rect.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	if is_queued_for_deletion():
		return
	color_rect.modulate = Color.WHITE

	if health <= 0:
		die()

func _update_hp_bar():
	if hp_fill:
		var ratio = clampf(float(health) / max_health, 0.0, 1.0)
		hp_fill.offset_right = -32.0 + 64.0 * ratio

func die():
	if is_dead:
		return

	is_dead = true
	print("Enemy died!")
	_drop_loot()
	died.emit(enemy_type)
	queue_free()

func _drop_loot():
	if drop_scene == null:
		return

	var drop = drop_scene.instantiate()
	var roll = randf()
	if roll < 0.4:
		drop.pickup_type = drop.PickupType.HEALTH
	elif roll < 0.7:
		drop.pickup_type = drop.PickupType.SPEED
	else:
		drop.pickup_type = drop.PickupType.MULTISHOT

	get_tree().current_scene.add_child(drop)
	drop.global_position = global_position
