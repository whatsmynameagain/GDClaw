#current goal: playable level 1 including menus, intro video cutscene and booty-map cutscene-results
#to-do: 
#	-notes:
#		-check if jump momentum is maintained after taking a teleporter in the original
#	-quick:
#		-move tile sprites to /sprites/tiles
#	--features: (in order)
#		-officer player detection and attacks (mid and low, high isn't used)
#		-create soldier enemy and add mechanics
#		-same with rat
#		-claw look up state and crouch camera movement
#		-game over screen
#		-special footstep sounds (remember that bad framerate can affect animation frame detections)
#		-menus (limited)
#		-loading screen + loading mechanic(?)
#		-video cutscenes
#		-map cutscene
#		-treasure results
#		(...)
#	--lower priority features:
#		-menu animated claw
#		-remapping controls
#		(...)
#	--eventual fixes:
#		-figure out sprite offsets with atlas
#		-recreate tilesets with the new editor
#		-create script to unify tilemap collisions
#		-figure out how to extract info from original maps for easier object/tile placing
#		-look into the rolling and teleporter shaders, would be nice to have them
#		-general optimizations (first priority: stop object processing when far away enough from the player)
#		(...)


extends Node


enum GameStates {Intro, Menu, Playing, Pause, Booty} 


#for debug spawning
const treasure_type_dict = {1:"Coin", 2:"Bars", 3:"Ring", 4:"Chalice", 5:"Cross", 
		6:"Scepter", 7:"Gecko", 8:"Crown", 9:"Skull", 10:"Pearls"}
const treasure_color_dict = {1:"Red", 2:"Blue", 3:"Green", 4:"Purple"}
const restore_type_dict  = {1:"Ammo", 2:"Magic", 3:"Dynamite", 4:"Health_Food", 5:"Health", 6:"Extra_Life"}
const restore_size_dict  = {1:"Small", 2:"Medium", 3:"Large"}
const restore_model_dict  = {1:"1-2", 2:"3-4", 3:"5-6", 4:"7-8", 5:"9-10", 6:"11-12", 7:"13", 8:"14"}
const powerup_type_dict  = {1:"Catnip", 2:"Catnip_Red", 3:"Ghost", 4:"Invulnerable", 5:"Fire_Sword", 
		6:"Ice_Sword", 7:"Lightning_Sword"}
#res
const powerup_music = preload("res://music/powerup.ogg")
const circle_close_sound = preload("res://sounds/generic/circle_fade.ogg")
const circle_open_sound = preload("res://sounds/checkpoint/flag_wave.ogg")
const teleporter_sound = preload("res://sounds/teleporter/warp.ogg")
const teleporter_transition_mask = preload("res://objects/ui/teleporter_transition_mask.png")
const teleporter_transition_mask_2 = preload("res://objects/ui/teleporter_transition_mask_2.png")
const values = {
	"Coin" : 100, 
	"Bars": 500, 
	"Ring" : 1500, 
	"Chalice" : 2500, 
	"Pearls" : 2500,
	"Cross" : 5000, 
	"Scepter" : 7500, 
	"Gecko" : 10000,
	"Crown" : 15000,
	"Skull" : 25000
	}

@export var _level = "test_arena" # (String, "test_arena", "level_1" )
@export var music_enabled: bool = true

var game_state = GameStates.Playing # temp
var level_music_stop_time : float
var player
var level
var hud = preload("res://objects/ui/hud.tscn").instantiate()
var fps_label
var level_collected_treasure = [] 
var music_player
var glitter_particle_texture = preload("res://sprites/objects/player_glitter/animated_texture.tres")
#maybe also a var for total collected treasure?

@onready var ui = $UI
@onready var pause_menu = $PauseMenu/PauseMenu
@onready var circle_transition = $Transitions/CircleTransition
@onready var teleporter_transition = $Transitions/TeleporterTransition
@onready var game_sounds = $GameSounds
@onready var game_sounds_2 = $GameSounds2 #check if needed
@onready var teleporter_transition_animation = teleporter_transition.get_node("AnimationPlayer")
@onready var circle_transition_animation = circle_transition.get_node("AnimationPlayer")

