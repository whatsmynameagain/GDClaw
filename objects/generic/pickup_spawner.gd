extends Position2D

signal pickup_spawned(pickup, pos, z)

var spawn_list := [] setget set_spawn_list
var play_loot_sound := true #single crates don't play the loot spawn sound
var impulse = Vector2.ZERO #for custom initial impulses

onready var sound = $AudioStreamPlayer2D


#called after instancing
func set_spawn_list(value) -> void:
	spawn_list = value
	if !play_loot_sound:
		spawn_elements()
		queue_free()
	else:
		sound.volume_db = Settings.EFFECTS_VOLUME
		sound.play()
		sound.connect("finished", self, "queue_free") #self destruct after the lootspawn sound ends
		spawn_elements()


func spawn_elements() -> void:
	for elem in spawn_list:
		var item
		match elem[0]:
			0:
				item = preload("res://objects/generic/treasure.tscn").instance()
				item.type = elem[1]
				item.color = elem[2] if not (item.type in ["Coin", "Bars", "Pearls"]) else "None"
			1:
				item = preload("res://objects/generic/restore.tscn").instance()
				item.type = elem[1]
				item.size = elem[2] if !(item.type in ["Dynamite", "Health_Food", "Extra_Life"]) else "None"
				item.food_model = elem[2] if item.type == "Health_Food" else "None"
			2:
				item = preload("res://objects/generic/powerup.tscn").instance()
				item.type = elem[1]
				item.duration = elem[2]
				item.stack_duration = elem[3]
				item.one_use = elem[4]
			3:
				item = preload("res://objects/generic/teleporter.tscn").instance()
				item.type = elem[1]
				item.destination = elem[2]
				item.orientation = elem[3]
				item.one_use = elem[4]
			4:
				item = preload("res://objects/generic/end_item.tscn").instance()
				item.type = elem[1]
				item.drop_anim = elem[2]
				item.drop_anim_pos = elem[3]
			_:
				print("error loading loot item")
		#item.glitterColor = elem[4] #dosn't really work because pickups physics overrides it with gold. 
		#Could be changed.
		item.physics = true
		item.initial_impulse = impulse
		emit_signal("pickup_spawned", item, global_position, z_index+1)
