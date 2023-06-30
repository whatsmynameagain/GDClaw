extends RigidBody2D

#can sometimes be placed in a wall (like in the original), but most of the time it starts bouncing around...
#not sure what to do with that, speedruners use it to trigger an extra jump after the damage state

signal spawn_explosion(explosion, pos)

var impulse := Vector2.ZERO #max (+-)400, -600
var impulse_applied := false
var checked := false
var orientation : int

@onready var projectile_glitter = $ProjectileGlitter
@onready var timer = $Timer

func _get_class() -> String:
	return "DynamiteProjectile"


func _is_class(name) -> bool:
	return name == "DynamiteProjectile" or super.is_class(name)


func _ready() -> void:
	z_index = Settings.PLAYER_Z + 1
	timer.wait_time = Settings.DYNAMITE_FUSE_TIME


func _integrate_forces(state):
	if !impulse_applied:
		apply_central_impulse(impulse)
		impulse_applied = true
	#change animation to bounce once it hits the ground
	#note: haven't tested it yet but this will fail if the projectile hits a ceiling
	#it'll have to be changed
	if state.get_contact_count() > 0 and !checked:
		var angle = rad_to_deg(state.get_contact_local_normal(0).angle())
		if angle < -85 and angle > -95: 
			checked = true
			$AnimatedSprite2D.animation = "bounce"


func _on_Timer_timeout() -> void:
	var explosion = preload("res://objects/generic/dynamite_explosion.tscn").instantiate()
	emit_signal("spawn_explosion", explosion, global_position)
	queue_free()