func _ready() -> void:
	level = load("res://levels/%s.tscn" % _level).instantiate()
	level.music_enabled = music_enabled
	game_sounds.volume_db = Settings.EFFECTS_VOLUME
	game_sounds_2.volume_db = Settings.EFFECTS_VOLUME
	fps_label = hud.get_node("FPSLabel")
	ui.add_child(hud)
	get_node("Level").add_child(level)
	pause_menu.connect("pause_toggled", Callable(self, "_on_pause_toggled"))
	on_level_loaded()


func on_level_loaded() -> void:
	player = level.get_player()
	player.connect("treasure_collected", Callable(self, "_on_treasure_collected"))
	player.connect("teleporter_taken", Callable(self, "_on_teleporter_taken"))
	player.connect("end_item_collected", Callable(self, "_on_end_item_collected"))
	player.connect("powerup_collected", Callable(self, "_on_powerup_collected"))
	player.connect("ranged_changed", Callable(self, "_on_ranged_changed")) 
	player.connect("ammo_updated", Callable(self, "_on_ammo_updated"))
	player.connect("health_updated", Callable(self, "_on_health_updated"))
	player.connect("lives_updated", Callable(self, "_on_lives_updated"))
	player.connect("respawn", Callable(self, "_on_respawn"))
	player.connect("powerup_timer_update", Callable(self, "_on_powerup_timer_update"))
	player.connect("powerup_timer_end", Callable(self, "_on_powerup_end"))
	
	if !player.get_node("Camera2D").is_current():
		player.get_node("Camera2D").set_current(true)
	
	level_collected_treasure.clear()
	
	#this should go in the level/player initialization when that's implemented
	hud.get_node("HealthHUD").update_value(player.health)
	hud.get_node("ScoreHUD").update_value(level.score)
	hud.get_node("PowerupHUD").disable()
	hud.get_node("AmmoHUD").change_ranged("pistol", player.pistol)
	hud.get_node("LivesHUD").update_value(player.lives)


func _input(_event) -> void:
	if Input.is_action_pressed("ui_spawntreasure"): #hold for STUFF
		spawn_random_treasure()
	if Input.is_action_pressed("ui_spawnrestore"): 
		spawn_random_restore()
	if Input.is_action_pressed("ui_spawnpowerup"): 
		spawn_random_powerup()
		
	if Input.is_action_pressed("ui_spawn_sword_projectile"):
		use_treasure_spawner()
		#spawn_dynamite()
		#spawn_sword_projectile()
	
	if Input.is_action_just_pressed("ui_debug_damage"):
		#player._on_damage_taken(player, 50)
		player.on_hit(0, player, 50, player.global_position)
		
	if Input.is_action_just_pressed("ui_move_unit_left"):
		player.global_position.x -= 1
	if Input.is_action_just_pressed("ui_move_unit_right"):
		player.global_position.x += 1
		
	#these need noclip on to bypass gravity and collision correction
	if Input.is_action_just_pressed("ui_move_unit_up"):
		player.global_position.y -= 1
	if Input.is_action_just_pressed("ui_move_unit_down"):
		player.global_position.y += 1
		
	if Input.is_action_pressed("ui_quit"):
		get_tree().quit()
	
	#this assplodes if you use it while teleporting
	if Input.is_action_pressed("ui_restart"):
		level.queue_free()
		level = load("res://levels/%s.tscn" % _level).instantiate()
		$Level.add_child(level)
		on_level_loaded()
		
		#if !level_collected_treasure.empty():
		#	for x in level_collected_treasure:
		#		print("%s %s" % [x[0], x[1]]) 
		#else:
		#	print("empty")
		#on_level_loaded()


func _physics_process(_delta) -> void:
	fps_label.set_text("FPS: %s" % str(Engine.get_frames_per_second()))

#-------debug stuff---------

