tool
extends PanelContainer


signal item_modified(property, value)

var destination = Vector2.ZERO
var use := false

onready var type_list = $VBoxContainer/HBoxContainer/CheckBox
onready var orientation_list = $VBoxContainer/HBoxContainer3/CheckBox
onready var destination_x = $VBoxContainer/HBoxContainer2/SpinBox
onready var destination_y = $VBoxContainer/HBoxContainer2/SpinBox2
onready var one_use = $VBoxContainer/HBoxContainer4/CheckBox


func set_from_item(item) -> void:
	type_list.selected = 0 if item[1] == "Generic" else 1
	orientation_list.selected = 0 if item[3] == "Horizontal" else 1
	destination_x.value = item[2].x
	destination_y.value = item[2].y
	one_use.pressed = item[4]


func _on_type_selected(id: int) -> void:
	var type = "Generic" if id == 0 else "Boss"
	emit_signal("item_modified", 1, type)
	orientation_list.disabled = true if type == "Boss" else false


func _on_orientation_selected(id: int) -> void:
	var orientation = "Horizontal" if id == 0 else "Vertical"
	emit_signal("item_modified", 3, orientation)


func _on_x_value_changed(value: float) -> void:
	destination.x = int(value)
	emit_signal("item_modified", 2, destination)


func _on_y_value_changed(value: float) -> void:
	destination.y = int(value)
	emit_signal("item_modified", 2, destination)


func _on_one_use_toggled(button_pressed: bool) -> void:
	use = button_pressed
	emit_signal("item_modified", 4, use)
