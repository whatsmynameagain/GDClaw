@tool
extends Pickup

class_name Treasure


signal spawn_value(value)

const type_value = {"Coin":100, "Bars":500, "Ring":1500, "Chalice":2500, "Pearls":2500, 
		"Cross":5000, "Scepter":7500, "Gecko":10000, "Crown":15000, "Skull":25000}
const value_number = {
	100 : preload("res://sprites/objects/treasure_value/100.png"),
	500 : preload("res://sprites/objects/treasure_value/500.png"),
	1500 : preload("res://sprites/objects/treasure_value/1500.png"),
	2500 : preload("res://sprites/objects/treasure_value/2500.png"),
	5000 : preload("res://sprites/objects/treasure_value/5000.png"),
	7500 : preload("res://sprites/objects/treasure_value/7500.png"),
	10000 : preload("res://sprites/objects/treasure_value/10000.png"),
	15000 : preload("res://sprites/objects/treasure_value/15000.png"),
	25000 : preload("res://sprites/objects/treasure_value/25000.png")
	}
const animations = preload("res://animations/treasure.tres")
		
		
@export_enum("Coin", "Bars", "Ring", "Chalice", "Pearls", 
		"Cross", "Scepter", "Gecko", "Crown", "Skull") var type : String = "Coin": 
	set = set_type
@export var color = "Red": set = set_color


func _get_class() -> String:
	return "Treasure"


func _is_class(_name) -> bool:
	return _name == "Treasure" or super._is_class(_name)


func set_type(value) -> void:
	type = value
	if type in ["Coin", "Bars", "Pearls"]:
		color = "None" #not really needed buuuut... meh
	else:
		color = "Red"
	queue_redraw()
	notify_property_list_changed() 


func set_color(value) -> void:
	color = value
	if color != "None" and type in ["Coin", "Bars", "Pearls"]:
		type = "Ring"
	elif color == "None" and not type in ["Coin", "Bars", "Pearls"]:
		type = "Coin"
	queue_redraw()
	notify_property_list_changed() 


func _ready() -> void:
	animation.frames = animations
	if Engine.is_editor_hint():
		return
	audio.volume_db = Settings.EFFECTS_VOLUME
	
	if type in ["Coin", "Bars", "Pearls"]:
		animation.play(type)
	else:
		animation.play("%s_%s" % [type, color])
	
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)


#spawn the value number thingy after being picked up
func _spawn_value() -> void:
	var value_body = RigidBody2D.new() #create a body to move
	#value_body.mode = RigidBody2D.MODE_CHARACTER #to avoid rotation (most likely unneeded) #gd4 broke it
	value_body.gravity_scale = 0.0 #floaty
	value_body.linear_velocity = Vector2(0, -15) #up it goes
	var value_sprite = Sprite2D.new() #create the sprite
	value_sprite.texture = value_number[type_value[type]] #load the apropriate image
	value_sprite.z_index = 100
	value_body.add_child(value_sprite) #add the sprite to the body
	var timer = Timer.new() #make it disappear after a certain time
	value_body.add_child(timer)
	timer.autostart = true
	timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	timer.one_shot = true
	timer.wait_time = 0.75
	timer.connect("timeout", Callable(timer.get_parent(), "queue_free")) #initiate self destruct sequence
	emit_signal("spawn_value", value_body, global_position)


func _on_pickup() -> void:
	match type:
		"Crown", "Skull", "Pearls":
			audio.stream = pickup_sounds["Chalice"]
		_:
			audio.stream = pickup_sounds[type]
	audio.play()
	#get_node("CollisionShape2D").disabled = true
	#area.get_node("CollisionShape2D").disabled = true
	#for some reason this^ doesn't work, gotta disable the collision mask instead:
	#update: maybe the setters could be called with call_deferred, dunno, could try that sometime
	set_collision_mask_value(1, false) #disable collision with layer 1 (tilemap) for collison box
	area.set_collision_layer_value(2, false) #disable area collision with layer 1 (player) for areabox
	stopped = true
	_spawn_value()
	linear_velocity = Vector2(-750, -750) #move to the top left
	#apply_central_impulse(Vector2(-750, -750)) #(either this or setting linear velocity works)
	gravity_scale = 0.0 #remove gravity to move in a straight line
	if has_node("Glitter"):
		get_node("Glitter").stop()
		get_node("Glitter").visible = false
	var timer = Timer.new()
	add_child(timer)
	timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	timer.one_shot = true
	timer.start(1.0)
	timer.connect("timeout", Callable(self, "queue_free"))


func _draw() -> void:
	if get_node("Animation").sprite_frames != animations:
		get_node("Animation").sprite_frames = animations
	
	if !Engine.is_editor_hint():
		return
	
	if type in ["Coin", "Bars", "Pearls"]:
		get_node("Animation").play(type)
	else:
		get_node("Animation").play("%s_%s" % [type, color])
	
	if !physics:
		if static_glitter:
			if !has_node("Glitter"):
					add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)
		else:
			if has_node("Glitter"):
				get_node("Glitter").queue_free()
