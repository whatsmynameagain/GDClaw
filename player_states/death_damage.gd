extends State


var wait_timer


func _on_enter() -> void:
	owner.motion = Vector2.ZERO
	owner.visible = false
	owner.set_collision_layer_value(1, false)
	var dummy = preload("res://objects/generic/death_dummy.tscn").instantiate()
	owner.emit_signal("spawn_dummy", dummy, owner.global_position, owner.orientation)
	owner.set_stance_collision(true, true)
	Utils.decide_player(owner.player_sounds, owner.action_sounds[9]) 
	wait_timer = Timer.new()
	wait_timer.name = "Death_damage_timer"
	add_child(wait_timer)
	wait_timer.one_shot = true
	wait_timer.start(2)
	wait_timer.connect("timeout", Callable(self, "_on_wait_over"))


func _on_wait_over() -> void:
	owner.emit_signal("respawn", 1, owner.orientation)
	owner.health = 100
	owner.emit_signal("health_updated", owner.health)
	emit_signal("finished", "Idle")
	owner.set_collision_layer_value(1, true)