func spawn_dynamite() -> void:
	var pos = $Level.get_global_mouse_position()
	var thingy = preload("res://objects/generic/dynamite_projectile.tscn").instantiate()
	level.add_child(thingy)
	pause_menu.connect("pause_toggled", Callable(thingy, "_on_pause_toggled"))
	thingy.global_position = pos


func use_treasure_spawner() -> void:
	var pos = $Level.get_global_mouse_position()
	var spawner = preload("res://objects/generic/pickup_spawner.tscn").instantiate()
	level.add_child(spawner)
	spawner.global_position = pos
	spawner.set_spawn_list([[0, "Coin"], [1, "Health", "Large"], [0, "Gecko", "Blue"]])


func spawn_sword_projectile() -> void:
	var pos = $Level.get_global_mouse_position()
	var thingy = preload("res://objects/generic/sword_projectile.tscn").instantiate()
	level.add_child(thingy)
	var types =  [5, 6, 7] #fire, ice, lightning
	thingy.type = types[randi()%3]
	thingy.global_position = pos


func spawn_random_treasure() -> void:
	var pos = $Level.get_global_mouse_position()
	var thingy = preload("res://objects/generic/treasure.tscn").instantiate()
	thingy.physics = true
	
	##for mouse placing
	#thingy.physics = false
	#thingy.staticGlitter = true
	#var glitters = ["Gold", "Green", "Purple", "Red"]
	#thingy.glitterColor = glitters[randi()%3+1]
	
	thingy.one_use = true
	randomize()
	var rand_type = randi()%10+1
	thingy.type = treasure_type_dict[rand_type]
	if thingy.type in ["Coin", "Bars", "Pearls"]:
		thingy.color = "None"
	else:
		var randColor = randi()%3+1
		thingy.color = treasure_color_dict[randColor]
	level._on_pickup_spawned(thingy, pos, Settings.PICKUP_Z)


func spawn_random_restore() -> void:
	var pos = $Level.get_global_mouse_position()
	var thingy = preload("res://objects/generic/restore.tscn").instantiate()
	thingy.physics = true
	thingy.one_use = true
	randomize()
	var rand_type = randi()%6+1
	thingy.type = restore_type_dict[rand_type]
	if thingy.type in ["Dynamite", "Health_Food", "Extra_Life"]:
		thingy.size = "None"
	else:
		var rand_size = randi()%3+1
		thingy.size = restore_size_dict[rand_size]
		
	if thingy.type == "Health_Food":
		var randModel = randi()%8+1
		thingy.food_model = restore_model_dict[randModel]
	else:
		thingy.food_model = "None"
	level._on_pickup_spawned(thingy, pos, Settings.PICKUP_Z)


func spawn_random_powerup() -> void:
	var pos = $Level.get_global_mouse_position()
	var thingy = preload("res://objects/generic/powerup.tscn").instantiate()
	thingy.physics = true
	thingy.one_use = true
	thingy.stack_duration = true
	randomize()
	var rand_type = randi()%7+1
	thingy.type = rand_type
	level._on_pickup_spawned(thingy, pos, Settings.PICKUP_Z)


func _on_powerup_timer_update(value) -> void:
	hud.get_node("PowerupHUD").update_value(value)


func _on_powerup_collected() -> void:
	hud.get_node("PowerupHUD").enable()
	if level.music_player.stream != powerup_music: 
		#testing restarting the music from where it left off, saving the point where it currently is
		#to resume later
		level_music_stop_time = level.music_player.get_playback_position() 
		level.music_player.stream = powerup_music
		level.music_player.play() 
	else:
		level.music_player.play(0.0)


func _on_powerup_end() -> void:
	hud.get_node("PowerupHUD").on_powerup_end()
	level.music_player.stream = level.music
	level.music_player.play(level_music_stop_time)


func _on_ranged_changed(new, value) -> void:
	hud.get_node("AmmoHUD").change_ranged(new, value)


func _on_ammo_updated(ammo) -> void:
	hud.get_node("AmmoHUD").update_value(ammo)


