tool
extends KinematicBody2D

class_name Enemy

#enemies will be implemented in a different way than the player
#-gonna try to implement a state machine without using different files
#no way that will be a clusterfuck, right? right
#-using animationplayer for most things

#--->enemy sprite size is scaled up in the original, gotta match that <--

signal drop_loot(loot)
signal enemy_dead#used for the linked liftable_dummy, could add (self) as an argument for other stuff
# warning-ignore:unused_signal
signal spawn_projectile(pew) #change later

enum States {IDLE, PATROL, ATTACK_MELEE, 
		ATTACK_RANGED, CHASE, LEAP, 
		LIFTED, THROW_LAND, DAMAGE, DEATH_COMBAT, 
		DEATH_SPIKES, DEATH_LIQUID,
		 DEAD_THROW}
enum Orientations {LEFT = 1 , RIGHT = -1}
#reverse from player's enum because enemy sprites look left by default, unlike player sprites

const MAXVELOCITY := 1024 #needs testing
const hit_effect = preload("res://objects/generic/hit_effect.tscn")
export(int) var health = 10 setget set_health
export(bool) var patrol = false setget set_patrol
export(Vector2) var patrol_width = Vector2.ZERO setget set_patrol_width #not a real 2d vector, it's (x1, x2)
export(Color) var patrol_color setget set_patrol_color
export(Array, Array) var contents

var type := ""
var has_melee := false
var has_ranged := false
var motion := Vector2.ZERO
var walk_speed := 100.0
var patrol_limit_positions := Vector2.ZERO #same as patrol, Vector2(x1, x2)
var throwable := true
var lifted := false
var thrown := false
var thrown_stop := false
var thrown_stop_checked:= false #there's got to be an easier way to do this, maybe with signals
var dropped := false
var linked_liftable_dummy
var alert := false #has seen the player
var dead := false
var spikes := false
var liquid := false
var juggle := false
var splash := true
var damage_cooldown := false #there's some sort of cooldown, haven't figured out how it works yet
	#currently waits until the hit animation ends
var dead_offscreen := false
var logic #: Node #variable to load the enemy type's logic
var player #for tracking once the player is detected?
var gravity := 0.0
var state = States.IDLE setget set_state
var orientation = Orientations.LEFT setget set_orientation #shouldn't this be an export? though it's
	#kinda irrelevant because of patrols and enemies don't have blind spots
var override := false


var sound_effects_generic = { #temp contents
	"land" : preload("res://sounds/generic/throw_land.wav"),
	"swing" : preload("res://sounds/enemy/officer/officer_swing.wav"),
	"hit_high" : preload("res://sounds/generic/enemy_hit_high.wav"),
	"hit_mid" : preload("res://sounds/generic/enemy_hit_mid.wav"),
	"drop_loot" : preload("res://sounds/generic/pickup_release.wav"),
	"splash" : preload("res://sounds/generic/splash.wav"),
	"death_liquid" : preload("res://sounds/generic/death_liquid.wav"),
	"death_spikes" : preload("res://sounds/generic/death_spikes.wav"),
}
var voice_lines = {} setget , _get_voice_lines

var hit

onready var sprite = $Sprite
onready var animation = $AnimationPlayer
onready var animation_player = $AnimationPlayer
onready var collision = $Collision
onready var collision_lifted = $CollisionLifted
onready var throw_hitbox = $ThrowHitbox
onready var contact_hitbox = $ContactHitbox
onready var voice = $Voice
onready var sounds = $Sounds
onready var exclamation = $Exclamation
onready var patrol_idle_timer = $Timer

func get_class() -> String:
	return "Enemy"


func is_class(name) -> bool:
	return name == "Enemy" or .is_class(name)


func set_health(value) -> void:
	health = max(1, value)


func set_orientation(value) -> void:
	if value != orientation:
		orientation = value
		sprite.flip_h = orientation == -1
		#flip detection stuff (after it's immplemented)
	pass
	

func set_patrol_color(value) -> void:
	patrol_color = value
	update()


func set_patrol(value) -> void:
	patrol = value
	if !value:
		patrol_width = Vector2.ZERO
	update()
	property_list_changed_notify()


func set_patrol_width(value : Vector2) -> void:
	if value.sign() == Vector2(1,1):
		patrol_width = value
		if value != Vector2.ZERO: #problem here
			patrol_width = Vector2(value)
		else:
			patrol_width = Vector2.ZERO
		patrol = patrol_width != Vector2.ZERO
	else:
		pass
	update()
	property_list_changed_notify()

