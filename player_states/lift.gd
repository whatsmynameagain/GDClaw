extends State


var lifting := false
var charge_key := ""
var charging := false
var charge : float
var charged := false
var throwing := false
var moving := false
var step_timer : float
var object_animation 

func _on_enter() -> void:
	owner.lifting = true
	owner.animation.play("lift")
	if !is_instance_valid(owner.lifted_object)and owner.liftable_in_close_range:
		owner.lifted_object = owner.liftables_in_range[0]
	owner.lifted_object._on_lift()
	owner.lifted_object.global_position = owner.lift_position_1.global_position
	object_animation = (owner.lifted_object.animation if !is_instance_valid(owner.lifted_object.linked_enemy) 
			else owner.lifted_object.linked_enemy.animation)
	object_animation.owner._flip_anim(true if owner.orientation == owner.Orientations.LEFT else false)
	await owner.animation.frame_changed #wait for the frame to change before playing the sound
	if is_instance_valid(owner.lifted_object): #in case damage happened in that yield time (onExit sets lifted_object to null)
		object_animation.play("held")
		owner.player_sounds.stream = owner.action_sounds[19]
		owner.player_sounds.play()
		owner.lifted_object.global_position = owner.lift_position_2.global_position
		await owner.animation.frame_changed #wait for the extra frame before being able to throw
		lifting = true


func _update(_delta) -> void:
	if !owner.is_on_floor():
		emit_signal("finished", "Idle")
	if lifting:
		if Input.is_action_just_pressed("ui_attack") and charge_key == "":
			charge_key = "ui_attack"
		elif Input.is_action_just_pressed("ui_lift") and charge_key == "":
			charge_key = "ui_lift"
		
		if charge_key != "":
			if Input.is_action_just_pressed(charge_key) and !charging and !throwing:
				charging = true
				owner.animation.play("lift_charge")
				owner.motion.x = 0
				owner.lifted_object.global_position = owner.lift_position_charge.global_position
			elif Input.is_action_pressed(charge_key) and charging and !charged:
				if Input.is_action_just_pressed("ui_left"):
					owner.orientation = owner.Orientations.LEFT
					owner.animation.flip_h = true
				elif Input.is_action_just_pressed("ui_right"):
					owner.orientation = owner.Orientations.RIGHT
					owner.animation.flip_h = false
				owner.lifted_object.global_position = owner.lift_position_charge.global_position
				charge += _delta
				if charge >= Settings.THROW_CHARGE_TIME:
					charged = true
			elif ((Input.is_action_just_released(charge_key) and charging) #letting go mid charge
					or (Input.is_action_pressed(charge_key) and charged)): #or completely charged
				charging = false
				charged = false
				charge_key = ""
				throwing = true
				moving = false
				owner.animation.play("lift_throw")
				owner.player_sounds.stream = owner.action_sounds[20]
				owner.player_sounds.play()
				var impulse = (Settings.THROW_MIN_IMPULSE + (Settings.THROW_MAX_IMPULSE - Settings.THROW_MIN_IMPULSE) * 
					(charge / Settings.THROW_CHARGE_TIME))
				impulse.x *= owner.orientation
				owner.lifted_object.apply_central_impulse(impulse)
				owner.lifted_object.sleeping = false
				owner.lifted_object.contact_monitor = true
				owner.lifted_object.max_contacts_reported = 1
				owner.lifted_object.throw_direction = owner.orientation
				owner.lifted_object._on_throw()
				
				if !object_animation.get_parent().is_class("Enemy"):
					object_animation.play("thrown")
				await owner.animation.animation_finished
				emit_signal("finished", "Idle")
		elif ((Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")) 
				and !moving and !throwing):
			step_timer = 0.7
		elif (Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) and !charging and !throwing:
			if Input.is_action_pressed("ui_left") or (Input.is_action_pressed("ui_left") 
					and Input.is_action_pressed("ui_right")):
				owner.orientation = owner.Orientations.LEFT
			elif Input.is_action_pressed("ui_right"):
				owner.orientation = owner.Orientations.RIGHT
			moving = true
			owner.lifted_object.global_position = owner.lift_position_2.global_position
			step_timer -= _delta
			if step_timer <= 0:
				step_timer = 0.7
			elif !(step_timer <= 0.4 and step_timer >= 0.15):
				owner.motion.x = Settings.LIFT_MOVEMENT_SPEED * owner.orientation
			else:
				owner.motion.x = 0
			owner.animation.play("lift_walk")
			owner.animation.flip_h = owner.orientation == owner.Orientations.LEFT
			if !owner.is_on_floor():
				owner.lifted_object.apply_central_impulse(Vector2(150 * owner.orientation, 0)) #not tested, seems ok
				emit_signal("finished", "Jump")
		elif moving and Input.is_action_just_released("ui_left" if owner.orientation == owner.Orientations.LEFT else "ui_right"):
			owner.animation.play("lift_idle")
			owner.motion.x = 0
			moving = false


func _on_exit()  -> void:
	lifting = false
	throwing = false
	charging = false
	charged = false
	charge = 0.0
	moving = false
	charge_key = ""
	if !owner.lifted_object.thrown:
		owner.lifted_object._on_dropped()
	owner.lifted_object.sleeping = false
	owner.lifted_object.contact_monitor = true
	owner.lifted_object.max_contacts_reported = 1
	owner.lifted_object = null
	owner.lifting = false