func _on_health_updated(health) -> void:
	hud.get_node("HealthHUD").update_value(health)


func _on_lives_updated(lives) -> void:
	hud.get_node("LivesHUD").update_value(lives)


func _on_treasure_collected(treasure) -> void:
	level.score = min(level.score + values[treasure.type], 99999999)
	var temp_treasure = []
	temp_treasure.append(treasure.type)
	temp_treasure.append(treasure.color)
	level_collected_treasure.append(temp_treasure) #objects get deleted when the level is reloaded
	hud.get_node("ScoreHUD").update_value(level.score)


func _on_end_item_spawned() -> void:
	print("end item spawned")
	#soft pause, spawn item, follow with camera and move item to preset spot


func _on_end_item_collected() -> void:
	print("end of level")
	#trigger end of level


#the transition isn't exactly the same as the original, but close enough
#I'll figure out how to do the pixelated gradient eventually
func _on_teleporter_taken(teleporter) -> void:
	teleporter_transition.material.set_shader_parameter("cutoff", 0.0)
	teleporter_transition.material.set_shader_parameter("smoothRange", 0.25)
	teleporter_transition.visible = true
	level.music_player.process_mode = PROCESS_MODE_PAUSABLE
	_on_pause_toggled()
	get_tree().paused = true
	teleporter_transition_animation.play("ToBlack")
	Utils.decide_player(game_sounds, teleporter_sound)
	await teleporter_transition_animation.animation_finished
	player.global_position = teleporter.destination
	player.camera.align()
	teleporter_transition.material.set_shader_parameter("mask", teleporter_transition_mask_2)
	teleporter_transition_animation.play("FromBlack")
	await teleporter_transition_animation.animation_finished
	_on_pause_toggled()
	teleporter_transition.material.set_shader_parameter("mask", teleporter_transition_mask)
	teleporter_transition.visible = false
	level.music_player.process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = false


#good enough for now but the circle is actually an ellipse, will fix the shader soon-ish
#still glitchy on high resolutions, gotta adapt the multiplier to the size
func _on_respawn(from, orientation) -> void:
	var multiplier #probably going to break with different resolutions, works for now
	var close_position
	var x = 0.54 if orientation == 1 else 0.47 #close on claw's face (...ish)
	var screen_size : Vector2 = get_viewport().size
	var screen_ratio : float = screen_size.y / screen_size.x
	match from:
		0: #spikes/liquid
			close_position = Vector2(x, 0.55)
			multiplier = 1.7
		1: #damage
			close_position = Vector2(x, 0.95)
			multiplier = 2.3
	circle_transition.material.set_shader_parameter("close_position", close_position)
	circle_transition.material.set_shader_parameter("progress", 0.0)
	circle_transition.material.set_shader_parameter("multiplier", multiplier)
	circle_transition.material.set_shader_parameter("screen_ratio", screen_ratio)
	circle_transition.visible = true
	level.music_player.process_mode = PROCESS_MODE_PAUSABLE
	_on_pause_toggled()
	get_tree().paused = true
	circle_transition_animation.play("Close")
	Utils.decide_player(game_sounds, circle_close_sound)
	await circle_transition_animation.animation_finished
	Utils.decide_player(game_sounds, circle_open_sound)
	await get_tree().create_timer(0.2).timeout
	player.global_position = level.spawn_point.global_position #replace with level.get_active_spawnpoint()
	player.camera.align()
	player.visible = true
	#-to do: make the close position higher, it opens from claw's head
	circle_transition.material.set_shader_parameter("close_position", Vector2(0.5, 0.5))
	circle_transition_animation.play("Open")
	await circle_transition_animation.animation_finished
	circle_transition.visible = false
	level.music_player.process_mode = PROCESS_MODE_ALWAYS
	_on_pause_toggled()
	get_tree().paused = false


func _on_pause_toggled() -> void:
	#pause the animation of the glitter particle (affects all scenes that use it)
	glitter_particle_texture.fps = 16.0 if glitter_particle_texture.fps == 0.0 else 0.0
