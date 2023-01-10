extends State

#handles jumping, falling, long falls and all air attacks


var released : bool
var limit : bool
var pistol := false
var magic := false
var dynamite := false
var melee_checked := false
var anim := ""


func _on_enter() -> void:
	owner.set_stance_collision(false, true)
	if Input.is_action_pressed("ui_jump") and !owner.falling:
		released = false
		limit = false
		owner.motion.y = owner.get_jump_height()
		owner.action_time = 0.0
		anim = "jump"
		
		#to-do: if boost resets when jumping, reset it here
		
	else:
		owner.action_time = 0.0
		owner.falling = true
		anim = "fall" if (owner.animation.animation != "jump" or owner.is_on_ceiling()) else "jump"
		owner.animation.play(anim)
		owner.motion.y = 0
	owner.animation.flip_h = owner.orientation == -1 


func _update(delta) -> void:
	owner.action_time += delta
	if !owner.falling:
		if Input.is_action_just_released("ui_jump"):
			released = true 
			owner.falling = true
			owner.action_time = 0.0
		
		if owner.is_on_ceiling():
			owner.falling = true
			owner.motion.y = 0.0
			owner.action_time = 0.0
			anim = "fall"
			
		if (Input.is_action_just_pressed("ui_up") or Input.is_action_pressed("ui_up")) and owner.on_ladder:
			emit_signal("finished", "Climb")
		
		elif limit:
			owner.falling = true
			owner.action_time = 0.0 
			if !owner.attacking and !pistol and !magic and !dynamite:
				anim = "fall" if (owner.animation.animation != "jump" or owner.is_on_ceiling()) else "jump" 
			owner.animation.play(anim)
			
		elif !owner.is_on_floor() and Input.is_action_pressed("ui_jump") and !released or owner.attacking:
			set_attacks() 
			check_lateral() 
			if owner.action_time < owner.get_jump_time(): 
				owner.motion.y = owner.get_jump_height()
			else:
				limit = true
		elif owner.is_on_floor(): 
			emit_signal("finished", "Idle")

	else: #old but it works. Should use animation signals instead (?)
		if owner.attacking:
			anim = "attack_air" 
		
		if anim == "jump" and owner.animation.frame == 7:
			anim = "fall"
		
		if anim == "fall" and owner.animation.frame == 4: #play fall_jump once and then switch to fall
			anim = "fall_loop"
		
		owner.animation.play(anim)
		if ((Input.is_action_just_pressed("ui_up") or Input.is_action_pressed("ui_up")) 
				and owner.on_ladder): #add tile check later
			emit_signal("finished", "Climb")
		else: #if falling  #this action_time check should technically be 0.781
			set_attacks() 
			check_lateral()
		

		if owner.action_time > 0.75 and !owner.attacking and !pistol and !magic and !dynamite:
			anim = "fall_long"
		
		#if landing without reaching the stun landing time
		if owner.is_on_floor() and owner.action_time <= 1.18:
			Utils.decide_player(owner.player_sounds, owner.action_sounds[0]) 
			if (Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left") 
					or Input.is_action_pressed("ui_left")):
				move(false, anim)
				emit_signal("finished", "Move") #skip one frame of idle state after landing
			elif Input.is_action_pressed("ui_right"):
				move(true, anim)
				emit_signal("finished", "Move") #skip one frame of idle state after landing
			else:
				emit_signal("finished", "Idle")
		elif owner.is_on_floor() and owner.action_time >= 1.18:
			owner.motion.x = 0
			emit_signal("finished", "Land")


