tool
extends Pickup
#script and scene inherit from Pickup

class_name Powerup



const animations = preload("res://animations/powerup.tres")

export(Settings.Powerups) var type := Settings.Powerups.CATNIP setget set_type
export(int) var duration = 15
export(bool) var stack_duration = true


func get_class() -> String:
	return "Powerup"


func is_class(name) -> bool:
	return name == "Powerup" or .is_class(name)


func set_type(value) -> void:
	type = value
	update()


func _ready() -> void:
	animation.frames = animations
	if Engine.is_editor_hint():
		return
	audio.volume_db = Settings.EFFECTS_VOLUME
	animation.play(Settings.Powerups.keys()[type-1])
	if !physics:
		if static_glitter:
			add_child(preload("res://src/objects/generic/glitter.tscn").instance()) 
			get_node("Glitter").play(glitter_color)


func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	get_node("Animation").play(Settings.Powerups.keys()[type-1])
	if !physics: 
		if static_glitter:
			if !has_node("Glitter"):
				add_child(preload("res://src/objects/generic/glitter.tscn").instance()) 
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
		audio.connect("finished", self, "queue_free") #destroy once it's done playing the pickup sound
		disable() #disable so that it can't be picked up again