func _get_voice_lines() -> Dictionary:
	
	return voice_lines

func set_state(value) -> void:
	#print("Prev state: %s, Next state: %s" % [States.keys()[state], States.keys()[value]])
	
	 #basically state.on_exit()
	match state:
		States.IDLE:
			override = _idle_on_exit() #check if overriden, if not, do something else
			if !override:
				patrol_idle_timer.stop()
				set_orientation(orientation * -1)
				pass
		States.PATROL:
			override = _patrol_on_exit()
			if !override:
				motion.x = 0.0
				pass
		States.ATTACK_MELEE:
			override = _attack_melee_on_exit()
			if !override:
				pass
		States.ATTACK_RANGED:
			override = _attack_ranged_on_exit()
			if !override:
				pass
		States.CHASE:
			override = _chase_on_exit()
			if !override:
				pass
		States.LEAP:
			override = _leap_on_exit()
			if !override:
				pass
		States.LIFTED:
			override = _lifted_on_exit()
			if !override:
				if dropped:
					set_collision_layer_bit(6, true)
		States.THROW_LAND:
			override = _throw_land_on_exit()
			if !override:
				if !dead:
					global_position.y -= 40 #bit hacky, but the alternative
						#would be to offset the sprite and collisionlifted area down 
						#to match the base of the main collision area beforehand.
						#will do that eventually but for now this is fine
					set_collision_layer_bit(6, true)
	
	state = value
	
	#basically state.on_enter()-------------------------
	match state: 
		States.IDLE:
			override = _idle_on_enter()
			if !override:
				dropped = false
				collision_lifted.disabled = true
				collision.disabled = false
				#collision_lifted.call_deferred("set_disabled", true)
				#collision.call_deferred("set_disabled", false)
				thrown_stop_checked = false
				thrown_stop = false
				contact_hitbox.monitoring = true
				if (global_position.x <= patrol_limit_positions.x 
						or global_position.x >= patrol_limit_positions.y):
						#or touching a wall/drop?
					#start a timer? #4seconds
					patrol_idle_timer.start(4.0)
					animation.play("idle_%s" % str(randi()%3+1))
					if randi()%100+1 <= Settings.ENEMY_PATROL_VOICE_CHANCE * 100: #chance to say something
						on_voice_trigger(_get_voice_lines()["idle_%s" % str(randi()%2+1)]) 
				else:
					set_state(States.PATROL)
		States.PATROL:
			override = _patrol_on_enter()
			if !override:
				pass

		States.ATTACK_MELEE:
			override = _attack_melee_on_enter()
			if !override:
				pass
		States.ATTACK_RANGED:
			override = _attack_ranged_on_enter()
			if !override:
				pass
		States.CHASE:
			override = _chase_on_enter()
			if !override:
				pass
		States.LEAP:
			override = _leap_on_enter()
			if !override:
				pass
		States.LIFTED:
			override = _lifted_on_enter()
			if !override:
				#temp voice line stuff, I don't know the chances
				contact_hitbox.monitoring = false
				animation.play("lifted")
				set_collision_layer_bit(6, false)
				randomize()
				var chance = randi()%3+1
				if chance == 3: #1/3 chance of saying something
					#this breaks if there aren't exactly two lift lines (fine for testing)
					on_voice_trigger(_get_voice_lines()["lift_%s" % str(randi()%2+1)])
					
				collision_lifted.call_deferred("set_disabled", false) #hm, future problems if an enemy is lifted
				collision.call_deferred("set_disabled", true) #in a small vertical space?
		States.THROW_LAND:
			override = _throw_land_on_enter()
			if !override:
				animation.play("land")
		States.DAMAGE:
			override = _damage_on_enter()
			if !override:
				pass
		States.DEATH_COMBAT:
			override = _death_combat_on_enter()
			if !override:
				contact_hitbox.monitoring = false
				pass
		States.DEATH_SPIKES:
			override = _death_spikes_on_enter()
			if !override:
				contact_hitbox.monitoring = false
				spikes = true
				motion = Vector2.ZERO
				set_collision_layer_bit(6, false)
				Utils.decide_player(sounds, sound_effects_generic["death_spikes"])
				if !contents.empty():
					drop_loot()
				animation_player.play("despawn")
		States.DEATH_LIQUID:
			override = _death_liquid_on_enter()
			if !override:
				contact_hitbox.monitoring = false
				pass
		States.DEAD_THROW:
			override = _death_throw_on_enter()
			if !override:
				if !contents.empty():
					drop_loot()
				animation_player.play("despawn")

