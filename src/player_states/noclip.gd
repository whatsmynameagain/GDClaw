extends State


func _on_enter() -> void:
	owner.animation.play("idle_bored")
	print("Enter Noclip")
	owner.call_deferred("set_stance_collision", true, true) #for when entering noclip from crouch
	owner.get_node("AreaCheck").get_node("CollisionShape2D").disabled = true
	owner.motion = Vector2.ZERO


func _update(_delta) -> void:
	owner.motion = Vector2.ZERO # to kill any momentum left 
	if Input.is_action_pressed("ui_up"):
		owner.motion.y = -1000
	
	if Input.is_action_pressed("ui_down"):
		owner.motion.y = 1000
	
	if Input.is_action_just_released("ui_up"):
		owner.motion.y = 0
	
	if Input.is_action_just_released("ui_down"):
		owner.motion.y = 0
	
	if Input.is_action_pressed("ui_left"):
		owner.motion.x = -1000
	
	if Input.is_action_pressed("ui_right"):
		owner.motion.x = 1000
	
	if Input.is_action_just_released("ui_left"):
		owner.motion.x = 0
	
	if Input.is_action_just_released("ui_right"):
		owner.motion.x = 0


func _on_exit() -> void:
	owner.motion = Vector2.ZERO
	owner.collision_standing.disabled = false
	owner.area_check.get_node("CollisionShape2D").disabled = false
	
