tool
extends Node2D

class_name Ladder

#Could be done by checking the tiles but MEH
#It's easier with signals

export(int, 1, 999) var size = 2 setget set_size

var set := false

onready var ladder_body_collision = $LadderBody/LadderBody/CollisionShape2D
onready var ladder_body = $LadderBody
onready var ladder_top = $LadderTop


func set_size(value) -> void:
	size = value
	if !Engine.is_editor_hint():
		call_deferred("update_size") #call after it's ready
	else:
		get_node("LadderBody").visible = false
		get_node("LadderTop").visible = false
	update()


func set_body(value: bool) -> void:
	ladder_body_collision.set_disabled(!value) 
	ladder_body_collision.get_parent().visible = value 


func update_size() -> void:
	if size == 1:
		set_body(false)
	else:
		set_body(true)
		ladder_body.position.y = (32 * size)
		ladder_body.scale.y = size -1
		#could also directly change the size of the thing instead of scaling it on the y axis
		#dunno which way is better... but meh, it works
		ladder_body.visible = true #for 'visible collision shapes' debugging
		ladder_top.visible = true


func _draw():
	if Engine.is_editor_hint():
		#draw the top edge
		draw_line(Vector2(-32,-28), Vector2(32, -28), Color(1,1,1,0.8), 8.0)
		#draw the body
		draw_line(Vector2(0, -32), Vector2(0, 64 * size - 32), Color(1,1,1,0.8), 8.0)
		#draw the bottom edge
		draw_line(Vector2(-32, (-36 + size * 64)), Vector2(32, (-36 + size * 64)), Color (1,1,1,0.8), 8.0)
