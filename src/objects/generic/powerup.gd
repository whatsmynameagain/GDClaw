@tool
extends Pickup
#script and scene inherit from Pickup

class_name Powerup



const animations = preload("res://animations/powerup.tres")

@export var type := Settings.Powerups.CATNIP: set = set_type
@export var duration: int = 15
@export var stack_duration: bool = true


func _get_class() -> String:
	return "Powerup"


func _is_class(_name : String ) -> bool:
	return _name == "Powerup" or super._is_class(_name)


func set_type(value) -> void:
	type = value
	queue_redraw()


func _ready() -> void:
	animation.frames = animations
	if Engine.is_editor_hint():
		return
	audio.volume_db = Settings.EFFECTS_VOLUME
	animation.play(Settings.Powerups.keys()[type-1])
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instantiate()) 
			get_node("Glitter").play(glitter_color)


func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	get_node("Animation").play(Settings.Powerups.keys()[type-1])
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
		Settings.Powerups.CATNIP, Settings.Powerups.CATNIP_RED:
			audio.stream = pickup_sounds["Catnip"]
		_:
			audio.stream = pickup_sounds["Ghost"]
	audio.play()
	if one_use:
		audio.connect("finished", Callable(self, "queue_free")) #destroy once it's done playing the pickup sound
		disable() #disable so that it can't be picked up again
