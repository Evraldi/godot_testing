extends Node2D

@onready var enemy_scene = preload("res://enemy.tscn")
@onready var pickup_scene = preload("res://pickup.tscn")
const ENEMY_SCRIPT = preload("res://enemy.gd")

var kills := 0
var spawn_wave := 0
var score := 0
var combo := 1
var combo_timer := 0.0
var high_score := 0
var xp := 0
var level := 1
var xp_needed := 20
var pending_levels := 0

const COMBO_WINDOW := 2.5
const SCORE_PATH := "user://scores.cfg"
const MAX_ENEMIES := 40
const UPGRADES := [
	{"key": "damage", "name": "Power Shot", "desc": "Damage +1"},
	{"key": "firerate", "name": "Rapid Fire", "desc": "Fire cooldown -0.05s"},
	{"key": "hp", "name": "Vitality", "desc": "Max HP +1 & heal 1"},
	{"key": "speed", "name": "Swift", "desc": "Move speed +15"},
	{"key": "shots", "name": "Multi-Shot", "desc": "+1 bullet per shot"},
]

var health_label: Label
var kills_label: Label
var score_label: Label
var combo_label: Label
var xp_label: Label
var game_over_kills_label: Label
var game_over_high_label: Label
var game_over_root: Control
var level_up_root: Control
var upgrade_box: VBoxContainer
var spawn_timer: Timer
var clearance_shape := CircleShape2D.new()

func _ready():
	$CanvasLayer/Control.visible = true
	_load_high_score()
	_setup_hud()
	_setup_auto_spawn()
	_update_score_hud()
	_update_xp_hud()

	var player = get_node("Player")
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.health, player.max_health)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		_prepare_enemy(enemy)

func _setup_hud():
	var layer = CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 24)
	health_label.position = Vector2(16, 12)
	layer.add_child(health_label)

	kills_label = Label.new()
	kills_label.add_theme_font_size_override("font_size", 24)
	kills_label.position = Vector2(16, 44)
	layer.add_child(kills_label)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.position = Vector2(16, 76)
	layer.add_child(score_label)

	combo_label = Label.new()
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.position = Vector2(16, 112)
	layer.add_child(combo_label)
	combo_label.modulate = Color(1, 0.7, 0.2)

	xp_label = Label.new()
	xp_label.add_theme_font_size_override("font_size", 24)
	xp_label.position = Vector2(16, 148)
	layer.add_child(xp_label)
	xp_label.modulate = Color(0.55, 0.9, 1)

	var game_over_layer = CanvasLayer.new()
	game_over_layer.name = "GameOver"
	add_child(game_over_layer)

	game_over_root = Control.new()
	game_over_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_root.visible = false
	game_over_layer.add_child(game_over_root)

	var shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_root.add_child(shade)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	game_over_root.add_child(vbox)

	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	game_over_kills_label = Label.new()
	game_over_kills_label.add_theme_font_size_override("font_size", 32)
	game_over_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(game_over_kills_label)

	game_over_high_label = Label.new()
	game_over_high_label.add_theme_font_size_override("font_size", 28)
	game_over_high_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_high_label.modulate = Color(1, 0.8, 0.3)
	vbox.add_child(game_over_high_label)

	var restart = Button.new()
	restart.text = "Restart"
	restart.add_theme_font_size_override("font_size", 24)
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(restart)

	_setup_level_up_ui()

func _setup_level_up_ui():
	var layer = CanvasLayer.new()
	layer.name = "LevelUp"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	level_up_root = Control.new()
	level_up_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_root.visible = false
	level_up_root.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(level_up_root)

	var shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_root.add_child(shade)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	level_up_root.add_child(vbox)

	var title = Label.new()
	title.text = "LEVEL UP!"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1, 0.85, 0.3)
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Choose an upgrade:"
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	upgrade_box = VBoxContainer.new()
	upgrade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_box.add_theme_constant_override("separation", 12)
	vbox.add_child(upgrade_box)

func _setup_auto_spawn():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 4.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _prepare_enemy(enemy):
	enemy.drop_scene = pickup_scene
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(enemy_type: int):
	kills += 1
	var base := _score_for_type(enemy_type)
	_add_score(base)
	_add_xp(base)
	kills_label.text = "Kills: %d" % kills

func _add_xp(amount: int):
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 20 * level
		pending_levels += 1
	if pending_levels > 0 and not level_up_root.visible:
		_show_level_up()
	_update_xp_hud()

func _update_xp_hud():
	xp_label.text = "Lv %d   XP: %d/%d" % [level, xp, xp_needed]

func _show_level_up():
	get_tree().paused = true
	level_up_root.visible = true
	for child in upgrade_box.get_children():
		child.queue_free()
	for u in _pick_upgrades(3):
		var b := Button.new()
		b.text = "%s — %s" % [u["name"], u["desc"]]
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(380, 0)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var key: String = u["key"]
		b.pressed.connect(func(): _on_upgrade_picked(key))
		upgrade_box.add_child(b)

func _pick_upgrades(count: int) -> Array:
	var pool := UPGRADES.duplicate()
	pool.shuffle()
	return pool.slice(0, count)

