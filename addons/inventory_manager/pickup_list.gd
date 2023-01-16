tool

extends PopupPanel

class_name PickupList

#item selection specifics (double click, right click, etc) can be experimented with

signal selected(item)


const treasure_animations = preload("res://animations/treasure.tres")
const restore_animations = preload("res://animations/restore.tres")
const powerup_animations = preload("res://animations/powerup.tres")
const teleporter_animations  = preload("res://animations/teleporter.tres")
const end_item_animations  = preload("res://animations/end_item.tres")

var contents = [
	[0, "Coin"],
	[0, "Bars"],
	[0, "Pearls"],
	[4, "Blue", false, Vector2(0,0)],
	
	[0, "Ring", "Red"],
	[0, "Ring", "Green"],
	[0, "Ring", "Blue"],
	[0, "Ring", "Purple"],
	
	[0, "Chalice", "Red"],
	[0, "Chalice", "Green"],
	[0, "Chalice", "Blue"],
	[0, "Chalice", "Purple"],
	
	[0, "Cross", "Red"],
	[0, "Cross", "Green"],
	[0, "Cross", "Blue"],
	[0, "Cross", "Purple"],
	
	[0, "Scepter", "Red"],
	[0, "Scepter", "Green"],
	[0, "Scepter", "Blue"],
	[0, "Scepter", "Purple"],
	
	[0, "Gecko", "Red"],
	[0, "Gecko", "Green"],
	[0, "Gecko", "Blue"],
	[0, "Gecko", "Purple"],
	
	[0, "Crown", "Red"],
	[0, "Crown", "Green"],
	[0, "Crown", "Blue"],
	[0, "Crown", "Purple"],
	
	[0, "Skull", "Red"],
	[0, "Skull", "Green"],
	[0, "Skull", "Blue"],
	[0, "Skull", "Purple"],
	
	[1, "Health_Food", "1-2"],
	[1, "Health", "Small"],
	[1, "Health", "Medium"],
	[1, "Health", "Large"],
	
	[1, "Ammo", "Small"],
	[1, "Ammo", "Medium"],
	[1, "Ammo", "Large"],
	[1, "Dynamite"],
	
	[1, "Magic", "Small"],
	[1, "Magic", "Medium"],
	[1, "Magic", "Large"],
	[1, "Extra_Life"],
	
	[2, Settings.Powerups.GHOST, 15, true, true],
	[2, Settings.Powerups.CATNIP, 15, true, true],
	[2, Settings.Powerups.CATNIP_RED, 15, true, true],
	[2, Settings.Powerups.INVULNERABLE, 15, true, true],
	
	[2, Settings.Powerups.FIRE_SWORD, 15, true, true],
	[2, Settings.Powerups.ICE_SWORD, 15, true, true],
	[2, Settings.Powerups.LIGHTNING_SWORD, 15, true, true],
	[3, "Generic", Vector2.ZERO, "Horizontal", false],
	
	#multiplayer stuff goes here (soon(tm))
]
	
onready var item_list = $VBoxContainer/HBoxContainer/ScrollContainer/ItemList


func _ready() -> void:
	if Engine.is_editor_hint():
		#populate the list
		if item_list.get_item_count() == 0 and !contents.empty():
			var animation_set = treasure_animations
			for item in contents:
				match item[0]:
					0: #treasure
						animation_set = treasure_animations 
						if item[1] in ["Coin", "Bars", "Pearls"]:
							item_list.add_icon_item(animation_set.get_frame(item[1], 0))
						else:
							item_list.add_icon_item(animation_set.get_frame("%s_%s" % [item[1], item[2]], 0))
					
					1: #restore
						animation_set = restore_animations 
						if item[1] in ["Dynamite", "Extra_Life"]:
							item_list.add_icon_item(animation_set.get_frame(item[1], 0))
						elif item[1] in ["Ammo","Health","Magic"]:
							item_list.add_icon_item(animation_set.get_frame("%s_%s" % [item[1], item[2]], 0))
						else: #Health_Food
							item_list.add_icon_item(animation_set.get_frame(item[2], 0))
					
					2: #powerup
						animation_set = powerup_animations 
						item_list.add_icon_item(animation_set.get_frame(item[1], 0))
					
					3: #teleporter
						animation_set = teleporter_animations 
						item_list.add_icon_item(animation_set.get_frame(item[1], 0))
					
					4:
						animation_set = end_item_animations 
						item_list.add_icon_item(animation_set.get_frame(item[1], 0))
		#call_deferred("popup") #for showing without a parent to make it visible


func _on_item_selected(index) -> void:
	emit_signal("selected", contents[index])
	visible = false
	item_list.unselect_all()
