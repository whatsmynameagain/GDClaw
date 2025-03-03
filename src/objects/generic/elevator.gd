@tool
extends Node2D

#still not completely decided on what the tool info should look like
#for now it works fine-ish aside from having to input coordinates manually in an array
#and the overlapping text in looping one-axis paths

#---this still has game breaking problems when the path is not a loop (teleporting),
#---the player is teleported with the elevator, haven't really looked into why yet

#-to do: needs a reset on death option

@export var type = "Standard" #to-do: change to enum # (String, "Standard", "Start", "Stop", "Trigger")
@export var one_way: bool = false
@export var texture: Texture2D = preload("res://sprites/objects/elevator/level1.png")
@export var preview: bool  = true: set = set_preview
@export var steps: PackedVector3Array = PackedVector3Array(): set = set_steps

var follow = Vector2.ZERO
var shadow_offset = Vector2(-44, -17)
var move_from = Vector2.ZERO
var move_to : Vector2
var carrying : bool = false
@onready var tween : Tween = get_tree().create_tween()

@onready var elevator_body = $ElevatorBody
@onready var sprite = $ElevatorBody/Sprite2D
@onready var carry_check = $ElevatorBody/DetectCarry
@onready var carry_check_safe = $ElevatorBody/DetectCarrySafe
@onready var carry_check_break = $ElevatorBody/DetectCarryBreak


func set_preview(value) -> void:
	preview = value
	queue_redraw()


func set_steps(value) -> void:
	steps = value
	queue_redraw()


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
		
		#tween.interpolate_property(self, "follow", 
		#		Vector2.ZERO, move_to, duration, 
		#		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, IDLE_DURATION
		#	)
		#tween.interpolate_property(self, "follow", 
		#		move_to, Vector2.ZERO, duration, 
		#		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, duration + IDLE_DURATION * 2
		#	)
		
		#tween.bind_node($Platform)
		#tween.set_loops()
		#tween.set_ease(Tween.EASE_IN_OUT)
		#tween.tween_property(self, "follow", move_to, duration).from(Vector2.ZERO)
		#tween.tween_property(self, "follow", Vector2.ZERO, duration).from(move_to)
		
		delay += duration
		move_from = move_to
	tween.set_repeat(!one_way)
	if type != "Start":
		tween.start()


func _physics_process(_delta) -> void:
	if !Engine.is_editor_hint():
		elevator_body.position = elevator_body.position.lerp(follow, 1)
		carry_check_break.enabled = true if !carrying else false
		if !carry_check_break.is_colliding():
			if carry_check.is_colliding(): 
				var collider = carry_check.get_collider()
				if collider.motion.y == 0:
					carrying = true
			elif carry_check_safe.is_colliding(): 
				var collider = carry_check_safe.get_collider()
				if collider.motion.y == 0:
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
		var default_font = ThemeDB.fallback_font
		var default_font_size = ThemeDB.fallback_font_size
		draw_string(default_font, Vector2(64, 64), "Hello world", HORIZONTAL_ALIGNMENT_LEFT, -1, default_font_size)
	
		label.queue_free()
		if preview:
			get_node("ElevatorBody").visible = false #can't use the onready variable elevator_body on the editor 
			for step in steps:
				move_to = Vector2(step.x + move_from.x, step.y + move_from.y)
				draw_texture(texture, Vector2(move_to.x + shadow_offset.x, move_to.y + shadow_offset.y), 
						Color(1,1,1,0.6))
				#doesn't really work with looping elevator paths that only have 2 steps (text overlaps in the middle)
				draw_string(default_font, 
						Vector2((move_to.x + move_from.x)/2 + 4, (move_to.y + move_from.y)/2  + 16), 
						"Step %s, Speed %s" % [i, step.z], 
						HORIZONTAL_ALIGNMENT_LEFT,
						-1, #default values
						16,
						Color("#ffffff"))
				draw_line(move_from, move_to, Color(1,1,1,0.5), 4.0)
				move_from = move_to
				i += 1
		else: $ElevatorBody.visible = true
