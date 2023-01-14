tool
extends Node2D

#still not completely decided on what the tool info should look like
#for now it works fine-ish aside from having to input coordinates manually in an array
#and the overlapping text in looping one-axis paths

#---this still has game breaking problems when the path is not a loop (teleporting),
#---the player is teleported with the elevator, haven't really looked into why yet

#-to do: needs a reset on death option

export(String, "Standard", "Start", "Stop", "Trigger") var type = "Standard" #to-do: change to enum
export(bool) var one_way = false
export(Texture) var texture = preload("res://sprites/objects/elevator/level1.png")
export(bool) var preview  = true setget set_preview
export(PoolVector3Array) var steps = PoolVector3Array() setget set_steps

var follow = Vector2.ZERO
var shadow_offset = Vector2(-44, -17)
var move_from = Vector2.ZERO
var move_to : Vector2
var carrying : bool = false

onready var elevator_body = $ElevatorBody
onready var tween = $ElevatorTween
onready var sprite = $ElevatorBody/Sprite
onready var carry_check = $ElevatorBody/DetectCarry
onready var carry_check_safe = $ElevatorBody/DetectCarrySafe
onready var carry_check_break = $ElevatorBody/DetectCarryBreak


func set_preview(value) -> void:
	preview = value
	update()


func set_steps(value) -> void:
	steps = value
	update()


func _ready():
	if Engine.is_editor_hint():
		return
	init_tween()
	elevator_body.visible = true
	z_index = Settings.PLAYER_Z - 1


func init_tween() -> void:
	var duration : float = 0.0
	var delay : float = 0.0
	for step in steps:
		move_to = Vector2(step.x + move_from.x, step.y + move_from.y) #get where to move from the current step
		if step.z != 0: #check for zero division
			#some weird calculation I copypasted, getting speed from step.z
			duration = move_to.distance_to(move_from) / float(step.z * 64)
		else: 
			duration = move_to.distance_to(move_from) / float(64)
		tween.interpolate_property(self, "follow", 
				move_from, move_to, duration, 
				Tween.TRANS_LINEAR, 0,
				delay)
		delay += duration
		move_from = move_to
	tween.set_repeat(!one_way)
	if type != "Start":
		 tween.start()


func _physics_process(_delta) -> void:
	if !Engine.is_editor_hint():
		elevator_body.position = elevator_body.position.linear_interpolate(follow, 1)
		carry_check_break.enabled = true if !carrying else false
		if !carry_check_break.is_colliding():
			if carry_check.is_colliding(): 
				var collider = carry_check.get_collider()
				if collider.motion.y == collider.gravity:
					carrying = true
			elif carry_check_safe.is_colliding(): 
				var collider = carry_check_safe.get_collider()
				if collider.motion.y == collider.gravity:
					carrying = true
			else: 
				carrying = false
		else: 
			carrying = false
		
		if carrying and type == "Start":
			tween.start()
		elif carrying and type == "Stop":
			tween.stop_all()
		elif !carrying and type == "Stop":
			tween.resume_all()
		elif carrying and type == "Trigger":
			tween.resume_all()
		elif !carrying and type == "Trigger":
			tween.stop_all()


func _draw() -> void:
	if Engine.is_editor_hint():
		move_from = Vector2.ZERO
		var i := 1
		var label = Label.new() #_draw is only called once and then again with every update()
		var font = label.get_font("") #gotta get the default font for draw_string
		label.queue_free()
		if preview:
			get_node("ElevatorBody").visible = false #can't use the onready variable elevator_body on the editor 
			for step in steps:
				move_to = Vector2(step.x + move_from.x, step.y + move_from.y)
				draw_texture(texture, Vector2(move_to.x + shadow_offset.x, move_to.y + shadow_offset.y), 
						Color(1,1,1,0.6))
				#doesn't really work with looping elevator paths that only have 2 steps (text overlaps in the middle)
				draw_string(font, Vector2((move_to.x + move_from.x)/2 + 4, 
						(move_to.y + move_from.y)/2  + 16), "Step %s, Speed %s" % [i, step.z], 
						Color("#ffffff"))
				draw_line(move_from, move_to, Color(1,1,1,0.5), 4.0)
				move_from = move_to
				i += 1
		else: $ElevatorBody.visible = true
