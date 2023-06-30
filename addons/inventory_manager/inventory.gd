@tool

extends Control

#Button-slots hardcoded for simplicity because the original game has a 9-item limit... I think?

#not fully tested, seems functional enough 
#small issue with horizontal size and horizontal resizing of docks in the same slot

signal inventory_changed(inv)


const treasure_animations = preload("res://animations/treasure.tres")
const restore_animations = preload("res://animations/restore.tres")
const powerup_animations = preload("res://animations/powerup.tres")
const teleporter_animations = preload("res://animations/teleporter.tres")
const end_item_animations = preload("res://animations/end_item.tres")

var selection_contents = []: set = set_selection_contents
var temp_contents = []: set = set_temp_contents
var selected : int
var valid_selection := false
var list = preload("res://addons/inventory_manager/pickup_list.tscn").instantiate()
var teleporter_panel = preload("res://addons/inventory_manager/teleporter_panel.tscn").instantiate()
var powerup_panel = preload("res://addons/inventory_manager/powerup_panel.tscn").instantiate()
var end_item_panel = preload("res://addons/inventory_manager/end_item_panel.tscn").instantiate()
var food_item_panel = preload("res://addons/inventory_manager/food_item_panel.tscn").instantiate()
var edited_item = []

@onready var inventory_slots = $VBoxContainer/HBoxContainer/GridContainer
@onready var item_properties = $VBoxContainer/PanelContainer/VBoxContainer
@onready var confirmed_label = $VBoxContainer/HBoxContainer/VBoxContainer/Label3
@onready var confirm_button = $VBoxContainer/HBoxContainer/VBoxContainer/Button
@onready var discard_button = $VBoxContainer/HBoxContainer/VBoxContainer/Button2
@onready var valid_object_label = $VBoxContainer/Label


func set_selection_contents(value) -> void:
	selection_contents = value.duplicate(true)
	set_temp_contents(selection_contents)


func set_temp_contents(value) -> void:
	temp_contents = value.duplicate(true)
	var slots = inventory_slots.get_children()
	for slot in slots:
		slot.get_node("AnimatedSprite2D").play("Empty")
	if !temp_contents.is_empty():
		var index := 0
		for item in temp_contents:
			var slot_animation = slots[index].get_node("AnimatedSprite2D")
			slot_animation.rotation_degrees = 0 #reset from vertical teleporter switch
			match item[0]:
				0: #treasure
					slot_animation.scale = Vector2(1, 1)
					slot_animation.frames = treasure_animations
					if item[1] in ["Coin", "Bars", "Pearls"]:
						slot_animation.play(item[1])
					else:
						slot_animation.play("%s_%s" % [item[1], item[2]])
						
				1: #restore
					slot_animation.scale = Vector2(1, 1)
					slot_animation.frames = restore_animations
					if item[1] in ["Dynamite", "Extra_Life"]:
						slot_animation.play(item[1])
					elif item[1] in ["Ammo","Health","Magic"]:
						slot_animation.play("%s_%s" % [item[1], item[2]])
					else: #Health_Food
						slot_animation.play(item[2])
						
				2: #powerup
					slot_animation.scale = Vector2(0.9, 0.9)
					slot_animation.frames = powerup_animations
					slot_animation.play(Settings.Powerups.keys()[item[1]-1])
					
				3: #teleporter
					slot_animation.scale = Vector2(0.8, 0.8) 
					slot_animation.frames = teleporter_animations
					var degrees = 0 if item[3] == "Horizontal" else 90
					slot_animation.rotation_degrees = degrees
					slot_animation.play(item[1])
					
				4: #enditem
					slot_animation.scale = Vector2(0.8, 0.8)
					slot_animation.frames = end_item_animations
					slot_animation.play(item[1])
					
			index += 1
	else:
		for slot in inventory_slots.get_children():
			slot.get_node("AnimatedSprite2D").play("Empty")
	confirm_button.disabled = selection_contents == temp_contents and !item_properties.visible
	discard_button.disabled = confirm_button.disabled 


