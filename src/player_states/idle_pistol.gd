extends State

#to fix: in the original you can press a movement (inc jump) key to interrupt 
#shortly after the bullet is fired
var fired : bool


func _on_enter() -> void:
	fired = false
	owner.active_ranged = owner.Ranged.PISTOL
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.animation.connect("animation_finished", Callable(self, "shoot"))
	if owner.pistol > 0:
		owner.on_pistol_fired() 
		owner.animation.play("pistol")
	else:
		owner.animation.play("pistol_empty")
	owner.emit_signal("ranged_changed", "pistol", owner.pistol)


func _update(_delta) -> void:
	
	#interruptions
	if !owner.is_on_floor():
		emit_signal("finished", "Jump")
	if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")) and fired:
		emit_signal("finished", "Move")
		_on_exit()
		return
	if Input.is_action_just_pressed("ui_down") and fired:
		for body in owner.floor_check.get_overlapping_bodies():
			if body.name == "LadderTopCollision":
				owner.above_ladder_top = true
				owner.ladder_x_pos = body.global_position.x
		if owner.above_ladder_top:
			owner.global_position.y += 2 #bypass the one way collison
			owner.above_ladder_top = false
			emit_signal("finished", "Climb")
			_on_exit()
			return
		else:
			emit_signal("finished", "Crouch")
			_on_exit()
			return
	if Input.is_action_just_pressed("ui_jump") and fired:
		emit_signal("finished", "Jump")
		_on_exit()
		return
		
	elif Input.is_action_just_pressed("ui_pistol"):
		if owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
			if owner.animation.frame >= 2:
				shoot()
				owner.animation.frame = 0


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", Callable(self, "shoot")):
		owner.animation.disconnect("animation_finished", Callable(self, "shoot"))
	
	if owner.pistol > 0:
		owner.spawn_pistol_projectile(1)
		owner.pistol -= 1
		owner.emit_signal("ammo_updated", owner.pistol)
		owner.animation.play("pistol_post")
		fired = true
	else:
		Utils.decide_player(owner.player_sounds, owner.action_sounds[6])
		owner.animation.play("pistol_empty_post")
	

	
	if !owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
		owner.animation.connect("animation_finished", Callable(self, "_on_animation_complete"))


func _on_animation_complete() -> void:
	owner.animation.disconnect("animation_finished", Callable(self, "_on_animation_complete"))
	owner.attacking = false
	emit_signal("finished", "Idle")


func _on_exit() -> void:
	owner.attacking = false
	if owner.animation.is_connected("animation_finished", Callable(self, "shoot")):
		owner.animation.disconnect("animation_finished", Callable(self, "shoot"))
	
	if owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
		owner.animation.disconnect("animation_finished", Callable(self, "_on_animation_complete"))
