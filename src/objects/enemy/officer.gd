#tool

extends Enemy

var active_state = "Idle"

var _voice_lines = { 
	"attack_1" : preload("res://sounds/enemy/officer/officer_attack_1.ogg"),
	"death_1" : preload("res://sounds/enemy/officer/officer_death_1.ogg"),
	"death_2" : preload("res://sounds/enemy/officer/officer_death_2.ogg"),
	"idle_1" : preload("res://sounds/enemy/officer/officer_idle_1.ogg"),
	"idle_2" : preload("res://sounds/enemy/officer/officer_idle_2.ogg"),
	"lift_1" : preload("res://sounds/enemy/officer/officer_lift_1.ogg"),
	"lift_2" : preload("res://sounds/enemy/officer/officer_lift_2.ogg"),

} setget , _get_voice_lines

onready var melee_hitbox = $MeleeHitbox


func _get_voice_lines() -> Dictionary:
	return _voice_lines
	

func _init() -> void:
	type = "officer"


func _attack_melee_on_enter() -> bool:
	sprite.offset = Vector2(-20, 0)
	return true


func _attack_melee_on_exit() -> bool:
	sprite.offset = Vector2.ZERO
	return true

#func _damage_on_enter() -> bool:
#	print("officer damage_on_enter")
#	return true


#not tested
func _on_MeleeHitbox_body_entered(body):
	var overlap = Utils.contact_point_2_rect(melee_hitbox, body.get_active_hitbox())
	body.on_hit(Settings.Damage_Types.COMBAT, self, 
		Settings.ENEMY_OFFICER_MELEE_DAMAGE, Utils.rect_corner_to_center(overlap).position)