func _ready():
	if !Engine.is_editor_hint():
		voice.volume_db = Settings.EFFECTS_VOLUME
		sounds.volume_db = Settings.EFFECTS_VOLUME
		set_orientation(1)
		#sprite.flip_h = (orientation == -1)
		animation.play("idle_%s" % str(randi()%3+1))
		hit = hit_effect.instance()
		add_child(hit)
		patrol_limit_positions = set_patrol_limit_points() 
		set_state(States.IDLE)
		z_index = Settings.ENEMY_Z


func _physics_process(delta):
	
	if !Engine.is_editor_hint():
		get_node("Label").text = "Pos: %s" % global_position
		get_node("StateLabel").text = "State: %s" % States.keys()[state]
		get_node("HealthLabel").text = "Orientation: %s" % str(orientation)
		
		if !dead_offscreen:

			if state != States.LIFTED:
				if spikes or liquid:
					motion = Vector2.ZERO
				motion = move_and_slide(motion, Vector2.UP)
				motion.y =  motion.y + (gravity *.75 * delta) if !is_on_floor() and motion.y < MAXVELOCITY else MAXVELOCITY
				
			for x in get_slide_count():
				var _collision = get_slide_collision(x)
				if _collision.collider.is_class("CrumblingPlatform") and !_collision.collider.activated:
					_collision.collider.activate()
		
			match state: #state.update()
				States.IDLE:
					override = _idle_update()
					if !override:
						pass
				States.PATROL:
					override = _patrol_update()
					if !override:
						if ((global_position.x >= patrol_limit_positions.x and orientation == 1) 
								or (global_position.x <= patrol_limit_positions.y and orientation == -1)): #problem here
							motion.x = -walk_speed * orientation
							animation.play("walk")
						else:
							if randi()%100+1 <= Settings.ENEMY_PATROL_WAIT_CHANCE * 100: 
								set_state(States.IDLE)
							else:
								set_orientation(orientation * -1)
								
				States.ATTACK_MELEE:
					override = _attack_melee_update()
					if !override:
						pass
				States.ATTACK_RANGED:
					override = _attack_ranged_update()
					if !override:
						pass
				States.CHASE:
					override = _chase_update()
					if !override:
						pass
				States.LEAP:
					override = _leap_update()
					if !override:
						pass
				States.LIFTED:
					override = _lifted_update()
					if !override:
						pass
				States.THROW_LAND:
					override = _throw_land_update()
					if !override:
						if thrown_stop and !thrown_stop_checked and !dead:
							thrown_stop_checked = true
							yield(get_tree().create_timer(1), "timeout") #gotta check the timing, seems ok-ish for now
							#error here, entity sometimes is killed somewhere else before the yield returns?
							#resume: Resumed function '_physics_process()' after yield, but class instance is gone. At script: res://objects/generic/enemy.gd:361
							if !dropped:
								print("taking throw damage")
								health -= Settings.THROW_DAMAGE 
								print("%s hit for %s by %s" % [name, Settings.THROW_DAMAGE , "throw"])
							if health <= 0:
								on_death(Settings.Damage_Types.THROW, 0)
							else:
								set_state(States.IDLE)
				States.DAMAGE:
					override = _damage_update()
					if !override:
						if motion.x > 5:
							motion.x -= 5
				States.DEATH_COMBAT:
					override = _death_combat_update()
					if !override:
						pass
				States.DEATH_SPIKES:
					override = _death_spikes_update()
					if !override:
						pass
				States.DEATH_LIQUID:
					override = _death_liquid_update()
					if !override:
						pass


