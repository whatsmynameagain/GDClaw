extends State


var old_anim_frame = 0


func _on_enter() -> void:
	if Input.is_action_pressed("ui_down"):
		owner.animation.play("climbing_top_down")
	else:
		owner.animation.play("climbing")
	owner.global_position.x = owner.ladder_x_pos
	owner.motion.x = 0


func _update(_delta) -> void:
	if Input.is_action_just_pressed("ui_jump") and !Input.is_action_pressed("ui_up"):
		#the second part makes the game a bit clunkier than I'd like but that's how the original does it
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_up"): #when pressing up after stopping
		owner.animation.frame += 1
		if owner.on_ladder_top:
			if owner.animation.animation == "climbing_top_down": #if the player is going up after an unfinished climbing down top animation
				old_anim_frame = owner.animation.frame #save the current animation's frame
				owner.animation.play("climbing_top") #play that animation starting from the stopping point of the previous anim
				owner.animation.frame = 6 - old_anim_frame if old_anim_frame != 3 else 4 #get the opposite frame for playing the opposite animation
			else: #resume normally
				owner.animation.play("climbing_top") 
		else:
			owner.animation.play("climbing")
		owner.motion.y = owner.climb_speed
	elif Input.is_action_pressed("ui_up"):
		owner.motion.y = owner.climb_speed
		if owner.on_ladder_top:
			owner.animation.play("climbing_top")
		else:
			owner.animation.play("climbing")
	elif !Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down"):
		owner.animation.stop()
		owner.motion.y = 0
	elif Input.is_action_just_pressed("ui_down"):
		owner.animation.frame += 1
		if owner.on_ladder_top:
			if owner.animation.animation == "climbing_top":
				old_anim_frame = owner.animation.frame
				owner.animation.play("climbing_top_down")
				owner.animation.frame = 6 - old_anim_frame
			else:
				owner.animation.play("climbing_top_down")
		else:
			owner.animation.play("climbing_down")
		owner.motion.y = -owner.climb_speed
	elif Input.is_action_pressed("ui_down"):
		if !owner.is_on_floor():
			owner.motion.y = -owner.climb_speed
			if owner.on_ladder_top:
				owner.animation.play("climbing_top_down") 
			else:
				owner.animation.play("climbing_down")
		elif !owner.on_ladder_top:
			emit_signal("finished", "Idle")
	
	if !owner.on_ladder and !owner.on_ladder_top:
		emit_signal("finished", "Idle")
		
	if Input.is_action_just_pressed("ui_select"):
		emit_signal("finished", "Damage")


func _on_exit() -> void:
	owner.motion.y = 500
