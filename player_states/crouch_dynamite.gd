extends State


var released : bool
var charge : float
var fired : bool
var button_used = ""


func _on_enter() -> void:
	
	button_used = "ui_dynamite" if Input.is_action_just_pressed("ui_dynamite") else "ui_ranged"
	owner.active_ranged = owner.Ranged.DYNAMITE
	released = false
	charge = 0.0
	fired = false
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x 
	owner.attacking = true
	owner.emit_signal("ranged_changed", "dynamite", owner.dynamite)
	if owner.dynamite > 0:
		owner.on_dynamite_prepared()
		owner.animation.play("dynamite_crouch_charge")
		owner.emit_signal("ranged_changed", "dynamite", owner.dynamite)
	else:
		owner.animation.play("dynamite_crouch_empty")


func _update(delta) -> void:
	if !Input.is_action_pressed("ui_down"):
		emit_signal("finished", "Idle") 
	elif !owner.is_on_floor() and !owner.on_elevator:
		emit_signal("finished", "Jump")
	elif owner.dynamite > 0:
		if Input.is_action_just_released(button_used):  
			released = true
			
		elif !released and charge < Settings.DYNAMITE_CHARGE_TIME:
			charge += delta
			
		elif !fired and charge >= Settings.DYNAMITE_CHARGE_TIME:
			charge = Settings.DYNAMITE_CHARGE_TIME
			shoot()
	elif owner.dynamite == 0:
		if !owner.animation.is_connected("animation_finished", Callable(self, "_on_animation_complete")):
			owner.animation.connect("animation_finished", Callable(self, "_on_animation_complete"))
		
	if released and !fired:
		shoot()


func shoot() -> void:
	if owner.animation.is_connected("animation_finished", Callable(self, "shoot")):
		owner.animation.disconnect("animation_finished", Callable(self, "shoot"))
	
	if owner.dynamite > 0:
		#note: needs a tiny bit more impulse on tap but imma leave like this
		var impulse = Settings.DYNAMITE_PROJECTILE_SPEED * (charge / Settings.DYNAMITE_CHARGE_TIME)
		impulse.x *= owner.orientation
		owner.spawn_dynamite_projectile(2, impulse)
		owner.dynamite -= 1
		owner.emit_signal("ammo_updated", owner.dynamite)
		owner.animation.play("dynamite_crouch_post")
		fired = true
	else:
		emit_signal("finished", "Crouch")
	
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