#to do: make enemy face the damage source. Can't really check how the original does it right now
func on_hit(_type : int, source : CollisionObject2D, damage : int, point : Vector2) -> void:
	juggle = dead
	if !damage_cooldown:
		damage_cooldown = !dead
		set_state(States.DAMAGE) #kinda pointless, there's nothing there
		
		if "orientation" in source:
			set_orientation(source.orientation) #because for the player -1 is looking left, blah blah
		else:
			# warning-ignore:narrowing_conversion
			set_orientation(sign(global_position.x - source.global_position.x))
		#sprite.flip_h = orientation == -1
		motion.x = 50 * orientation #not tested
		
		print("%s hit for %s by %s" % [type, damage, source.name])
		
		
		hit.position = to_local(point)
		hit.play("enemy_%s" % str(randi()%3+1))
		health -= damage
		
		if health <= 0:
			if source.is_class("PistolBullet"): #pistol bullets disappear after killing
				source.queue_free()
			elif source.is_class("Player"):
				source._on_enemy_kill() #probably should be a signal
			on_death(_type, orientation)
			
		#dunno if the sword projectiles trigger a hit sound aside from the elemental hit sound in the original
		var hit_type = "high" if source.is_class("Player") and source.melee_attack == 4 else "mid"
		if !dead: #a bit redundant but easier. Maybe change later.
			animation.play("hit_%s" % hit_type) 
		Utils.decide_player(sounds, sound_effects_generic["hit_%s" % hit_type])


func knockback() -> void:
	motion.x = 50 * orientation


func stop_knockback() -> void:
	motion.x = 0


#called on spawn
func set_patrol_limit_points() -> Vector2:
	return Vector2(global_position.x - patrol_width.x, global_position.x + patrol_width.y)


func on_voice_trigger(audio) -> void:
	if !voice.playing:
		exclamation.visible = true
		voice.stream = audio
		voice.play()

#source = type, side = (-1, 0, 1)
func on_death(source, side : int) -> void:
	dead = true
	emit_signal("enemy_dead")
	set_collision_layer_bit(7, false) #disable collision with death tiles
	match source:
		Settings.Damage_Types.COMBAT: #melee
			print("enemy death by combat")
			death_combat(side)
		Settings.Damage_Types.SPIKES:
			print("enemy death by spikes")
			set_state(States.DEATH_SPIKES)
		Settings.Damage_Types.LIQUID:
			print("enemy death by liquid")
			set_state(States.DEATH_LIQUID)
		Settings.Damage_Types.THROW:
			print("enemy death by throw")
			set_state(States.DEAD_THROW)
		Settings.Damage_Types.OTHER:
			print("enemy death by.... something")
		Settings.Damage_Types.FIRE:
			print("enemy death by fire")
			death_combat(side, "fire")
		Settings.Damage_Types.ICE:
			print("enemy death by ice")
			death_combat(side, "ice")
		Settings.Damage_Types.LIGHTNING:
			print("enemy death by lightning")
			death_combat(side, "lightning")


func on_lifted() -> void:
	set_state(States.LIFTED)


func land() -> void:
	#dunno if dropping enemies plays the land sound or not, check later
	animation.play("land")
	if !dead:
		if !dropped:
			sounds.stream = sound_effects_generic["land"]
			sounds.play()
		set_state(States.THROW_LAND)


func death_throw() -> void:
	pass


#modifier = elemental swords
func death_combat(side : int, modifier := "") -> void:
	set_state(States.DEATH_COMBAT)
	damage_cooldown = false
	if modifier == "":
		animation.play("dead")
	else:
		animation.play("dead_%s" % (modifier if modifier != "lightning" else "fire"))
		var elem_expl = preload("res://objects/generic/elemental_explosion.tscn").instance()
		add_child(elem_expl)
		elem_expl.global_position = global_position
		elem_expl.connect("animation_finished", elem_expl, "queue_free") 
		#or could add an empty frame at the end of the animations
		elem_expl.play(modifier)
		
	#I think there's a chance to not play a voice line, check later (and during juggle)	
	randomize()
	Utils.decide_player(sounds, _get_voice_lines()["death_%s" % str(randi()%2+1)]) 
	if !contents.empty() and !juggle:
		drop_loot()
			

	#disable map collision
	set_collision_mask_bit(0, false)
	set_collision_mask_bit(3, false)
	
	motion = Vector2(150 * side, -750)
	
	pass


func drop_loot():
	Utils.decide_player(sounds, sound_effects_generic["drop_loot"])
	var spawner = preload("res://objects/generic/pickup_spawner.tscn").instance()
	emit_signal("drop_loot", spawner, global_position, z_index+1, false, contents)


func _on_dialogue_end() -> void:
	exclamation.visible = false


func get_active_hitbox() -> CollisionShape2D:
	return collision


func enable_thrown_hitbox() -> void:
	throw_hitbox.monitoring = true


func disable_thrown_hitbox() -> void:
	throw_hitbox.monitoring = false


func _flip_anim(x) -> void: #has to match the method on the barrel script
	sprite.flip_h = x


