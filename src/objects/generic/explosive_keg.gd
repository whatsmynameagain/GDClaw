extends LiftableDummy

class_name ExplosiveKeg


var exploding = false

@onready var collision = $CollisionShape2D
@onready var area = $Area2D
@onready var explosion_area = $Area2D/CollisionShape2D
@onready var animation = $AnimatedSprite2D
@onready var audio = $AudioStreamPlayer2D


func _get_class() -> String:
	return "ExplosiveKeg"


func _is_class(_name) -> bool:
	return _name == "ExplosiveKeg" or super.is_class(name)


func _ready() -> void:
	audio.volume_db = Settings.EFFECTS_VOLUME
	z_index = Settings.KEG_Z
	physics_material_override = load("res://src/objects/generic/pickup_physics_material_bounceless.tres")


#neutralize this overriden method, it's not needed in this script
func _carry() -> void:
	pass


func explode() -> void:
	exploding = true
	linear_velocity = Vector2.ZERO
	gravity_scale = 0
	animation.play("explosion")
	audio.play()
	get_tree().call_group("camera", "shake", 0.8, 30, 12)
	await animation.animation_finished
	explosion_area.disabled = false
	collision.disabled = true
	animation.play("explosion_2")
	await animation.animation_finished
	explosion_area.disabled = true
	animation.play("explosion_3")
	await animation.animation_finished
	queue_free()


func _on_lift() -> void:
	super._on_lift()
	area.set_collision_mask_value(2, false)
	area.set_collision_mask_value(7, false)
	area.set_collision_mask_value(9, false)
	area.set_collision_mask_value(12, false)


func _on_land() -> void:
	area.set_collision_mask_value(2, true)
	area.set_collision_mask_value(7, true)
	area.set_collision_mask_value(9, true)
	area.set_collision_mask_value(12, true)
	explode()


func _flip_anim(x) -> void:
	animation.flip_h = x


func _on_movement_stop() -> void:
	pass

#explosion effects
func _on_Area2D_body_entered(body: Node) -> void:
	if body._is_class("Crate"):
		body.on_break()
	elif body._is_class("Player") or body._is_class("Enemy"):
		body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.KEG_DAMAGE, global_position)
	else: #keg
		if !body.lifted and !body.thrown and !body.exploding:
			body.explode()