#1: melee
#2: pistol
#3: magic
#4: dynamite
func start_attack(attack : int) -> void:
	match attack:
		1:
			owner.animation.play("attack_air")
			Utils.decide_player(owner.player_sounds, owner.action_sounds[16]) 
			owner.attacking = true
			melee_checked = false
			owner.melee_attack = 5
		2:
			pistol = true
			if owner.pistol > 0:
				owner.spawn_pistol_projectile(3)
				owner.pistol -= 1
				owner.emit_signal("ammo_updated", owner.pistol)
				anim  = "pistol_air_post"
			else:
				anim = "pistol_air_empty"
		3:
			magic = true
			if owner.magic > 0:
				owner.spawn_magic_projectile(3)
				owner.magic -= 1
				owner.emit_signal("ammo_updated", owner.magic)
				anim  = "magic_air_post"
			else:
				anim = "magic_air_empty"
		4: 
			dynamite = true
			if owner.dynamite > 0:
				#NEEDS CHECKING, okayish for now
				owner.spawn_dynamite_projectile(3, Vector2(200 * owner.orientation, -200)) 
				owner.dynamite -= 1
				owner.emit_signal("ammo_updated", owner.dynamite)
				anim  = "dynamite_air_post"
			else:
				anim = "dynamite_air_empty"
	
	if !owner.animation.is_connected("animation_finished", self, "_on_exit"):
		owner.animation.connect("animation_finished", self, "_on_exit")


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	start_attack(2 if pistol else 3 if magic else 4)


func set_attacks() -> void:
	if !owner.attacking and !pistol and !magic and !dynamite:
		if Input.is_action_just_pressed("ui_attack"):
			start_attack(1)
		elif (Input.is_action_just_pressed("ui_pistol") 
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.PISTOL)):
			owner.active_ranged = owner.Ranged.PISTOL
			if owner.animation.is_connected("animation_finished", self, "_on_exit"):
				if owner.animation.frame >= 4 and owner.animation.frame <= 7: #not checked, good enough for now
					start_attack(2)
					owner.animation.frame = 0
			pistol = true
			owner.animation.connect("animation_finished", self, "shoot")
			if owner.pistol > 0: 
				anim = "pistol_air" 
			else:
				anim = "pistol_air_empty"
				Utils.decide_player(owner.player_sounds, owner.action_sounds[6]) 
			owner.emit_signal("ranged_changed", "pistol", owner.pistol)
		elif (Input.is_action_just_pressed("ui_magic") 
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.MAGIC)):
			owner.active_ranged = owner.Ranged.MAGIC
			magic = true
			owner.animation.connect("animation_finished", self, "shoot")
			if owner.magic > 0: 
				anim = "magic_air" 
			else:
				anim = "magic_air_empty"
				Utils.decide_player(owner.player_sounds, owner.action_sounds[8]) 
			
			owner.emit_signal("ranged_changed", "magic", owner.magic)
		elif (Input.is_action_just_pressed("ui_dynamite")
				or (Input.is_action_just_pressed("ui_ranged") and owner.active_ranged == owner.Ranged.DYNAMITE)):
			owner.active_ranged = owner.Ranged.DYNAMITE
			dynamite = true
			owner.animation.connect("animation_finished", self, "shoot")
			anim = "dynamite_air" if owner.dynamite > 0 else "dynamite_air_empty"
			owner.emit_signal("ranged_changed", "dynamite", owner.dynamite)
	elif owner.attacking and !melee_checked:
		check_attack(owner.attack_air, owner.magic_sword)
		melee_checked = true
		anim = "attack_air"


func check_lateral() -> void:
	if (Input.is_action_pressed("ui_right") and Input.is_action_pressed("ui_left") 
			or Input.is_action_pressed("ui_left")):
		move(false, anim)
	elif Input.is_action_pressed("ui_right"):
		move(true, anim)
	else:
		owner.animation.play(anim)
		owner.motion.x = 0


#doubles as a replacement for the _on_animation_complete method inherited from State 
#(can't use that because it ends the state too) and as an exit state method
func _on_exit() -> void:
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	if owner.animation.is_connected("animation_finished", self, "_on_exit"):
		owner.animation.disconnect("animation_finished", self, "_on_exit")
	owner.melee_attack = 0
	owner.attacking = false
	owner.falling = !(owner.is_on_floor() or owner.on_ladder)
	pistol = false
	magic = false
	dynamite = false
	for child in owner.attack_areas.get_children():
		if !child.disabled:
			 child.call_deferred("set_disabled", true) #in case the player lands right after checking the attack
	anim = "jump" if !owner.falling else "fall"
