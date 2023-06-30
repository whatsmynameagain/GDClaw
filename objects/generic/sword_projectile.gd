extends RigidBody2D

class_name SwordProjectile


var type = Settings.Damage_Types.FIRE: set = set_type
var orientation : int

@onready var animation = $AnimatedSprite2D


func _get_class() -> String:
	return "SwordProjectile"


func _is_class(name) -> bool:
	return name == "SwordProjectile" or super.is_class(name)


func set_type(value) -> void:
	type = value
	call_deferred("setup")


func setup() -> void:
	animation.play(Settings.Damage_Types.keys()[type])


func _ready() -> void:
	linear_velocity = Settings.SWORD_PROJECTILE_SPEED
	z_index = Settings.PLAYER_Z+1


#delete after hitting a wall
func _integrate_forces(_state) -> void:
	#change if something is added to affect proj speed
	if abs(linear_velocity.x) != Settings.SWORD_PROJECTILE_SPEED.x:
		queue_free()


func _on_body_entered(body) -> void:
	if body._is_class("Crate"):
		body.on_break()
	if body.has_method("on_hit"):
		#-add elemental hit effect to body
		body.on_hit(type, self, Settings.SWORD_PROJECTILE_DAMAGE, body.global_position)


func _on_timer_timeout() -> void:
	queue_free()
