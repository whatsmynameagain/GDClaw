extends Node2D

class_name Level

enum Death_Types {SPIKES = Settings.Damage_Types.SPIKES, 
		LIQUID = Settings.Damage_Types.LIQUID}

@export var GRAVITY: int = 3200 #less than 3k
@export var death_type: Death_Types = Death_Types.SPIKES

var music = preload("res://music/la_roca.ogg") #default
var music_enabled = true
var player
var timer 
var score = 0
#add the values in _init() in each level's script
var ladder_tile_start_names := [] 
var ladder_tile_mid_names := [] 
var ladder_tile_end_names := []  
var death_tile_start_names := []  
var death_tile_mid_names := [] 
var death_tile_end_names := []  
var treasure = {
	"Coin" : 0,
	"Bars" : 0,
	"Ring" : 0,
	"Chalice" : 0,
	"Cross" : 0,
	"Scepter" : 0,
	"Gecko" : 0,
	"Crown" : 0,
	"Skull" : 0
}

@onready var spawn_point = get_node("SpawnPoint")
@onready var level_sounds = $LevelSounds
@onready var music_player = $MusicPlayer
@onready var crates = $Objects/Crates
@onready var projectiles = $Objects/Projectiles
@onready var death_tiles = $Objects/DeathTileColliders
@onready var tile_map = $TileMap


func _ready() -> void:
	add_objects() #27.5 ms run time avg. #add ladder and deathTile objects based on the tilenames arrays
	#following the original game logic, only one type of deathTile can be active in a level (I think)
	for object in death_tiles.get_children():
		if object.death_type == 0: #"SET_BY_LEVEL" in deathTile
			object.death_type = death_type
	#but if that changes, add_objects() needs to be changed a bit
	
	#signal connections and counting
	for trigger in $Objects/AudioTriggers.get_children():
		trigger.connect("level_sound_trigger", Callable(self, "_on_audio_trigger"))
	#to do: get level treasure count
	for pickup in $Objects/Pickups.get_children():
		if pickup.is_class("Treasure"):
			pickup.connect("spawn_value", Callable(self, "_on_spawn_value"))
			#add to treasure list count
	for crate in $Objects/Crates.get_children():
		crate.connect("spawn_subcrates", Callable(self, "_on_spawn_subcrates"))
		crate.connect("drop_loot", Callable(self, "_on_spawn_spawner"))
		for item in crate.contents:
			if item[0] == 0:
				#add to treasure list count
				pass
	for enemy in $Objects/Enemies.get_children():
		enemy.gravity = GRAVITY
		#enemy.connect("projectile_fired", self, _on_projectile_fired") #soon(tm)
		enemy.connect("drop_loot", Callable(self, "_on_spawn_spawner"))
		enemy.connect("killed_by_player", Callable(self, "_on_enemy_kill_by_player"))
		for item in enemy.contents:
			if item[0] == 0:
				#add to treasure list count
				pass
	#----------
	player = preload("res://player.tscn").instantiate()
	level_sounds.set_volume_db(Settings.EFFECTS_VOLUME)
	music_player.set_volume_db(Settings.MUSIC_VOLUME)
	music_player.stream = music
	if music_enabled:
		music_player.play()
		
	add_child(player)
	player.connect("projectile_fired", Callable(self, "_on_projectile_fired"))
	player.connect("spawn_dummy", Callable(self, "_on_spawn_dummy"))
	player.connect("respawn", Callable(self, "_on_player_respawn"))
	player.gravity = GRAVITY
	if is_instance_valid(spawn_point):
		player.global_position = spawn_point.global_position #or both local?
	else:
		player.global_position = Vector2.ZERO


