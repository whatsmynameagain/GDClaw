@tool
extends PanelContainer


signal item_modified(property, value)

var model := "1-2"

@onready var model_list = $VBoxContainer/HBoxContainer/CheckBox


func set_from_item(item) -> void:
	match item[1]:
		"1-2":
			model_list.selected = 0
		"3-4":
			model_list.selected = 1
		"5-6":
			model_list.selected = 2
		"7-8":
			model_list.selected = 3
		"9-10":
			model_list.selected = 4
		"11-12":
			model_list.selected = 5
		"13":
			model_list.selected = 6
		"14":
			model_list.selected = 7


func _on_model_selected(id: int) -> void:
	match id:
		0:
			model = "1-2"
		1:
			model = "3-4"
		2:
			model = "5-6"
		3:
			model = "7-8"
		4:
			model = "9-10"
		5:
			model = "11-12"
		6:
			model = "13"
		7:
			model = "14"
	emit_signal("item_modified", 2, model)
