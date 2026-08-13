extends Node2D

enum DecorType { POND, FLOWER, BUSH, ROCK, TREE, TALL_TREE, WALL }

@export var random_seed: int = 1337
@export var decoration_count: int = 160
@export var arena_rect := Rect2(-937, 199, 2240, 1600)
@export var player_start := Vector2(183, 999)
@export var clear_radius: float = 170.0

var items: Array[Dictionary] = []

const FLOWER_COLORS: Array[Color] = [
	Color(0.9, 0.32, 0.32),
	Color(0.95, 0.8, 0.2),
	Color(0.65, 0.38, 0.9),
	Color(0.95, 0.95, 0.95),
]

const BOUNDARY: Array[Dictionary] = [
	{"pos": Vector2(183, 199), "size": Vector2(1872, 32), "rot": 0.0},
	{"pos": Vector2(1203, 299), "size": Vector2(314, 32), "rot": 0.785398},
	{"pos": Vector2(1303, 999), "size": Vector2(32, 1232), "rot": 0.0},
	{"pos": Vector2(1203, 1699), "size": Vector2(314, 32), "rot": 2.35619},
	{"pos": Vector2(183, 1799), "size": Vector2(1872, 32), "rot": 0.0},
	{"pos": Vector2(-837, 1699), "size": Vector2(314, 32), "rot": -2.35619},
	{"pos": Vector2(-937, 999), "size": Vector2(32, 1232), "rot": 0.0},
	{"pos": Vector2(-837, 299), "size": Vector2(314, 32), "rot": -0.785398},
]

func _ready():
	_generate()
	_add_colliders()
	queue_redraw()

func _generate():
	items.clear()
	_add(DecorType.POND, Vector2(-420, 900), 1.1, 1)
	_add(DecorType.POND, Vector2(780, 1340), 0.85, 2)
	_add(DecorType.POND, Vector2(620, 430), 0.6, 3)
	_add(DecorType.TREE, Vector2(-560, 420), 1.3, 1)
	_add(DecorType.TREE, Vector2(880, 620), 1.2, 2)
	_add(DecorType.WALL, Vector2(-550, 600), 1.0, 0, Vector2(700, 34))
	_add(DecorType.WALL, Vector2(750, 600), 1.0, 1, Vector2(600, 34))
	_add(DecorType.WALL, Vector2(-300, 1200), 1.0, 2, Vector2(600, 34))
	_add(DecorType.WALL, Vector2(850, 1200), 1.0, 3, Vector2(400, 34))
	_add(DecorType.WALL, Vector2(-600, 1500), 1.0, 4, Vector2(600, 34))
	_add(DecorType.WALL, Vector2(250, 1500), 1.0, 5, Vector2(600, 34))
	_add(DecorType.WALL, Vector2(500, 850), 1.0, 6, Vector2(34, 500))
	_add(DecorType.WALL, Vector2(-700, 1000), 1.0, 7, Vector2(34, 400))
	_add(DecorType.WALL, Vector2(900, 350), 1.0, 0, Vector2(34, 300))

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var placed := 0
	var attempts := 0
	while placed < decoration_count and attempts < decoration_count * 6:
		attempts += 1
		var pos := Vector2(
			rng.randf_range(arena_rect.position.x + 56, arena_rect.position.x + arena_rect.size.x - 56),
			rng.randf_range(arena_rect.position.y + 56, arena_rect.position.y + arena_rect.size.y - 56)
		)
		if pos.distance_to(player_start) < clear_radius:
			continue
		if _too_close(pos):
			continue
		var roll := rng.randf()
		if roll < 0.4:
			var dtype := DecorType.TREE
			_add(dtype, pos, rng.randf_range(0.8, 1.35), rng.randi_range(0, 7))
		elif roll < 0.6:
			_add(DecorType.BUSH, pos, rng.randf_range(0.8, 1.4), rng.randi_range(0, 7))
		elif roll < 0.76:
			_add(DecorType.FLOWER, pos, rng.randf_range(0.8, 1.4), rng.randi_range(0, 7))
		else:
			_add(DecorType.ROCK, pos, rng.randf_range(0.7, 1.4), rng.randi_range(0, 7))
		placed += 1

