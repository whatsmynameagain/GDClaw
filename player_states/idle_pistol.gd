extends State


func _on_enter() -> void:
	owner.active_ranged = owner.Ranged.PISTOL
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.animation.connect("animation_finished", self, "shoot")
	if owner.pistol > 0:
		owner.on_pistol_fired() 
		owner.animation.play("pistol")
	else:
		owner.animation.play("pistol_empty")
	owner.emit_signal("ranged_changed", "pistol", owner.pistol)


func _update(_delta) -> void:
	if !owner.is_on_floor():
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_down"):
		emit_signal("finished", "Crouch")
	elif Input.is_action_just_pressed("ui_pistol"):
		if owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
			if owner.animation.frame >= 2:
				shoot()
				owner.animation.frame = 0


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	
	if owner.pistol > 0:
		owner.spawn_pistol_projectile(1)
		owner.pistol -= 1
		owner.emit_signal("ammo_updated", owner.pistol)
		owner.animation.play("pistol_post")
	else:
		Utils.decide_player(owner.player_sounds, owner.action_sounds[6])
		owner.animation.play("pistol_empty_post")
	
	if !owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.connect("animation_finished", self, "_on_animation_complete")


func _on_animation_complete() -> void:
	owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
	owner.attacking = false
	emit_signal("finished", "Idle")


func _on_exit() -> void:
	owner.attacking = false
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	
	if owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
