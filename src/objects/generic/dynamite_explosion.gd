extends Area2D

class_name DynamiteExplosion


var overlap_local = Rect2(Vector2.ZERO, Vector2.ZERO)

@onready var audio = $AudioStreamPlayer
@onready var animation = $AnimatedSprite2D
@onready var collision = $CollisionShape2D


func _get_class() -> String:
	return "DynamiteExplosion"


func _is_class(_name) -> bool:
	return _name == "DynamiteExplosion" or super.is_class(name)


func _ready() -> void:
	z_index = Settings.PLAYER_Z + 1
	animation.play()
	#animation.modulate = Color(1,1,1,0.2)
	audio.set_volume_db(Settings.EFFECTS_VOLUME)
	audio.play()
	#duration, frequency, amplitude
	await get_tree().create_timer(0.15).timeout #slight delay before cam shake
	get_tree().call_group("camera", "shake", 0.8, 30, 12)


func _process(_delta) -> void:
	#explosion doesn't do damage until a couple frames in
	#seems ok, check timing... eventually
	if animation.frame == 2:
		collision.disabled = false
	elif animation.frame == 4: #disabled on frame 3, could be on frame 2
		collision.disabled = true


func _on_body_entered(body) -> void:
	if body._is_class("Crate"):
		body.on_break()
	elif body._is_class("ExplosiveKeg"):
		body.explode()
	else:
		#SHIT WILL BREAK IF THE EXPLOSION AREA IS NOT A RECTANGLE
		var overlap = Utils.contact_point_2_rect(collision, body.get_active_hitbox())
		if body.has_method("on_hit"): #enemy, player
			body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.DYNAMITE_DAMAGE, 
					Utils.rect_corner_to_center(overlap).position)
	#show a rectangle that covers the overlapped area
#	overlap_local = Rect2(to_local(overlap.position), overlap.size)
#	update() #call _draw


#func _draw() -> void:
#	draw_rect(overlap_local, Color.purple, true)


func _on_animation_finished() -> void:
	queue_free()
