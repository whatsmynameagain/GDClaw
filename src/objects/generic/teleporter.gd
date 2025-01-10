tool
extends Pickup

class_name Teleporter

#maybe make the helper moveable with the mouse
const animations = preload("res://animations/teleporter.tres")

export(String, "Generic", "Boss") var type = "Generic" setget set_type
export(Vector2) var destination = Vector2.ZERO setget set_destination
export(String, "Horizontal", "Vertical") var orientation = "Horizontal" setget set_orientation

onready var destination_helper = $DestinationHelper


func get_class() -> String:
	return "Teleporter"


func is_class(name) -> bool:
	return name == "Teleporter" or .is_class(name)


func set_destination(value) -> void:
	destination = value
	if is_instance_valid(destination_helper):
		destination_helper.global_position = value
	update()


func set_type(value) ->void:
	type = value
	if type == "Boss":
		one_use = false
	update()
	property_list_changed_notify()


func set_orientation(value) -> void:
	orientation = value
	update()


func _ready() -> void:
	animation.frames = animations
	animation.visible = true
	var degrees : int
	degrees = 0 if orientation == "Horizontal" else 90
	if Engine.is_editor_hint():
		destination_helper.rotation_degrees = degrees
		destination_helper.global_position = destination
		return
	else:
		set_process(false)
	destination_helper.visible = false
	animation.rotation_degrees = degrees
	
	one_use = !type == "Boss" #to avoid accidental locks after respawning
	animation.play(type)
	
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instance()) 
			get_node("Glitter").play(glitter_color)
	#if destination_helper != null:
	#destination = destination_helper.global_position


func _process(_delta) -> void:
	if !Engine.is_editor_hint():
		return
		
	if is_instance_valid(destination_helper):
		destination_helper.global_position = destination
		
	update()



func _draw() -> void:
	if !Engine.is_editor_hint():
		return
		
	if get_node("Animation").frames != animations:
		get_node("Animation").frames = animations
	if get_node("Animation").visible == false:
		get_node("Animation").visible = true
	
	draw_line(Vector2.ZERO, get_node("DestinationHelper").position, Color("#ffffff"), 2.0)
	var degrees : int
	degrees = 0 if orientation == "Horizontal" else 90
	get_node("Animation").play(type)
	get_node("Animation").rotation_degrees = degrees
	get_node("DestinationHelper").rotation_degrees = degrees
	
	if !physics:
		if static_glitter:
			if !has_node("Glitter"):
					add_child(preload("res://src/objects/generic/glitter.tscn").instance() ) 
			get_node("Glitter").play(glitter_color)
		else:
			if has_node("Glitter"):
				get_node("Glitter").queue_free()
	#gotta use get_node instead of the reference variable or else the editor starts bitching
	#update: might have been fixed with newer versions

func _on_pickup() -> void: 
	if one_use: 
		#give the game time to get the destination info before self destructing
		yield(get_tree().create_timer(1.5), "timeout")
		queue_free()
