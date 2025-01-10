extends State


func _on_enter() -> void:
	owner.action_time = 0.0
	owner.motion.x = 0
	owner.set_stance_collision(true,false)
	
	if owner.player_glitter.emitting:
		#set the particle emmision area to match the crouch area
		var glitter = owner.player_glitter as Particles2D
		glitter.process_material.emission_box_extents = Vector3(16,30,1)
		glitter.position = Vector2(0,20)
	owner.animation.play("crouching")


func _update(_delta) -> void:
	if !Input.is_action_pressed("ui_down"):
		emit_signal("finished", "Idle")
	elif !owner.is_on_floor() and !owner.on_elevator:
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_attack"):
		emit_signal("finished", "Crouch_Attack")
	elif (Input.is_action_just_pressed("ui_pistol") or 
				(Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.PISTOL)):
		emit_signal("finished", "Crouch_Pistol")
	elif (Input.is_action_just_pressed("ui_magic") or 
				(Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.MAGIC)):
		emit_signal("finished", "Crouch_Magic")
	elif (Input.is_action_just_pressed("ui_dynamite") or 
				(Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.DYNAMITE)):
		emit_signal("finished", "Crouch_Dynamite")


func _on_exit() -> void:
	if !owner.next_state_name in ["Crouch_Attack", "Crouch_Pistol", "Crouch_Magic", "Crouch_Dynamite"]:
		owner.set_stance_collision(false, true)
		owner.action_time = 0.0
		#reset the glitter area
		if owner.player_glitter.emitting:
			var glitter = owner.player_glitter as Particles2D
			glitter.process_material.emission_box_extents = Vector3(16,54,1)
			glitter.position = Vector2(0,0)
