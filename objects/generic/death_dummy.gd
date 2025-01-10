extends KinematicBody2D


const MAXSPEED := 1000

var fall := false
var speed := 0.0

onready var hang_timer = $HangTimer
onready var despawn_timer = $DespawnTimer


func _ready() -> void:
	hang_timer.wait_time = 0.75
	hang_timer.one_shot = true
	hang_timer.start()


func _physics_process(_delta) -> void:
	if fall:
		if speed < MAXSPEED:
			speed += get_parent().GRAVITY * _delta #this would despawn the dummy on screen if the level's gravity is low enough, meh
# warning-ignore:return_value_discarded
		move_and_slide(Vector2(0, speed))


func _on_hang_timeout() -> void:
	fall = true
	despawn_timer.wait_time = 3 
	despawn_timer.one_shot = true
	despawn_timer.start()


func _on_despawn_timeout() -> void:
	queue_free()
