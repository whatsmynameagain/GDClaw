tool

extends Enemy

var active_state = "Idle"

var _voice_lines = { 
	"attack_1" : preload("res://sounds/enemy/officer/officer_attack_1.wav"),
	"death_1" : preload("res://sounds/enemy/officer/officer_death_1.wav"),
	"death_2" : preload("res://sounds/enemy/officer/officer_death_2.wav"),
	"idle_1" : preload("res://sounds/enemy/officer/officer_idle_1.wav"),
	"idle_2" : preload("res://sounds/enemy/officer/officer_idle_2.wav"),
	"lift_1" : preload("res://sounds/enemy/officer/officer_lift_1.wav"),
	"lift_2" : preload("res://sounds/enemy/officer/officer_lift_2.wav"),

} setget , _get_voice_lines

func _get_voice_lines() -> Dictionary:
	return _voice_lines
	

func _init() -> void:
	type = "officer"


func damage_on_enter() -> void:
	print("officer damage_on_enter")
