extends State


func _on_enter() -> void:
	owner.active_ranged = owner.Ranged.PISTOL
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.animation.connect("animation_finished", Callable(self, "shoot"))
	if owner.pistol > 0:
		owner.animation.play("pistol_crouch")
		owner.emit_signal("ranged_changed", "pistol", owner.pistol)
	else:
		owner.animation.play("pistol_crouch_empty")


func _update(_delta) -> void:
	if Input.is_action_just_pressed("ui_pistol") and Input.is_action_pressed("ui_down"):
		if owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
			if owner.animation.frame >= 7: 
				shoot()
				owner.animation.frame = 0
	elif !owner.is_on_floor() and !owner.on_elevator:
		emit_signal("finished", "Jump")


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", Callable(self, "shoot")):
		owner.animation.disconnect("animation_finished", Callable(self, "shoot"))
	
	if owner.pistol > 0:
		owner.spawn_pistol_projectile(2)
		owner.pistol -= 1
		owner.emit_signal("ammo_updated", owner.pistol)
		owner.animation.play("pistol_crouch_post")
		if !Input.is_action_pressed("ui_down"): #can move right after shooting
			emit_signal("finished", "Crouch")
	else:
		Utils.decide_player(owner.player_sounds, owner.action_sounds[6]) 
		owner.animation.play("pistol_crouch_empty_post")
		#can't move until the empty anim is over
	
	if !owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
		owner.animation.connect("animation_finished", Callable(self, "_on_animation_complete"))


func _on_animation_complete() -> void:
	owner.animation.disconnect("animation_finished", Callable(self, "_on_animation_complete"))
	owner.attacking = false
	emit_signal("finished", "Crouch")


func _on_exit() -> void:
	owner.attacking = false
	if owner.animation.is_connected("animation_finished", Callable(self, "shoot")):
		owner.animation.disconnect("animation_finished", Callable(self, "shoot"))
	if owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
		owner.animation.disconnect("animation_finished", Callable(self, "_on_animation_complete"))
