extends StaticBody2D

#there's an engine bug where if only a couple pixels of a falling body's collision touch 
#the edge of a surface while falling, the body will go through the surface's one way collision
# -> the player can activate the platform while passing through it

@export var reusable := false

var active := true: set = set_active
var sound_played := false 
var activated := false

@onready var collision = $CollisionShape2D
@onready var animation = $AnimatedSprite2D
@onready var sound = $Sound
@onready var timer = $Timer


func _get_class() -> String:
	return "CrumblingPlatform"


func _is_class(name) -> bool:
	return name == "CrumblingPlatform" or super.is_class(name)


func set_active(value) -> void:
	active = value
	if active:
		animation.visible = true
		animation.play("Idle")
		collision.disabled = false
		activated = false



func _ready() -> void:
	animation.visible = true
	animation.play("Idle")
	sound.set_volume_db(Settings.EFFECTS_VOLUME)



func activate() -> void:
	activated = true
	animation.connect("animation_finished", Callable(self, "_on_animation_finished"))
	animation.play("Crumbling")
	sound.play()
	timer.start()


func _on_animation_finished() -> void:
	if !reusable:
		queue_free()
	else:
		animation.disconnect("animation_finished", Callable(self, "_on_animation_finished"))
		animation.play("Used")


func _on_Timer_timeout() -> void:
	collision.disabled = true
	timer.stop() #for reusable
