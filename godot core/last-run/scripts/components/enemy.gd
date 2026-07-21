# enemy.gd
extends CharacterBody2D

@export var speed: float = 80.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0

# Имена анимаций — ПОСМОТРИ в своём AnimatedSprite2D и впиши точно как там
@export var run_anim: StringName = &"run"
@export var attack_anim: StringName = &"attack"
@export var idle_anim: StringName = &"idle"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer

var player: CharacterBody2D = null
var can_attack: bool = true
var player_in_range: bool = false   # игрок внутри зоны атаки

func _ready() -> void:
	health.health_depleted.connect(_on_enemy_death)
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_end)

	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	_try_find_player()

func _physics_process(_delta: float) -> void:
	if player == null:
		_try_find_player()
		return
	if not health.is_alive():
		return

	# Разворот спрайта к игроку — всегда
	var dir := (player.global_position - global_position)
	if dir.x < 0:   sprite.flip_h = true
	elif dir.x > 0: sprite.flip_h = false

	if player_in_range:
		# === В УПОР: стоим и бьём, показываем атаку ===
		velocity = Vector2.ZERO
		if sprite.animation != attack_anim:
			sprite.play(attack_anim)
	else:
		# === ПРЕСЛЕДОВАНИЕ - RUN ===
		velocity = dir.normalized() * speed
		move_and_slide()
		if sprite.animation != run_anim:
			sprite.play(run_anim)

func _try_find_player() -> void:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		player = nodes[0] as CharacterBody2D
		return
	var root := get_tree().current_scene
	if root:
		var found := root.find_child("Player", true, false)
		if found is CharacterBody2D:
			player = found

# === КОНТАКТ С ИГРОКОМ ===
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:                 # <-- надёжнее, чем проверка группы
		player_in_range = true
		if can_attack:
			_deal_damage_to_player()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false

func _deal_damage_to_player() -> void:
	if player == null or not can_attack:
		return
	can_attack = false
	attack_timer.start()
	var knockback_dir := (player.global_position - global_position).normalized()
	if player.has_method("receive_damage"):
		player.receive_damage(damage, knockback_dir)

func _on_attack_cooldown_end() -> void:
	can_attack = true
	if player_in_range:                # всё ещё в упор — бьём снова
		_deal_damage_to_player()

# === УРОН ПО ВРАГУ (от пуль, на будущее) ===
func receive_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if not health.is_alive():
		return
	health.take_damage(amount)
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	if knockback_dir != Vector2.ZERO:
		velocity += knockback_dir * 150.0

# === СМЕРТЬ ===
func _on_enemy_death() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