func _on_upgrade_picked(key: String):
	if not level_up_root.visible:
		return
	_apply_upgrade(key)
	pending_levels -= 1
	if pending_levels > 0:
		_show_level_up()
	else:
		level_up_root.visible = false
		get_tree().paused = false

func _apply_upgrade(key: String):
	var player = get_node("Player")
	match key:
		"damage":
			player.damage += 1
		"firerate":
			player.fire_cooldown = max(0.1, player.fire_cooldown - 0.05)
		"hp":
			player.max_health += 1
			player.health = min(player.max_health, player.health + 1)
			player.health_changed.emit(player.health, player.max_health)
		"speed":
			player.speed += 15
		"shots":
			player.base_shots += 1
			player.shots_per_fire = max(player.shots_per_fire, player.base_shots)

func _add_score(base: int):
	if combo_timer > 0.0:
		combo += 1
	else:
		combo = 1
	combo_timer = COMBO_WINDOW
	score += base * combo
	_update_score_hud()

func _update_score_hud():
	score_label.text = "Score: %d" % score
	var text := "Combo: x%d" % combo
	if combo > 1:
		text += "  (%.1fs)" % combo_timer
	combo_label.text = text
	combo_label.modulate = Color(1, 0.7, 0.2) if combo > 1 else Color(1, 1, 1)

func _score_for_type(t: int) -> int:
	match t:
		ENEMY_SCRIPT.Type.FAST:
			return 15
		ENEMY_SCRIPT.Type.TANK:
			return 30
		ENEMY_SCRIPT.Type.RANGED:
			return 25
		_:
			return 10

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_timer = 0.0
			combo = 1
			_update_score_hud()

func _load_high_score():
	var cfg := ConfigFile.new()
	if cfg.load(SCORE_PATH) == OK:
		high_score = cfg.get_value("score", "high", 0)

func _save_high_score():
	if score <= high_score:
		return
	high_score = score
	var cfg := ConfigFile.new()
	cfg.set_value("score", "high", high_score)
	cfg.save(SCORE_PATH)

func _on_player_health_changed(current: int, maximum: int):
	health_label.text = "HP: %d/%d" % [current, maximum]

func _on_player_died():
	_save_high_score()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		bullet.set_physics_process(false)
	game_over_root.visible = true
	game_over_kills_label.text = "Kills: %d   Level: %d   Score: %d" % [kills, level, score]
	game_over_high_label.text = "High Score: %d" % high_score
	$CanvasLayer/Control.visible = false
	spawn_timer.stop()

func _on_spawn_timer_timeout():
	spawn_wave += 1
	var count = 1 + int(spawn_wave / 3)
	var alive = get_tree().get_nodes_in_group("enemy").size()
	count = mini(count, maxi(0, MAX_ENEMIES - alive))
	for i in range(count):
		_spawn_enemy(_random_spawn_position())

func _on_spawn_button_pressed():
	_spawn_enemy(_random_spawn_position())

func _spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	enemy.enemy_type = _random_enemy_type(spawn_wave)
	add_child(enemy)
	enemy.global_position = pos
	_prepare_enemy(enemy)

func _random_enemy_type(wave: int) -> int:
	var roll := randf()
	if wave < 2:
		return ENEMY_SCRIPT.Type.NORMAL
	if wave < 4:
		return ENEMY_SCRIPT.Type.FAST if roll < 0.4 else ENEMY_SCRIPT.Type.NORMAL
	if wave < 7:
		if roll < 0.1:
			return ENEMY_SCRIPT.Type.RANGED
		if roll < 0.3:
			return ENEMY_SCRIPT.Type.TANK
		if roll < 0.6:
			return ENEMY_SCRIPT.Type.FAST
		return ENEMY_SCRIPT.Type.NORMAL
	if roll < 0.2:
		return ENEMY_SCRIPT.Type.RANGED
	if roll < 0.45:
		return ENEMY_SCRIPT.Type.TANK
	if roll < 0.75:
		return ENEMY_SCRIPT.Type.FAST
	return ENEMY_SCRIPT.Type.NORMAL

func _random_spawn_position() -> Vector2:
	var player = get_node("Player")
	var offsets := [
		Vector2(450, 0), Vector2(-450, 0), Vector2(0, 450), Vector2(0, -450),
		Vector2(450, 300), Vector2(-450, 300), Vector2(450, -300), Vector2(-450, -300),
	]
	offsets.shuffle()
	for off in offsets:
		var pos = player.global_position + off + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		pos = Vector2(
			clampf(pos.x, -580, 1570),
			clampf(pos.y, -420, 1090)
		)
		if not _is_position_blocked(pos):
			return pos
	return Vector2(183, 550) + Vector2(320, -656)

func _is_position_blocked(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.position = pos
	point_query.collision_mask = 2
	if not space.intersect_point(point_query).is_empty():
		return true
	clearance_shape.radius = 60.0
	var sq := PhysicsShapeQueryParameters2D.new()
	sq.shape = clearance_shape
	sq.transform = Transform2D(0, pos)
	sq.collision_mask = 2
	return not space.intersect_shape(sq).is_empty()
