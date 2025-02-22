extends HUDElement


func _ready() -> void:
	sprites = {
		0 : preload("res://sprites/ui/hud/ammo_lives_numbers/000.png"),
		1 : preload("res://sprites/ui/hud/ammo_lives_numbers/001.png"),
		2 : preload("res://sprites/ui/hud/ammo_lives_numbers/002.png"),
		3 : preload("res://sprites/ui/hud/ammo_lives_numbers/003.png"),
		4 : preload("res://sprites/ui/hud/ammo_lives_numbers/004.png"),
		5 : preload("res://sprites/ui/hud/ammo_lives_numbers/005.png"),
		6 : preload("res://sprites/ui/hud/ammo_lives_numbers/006.png"),
		7 : preload("res://sprites/ui/hud/ammo_lives_numbers/007.png"),
		8 : preload("res://sprites/ui/hud/ammo_lives_numbers/008.png"),
		9 : preload("res://sprites/ui/hud/ammo_lives_numbers/009.png")
	}
	animation = $AnimationPlayer
	animation.play("loop")
	position.x = ProjectSettings.get_setting("display/window/size/viewport_width")
# warning-ignore:return_value_discarded
	get_parent().connect("resized", Callable(self, "update_position"))
