extends State


func _on_enter() -> void:
	owner.attacking = true
	owner.animation.connect("animation_finished", self, "_check_attack")
	owner.animation.play("attack_crouch")
	Utils.decide_player(owner.player_sounds, owner.action_sounds[17]) 


func _update(_delta) -> void:
	if !Input.is_action_pressed("ui_down"):
		emit_signal("finished", "Idle")
	elif !owner.is_on_floor() and !owner.on_elevator:
		emit_signal("finished", "Jump")


func _check_attack() -> void:
	owner.melee_attack = 6
	check_attack(owner.attack_crouch, owner.magic_sword) 
	owner.animation.disconnect("animation_finished", self, "_check_attack")
	owner.animation.connect("animation_finished", self, "_on_animation_complete")
	owner.animation.play("attack_crouch_post")


func _on_exit() -> void:
	if owner.animation.is_connected("animation_finished", self, "_on_animation_complete"):
		owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
	if owner.animation.is_connected("animation_finished", self, "_check_attack"):
		owner.animation.disconnect("animation_finished", self, "_check_attack")
	owner.attacking = false
