extends Area2D

enum PickupType { HEALTH, SPEED, MULTISHOT }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var amount: int = 1
@export var duration: float = 10.0

var bob_time := 0.0

@onready var visual = $Visual
@onready var color_rect = $Visual/ColorRect
@onready var label = $Visual/Label

func _ready():
	body_entered.connect(_on_body_entered)
	_apply_visual()

func _physics_process(delta):
	bob_time += delta * 4.0
	visual.position.y = sin(bob_time) * 3.0

func _apply_visual():
	match pickup_type:
		PickupType.HEALTH:
			color_rect.color = Color(0.2, 0.9, 0.3)
			label.text = "HP"
		PickupType.SPEED:
			color_rect.color = Color(0.95, 0.75, 0.15)
			label.text = "SPD"
		PickupType.MULTISHOT:
			color_rect.color = Color(0.9, 0.3, 0.85)
			label.text = "3x"

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("collect_pickup"):
		body.collect_pickup(pickup_type, amount, duration)
		queue_free()