func add_objects() -> void:
	#assumes all objects are properly constructed (start -> end) and tiles are properly named
	#with the name variables updated
	for type in ["ladder", "death_tile"]:
		var start_names := []
		var mid_names := []
		var end_names := []
		var resource_string := ""
		var node_name := ""
		var offset := Vector2.ZERO
		var bool_type : bool
		match type:
			"ladder":
				start_names = ladder_tile_start_names
				mid_names = ladder_tile_mid_names
				end_names = ladder_tile_end_names
				resource_string = "res://objects/generic/ladder.tscn" 
				node_name = "Objects/Ladders"
				offset = Vector2(32,32)
				bool_type = true
			"death_tile":
				start_names = death_tile_start_names
				mid_names = death_tile_mid_names
				end_names = death_tile_end_names
				resource_string = "res://objects/generic/death_tile.tscn"
				node_name = "Objects/DeathTileColliders"
				offset = Vector2(0,46)
				bool_type = false
		
		var top_ids := []
		for _name in start_names:
			top_ids.append(tile_map.tile_set.find_tile_by_name(_name))
		var mid_ids := []
		for _name in mid_names:
			mid_ids.append(tile_map.tile_set.find_tile_by_name(_name))
		var end_ids := []
		for _name in end_names:
			end_ids.append(tile_map.tile_set.find_tile_by_name(_name))
		var starts := []
		for id in top_ids:
			starts += tile_map.get_used_cells_by_id(id)
		
		for x in range(starts.size()):
			var new_object = load(resource_string).instantiate()
			get_node(node_name).add_child(new_object)
			new_object.global_position = tile_map.map_to_local(starts[x]) + offset
			var size := 1
			var warned := false
			var _position := (Vector2(starts[x].x, starts[x].y + size) if bool_type
					else Vector2(starts[x].x + size, starts[x].y))
			
			while !(tile_map.get_cellv(_position) in end_ids):
				if (!(tile_map.get_cellv(_position) in mid_ids)
						and !warned):
					push_warning("Warning, %s at tile_map point %s seems to not be correctly built." 
							% [type, Vector2(starts[x].x, starts[x].y)])
					warned = true
				size += 1
				
				if size > Settings.MAX_OBJECT_SIZE: 
					push_error("Badly constructed %s at tile_map point %s, no end tile found."
							% [type, Vector2(starts[x].x, starts[x].y)])
					assert(size <= Settings.MAX_OBJECT_SIZE)
				_position += Vector2(0, 1) if bool_type else Vector2(1, 0)
			new_object.size = size if bool_type else size+1


#called when the player respawns or loads a save
func init(_score : int = 0, _player_health := 100, _player_ammo := 10, _player_magic := 5, 
			_player_dynamite := 3, _player_lives := 3, _position := Vector2.ZERO) -> void:
	score = _score
	player = get_node("Player")
	player.health = _player_health
	player.ammo = _player_ammo
	player.magic = _player_magic
	player.dynamite = _player_dynamite
	player.lives = _player_lives


#signal stuff
func _on_audio_trigger(audio) -> void:
	Utils.decide_player(level_sounds, audio)


func _on_player_respawn(_from, _orientation) -> void:
	for platform in $Objects/CrumblingPlatforms.get_children():
		platform.active = platform.reusable

	#to-do: reset elevators? no idea if the original does it
	#to-do: remove the active flag checkpoint? again, not sure how it is
		#update: only super checkpoints are removed when the level (save point) is loaded from the menu
	#...and something else? dunno


func get_player() -> Player: #or node?... or... something?
	return player


func get_active_spawnpoint() -> Vector2:
	#to do: get the apropriate checkpoint/spawn point and return its global position
	
	return Vector2.ZERO


func _on_projectile_fired(projectile, pos, orientation, _rotation, impulse) -> void:
	
	projectile.orientation = orientation
	projectiles.add_child(projectile)
	if projectile.has_signal("spawn_explosion"): 
		projectile.connect("spawn_explosion", Callable(self, "_on_spawn_explosion"))
	projectile.global_position = pos
	if orientation != null: 
		projectile.linear_velocity *= orientation
	if _rotation != null: 
		projectile.rotation_degrees = _rotation
	if impulse != null: 
		projectile.impulse = impulse


func _on_spawn_explosion(explosion, pos) -> void:
	#gotta check where exactly to spawn explosions, if it matters
	add_child(explosion)
	explosion.global_position = pos


func _on_spawn_subcrates(sub_crates, pos, z) -> void:
	var x := 1
	for crate in sub_crates:
		$Objects/Crates.add_child(crate)
		crate.connect("drop_loot", Callable(self, "_on_spawn_spawner"))
		crate.global_position = Vector2(pos.x, pos.y - 42 * x)
		crate.z_index = z + x
		x += 1


func _on_spawn_value(value, pos) -> void:
	add_child(value)
	value.global_position = pos


func _on_spawn_spawner(spawner, pos, z, only_stack, contents) -> void:
	add_child(spawner)
	spawner.connect("pickup_spawned", Callable(self, "_on_pickup_spawned"))
	spawner.global_position = pos
	spawner.z_index = z + 3
	if only_stack: 
		spawner.play_loot_sound = false
		spawner.impulse = Settings.PICKUP_IMPULSE_SINGLE_CRATE
	else:
		spawner.play_loot_sound = true
	spawner.call_deferred("set_spawn_list", contents)


func _on_pickup_spawned(pickup, pos, z) -> void:
	add_child(pickup)
	if pickup.is_class("Treasure"):
		pickup.connect("spawn_value", Callable(self, "_on_spawn_value"))
	pickup.global_position = pos
	pickup.z_index = z


func _on_spawn_dummy(dummy, pos, orientation) -> void:
	add_child(dummy)
	dummy.get_node("Sprite2D").flip_h = orientation == -1
	dummy.global_position = pos


func _on_enemy_kill_by_player() -> void:
	player._on_enemy_kill()
