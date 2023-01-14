extends State


var stun_time


func _on_enter() -> void:
	owner.set_stance_collision(true, false)
	Utils.decide_player(owner.player_sounds, owner.action_sounds[15]) 
	stun_time = 0.5
	owner.animation.play("land")
	if owner.player_glitter.emitting:
		#set the particle emmision area to match the crouch area
		var glitter = owner.player_glitter as Particles2D
		glitter.process_material.emission_box_extents = Vector3(16,30,1)
		glitter.position = Vector2(0,20)


func _update(delta) -> void:
	stun_time -= delta
	if stun_time <= 0:
		emit_signal("finished", "Idle")


func _on_exit() -> void:
	owner.set_stance_collision(false, true)
	if owner.player_glitter.emitting:
		#set the particles area back to standing size
		var glitter = owner.player_glitter as Particles2D
		glitter.process_material.emission_box_extents = Vector3(16,54,1)
		glitter.position = Vector2(0,0)
