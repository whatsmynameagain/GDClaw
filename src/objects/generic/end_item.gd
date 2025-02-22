@tool
@icon("res://sprites/objects/pickup/end_item/map_piece/map_fragment.png")

extends Pickup

class_name EndItem

#to do: export setgets not really tested

var animations = preload("res://animations/end_item.tres")

@export var type = "Map": set = set_type
@export var drop_anim: bool = false: set = set_drop_anim
@export var drop_anim_pos: Vector2 = Vector2.ZERO: set = set_drop_anim_pos


func _get_class() -> String:
	return "EndItem"


func _is_class(_name) -> bool:
	return _name == "EndItem" or super._is_class(_name)


func set_type(value) -> void:
	type = value
	drop_anim = type == "map"


func set_drop_anim(value) -> void:
	drop_anim = value
	if drop_anim and type == "Map":
		type = "Blue"


func set_drop_anim_pos(value) -> void:
	drop_anim_pos = value
	if value != Vector2.ZERO:
		set_drop_anim(true)


func _ready() -> void:
	animation.frames = animations
	animation.play(type)
	if !Engine.is_editor_hint():
		audio.volume_db = Settings.EFFECTS_VOLUME
	
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").speed_scale = 1.6
			get_node("Glitter").play(glitter_color)


func _draw() -> void:
	if get_node("Animation").sprite_frames != animations:
		get_node("Animation").sprite_frames = animations
	
	if !Engine.is_editor_hint():
		return
	get_node("Animation").play(type)
	
	if !physics:
		if static_glitter:
			if !has_node("Glitter"):
					add_child(preload("res://src/objects/generic/glitter.tscn").instantiate())
			get_node("Glitter").speed_scale = 1.6 
			get_node("Glitter").play(glitter_color)
		else:
			if has_node("Glitter"):
				get_node("Glitter").queue_free()


func _on_pickup() -> void:
	audio.stream = pickup_sounds["EndItem"]
	audio.play()
	#actual trigger is a signal on player script
	#no need to queue free the item with an audio signal
