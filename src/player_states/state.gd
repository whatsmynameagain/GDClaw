extends Node

class_name State


signal finished(animation)

var scanned := false #for melee attack states
var attack_timer : Timer
var _attack_area : CollisionShape2D


func get_class() -> String:
	return "State"


func is_class(name) -> bool:
	return name == "State" or .is_class(name)


func _ready() -> void:
	attack_timer = Timer.new()
	add_child(attack_timer)
	
	
func _on_enter() -> void:
	pass


func _update(_delta) -> void:
	pass


func _on_exit()  -> void:
	pass


#method for switching sides and applying movement (for many states)
func move(direction : bool, animation : String = owner.animation.animation) -> void:
	owner.motion.x = owner.get_run_speed() if direction else -owner.get_run_speed()
	owner.animation.flip_h = !direction
	owner.animation.play(animation)
	owner.orientation = owner.Orientations.RIGHT if direction else owner.Orientations.LEFT


#for melee attack states
func check_attack(attack_area : CollisionShape2D, magic_sword : bool = false) -> void:
	if magic_sword: #don't activate the attack_area
		owner.spawn_sword_projectile(1)
	else:
		_attack_area = attack_area
		attack_area.disabled = false
		if !attack_timer.is_connected("timeout", self, "_disable_attack_hitbox"):
			# warning-ignore:return_value_discarded
			attack_timer.connect("timeout", self, "_disable_attack_hitbox")
		attack_timer.one_shot = true
		attack_timer.start(Settings.MELEE_ATTACK_SCAN_TIME)
		


func _disable_attack_hitbox() -> void:
	_attack_area.disabled = true
	attack_timer.disconnect("timeout", self, "_disable_attack_hitbox")


func _on_animation_complete() -> void:
	owner.animation.disconnect("animation_finished", self, "_on_animation_complete")
	owner.melee_attack = 0
	owner.attacking = false
	emit_signal("finished", owner.previous_state.name)
