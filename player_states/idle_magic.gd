extends State


func _on_enter() -> void:
	owner.active_ranged = owner.Ranged.MAGIC
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.animation.connect("animation_finished", self, "shoot")
	if owner.magic > 0:
		owner.animation.play("magic")
		owner.emit_signal("ranged_changed", "magic", owner.magic)
	else:
		owner.animation.play("magic_empty")
		Utils.decide_player(owner.player_sounds, owner.action_sounds[8]) 


func _update(_delta) -> void:
	if !owner.is_on_floor():
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_down"):
		emit_signal("finished", "Crouch")


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	
	if owner.magic > 0:
		owner.spawn_magic_projectile(1)
		owner.magic -= 1
		owner.emit_signal("ammo_updated", owner.magic)
	owner.animation.play("magic_post")

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
