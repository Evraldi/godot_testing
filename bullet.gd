extends Area2D

var speed = 600
var direction = Vector2(1, 0)

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta
	
	if position.x > 2000 or position.x < -500 or position.y > 2000 or position.y < -500:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)
	
	queue_free()
