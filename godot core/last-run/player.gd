extends CharacterBody2D

@export var speed: float = 250.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent

# Визуальный фидбек при уроне
var is_hurt: bool = false
var hurt_timer: float = 0.0
const HURT_DURATION: float = 0.15

# Переменные для полоски здоровья
var hp_fill: ColorRect
var hp_bg: ColorRect
const HP_BAR_WIDTH: float = 48.0
const HP_BAR_HEIGHT: float = 6.0

func _ready() -> void:
	health.health_depleted.connect(_on_player_death)
	health.health_changed.connect(_on_health_changed)
	_build_health_bar()

func _physics_process(delta: float) -> void:
	# === ДВИЖЕНИЕ ===
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		velocity.x = move_toward(velocity.x, input_dir.x * speed, acceleration * delta)
		velocity.y = move_toward(velocity.y, input_dir.y * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y = move_toward(velocity.y, 0, friction * delta)
	
	move_and_slide()
	_update_animation(input_dir)
	
	# === МИГАНИЕ ПРИ УРОНЕ ===
	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
			sprite.modulate = Color.WHITE

func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

# === ПУБЛИЧНЫЙ МЕТОД: враг вызывает его ===
func receive_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if not health.is_alive():
		return
	
	health.take_damage(amount)
	
	# Визуал: мигание красным
	is_hurt = true
	hurt_timer = HURT_DURATION
	sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
	
	# Отбрасывание (knockback)
	if knockback_dir != Vector2.ZERO:
		velocity += knockback_dir * 200.0

func _build_health_bar() -> void:
	var bar_root := Node2D.new()
	bar_root.name = "HealthBar"
	bar_root.position = Vector2(0, -45)   # Высота над головой (подбери -45, -50 или -60 под свой спрайт)
	bar_root.z_index = 50                 # Поверх всего
	add_child(bar_root)

	hp_bg = ColorRect.new()
	hp_bg.color = Color(0.15, 0.0, 0.0, 0.85)
	hp_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	hp_bg.position = Vector2(-HP_BAR_WIDTH / 2.0, 0)
	bar_root.add_child(hp_bg)

	hp_fill = ColorRect.new()
	hp_fill.color = Color(0.1, 0.9, 0.2)
	hp_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	hp_fill.position = Vector2(-HP_BAR_WIDTH / 2.0, 0)
	bar_root.add_child(hp_fill)

	# Сразу отрисовать полное здоровье
	_on_health_changed(health.current_hp, health.max_hp)

func _on_health_changed(current: float, maximum: float) -> void:
	if hp_fill == null:
		return
	var ratio: float = clampf(current / maximum, 0.0, 1.0)
	hp_fill.size.x = HP_BAR_WIDTH * ratio
	# Плавная смена цвета: зелёный -> жёлтый -> красный
	hp_fill.color = Color(1.0 - ratio, ratio, 0.1).lerp(Color(0.1, 0.9, 0.2), ratio * 0.5)

func _on_player_death() -> void:
	print("PLAYER DIED — GAME OVER")
	set_physics_process(false)
	if sprite.animation == "death":
		sprite.play("death")
	else:
		sprite.play("idle")