func _too_close(pos: Vector2) -> bool:
	for item in items:
		var dist := pos.distance_to(item["pos"])
		match item["type"]:
			DecorType.TREE, DecorType.TALL_TREE:
				if dist < 90.0:
					return true
			DecorType.POND:
				if dist < 130.0:
					return true
			DecorType.WALL:
				if dist < 150.0:
					return true
			_:
				if dist < 42.0:
					return true
	return false

func _add(type: DecorType, pos: Vector2, scale_f: float, variant: int, size := Vector2.ZERO):
	items.append({"type": type, "pos": pos, "scale": scale_f, "variant": variant, "size": size})

func _draw():
	for b in BOUNDARY:
		draw_set_transform(b["pos"], b["rot"], Vector2.ONE)
		_draw_wall(Vector2.ZERO, b["size"], 0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if items.is_empty():
		return
	for item in items:
		match item["type"]:
			DecorType.TREE:
				_draw_tree(item["pos"], item["scale"], item["variant"])
			DecorType.TALL_TREE:
				_draw_tall_tree(item["pos"], item["scale"], item["variant"])
			DecorType.BUSH:
				_draw_bush(item["pos"], item["scale"], item["variant"])
			DecorType.FLOWER:
				_draw_flower(item["pos"], item["scale"], item["variant"])
			DecorType.ROCK:
				_draw_rock(item["pos"], item["scale"], item["variant"])
			DecorType.POND:
				_draw_pond(item["pos"], item["scale"], item["variant"])
			DecorType.WALL:
				_draw_wall(item["pos"], item["size"], item["variant"])

func _add_colliders():
	for item in items:
		var size := Vector2.ZERO
		match item["type"]:
			DecorType.WALL:
				size = item["size"]
			DecorType.POND:
				size = Vector2(124.0, 80.0) * item["scale"]
			DecorType.ROCK:
				size = Vector2(34.0, 20.0) * item["scale"]
		if size.x <= 0.0 or size.y <= 0.0:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = 2
		body.position = item["pos"]
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		body.add_child(shape)
		add_child(body)

func _shade(v: int) -> float:
	return 0.88 + 0.12 * float(v % 3) / 2.0

func _draw_tree(pos: Vector2, s: float, v: int):
	var sh := _shade(v)
	var dark := Color(0.09 * sh, 0.33 * sh, 0.15 * sh)
	var light := Color(0.2 * sh, 0.55 * sh, 0.26 * sh)
	draw_rect(Rect2(pos.x - 4.0 * s, pos.y - 2.0 * s, 8.0 * s, 24.0 * s), Color(0.36, 0.24, 0.14))
	draw_circle(pos + Vector2(0, -15) * s, 17.0 * s, dark)
	draw_circle(pos + Vector2(-13, -7) * s, 11.0 * s, dark)
	draw_circle(pos + Vector2(13, -7) * s, 11.0 * s, dark)
	draw_circle(pos + Vector2(-6, -20) * s, 8.0 * s, light)
	draw_circle(pos + Vector2(6, -16) * s, 7.0 * s, light)

func _draw_tall_tree(pos: Vector2, s: float, v: int):
	var sh := _shade(v)
	var dark := Color(0.08 * sh, 0.3 * sh, 0.14 * sh)
	var light := Color(0.18 * sh, 0.5 * sh, 0.24 * sh)
	draw_rect(Rect2(pos.x - 5.0 * s, pos.y - 2.0 * s, 10.0 * s, 36.0 * s), Color(0.3, 0.2, 0.12))
	draw_circle(pos + Vector2(0, -24) * s, 21.0 * s, dark)
	draw_circle(pos + Vector2(-16, -12) * s, 13.0 * s, dark)
	draw_circle(pos + Vector2(16, -12) * s, 13.0 * s, dark)
	draw_circle(pos + Vector2(-7, -30) * s, 10.0 * s, light)
	draw_circle(pos + Vector2(7, -25) * s, 9.0 * s, light)

func _draw_bush(pos: Vector2, s: float, v: int):
	var sh := _shade(v)
	var dark := Color(0.1 * sh, 0.36 * sh, 0.16 * sh)
	var light := Color(0.2 * sh, 0.56 * sh, 0.28 * sh)
	draw_circle(pos + Vector2(0, -7) * s, 13.0 * s, dark)
	draw_circle(pos + Vector2(-10, -2) * s, 9.0 * s, dark)
	draw_circle(pos + Vector2(10, -2) * s, 9.0 * s, dark)
	draw_circle(pos + Vector2(-5, -12) * s, 6.0 * s, light)
	draw_circle(pos + Vector2(5, -8) * s, 5.0 * s, light)
	draw_circle(pos + Vector2(-7, -4) * s, 2.0 * s, Color(0.85, 0.25, 0.25))
	draw_circle(pos + Vector2(6, -3) * s, 2.0 * s, Color(0.85, 0.25, 0.25))

func _draw_flower(pos: Vector2, s: float, v: int):
	var base := FLOWER_COLORS[v % FLOWER_COLORS.size()]
	for i in 5:
		var ang := TAU * i / 5.0
		var off := Vector2(cos(ang), sin(ang) * 0.8) * 11.0 * s
		draw_circle(pos + off, 4.2 * s, base)
		draw_circle(pos + off, 1.6 * s, Color(0.98, 0.9, 0.5))
	draw_circle(pos, 2.4 * s, Color(0.3, 0.55, 0.25))

func _draw_rock(pos: Vector2, s: float, v: int):
	var dark := Color(0.33, 0.35, 0.38)
	var light := Color(0.5, 0.52, 0.55)
	var rel := [Vector2(-15, 6), Vector2(-12, -6), Vector2(-2, -11), Vector2(10, -8), Vector2(15, 3), Vector2(7, 9)]
	var pts := PackedVector2Array()
	for r in rel:
		pts.append(pos + r * s)
	draw_colored_polygon(pts, dark)
	var hi := PackedVector2Array()
	for r in [Vector2(-9, -2), Vector2(-5, -7), Vector2(2, -8)]:
		hi.append(pos + r * s)
	draw_colored_polygon(hi, light)

func _draw_pond(pos: Vector2, s: float, v: int):
	var n := 40
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		outer.append(pos + Vector2(cos(a) * 62.0 * s, sin(a) * 40.0 * s))
		inner.append(pos + Vector2(cos(a) * 46.0 * s, sin(a) * 29.0 * s))
	draw_colored_polygon(outer, Color(0.14, 0.42, 0.58, 0.92))
	draw_colored_polygon(inner, Color(0.3, 0.65, 0.82, 0.95))
	draw_arc(pos, 24.0 * s, 0, TAU, 32, Color(0.75, 0.9, 0.98, 0.9), 2.4 * s)
	draw_arc(pos + Vector2(-10, 7) * s, 14.0 * s, 0, TAU, 28, Color(0.75, 0.9, 0.98, 0.75), 1.8 * s)

func _draw_wall(pos: Vector2, size: Vector2, v: int):
	var sh := _shade(v)
	var base := Color(0.45 * sh, 0.47 * sh, 0.5 * sh)
	var dark := Color(0.3 * sh, 0.32 * sh, 0.36 * sh)
	var top := Color(0.62 * sh, 0.64 * sh, 0.68 * sh)
	draw_rect(Rect2(pos.x - size.x / 2, pos.y - size.y / 2, size.x, size.y), base)
	if size.x >= size.y:
		var step := 34.0
		var x := pos.x - size.x / 2 + step / 2
		while x < pos.x + size.x / 2:
			draw_line(Vector2(x, pos.y - size.y / 2), Vector2(x, pos.y + size.y / 2), dark, 1.6)
			x += step
		draw_line(Vector2(pos.x - size.x / 2, pos.y), Vector2(pos.x + size.x / 2, pos.y), dark, 1.6)
	else:
		var step := 34.0
		var y := pos.y - size.y / 2 + step / 2
		while y < pos.y + size.y / 2:
			draw_line(Vector2(pos.x - size.x / 2, y), Vector2(pos.x + size.x / 2, y), dark, 1.6)
			y += step
		draw_line(Vector2(pos.x, pos.y - size.y / 2), Vector2(pos.x, pos.y + size.y / 2), dark, 1.6)
	draw_rect(Rect2(pos.x - size.x / 2, pos.y - size.y / 2, size.x, 4), top)
