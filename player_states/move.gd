extends State

#running state


var played_l
var played_r 


func play_footsteps() -> void:
	#add a check for if the player is in an area that triggers a different footstep sound 
	#(like water puddles)
	if owner.animation.get_frame() == 4 and !played_l:
		Utils.decide_player(owner.player_sounds, owner.action_sounds[0]) 
		played_l = true
		played_r = false
	elif owner.animation.get_frame() == 9 and !played_r: 
		Utils.decide_player(owner.player_sounds, owner.action_sounds[1]) 
		played_r = true
		played_l = false


func _on_enter() -> void:
	played_l = false
	played_r = false
	if owner.powerup == owner.Powerup_enum.CATNIP and owner.animation.speed_scale == 1:
		owner.animation.speed_scale = 1.15 #1.2
	
	if owner.get_run_speed() == owner.SPEED_BOOST:
		owner.animation.speed_scale = 1.1
	
	if Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_left"):
		move(false, "running")
	elif Input.is_action_pressed("ui_right"):
		move(true, "running")


func _update(delta) -> void:
	if owner.powerup != owner.Powerup_enum.CATNIP:
		owner.run_boost_charge += delta
	
	if Input.is_action_pressed("ui_down"):
		for body in owner.floor_check.get_overlapping_bodies():
			if body.name == "LadderTopCollision":
				owner.above_ladder_top = true
				owner.ladder_x_pos = body.global_position.x
		if owner.above_ladder_top:
			owner.global_position.y += 2 #bypass the one way collison
			owner.above_ladder_top = false
			emit_signal("finished", "Climb")
		else:
			emit_signal("finished", "Crouch")
	elif !Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
		if Input.is_action_just_pressed("ui_jump"):
			emit_signal("finished", "Jump")
		emit_signal("finished", "Idle")
	
	#check if any of the 4 attack types keys are pressed
	#could use a dictionary with a loop
	elif Input.is_action_just_pressed("ui_attack"):
		emit_signal("finished", "Idle_Attack")
	elif Input.is_action_just_pressed("ui_pistol"):
		emit_signal("finished", "Idle_Pistol") 
	elif Input.is_action_just_pressed("ui_magic"):
		emit_signal("finished", "Idle_Magic")
	elif Input.is_action_just_pressed("ui_dynamite"):
		emit_signal("finished", "Idle_Dynamite")
		
	elif owner.orientation == owner.Orientations.RIGHT: #if the character is moving to the right
		if Input.is_action_just_pressed("ui_jump"):
			move(true, "jump")
			emit_signal("finished", "Jump")
		
		if Input.is_action_just_pressed("ui_left"):
			move(false, "running") #move left
		elif Input.is_action_pressed("ui_right"):
			play_footsteps()
			move(true, "running") #this is needed for updating the speed when a catnip effects ends in the middle of a run action
	else: #if moving to the left
		if Input.is_action_just_pressed("ui_jump"):
			move(false, "jump")
			emit_signal("finished", "Jump")
		
		if Input.is_action_just_released("ui_left") and Input.is_action_pressed("ui_right"):
			#if moving left while also holding right, go right as soon as left is released
			move(true, "running")
		elif Input.is_action_pressed("ui_left"):
			play_footsteps()
			move(false, "running")#this is needed for updating the speed when a catnip effects ends in the middle of a run action
		
	if !owner.is_on_floor(): 
		owner.falling = true
		emit_signal("finished", "Jump")


func _on_exit() -> void:
	if owner.animation.speed_scale != 1.0:
		owner.animation.speed_scale = 1.0
