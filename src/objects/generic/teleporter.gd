@tool
extends Pickup

class_name Teleporter

#maybe make the helper moveable with the mouse
const animations = preload("res://animations/teleporter.tres")

@export var type = "Generic": set = set_type
@export var destination: Vector2 = Vector2.ZERO: set = set_destination
@export var orientation = "Horizontal": set = set_orientation

@onready var destination_helper = $DestinationHelper


func _get_class() -> String:
	return "Teleporter"


func _is_class(_name) -> bool:
	return _name == "Teleporter" or super.is_class(name)


func set_destination(value) -> void:
	destination = value
	if is_instance_valid(destination_helper):
		destination_helper.global_position = value
	queue_redraw()


func set_type(value) ->void:
	type = value
	if type == "Boss":
		one_use = false
	queue_redraw()
	notify_property_list_changed()


func set_orientation(value) -> void:
	orientation = value
	queue_redraw()


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
			add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)
	#if destination_helper != null:
	#destination = destination_helper.global_position


func _process(_delta) -> void:
	if !Engine.is_editor_hint():
		return
		
	if is_instance_valid(destination_helper):
		destination_helper.global_position = destination
		
	queue_redraw()



func _draw() -> void:
	if !Engine.is_editor_hint():
		return
		
	if get_node("Animation").sprite_frames != animations:
		get_node("Animation").sprite_frames = animations
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
					add_child(preload("res://src/objects/generic/glitter.tscn").instantiate() ) 
			get_node("Glitter").play(glitter_color)
		else:
			if has_node("Glitter"):
				get_node("Glitter").queue_free()
	#gotta use get_node instead of the reference variable or else the editor starts bitching
	#update: might have been fixed with newer versions

func _on_pickup() -> void: 
	if one_use: 
		#give the game time to get the destination info before self destructing
		await get_tree().create_timer(1.5).timeout
		queue_free()
