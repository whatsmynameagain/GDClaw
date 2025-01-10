extends State


var stun_time
var random

func _on_enter() -> void:
	owner.set_stance_collision(false, true)
	#playing a random hit sound and animation for now
	randomize()
	random = randi() % 4 + 2
	Utils.decide_player(owner.player_sounds, owner.action_sounds[random]) 
	stun_time = owner.DAMAGE_STUN_DURATION
	random = rand_range(1,11)
	if random > 5: #temp, update later
		owner.animation.play("damage_high")
	else:
		owner.animation.play("damage_low")
	owner.motion.y = 0 #because getting hit in the original makes you stay stunned in the air
					#though this line probably isn't needed
	owner.motion.x = Settings.DAMAGE_KNOCKBACK * owner.knockback


func _update(delta) -> void:
	stun_time -= delta
	if stun_time < owner.DAMAGE_STUN_DURATION/3:
		owner.motion.x = 0
	if stun_time <= 0:
		if owner.is_on_floor():
			emit_signal("finished", "Idle")
		else:
			emit_signal("finished", "Jump")


func _on_exit() -> void:
	owner.motion.x = 0
