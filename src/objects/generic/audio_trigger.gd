extends Area2D

#maybe add a dropdown menu to choose the audio from, with an apropriate name
#aside from the direct audio file selection

signal level_sound_trigger(audio)

@export var audio: AudioStream
@export var enabled: bool = false
@export var exclamation: bool = false #player voice line or level sound
@export var uses: int = 1: set = set_uses


func set_uses(value) -> void:
	if !value <= -1:
		uses = value
	notify_property_list_changed()


func _ready() -> void:
	$Sprite2D.visible = Engine.is_editor_hint()


#when a body (player) enters the area:
func _on_body_entered(body) -> void:
	if enabled and (uses > 0 or uses == -1):
		if exclamation: #if it's a player voice trigger
			if body.has_method("on_voice_trigger"): #safety check, shouldn't be needed with collision layers
				body.on_voice_trigger(audio)
			else:
				print("Body has no voice trigger method. Check collision layers.")
		else: #if it's a level sound trigger
			emit_signal("level_sound_trigger", audio)
		set_uses(uses - 1)
