extends AnimatedSprite2D

class_name HitEffect

# I think there's 3 different animations and they are random, needs more testing

var loops := 1


func _on_animation_finished():
	play("empty")
