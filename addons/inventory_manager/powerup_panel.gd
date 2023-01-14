tool
extends PanelContainer


signal item_modified(property, value)

var duration := 15
var stack_duration := true
var use := false

onready var duration_value = $VBoxContainer/HBoxContainer/SpinBox
onready var stack_duration_toggle = $VBoxContainer/HBoxContainer2/CheckButton
onready var one_use = $VBoxContainer/HBoxContainer3/CheckBox


func set_from_item(item) -> void:
	duration_value.value = item[2]
	stack_duration = item[3]
	one_use.pressed = item[4]


func _on_duration_value_changed(value: float) -> void:
	duration = int(value)
	emit_signal("item_modified", 2, duration)


func _on_stack_duration_toggled(button_pressed: bool) -> void:
	stack_duration = button_pressed
	emit_signal("item_modified", 3, stack_duration)


func _on_one_use_toggled(button_pressed: bool) -> void:
	use = button_pressed
	emit_signal("item_modified", 4, use)
