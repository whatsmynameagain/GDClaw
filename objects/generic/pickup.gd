extends RigidBody2D

class_name Pickup

export(bool) var physics = false setget set_physics
export(bool) var static_glitter = false setget set_glitter
export(String, "None", "Gold", "Green", "Purple", "Red") var glitter_color = "Gold" setget set_glitter_color
export(bool) var one_use = true

var pickup_sounds = {
	"Coin" : preload("res://sounds/pickups/treasure/coin.ogg"),
	"Bars" : preload("res://sounds/pickups/treasure/bars.ogg"),
	"Ring" : preload("res://sounds/pickups/treasure/ring.ogg"),
	"Chalice" : preload("res://sounds/pickups/treasure/chalice.ogg"), # & crown & skull
	"Cross" : preload("res://sounds/pickups/treasure/cross.ogg"),
	"Scepter" : preload("res://sounds/pickups/treasure/scepter.ogg"),
	"Gecko" : preload("res://sounds/pickups/treasure/gecko.ogg"),
	"Health" : preload("res://sounds/pickups/restore/health.ogg"),
	"Health_Food" : preload("res://sounds/pickups/restore/food_item.ogg"),
	"Ammo" : preload("res://sounds/pickups/restore/ammunition.ogg"), # & dynamite
	"Magic" : preload("res://sounds/pickups/restore/magic_powerup.ogg"),
	"Extra_Life" : preload("res://sounds/pickups/restore/extra_life.ogg"),
	"Catnip" : preload("res://sounds/pickups/powerup/catnip.ogg"), # & catnip_red
	"Ghost" : preload("res://sounds/pickups/powerup/pickup_1.ogg"), # & invuln, all swords
	"EndItem" : preload("res://sounds/pickups/map_piece.ogg"),
	"Bounce" : preload("res://sounds/pickups/pickup_bounce.ogg")
	}
	
var initial_impulse := Vector2.ZERO
var initial_impulse_applied := false
var x_velocity_safe := 0.0
var bounces := 3
var stopped := false
var despawning := false
#var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

onready var animation = $Animation
onready var collision = $CollisionShape2D
onready var area = $Area
onready var audio = $Audio
onready var animation_player = $AnimationPlayer


func get_class() -> String:
	return "Pickup"


func is_class(name) -> bool:
	return name == "Pickup" or .is_class(name)


func set_physics(value) -> void:
	physics = value
	if physics:
		static_glitter = false 
		glitter_color = "None"
		if has_node("Glitter"):
			get_node("Glitter").queue_free()
		gravity_scale = 1
		var temp_material = preload("res://objects/generic/pickup_physics_material_bounce.tres") 
		#because this is definitely easier than just setting rigidbody2d.bounce = something, right?
		#ugh...
		physics_material_override = temp_material
	else:
		#mode = MODE_STATIC ##<<<--- if I do this, (and do not set mode = MODE_CHARACTER in the same conditional branch)
		#then static treasures don't move after being picked up
		#even after switching the mode back to MODE_CHARACTER (or MODE_RIGID).. 
		#...is that a bug or something I'm unaware of?
		gravity_scale = 0
	update() #redraw
	property_list_changed_notify() #update the inspector value


func set_glitter(value) -> void:
	static_glitter = value
	if !static_glitter:
		glitter_color = "None"
		if has_node("Glitter"):
			get_node("Glitter").queue_free()
	else:
		glitter_color = "Gold"
		physics = false
	update()
	property_list_changed_notify()


func set_glitter_color(value) -> void:
	glitter_color = value
	if !static_glitter and value != "None":
		static_glitter = true
		physics = false
	elif value == "None":
		static_glitter = false	
	update()
	property_list_changed_notify()


func _init() -> void:
	if !Engine.is_editor_hint():
		if !is_connected("body_entered", self, "_on_bounce"):
# warning-ignore:return_value_discarded
			connect("body_entered", self, "_on_bounce") 


func _ready() -> void:
	z_index = Settings.PICKUP_Z if physics else Settings.PICKUP_BG_Z


func _integrate_forces(_state) -> void:
	if Engine.is_editor_hint():
		return
		
	if physics:
		#At the time of making this, there's an engine bug where rigidbody2ds never stop bouncing, 
		#gotta patch it a bit with materials, which actually makes it behave pretty similarly to the original
		
		#fix for pickups losing x velocity when bouncing
		#now they lose only 50% speed per bounce
		if !stopped:
			if abs(linear_velocity.x) >= 0:
				if abs(linear_velocity.x) >= abs(x_velocity_safe):
					x_velocity_safe = linear_velocity.x
				elif abs(x_velocity_safe) > abs(linear_velocity.x):
					if linear_velocity.x == 0 and bounces >= 0:
						linear_velocity.x = x_velocity_safe/2
			if bounces == 0:
				if !stopped:
					stopped = true
				var temp_material := preload("res://objects/generic/pickup_physics_material_bounceless.tres") 
				physics_material_override = temp_material
			
		if !initial_impulse_applied:
			if initial_impulse == Vector2.ZERO:
				randomize()
				#fugly, will probably rework later
				var impulse_x = (rand_range(-Settings.PICKUP_IMPULSE_RANGE_X, Settings.PICKUP_IMPULSE_RANGE_X) 
						* Settings.PICKUP_IMPULSE_X_MULTIPLIER)
				var impulse_y = (rand_range(-Settings.PICKUP_IMPULSE_RANGE_Y, Settings.PICKUP_IMPULSE_RANGE_Y) 
					- 450) * Settings.PICKUP_IMPULSE_Y_MULTIPLIER 
				apply_impulse(Vector2.ZERO, Vector2(impulse_x, impulse_y))
			else: #spawning from a single crate (no lateral movement) (assigned on spawn)
				apply_impulse(Vector2.ZERO, initial_impulse)
			initial_impulse_applied = true


func _on_bounce(_body) -> void:
	bounces -= 1
	Utils.decide_player(audio, pickup_sounds["Bounce"])
	if bounces == -1: #spawn glitter once it stops bouncing
		if !has_node("Glitter") and !despawning:
			add_child(preload("res://objects/generic/glitter.tscn").instance())
			if is_class("EndItem"):
				get_node("Glitter").speed_scale = 1.6
				get_node("Glitter").play("Green")
			else:
				get_node("Glitter").play("Gold")


func disable() -> void:
	if !Engine.is_editor_hint():
		disconnect("body_entered", self, "_on_bounce") 
		animation.visible = false
		area.set_collision_layer_bit(2, false)
		if has_node("Glitter"):
			get_node("Glitter").visible = false
			get_node("Glitter").stop()


#pickups still bounce once on death tiles, fix later
func on_death(_x) -> void: #when falling on spikes or liquid
	despawning = true 
	bounces = 0
	animation_player.play("despawn")


func _on_pickup() -> void:
	queue_free()
