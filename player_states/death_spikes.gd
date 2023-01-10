extends State


var wait_timer


func _on_enter() -> void:
	owner.set_collision_layer_bit(1, false)
	owner.motion = Vector2.ZERO
	Utils.decide_player(owner.player_sounds, owner.action_sounds[10]) 
	owner.animation.play("death_env")
	owner.set_stance_collision(true, true)
	if owner.powerup != owner.Powerup_enum.NONE:
		owner._on_powerup_timer_end()
	wait_timer = Timer.new()
	add_child(wait_timer)
	wait_timer.one_shot = true
	wait_timer.start(2.5)
	wait_timer.connect("timeout", self, "_on_wait_over")


func _on_wait_over() -> void:
	owner.emit_signal("respawn", 0, owner.orientation)
	yield(get_tree().create_timer(1.3), "timeout")
	owner.health = 100
	owner.emit_signal("health_updated", owner.health)
	emit_signal("finished", "Idle")
	yield(get_tree().create_timer(1.7), "timeout") #wait before resetting the collision layer
	owner.set_collision_layer_bit(1, true) #so that the deathtile doesn't detect the player again