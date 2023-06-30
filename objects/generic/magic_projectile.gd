extends RigidBody2D

class_name MagicProjectile

var orientation : int

@onready var projectile_glitter = $ProjectileGlitter


func _get_class() -> String:
	return "MagicProjectile"


func _is_class(name) -> bool:
	return name == "MagicProjectile" or super.is_class(name)


func _ready():
	linear_velocity = Settings.MAGIC_PROJECTILE_SPEED
	z_index = Settings.PLAYER_Z+1


#delete after hitting a wall
func _integrate_forces(_state) -> void:
	if abs(linear_velocity.x) != Settings.MAGIC_PROJECTILE_SPEED.x:
		queue_free()


func _on_Timer_timeout():
	queue_free()


func _on_body_entered(body):
	if body._is_class("Crate"):
		body.on_break()
	if body.has_method("on_hit"):
		body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.MAGIC_DAMAGE, body.global_position)
