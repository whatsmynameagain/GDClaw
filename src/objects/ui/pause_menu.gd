extends Control

signal pause_toggled


#var _paused : bool = false


#this isn't working anymore
func _input(event) -> void:
	if event.is_action_pressed("ui_pause"):
		emit_signal("pause_toggled")
		visible = !get_tree().paused
		get_tree().paused = visible


#uncomment to start the game paused
#func _ready():
	#get_tree().paused = true
	#visible = true
	
#note: level music shouldn't be paused, so the level scene's music player's pause option is set to process
