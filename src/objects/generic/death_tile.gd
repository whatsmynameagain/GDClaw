extends Node2D

#maybe make it a tool similar to ladders... soon(tm)
class_name DeathTile

enum Death_Types {SET_BY_LEVEL = 0, 
		SPIKES = Settings.Damage_Types.SPIKES, 
		LIQUID = Settings.Damage_Types.LIQUID}
		
@export var death_type: Death_Types = Death_Types.SPIKES
@export var size : int :
	set(value):
		set_size(value)

@onready var area = $DeathArea


func _get_class() -> String:
	return "DeathTile"


func _is_class(name) -> bool:
	return name == "DeathTile" or super.is_class(name)


func set_size(value) -> void:
	size = value
	if !Engine.is_editor_hint():
		area.position.x = (32 * size)
		area.scale.x = size - 1


func _on_body_entered(body: Node) -> void:
	if body.is_class("Player") or body.is_class("Pickup"):
		body.on_death(death_type)
	elif body.is_class("Enemy"):
		body.on_death(death_type, 0)
