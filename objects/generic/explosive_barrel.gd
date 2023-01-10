extends LiftableDummy

class_name ExplosiveBarrel


var exploding = false

onready var collision = $CollisionShape2D
onready var area = $Area2D
onready var explosion_area = $Area2D/CollisionShape2D
onready var animation = $AnimatedSprite
onready var audio = $AudioStreamPlayer2D


func get_class() -> String:
	return "ExplosiveBarrel"


func is_class(name) -> bool:
	return name == "ExplosiveBarrel" or .is_class(name)


func _ready() -> void:
	audio.volume_db = Settings.EFFECTS_VOLUME
	z_index = Settings.BARREL_Z
	physics_material_override = load("res://objects/generic/pickup_physics_material_bounceless.tres")


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
	yield(animation, "animation_finished")
	explosion_area.disabled = false
	collision.disabled = true
	animation.play("explosion_2")
	yield(animation, "animation_finished")
	explosion_area.disabled = true
	animation.play("explosion_3")
	yield(animation, "animation_finished")
	queue_free()


func _on_lift() -> void:
	._on_lift()
	area.set_collision_mask_bit(1, false)
	area.set_collision_mask_bit(6, false)
	area.set_collision_mask_bit(8, false)
	area.set_collision_mask_bit(11, false)


func _on_land() -> void:
	area.set_collision_mask_bit(1, true)
	area.set_collision_mask_bit(6, true)
	area.set_collision_mask_bit(8, true)
	area.set_collision_mask_bit(11, true)
	explode()


func _flip_anim(x) -> void:
	animation.flip_h = x


func _on_movement_stop() -> void:
	pass

#explosion effects
func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_class("Crate"):
		body.on_break()
	elif body.is_class("Player") or body.is_class("Enemy"):
		body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.BARREL_DAMAGE, global_position)
	else: #barrel
		if !body.lifted and !body.thrown and !body.exploding:
			body.explode()
