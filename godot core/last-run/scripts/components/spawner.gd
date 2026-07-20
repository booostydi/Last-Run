extends Node2D

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn") #Путь

@export var spawn_interval: float = 2.0
@export var max_enemies: int = 30
@export var min_distance_to_player: float = 250.0

@export var spawn_top_left: Marker2D
@export var spawn_bottom_right: Marker2D

var spawn_timer: Timer
var _warned: bool = false

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)
	spawn_timer.start()

func _spawn_enemy() -> void:
	if spawn_top_left == null or spawn_bottom_right == null:
		if not _warned:
			push_error("Spawner: назначь spawn_top_left и spawn_bottom_right в инспекторе!")
			_warned = true
		return

	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if enemies.size() >= max_enemies:
		return

	# Явное указание типа Node убирает ошибку Variant
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		var root: Node = get_tree().current_scene
		if root != null:
			var found: Node = root.find_child("Player", true, false)
			if found != null:
				player = found

	var spawn_pos: Vector2 = _pick_spawn_position(player)

	var enemy: Node2D = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)

func _pick_spawn_position(player: Node) -> Vector2:
	var tl: Vector2 = spawn_top_left.global_position
	var br: Vector2 = spawn_bottom_right.global_position
	
	var min_x: float = min(tl.x, br.x)
	var max_x: float = max(tl.x, br.x)
	var min_y: float = min(tl.y, br.y)
	var max_y: float = max(tl.y, br.y)

	# 12 попыток найти точку внутри маркеров и не в упор к игроку
	for i in 12:
		var pos: Vector2 = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		if player == null or pos.distance_to(player.global_position) >= min_distance_to_player:
			return pos
			
	# Если не удалось найти идеальную точку, возвращаем любую внутри зоны
	return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
