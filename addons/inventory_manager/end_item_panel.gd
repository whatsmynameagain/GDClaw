tool
extends PanelContainer


signal item_modified(property, value)

var type := "Map"
var drop_anim := true
var drop_anim_position := Vector2.ZERO

onready var type_list = $VBoxContainer/HBoxContainer/OptionButton
onready var drop_anim_toggle = $VBoxContainer/HBoxContainer2/CheckBox
onready var drop_anim_x = $VBoxContainer/HBoxContainer3/SpinBox
onready var drop_anim_y = $VBoxContainer/HBoxContainer3/SpinBox2


func set_from_item(item) -> void:
	match item[1]:
		"Map":
			type_list.selected = 0
		"Blue":
			type_list.selected = 1
		"Green":
			type_list.selected = 2
		"Red":
			type_list.selected = 3
		"RedBlue":
			type_list.selected = 4
		"Center":
			type_list.selected = 5
	drop_anim_toggle = item[2]
	drop_anim_x.value = item[3].x
	drop_anim_y.value = item[3].y


func _on_type_item_selected(id: int) -> void:
	match id:
		0:
			type = "Map"
		1:
			type = "Blue"
		2:
			type = "Green"
		3:
			type = "Red"
		4:
			type = "RedBlue"
		5:
			type = "Center"
	emit_signal("item_modified", 1, type)


func _on_drop_animation_toggled(button_pressed: bool) -> void:
	drop_anim = button_pressed
	emit_signal("item_modified", 2, drop_anim)


func _on_x_value_changed(value: float) -> void:
	drop_anim_x = int(value) 
	emit_signal("item_modified", 3, drop_anim_x)
	
	
func _on_y_value_changed(value: float) -> void:
	drop_anim_y = int(value) 
	emit_signal("item_modified", 3, drop_anim_y)
