@tool
extends Pickup
#script and scene inherit from Pickup

class_name Restore


const animations = preload("res://animations/restore.tres")

#TO DO: cyclic call of setters here, gd4 now always calls the setter functions
#this is going to be a pain in the ass to solve

@export_enum("Ammo", "Magic", "Dynamite", 
		"Health_Food", "Health", "Extra_Life") var type : String = "Health_Food": 
	set = set_type
@export var size = "None": 
	set = set_size
@export_enum("None", "1-2", "3-4", "5-6", "7-8", 
		"9-10", "11-12", "13", "14") var food_model : String = "1-2": 
	set = set_food_model


func _get_class() -> String:
	return "Restore"


func _is_class(_name) -> bool:
	return _name == "Restore" or super.is_class(name)


func set_type(value) -> void:
	type = value
	if type in ["Dynamite", "Health_Food", "Extra_Life"]:
		size = "None"
		if type == "Health_Food":
			food_model = "1-2"
		else:
			food_model = "None"
	else:
		size = "Small"
		food_model = "None"
	queue_redraw()
	notify_property_list_changed()


func set_size(value) -> void:
	size = value
	if size == "None" and not type in ["Dynamite", "Health_Food", "Extra_Life"]:
		type = "Health_Food"
		food_model = "1-2"
	elif size != "None" and not type in ["Ammo", "Magic", "Health"]: 
		type = "Health"
	queue_redraw()
	notify_property_list_changed()


func set_food_model(value) ->void:
	food_model = value
	if food_model != "None" and type != "Health_Food":
		type = "Health_Food"
		size = "None"
	elif food_model == "None" and type == "Health_Food":
		type = "Health"
		size = "Small"
	queue_redraw()
	notify_property_list_changed()


func _ready():
	animation.frames = animations
	if Engine.is_editor_hint():
		return
	audio.volume_db = Settings.EFFECTS_VOLUME
	match type:
		"Extra_Life", "Dynamite":
			animation.play(type)
		"Health_Food":
			animation.play(food_model)
		_: #Health, Ammo, Magic
			animation.play("%s_%s" % [type, size])
		
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)


func _draw() -> void:
	if get_node("Animation").sprite_frames != animations:
		get_node("Animation").sprite_frames = animations
	
	if !Engine.is_editor_hint():
		return
	match type:
		"Extra_Life", "Dynamite":
			get_node("Animation").play(type)
		"Health_Food":
			get_node("Animation").play(food_model)
		_: #Health, Ammo, Magic
			get_node("Animation").play("%s_%s" % [type, size])
		
	if !physics:
		if static_glitter:
			if !has_node("Glitter"):
					add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)
		else:
			if has_node("Glitter"):
				get_node("Glitter").queue_free()


func _on_pickup() -> void:
	match type:
		"Ammo", "Dynamite":
			audio.stream = pickup_sounds["Ammo"]
		_: #not 100% sure all of these have the same sound
			audio.stream = pickup_sounds[type]
	audio.play()
	if type == "Extra_Life":
		set_collision_mask_value(0, false)
		area.set_collision_mask_value(1, false)
		stopped = true
		linear_velocity = Vector2(750, -750)
		gravity_scale = 0.0 
		if has_node("Glitter"):
			get_node("Glitter").stop()
			get_node("Glitter").visible = false
		var timer = Timer.new()
		add_child(timer)
		timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		timer.one_shot = true
		timer.start(1.0)
		timer.connect("timeout", Callable(self, "queue_free"))
	else:
		if one_use:
			audio.connect("finished", Callable(self, "queue_free"))
			disable()
