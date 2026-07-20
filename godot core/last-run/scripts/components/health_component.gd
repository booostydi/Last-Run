# health_component.gd
extends Node
class_name HealthComponent

signal health_changed(current_hp: float, max_hp: float)
signal health_depleted  # смерть

@export var max_hp: float = 100.0
var current_hp: float = max_hp


func _ready() -> void:
	current_hp = max_hp

func take_damage(amount: float) -> void:
	if current_hp <= 0:
		return  # уже мёртв, игнорируем
	
	current_hp -= amount
	current_hp = max(current_hp, 0)  # не уходим в минус
	
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		health_depleted.emit()

func heal(amount: float) -> void:
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)

func is_alive() -> bool:
	return current_hp > 0
