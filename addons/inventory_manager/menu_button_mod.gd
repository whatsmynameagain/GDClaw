tool
extends Button

signal button_down_self(_self)


func _ready() -> void:
	connect("button_down", self, "_add_self")


func _add_self() -> void:
	emit_signal("button_down_self", self)
