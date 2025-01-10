tool

extends RigidBody2D

class_name Crate, "res://sprites/objects/crate/1/crate001.png"

#-collision positions are not perfect
#-small issue with overlapping sprite areas when trying to place crates on the map
#to-do: check small hitbox details compared to the original (eg, crouch attack not hitting previously stacked crates)
#to-do: selectable sprite model

#connected to level
signal spawn_subcrates(crates, pos, z)
signal drop_loot(spawner, pos, z, only, contents)


const BreakSoundA = preload("res://sounds/crate/crate_break.ogg")
const BreakSoundB = preload("res://sounds/crate/crate_break_2.ogg")

export(String, "Front", "Back", "Stack") var z_position = "Front" setget set_z_position
export(Array, Array) var contents setget set_contents #can be edited from the export var or from the plugin

var collision
var only_stack := true 
var tool_texture : Texture
var broken := false
var sub_crates = []

onready var animation = $AnimatedSprite
onready var sound = $AudioStreamPlayer2D
onready var collision_front = $CollisionFront
onready var collision_stack = $CollisionStack
onready var collision_back = $CollisionBack


func get_class() -> String:
	return "Crate"


func is_class(_name) -> bool:
	return _name == "Crate" or .is_class(_name)


func set_z_position(value) -> void:
	if z_position != value:
		z_position = value
		if !Engine.is_editor_hint():
			match value: 
				"Front", "Stack_Front":
					z_index = Settings.FG_OBJECT_Z
				"Back", "Stack_Back":
					z_index = Settings.BG_OBJECT_Z
		call_deferred("set_collisions")
		update()


func set_contents(value) -> void:
	contents = value
	if Engine.is_editor_hint(): 
		call_deferred("toggle_sprite_visibility", !contents.size() > 0) #I hate this
	update()
	update_configuration_warning()


func _ready() -> void:
	#choose a random break sound
	if !Engine.is_editor_hint():
		collision = collision_back
		set_z_position(z_position)
		var x = randi()%2 + 1
		sound.stream = BreakSoundA if x%2 == 0 else BreakSoundB
		sound.volume_db = Settings.EFFECTS_VOLUME + 5
		#if z_position == "Front": 
		#	z_index = Settings.FG_OBJECT_Z
		#elif z_position == "Back": 
		#	z_index = Settings.BG_OBJECT_Z
		
		if contents.size() > 1:
			call_deferred("spawn_sub_crates")
	else:
		tool_texture = $AnimatedSprite.frames.get_frame("Idle", 0) 


func toggle_sprite_visibility(x : bool) -> void:
	animation.visible = x


func set_collisions() -> void:
	if !broken:
		match z_position:
			"Front":
				collision = collision_front
				collision_front.disabled = false
				collision_back.disabled = true
				collision_stack.disabled = true
			"Back":
				collision = collision_back
				collision_back.disabled = false
				collision_front.disabled = true
				collision_stack.disabled = true
			"Stack":
				collision = collision_stack
				collision_stack.disabled = false
				collision_front.disabled = true
				collision_back.disabled = true
		collision.disabled = false


func spawn_sub_crates() -> void:
	only_stack = false
	for x in range(1, contents.size()):
		var sub_crate = load("res://objects/generic/crate.tscn").instance()
		sub_crate.contents = [contents[x].duplicate(true)]
		sub_crate.only_stack = false
		sub_crate.z_position = "Stack"
		sub_crates.append(sub_crate)
	var x := 1
	for sub_crate in sub_crates:
		sub_crate.sub_crates = sub_crates.slice(x, sub_crates.size() - 1)
		x += 1
	
	emit_signal("spawn_subcrates", sub_crates, global_position, z_index)
	contents = [contents[0].duplicate(true)]


func on_break() -> void:
	broken = true
	for sub_crate in sub_crates:
		if is_instance_valid(sub_crate) and !sub_crate.broken:
				sub_crate.z_position = z_position
				break
	collision.call_deferred("set_disabled", true)
	gravity_scale = 0
	linear_velocity = Vector2.ZERO
	if !animation.is_connected("animation_finished", self, "queue_free"):
		animation.connect("animation_finished", self, "queue_free")
	animation.play("Break")
	sound.play()
	#having a pool of instantiated spawners could improve performance a bit here
	var spawner = preload("res://objects/generic/pickup_spawner.tscn").instance()
	emit_signal("drop_loot", spawner, global_position, z_index+1, only_stack, contents)


func _draw() -> void:
	if Engine.is_editor_hint():
		for x in contents.size():
			draw_texture(tool_texture, Vector2(-69, -58 -42*x)) #weird offset because of the texture's empty space


func _get_configuration_warning() -> String:
	return "Contents not set, crate is empty." if contents.empty() else ""
