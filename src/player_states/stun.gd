extends State

#state for siren scream stun effect

onready var stun_time

#Needs checks for current motion so that you don't automatically fall straight down when stunned in the air
#though... all stuns could just disable gravity


func _on_enter() -> void:
	stun_time = owner.LANDING_STUN
	owner.animation.play("stunned")


func _update(delta) -> void:
	stun_time -= delta
	owner.motion.y = owner.GRAVITY
	if stun_time <= 0:
		emit_signal("finished", "Idle")
