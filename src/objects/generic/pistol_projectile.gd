extends RigidBody2D

class_name PistolProjectile

var queued := false #queued for despawning
var orientation : int

func _get_class() -> String:
	return "PistolProjectile"


func _is_class(_name) -> bool:
	return _name == "PistolProjectile" or super.is_class(name)


func _ready():
	linear_velocity = Settings.PISTOL_PROJECTILE_SPEED
	z_index = Settings.PLAYER_Z-1


#delete after hitting a wall
func _integrate_forces(_state) -> void:
	
	#(from sword_projectile.gd)
	#this broke because the projectile is losing linear_velocity over time.
	#figure out why
	if abs(linear_velocity.x) != Settings.PISTOL_PROJECTILE_SPEED.x:
		queue_free()


func _on_Timer_timeout():
	queue_free()


func _on_body_entered(body):
	if not queued: #to avoid double crate impacts
		
		#this next bit could be simplified by changing
		#the crate and keg methods to have the same name 
		if body._is_class("Crate"):
			body.on_break()
			queued = true
			queue_free()
		elif body._is_class("ExplosiveKeg"):
			body.explode()
			queued = true
			queue_free()
		
		if body.has_method("on_hit"):
			body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.PISTOL_DAMAGE, global_position)
	else:
		queue_free()
