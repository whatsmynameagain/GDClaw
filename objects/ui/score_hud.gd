extends HUDElement


func _ready() -> void:
	sprites = {
		0 : preload("res://sprites/ui/hud/score_timer_numbers/000.png"),
		1 : preload("res://sprites/ui/hud/score_timer_numbers/001.png"),
		2 : preload("res://sprites/ui/hud/score_timer_numbers/002.png"),
		3 : preload("res://sprites/ui/hud/score_timer_numbers/003.png"),
		4 : preload("res://sprites/ui/hud/score_timer_numbers/004.png"),
		5 : preload("res://sprites/ui/hud/score_timer_numbers/005.png"),
		6 : preload("res://sprites/ui/hud/score_timer_numbers/006.png"),
		7 : preload("res://sprites/ui/hud/score_timer_numbers/007.png"),
		8 : preload("res://sprites/ui/hud/score_timer_numbers/008.png"),
		9 : preload("res://sprites/ui/hud/score_timer_numbers/009.png")
		}
	animation.play() 
