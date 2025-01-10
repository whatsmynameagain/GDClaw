extends State
#Everything that happens while there's no player input or external events affecting the player


const idle_limit := 15.0 
const talky_frame := 38
#keys for the voicelines dictionary

var idle_time := 0.0 #could use a timer instead
var connected := false
var previous_line := 0
var talking := false


func _on_enter() -> void:
	owner.animation.play("idle")
	owner.set_stance_collision(false, true)
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x
	idle_time = 0.0
	
	if owner.previous_state.name == "Climb":
		owner.motion.y = 500
	#for avoiding the bounce after finishing climbing a ladder. the player goes climb->idle->fall->idle


func _update(delta) -> void:	
	#could be done with only 2 edge checks that flip? #no, tried it, long story short: causes problems on elevators
	if !owner.wall_check.is_colliding():
		if (owner.edge_check_l.is_colliding() 
				and !owner.edge_check_m.is_colliding() 
				and !owner.edge_check_r.is_colliding()): 
			owner.orientation = owner.Orientations.RIGHT
			owner.animation.flip_h = false
			if owner.animation.animation != "ledge":
				if randi()%100+1 <= Settings.LEDGE_VOICE_CHANCE * 100:
					owner.on_voice_trigger(owner.dialogue["ledge"])
			owner.animation.play("ledge") 
		elif ((owner.edge_check_r.is_colliding() 
				and !owner.edge_check_m.is_colliding() 
				and !owner.edge_check_l.is_colliding())):
			owner.orientation = owner.Orientations.LEFT
			owner.animation.flip_h = true
			if owner.animation.animation != "ledge":
				if randi()%100+1 <= Settings.LEDGE_VOICE_CHANCE * 100:
					owner.on_voice_trigger(owner.dialogue["ledge"])
			owner.animation.play("ledge")
			
	
	if ((Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_left") 
			or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")) 
			and !Input.is_action_just_pressed("ui_jump")):
		emit_signal("finished", "Move")
	elif (Input.is_action_just_pressed("ui_jump") and (Input.is_action_pressed("ui_right") 
			or Input.is_action_pressed("ui_left"))
			or Input.is_action_just_pressed("ui_jump")): #or... just check for jump key? dunno, that might skip a frame or something, check later
		emit_signal("finished", "Jump") #update: still gotta check that btw^
	elif !owner.is_on_floor() and !owner.on_elevator:
		owner.falling = true
		emit_signal("finished", "Jump")
	elif Input.is_action_pressed("ui_down"):
		for body in owner.floor_check.get_overlapping_bodies():
			if body.name == "LadderTopCollision":
				owner.above_ladder_top = true
				owner.ladder_x_pos = body.global_position.x
		if owner.above_ladder_top:
			owner.global_position.y += 2 #bypass the one way collison
			owner.above_ladder_top = false
			emit_signal("finished", "Climb")
		elif !owner.animation.animation == "ledge":
			emit_signal("finished", "Crouch")
	elif Input.is_action_just_pressed("ui_up") and owner.on_ladder:
		emit_signal("finished", "Climb")
		
	elif !owner.animation.animation == "ledge": 
		if (Input.is_action_just_pressed("ui_lift") 
				or (Input.is_action_pressed("ui_up") and Input.is_action_just_pressed("ui_attack") 
				and !owner.powerup in [5, 6, 7])):
			if owner.liftable_in_close_range:
				if owner.liftables_in_range[0].is_class("Enemy"):
					var enemy = owner.liftables_in_range[0]
					var dummy = preload("res://objects/generic/liftable_dummy.tscn").instance()
					dummy.linked_enemy = enemy
					owner.add_child(dummy)
					dummy.set_as_toplevel(true)
					owner.lifted_object = dummy
					emit_signal("finished", "Lift")
				elif !owner.liftables_in_range[0].exploding:
					emit_signal("finished", "Lift")
		elif Input.is_action_just_pressed("ui_attack"):
			emit_signal("finished", "Idle_Attack")
		elif (Input.is_action_just_pressed("ui_pistol") 
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.PISTOL)):
			emit_signal("finished", "Idle_Pistol")
		elif (Input.is_action_just_pressed("ui_magic") 
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.MAGIC)):
			emit_signal("finished", "Idle_Magic")
		elif (Input.is_action_just_pressed("ui_dynamite") 
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.DYNAMITE)):
			emit_signal("finished", "Idle_Dynamite")
		else:
			if idle_time < idle_limit:
				idle_time += delta
			elif !connected:
				owner.animation.play("idle_bored")
				owner.animation.connect("animation_finished", self, "_on_bored_end")
				connected = true
				
			elif owner.animation.frame == talky_frame and !talking:
				talking = true
				randomize()
				var rand_line = randi()%12+1
				while rand_line == previous_line: #don't repeat
					rand_line = randi()%12+1
				owner.player_voice.stream = owner.dialogue["idle_%s" % rand_line]
				owner.player_voice.play()
				owner.exclamation.visible = true


#called when the idle_bored animation ends, resets the animation and counter
func _on_bored_end() -> void:
	idle_time = 0.0
	owner.animation.play("idle")
	owner.animation.disconnect("animation_finished", self, "_on_bored_end")
	connected = false
	talking = false


func _on_exit() -> void:
	#to avoid doing things with the signal if the animation changes before the idle_bored animation ends
	if owner.animation.is_connected("animation_finished", self, "_on_bored_end"):
		owner.animation.disconnect("animation_finished", self, "_on_bored_end")
		connected = false
	talking = false
