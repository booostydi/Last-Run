extends CharacterBody2D

# Скорость и плавность движения (можно менять в Инспекторе)
@export var speed: float = 250.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@onready var sprite := $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. Получаем направление движения (WASD или стрелки)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 2. Рассчитываем ускорение и торможение
	if input_dir != Vector2.ZERO:
		# Разгон
		velocity.x = move_toward(velocity.x, input_dir.x * speed, acceleration * delta)
		velocity.y = move_toward(velocity.y, input_dir.y * speed, acceleration * delta)
	else:
		# Торможение (инерция)
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.y = move_toward(velocity.y, 0, friction * delta)

	# 3. Применяем движение
	move_and_slide()

	# 4. Управление анимацией
	_update_animation(input_dir)

func _update_animation(direction):
	
	if direction != Vector2.ZERO:
		# Отзеркаливаем спрайт, если идем влево
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false
			
		# Включаем анимацию ходьбы
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		# Включаем анимацию покоя
		if sprite.animation != "idle":
			sprite.play("idle")
