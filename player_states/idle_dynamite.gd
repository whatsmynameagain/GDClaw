extends State


var released := false
var charge : float
var fired := false
var button_used = ""


func _on_enter() -> void:
	button_used = "ui_dynamite" if Input.is_action_just_pressed("ui_dynamite") else "ui_ranged"
	owner.active_ranged = owner.Ranged.DYNAMITE
	charge = 0.0
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.emit_signal("ranged_changed", "dynamite", owner.dynamite)
	if owner.dynamite > 0:
		owner.on_dynamite_prepared()
		if !owner.animation.is_connected("animation_finished", self, "_next_anim"):
			owner.animation.connect("animation_finished", self, "_next_anim")
		owner.animation.play("dynamite_windup")
		
	else:
		owner.animation.connect("animation_finished", self, "_on_animation_complete")
		owner.animation.play("dynamite_empty")


func _update(delta) -> void:
	if !owner.is_on_floor() or Input.is_action_just_pressed("ui_jump"):
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_down"):
		emit_signal("finished", "Crouch")
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		emit_signal("finished", "Move")
	elif owner.dynamite > 0:
		#not a great fix, would be better to know which button is being used
		if Input.is_action_just_released(button_used): 
			released = true
			
		elif !released and charge < Settings.DYNAMITE_CHARGE_TIME:
			charge += delta
			
		elif !fired and charge >= Settings.DYNAMITE_CHARGE_TIME:
			charge = Settings.DYNAMITE_CHARGE_TIME
			shoot()
	
	if released and !fired:
		if owner.animation.animation == "dynamite_windup": 
			if owner.animation.frame >= 4:
				shoot()
		elif owner.animation.animation == "dynamite_charge":
			shoot()


func _next_anim() -> void:
	owner.animation.disconnect("animation_finished", self, "_next_anim")
	if owner.animation.animation == "dynamite_windup":
		owner.animation.animation = "dynamite_charge"


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	
	if owner.dynamite > 0:
		var impulse = Settings.DYNAMITE_PROJECTILE_SPEED * (charge / Settings.DYNAMITE_CHARGE_TIME)
		impulse.x *= owner.orientation
		owner.spawn_dynamite_projectile(1, impulse)
		owner.dynamite -= 1
		owner.emit_signal("ammo_updated", owner.dynamite)
		owner.animation.play("dynamite_post")
		fired = true
	else:
		emit_signal("finished", "Idle")
	
	if !owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.connect("animation_finished", self, "_on_animation_complete")


func _on_animation_complete() -> void:
	owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
	owner.attacking = false
	emit_signal("finished", "Idle")


func _on_exit() -> void:
	button_used = ""
	fired = false
	released = false
	owner.attacking = false
	if owner.animation.is_connected("animation_finished", self, "shoot"):
		owner.animation.disconnect("animation_finished", self, "shoot")
	
	if owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
