extends Node2D

@onready var enemy_scene = preload("res://enemy.tscn")

func _ready():
	$CanvasLayer/Control.visible = true

func _on_spawn_button_pressed():
	var new_enemy = enemy_scene.instantiate()
	
	var spawn_position = Vector2(450, 1000)
	
	new_enemy.global_position = spawn_position
	add_child(new_enemy)
	print("Spawned enemy at: ", spawn_position)
