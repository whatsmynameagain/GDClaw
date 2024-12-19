extends RigidBody2D

class_name PistolBullet

var queued := false #queued for despawning
var orientation : int

func _get_class() -> String:
	return "PistolBullet"


func _is_class(_name) -> bool:
	return _name == "PistolBullet" or super.is_class(name)


func _ready():
	linear_velocity = Settings.PISTOL_PROJECTILE_SPEED
	z_index = Settings.PLAYER_Z-1


#delete after hitting a wall
func _integrate_forces(_state) -> void:
	if abs(linear_velocity.x) != Settings.PISTOL_PROJECTILE_SPEED.x:
		queue_free()


func _on_Timer_timeout():
	queue_free()


func _on_body_entered(body):
	if not queued: #to avoid double crate impacts
		if body._is_class("Crate"):
			body.on_break()
			queued = true
			queue_free()
		elif body._is_class("ExplosiveBarrel"):
			body.explode()
			queued = true
			queue_free()
		
		if body.has_method("on_hit"):
			body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.PISTOL_DAMAGE, global_position)
	else:
		queue_free()

