@tool
extends Node2D

@onready var animation = get_node("AnimatedSprite2D")


func _ready() -> void:
	if !Engine.is_editor_hint():
		animation.stop()
		visible = false
