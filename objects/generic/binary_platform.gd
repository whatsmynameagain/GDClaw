extends Node2D

#-not sure what to do about different models without hardcoding something like "(type)_on, (type)_off, (type)_transition"

#Sets of these need to have their own node with an area that activates them when the player steps in
#Figure that out later when optimizing for objects outside the viewport/a certain distance away from the player

#-not much here is tested by comparing it to the original
#it works fine(ish?) but some settings functionality might be different

#gotta confirm whether enemies can land on these

const transition_time := {"Vanish" : 0.4, "Slide" : 0.2, "Sink" : 0.3}
#timings for slide and sink are temporary, figure them out later

#add another const dict with the sounds res strings based on the type (and an export string for the type)
export(bool) var active = true
export(float) var time_off = 1.0
export(float) var time_on =  1.0
export(float) var time_delay = 0.0 #used for sets of platforms, to keep them in sync
export(String, "Vanish", "Slide", "Sink") var transition_type = "Vanish"
export(bool) var always_on = false 


onready var collision = $CollisionShape2D
onready var animation = $AnimatedSprite
onready var sound = $Sound
onready var timer = $Timer


func _ready() -> void:
	sound.set_volume_db(Settings.EFFECTS_VOLUME)
	timer.connect("timeout", self, "_on_timeout")
	animation.connect("animation_finished", self, "_on_animation_finished")
	if !active:
		timer.wait_time = time_off + time_delay
		collision.disabled = false
		animation.play("transition_off")
		animation.frame = 10
	else:
		timer.wait_time = time_on + time_delay
		collision.disabled = true
		animation.play("transition_on")
		animation.frame = 10
	timer.start()

func _on_timeout() -> void:
	if active:
		timer.stop()
		timer.wait_time = time_off
		active = false
		animation.play("transition_off")
		collision.disabled = true
	else:
		timer.stop()
		timer.wait_time = time_on
		active = true
		animation.play("transition_on")


func _on_animation_finished() -> void:
	timer.start()
	collision.disabled = !active

