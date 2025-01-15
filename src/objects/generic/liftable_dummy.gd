extends RigidBody2D

class_name LiftableDummy

#to-do: too bouncy

var spawn_settle := false
var impulse := Vector2.ZERO
var lifted := false
var thrown := false
var dropped := false
var checked := false
var original_gravity_scale := 0.0
var linked_enemy : set = set_linked_enemy
var throw_direction := 0


func set_linked_enemy(value) -> void:
	linked_enemy = value
	linked_enemy.connect("enemy_dead", Callable(self, "_on_linked_enemy_death"))

func _get_class() -> String:
	return "LiftableDummy"


func _is_class(_name) -> bool:
	return _name == "LiftableDummy" or super.is_class(name)


func _ready() -> void:
	if is_instance_valid(linked_enemy):
		linked_enemy.on_lifted()


func _physics_process(_delta) -> void:
	_carry()


func _integrate_forces(state) -> void:
	if lifted and !thrown:
		state.transform = Transform2D(0.0, global_position)
		return
	
	if !spawn_settle and !thrown and linear_velocity == Vector2.ZERO:
		spawn_settle = true
		sleeping = true
		
	if !checked and (thrown or dropped) and state.get_contact_count() > 0:
		var angle = rad_to_deg(state.get_contact_local_normal(0).angle())
		if angle < -85 and angle > -95:  #if not hitting a wall
			_on_land()
			checked = true
		#weird bounces happen because of a general physics issue related to tilemaps having
		#multiple collision shapes close to each other. If the dummy hits the area between two
		#tiles, it can bounce backwards. Only way to really fix it is to convert the tilemap
		#surface collision shapes into single larger collision shapes that cover the entire area
	if checked and is_equal_approx(linear_velocity.x, 0.0):
		_on_movement_stop()


func _carry() -> void:
	if is_instance_valid(linked_enemy):
		linked_enemy.global_position = global_position


func _on_lift() -> void:
	lifted = true
	original_gravity_scale = gravity_scale
	gravity_scale = 0


func _on_throw() -> void:
	thrown = true
	lifted = false
	gravity_scale = original_gravity_scale
	if is_instance_valid(linked_enemy):
		linked_enemy.enable_thrown_hitbox()
		physics_material_override = load("res://src/objects/generic/enemy_physics_material_bounce.tres")
	else:
		physics_material_override = load("res://src/objects/generic/pickup_physics_material_bounce.tres")

	
func _on_dropped() -> void: 
	gravity_scale = original_gravity_scale
	lifted = false
	thrown = true
	dropped = true
	if is_instance_valid(linked_enemy):
		linked_enemy.dropped = dropped


func _on_land() -> void:
	if is_instance_valid(linked_enemy):
		linked_enemy.land() #problem if enemy dies as it lands on death tiles
	

func _on_movement_stop() -> void:
	if is_instance_valid(linked_enemy):
		linked_enemy.motion = Vector2.ZERO
		linked_enemy.disable_thrown_hitbox()
		linked_enemy.thrown_stop = true
	queue_free()


func _flip_anim(x) -> void:
	if is_instance_valid(linked_enemy):
		linked_enemy._flip_anim(x)

func _on_linked_enemy_death() -> void:
	_on_movement_stop()