func _ready() -> void:
	if Engine.is_editor_hint():
		set_temp_contents(selection_contents)
		add_child(list)
		list.visible = false
		list.connect("selected", Callable(self, "_on_list_item_selected"))
		for button in inventory_slots.get_children():
			button.connect("button_down_self", Callable(self, "_get_selected_slot"))
			button.get_popup().connect("id_pressed", Callable(self, "_on_menu_option_pressed"))
		
		for panel in [teleporter_panel, powerup_panel, end_item_panel, food_item_panel]:
			item_properties.add_child(panel)
			panel.connect("item_modified", Callable(self, "_on_item_modified"))
			panel.visible = false
		confirm_button.disabled = true
		discard_button.disabled = true


func clear() -> void:
	set_selection_contents([])


func toggle(x) -> void:
	valid_selection = x
	for slot in inventory_slots.get_children():
		slot.disabled = !x
		slot.get_node("AnimatedSprite2D").play("Empty")
	valid_object_label.text = "Valid Item" if x else "Invalid Item"


func _on_confirm_pressed() -> void:
	emit_signal("inventory_changed", temp_contents)
	confirmed_label.visible = true
	confirmed_label.get_node("Timer").start(2.0)
	confirm_button.disabled = true
	discard_button.disabled = true


func _on_discard_pressed() -> void:
	set_temp_contents(selection_contents)


#get the selected button id from its node name (calls the custom signal that carries the button object)
func _get_selected_slot(slot) -> void:
	selected = int(slot.name.lstrip("Button")) - 1 #starts from 1
	var button_popup = inventory_slots.get_children()[selected].get_popup()
	#reset the popup menu
	button_popup.set_item_disabled(0, false) 
	button_popup.set_item_disabled(1, false) 
	button_popup.set_item_disabled(2, false) 
	if !len(temp_contents) == 0 and len(temp_contents) > selected: #if there's an item in this slot
		#if it's a treasure or restore item, disable the edit option
		if temp_contents[selected][0] == 0 or (temp_contents[selected][0] == 1 
				and temp_contents[selected][1] != "Health_Food"): 
			button_popup.set_item_disabled(2, true) 
		else:
			button_popup.set_item_disabled(2, false) 
			
	else:#if there's no item in this slot, disable the edit and remove options
		button_popup.set_item_disabled(1, true) 
		button_popup.set_item_disabled(2, true) 


func _on_menu_option_pressed(index : int) -> void:
	match index:
		0: #add item
			list.get_global_position()
			#code adapted from... some node inheritance addon thing I found online
			var x = Vector2(get_tree().get_root().size.x,0) / 2
			var pos = self.get_global_position()
			var side = 1 if pos > x else 0
			list.set_global_position(self.get_global_position()+Vector2(side * -200,20))
			list.popup()
			
		1: #clear slot
			if len(temp_contents) >= selected and len(temp_contents) != 0:
				temp_contents.remove(selected)
				set_temp_contents(temp_contents)
			_on_cancel_pressed()
			
		2: #edit item
			if temp_contents[selected][0] != 0:
				item_properties.visible = true
				edited_item = temp_contents.duplicate(true)[selected] 
				var panel
				match edited_item[0]:
					1:
						panel = food_item_panel
					2:
						panel = powerup_panel
					3:
						panel = teleporter_panel
					4:
						panel = end_item_panel
				hide_property_panels()
				panel.visible = true
				panel.set_from_item(edited_item)


func _on_list_item_selected(item) -> void:
	temp_contents.append(item)
	set_temp_contents(temp_contents)


func _on_apply_pressed() -> void:
	temp_contents[selected] = edited_item.duplicate(true)
	set_temp_contents(temp_contents)
	item_properties.visible = false
	hide_property_panels()


func _on_cancel_pressed() -> void:
	item_properties.visible = false
	hide_property_panels()
	edited_item = []


func _on_item_modified(property, value) -> void:
	edited_item[property] = value


func hide_property_panels() -> void:
	powerup_panel.visible = false
	teleporter_panel.visible = false
	end_item_panel.visible = false
	food_item_panel.visible = false


func _on_confirm_label_timeout() -> void:
	confirmed_label.visible = false
	confirmed_label.get_node("Timer").stop()
