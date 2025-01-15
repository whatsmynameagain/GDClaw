extends Node2D

class_name HUDElement


var sprites = {}

@onready var animation = get_node("AnimatedSprite2D")


func _ready() -> void:
	animation.play()


func update_value(num : int) -> void:
	Utils.update_sprites(num, get_node("Sprites").get_children().size(), self, sprites)


func update_position():
	position.x = get_parent().size.x
