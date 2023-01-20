extends State


#could use arrays
const animation_strings = {1:"swipe", 2:"punch", 3:"kick", 4:"hook"}
const sounds_numbers = {1:16, 2:17, 3:18, 4:18}


func _on_enter() -> void:
	owner.attacking = true
	owner.motion.x = 0 if owner.motion.x != 0 else owner.motion.x #gotta stand still
	#if the player has a sword powerup, use the swipe attack
	if owner.magic_sword:
		owner.melee_attack = 1 #swipe
	#if there are no enemies in close range but there is something in swipe range, use swipe
	elif !owner.enemy_in_close_range:
		if owner.object_in_swipe_range:
			owner.melee_attack = 1 #swipe
		#if nothing nearby, attack at random
		else:
			randomize()
			#for now this is random between all 4 attacks but in the original, 
			#swipes and kicks have a smaller chance of happening when attacking at nothing
			owner.melee_attack = randi()%4+1 #swipe, punch, hook or kick
	#if there's an enemy in melee range, attack with close range attacks
	else: 
		randomize()
		owner.melee_attack = randi()%3+2 #punch, hook or kick
	owner.animation.connect("animation_finished", self, "_check_attack")
	owner.animation.play("attack_%s" % animation_strings[owner.melee_attack])
	Utils.decide_player(owner.player_sounds, owner.action_sounds[sounds_numbers[owner.melee_attack]]) 


func _update(_delta) -> void:
	#can cancel melee attacks with crouching
	if !owner.is_on_floor():
		emit_signal("finished", "Jump")
	elif Input.is_action_just_pressed("ui_down"):
		if owner.animation.is_connected("animation_finished", self, "_check_attack"):
			owner.animation.disconnect("animation_finished", self, "_check_attack")
		emit_signal("finished", "Crouch")


func _check_attack() -> void:
	match owner.melee_attack:
		1: #swipe
			check_attack(owner.attack_sword, owner.magic_sword)
		2: #punch
			check_attack(owner.attack_punch)
		3: #kick
			check_attack(owner.attack_kick)
		4: #hook
			check_attack(owner.attack_hook)
	owner.animation.disconnect("animation_finished", self, "_check_attack")
	if !owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.connect("animation_finished", self, "_on_animation_complete")
	if owner.melee_attack != 0:
		owner.animation.play("attack_%s_post" % animation_strings[owner.melee_attack])


func _on_exit() -> void:
	if owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
	owner.attacking = false