func _draw() -> void:
	if Engine.is_editor_hint(): #or patrol is set to visible? (for debugging)
		#edges
		draw_line(Vector2(-patrol_width.x, -64), Vector2(-patrol_width.x, 64), patrol_color, 4.0)
		draw_line(Vector2(patrol_width.y, -64), Vector2(patrol_width.y, 64), patrol_color, 4.0)
		draw_line(Vector2(-patrol_width.x, 0), Vector2(patrol_width.y,0), patrol_color, 4.0)


func _on_damage_animation_completed() -> void:
	damage_cooldown = false
	motion.x = 0 #temp, might break something later
	set_state(States.IDLE)


#/shouldn't/ trigger when the enemy dies offscreen
func _on_screen_exited_dead() -> void:
	if dead and splash:
		dead_offscreen = true
		visible = false
		motion = Vector2.ZERO
		sounds.volume_db += abs(sounds.volume_db) * .20 #temporary, gonna figure out how to normalize all the soundfx later
		sounds.stream = sound_effects_generic["splash"]
		if !sounds.is_connected("finished", self, "queue_free"):
			sounds.connect("finished", self, "queue_free")
		sounds.play()



func _on_throw_hitbox_body_entered(body: Node) -> void:
	if body == self:
		return
	if body.is_class("Enemy"):
		var overlap = Utils.contact_point_2_rect(collision, body.get_active_hitbox())
		body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.THROW_DAMAGE, 
				Utils.rect_corner_to_center(overlap).position)
	else: #crate
		body.on_break()


#player contact damage // to-do: keep damaging while inside the area 
#(currently needs to exit and re enter to trigger 
func _on_contact_hitbox_body_entered(body: KinematicBody2D) -> void:	
	if body == self:
		return
	else:
		var overlap = Utils.contact_point_2_rect(collision, body.get_active_hitbox())
		body.on_hit(Settings.Damage_Types.COMBAT, self, Settings.ENEMY_CONTACT_DAMAGE, 
				Utils.rect_corner_to_center(overlap).position)


func _on_patrol_idle_timer_timeout() -> void:
	set_state(States.PATROL)

#--------------override methods--------------#

#----------ON EXIT-------------#
func _idle_on_exit() -> bool:
	
	return false
	
func _patrol_on_exit() -> bool:
	
	return false

func _attack_melee_on_exit() -> bool:
	
	return false
	
func _attack_ranged_on_exit() -> bool:
	
	return false

func _chase_on_exit() -> bool:
	
	return false

func _leap_on_exit() -> bool:
	
	return false

func _lifted_on_exit() -> bool:
	
	return false

func _throw_land_on_exit() -> bool:
	
	return false

#----------ON ENTER-------------#
func _idle_on_enter() -> bool:
	
	return false

func _patrol_on_enter() -> bool:
	
	return false

func _attack_melee_on_enter() -> bool:
	
	return false

func _attack_ranged_on_enter() -> bool:
	
	return false

func _chase_on_enter() -> bool:
	
	return false
	
func _leap_on_enter() -> bool:
	
	return false

func _lifted_on_enter() -> bool:
	
	return false

func _throw_land_on_enter() -> bool:
	
	return false

func _damage_on_enter() -> bool:
	
	return false

func _death_combat_on_enter() -> bool:
	
	return false

func _death_spikes_on_enter() -> bool:
	
	return false

func _death_liquid_on_enter() -> bool:
	
	return false

func _death_throw_on_enter() -> bool:
	
	return false


#---------------UPDATE--------------#


func _idle_update() -> bool:
	
	return false

func _patrol_update() -> bool:
	
	return false

func _attack_melee_update() -> bool:
	
	return false

func _attack_ranged_update() -> bool:
	
	return false

func _chase_update() -> bool:
	
	return false

func _leap_update() -> bool:
	
	return false

func _lifted_update() -> bool:
	
	return false

func _throw_land_update() -> bool:
	
	return false

func _damage_update() -> bool:
	
	return false

func _death_combat_update() -> bool:
	
	return false

func _death_spikes_update() -> bool:
	
	return false

func _death_liquid_update() -> bool:
	
	return false

#enum States {IDLE, PATROL, ATTACK_MELEE, 
#		ATTACK_RANGED, CHASE, LEAP, 
#		LIFTED, THROW_LAND, DAMAGE, DEATH_COMBAT, 
#		DEATH_SPIKES, DEATH_LIQUID,
#		 DEAD_THROW}
