extends KinematicBody2D

class_name Player, "res://sprites/objects/pickup/restore/extra_life/frame001.png"

signal powerup_timer_end
signal ranged_changed(_type, _ammo)
signal treasure_collected(treasure)
signal powerup_collected
signal health_updated(health)
signal ammo_updated(ammo)
signal lives_updated(lives)
signal powerup_timer_update(value)
signal teleporter_taken(teleporter)
signal end_item_collected
signal projectile_fired(projectile, pos, orientation, _rotation, impulse)
# warning-ignore:unused_signal
signal respawn(from, orientation)
# warning-ignore:unused_signal
signal spawn_dummy(dummy, pos, orientation)

enum Powerup_enum {NONE = 0, CATNIP, GHOST = 3, INVULNERABLE, 
		FIRE_SWORD, ICE_SWORD, LIGHTNING_SWORD} 
enum Orientations {LEFT = -1 , RIGHT = 1}
enum Ranged {PISTOL, MAGIC, DYNAMITE}
enum KnockBackSide {LEFT = -1, RIGHT = 1, NONE = 0}

#catnip and boost % values checked... might be wrong tho
#base values for SPEED, JUMP and CLIMB* not 100% confirmed but they should be close enough
#climb still needs accurate-ish testing
const MAXVELOCITY := 1024 #(32*32)
const SPEED := 255.0 #checked
const SPEED_BOOST := SPEED * 1.25 #125% of SPEED 
const SPEED_CATNIP := SPEED * 1.33 #133% of SPEED
const JUMP := -512.0  #use video
const JUMP_BOOST := JUMP * 1.10 #everything jump related needs ALL THE TWEAKING, still slightly off
const JUMP_CATNIP := JUMP * 1.26 #
const JUMP_TIME := 0.24
const JUMP_TIME_BOOST := JUMP_TIME * 1.03 
const JUMP_TIME_CATNIP := JUMP_TIME * 1.05
const JUMP_MIN := 0.11
const CLIMB := -225.0
const CLIMB_CATNIP := CLIMB * 1.2 #120% of CLIMB
const BOOST_START = 1.5 #calculated, might not be 100% accurate
const LANDING_STUN := 0.75
const DAMAGE_STUN_COOLDOWN := 1.0
const DAMAGE_STUN_DURATION := 0.5
const ATTACK_DAMAGE = { #according to the design document, not tested
	1: 5, #swipe		#update: some basic testing suggests this is correct.. still not sure
	2: 5, #punch
	3: 5, #kick
	4: 5, #hook
	5: 5, #air-swipe
	6: 2, #crouch-swipe
	}
#---resources---
#gotta remove all that aren't used on normal actions, any other lines are set in audio triggers
#soon(tm) 
const dialogue = { #Lines that trigger the exclamation bubble
	
	"enemy_kill_1" : preload("res://sounds/claw/1001.ogg"), #"Hah hah, take that!"
	"enemy_kill_2" : preload("res://sounds/claw/1110058.ogg"), #"Touche! (?)"
	"enemy_kill_3" : preload("res://sounds/claw/1110059.ogg"), #"Weakling! (?)"
	"enemy_kill_4" : preload("res://sounds/claw/1004a.ogg"), #"Ssscallywag!"
	"enemy_kill_5" : preload("res://sounds/claw/1004b.ogg"), #"Scallywaaaag"!
	"enemy_kill_6" : preload("res://sounds/claw/1007a.ogg"), #"Land lover!"
	"enemy_kill_7" : preload("res://sounds/claw/1007b.ogg"), #"Laaaaand loveeeer!"
	"enemy_kill_8" : preload("res://sounds/claw/1010.ogg"), #"Chew on DAT!"
	"enemy_kill_9" : preload("res://sounds/claw/1110063.ogg"), #"YUS!"
	"enemy_kill_10" : preload("res://sounds/claw/1110033.ogg"), #"Ha hah!" #on kill?
	"ledge" : preload("res://sounds/claw/1021.ogg"), #"Wooow" (ledge)
	"powerup_fire_sword" : preload("res://sounds/claw/1110001.ogg"), #"Yes! Fire Sword!"
	"powerup_ice_sword" : preload("res://sounds/claw/1110012.ogg"), #"Ha hah, Frost Sword!"
	"powerup_lightning_sword" : preload("res://sounds/claw/1110022.ogg"), #"Ha hah, Lightning Sword!"
	"powerup" : preload("res://sounds/claw/1110064.ogg"), #"YES!" #invulnerable and invisible powerups
	"idle_1" : preload("res://sounds/claw/1054.ogg"), #"Don't waste my time"
	"idle_2" : preload("res://sounds/claw/1056.ogg"), #"Hello? I'm in the middle of an adventure here!"
	"idle_3" : preload("res://sounds/claw/1057.ogg"), #"I don't have all day!"
	"idle_4" : preload("res://sounds/claw/1058.ogg"), #"Excuse me! I have someplace to go!"
	"idle_5" : preload("res://sounds/claw/1110035.ogg"), #"Hellooo?"
	"idle_6" : preload("res://sounds/claw/1110037.ogg"), #"I'm NOT getting any younger!"
	"idle_7" : preload("res://sounds/claw/1110038.ogg"), #"At least bring me something back from the kitchen!"
	"idle_8" : preload("res://sounds/claw/1110043.ogg"), #"I'm growing impatient!"
	"idle_9" : preload("res://sounds/claw/1110045.ogg"), #"I'm waiting..."
	"idle_10" : preload("res://sounds/claw/1110056.ogg"), #"The gems won't find themselves!"
	"idle_11" : preload("res://sounds/claw/1110057.ogg"), #"The amulet awaits!"
	"idle_12" : preload("res://sounds/claw/1062.ogg"), #"Not this cat, jack" #trigger

	"fire_pistol" : preload("res://sounds/claw/1003.ogg"), #"Eat lead!" #pistol
	"fire_dynamite" : preload("res://sounds/claw/1009.ogg"), #"Chew(?) on this!"#dynamite
	
	#all these triggers could be ignored because they are just called from the audiotrigger objects
	#and both this and the audiotrigger's contents reference the same resource when used
	#leaving this here for now just because the voice lines are written down
	"trigger_food" : preload("res://sounds/claw/1000.ogg"), #"Yum, looks yummy" #trigger
	"trigger_death_trap" : preload("res://sounds/claw/death_trap.ogg"), #"What a death trap" #trigger
	"trigger_tough" : preload("res://sounds/claw/1004.ogg"), #"NYEH, this'll be tough" #trigger
	"trigger_challenging" : preload("res://sounds/claw/1005.ogg"), #"This looks challenging..." #trigger
	"trigger_was_close" : preload("res://sounds/claw/1006.ogg"), #"Phew, that was close" #trigger
	"trigger_way_out" : preload("res://sounds/claw/1007.ogg"), #"There's got to be a way out" #trigger
	"trigger_getting_close" : preload("res://sounds/claw/1013.ogg"), #"I'm getting close, I can feel it" #trigger
	"trigger_catnapping" : preload("res://sounds/claw/1032.ogg"), #"I must be catnapping" #trigger
	"trigger_nuisance" : preload("res://sounds/claw/1040.ogg"), #"Meh, this is a minor nuisance" #trigger
	"trigger_fight_way_out" : preload("res://sounds/claw/1044.ogg"), #"I'll have to fight my way out of this one" #trigger
	"trigger_strategy" : preload("res://sounds/claw/1045.ogg"), #"Ah, this will take some careful strategy..." #trigger
	"trigger_pointless_exercise" : preload("res://sounds/claw/1052.ogg"), #"*yawn*... pointless exercise" #trigger
	"trigger_waste_of_time" : preload("res://sounds/claw/1053.ogg"), #"Waste of time" #trigger?
	"trigger_mirror" : preload("res://sounds/claw/1055.ogg"), #"Mirror mirror on the wall...  who's the handsomest cat of all?" #trigger?
	"trigger_circles" : preload("res://sounds/claw/1060.ogg"), #"I don't have all day to run around in circles!" #trigger
	"trigger_jack" : preload("res://sounds/claw/1062.ogg"), #"Not this cat, jack" #trigger
	"trigger_so_far" : preload("res://sounds/claw/so_far_so_good.ogg"), #"So far so good!" #trigger
	"trigger_gold" : preload("res://sounds/claw/smell_gold.ogg"), #"Ohh, is that gold I smell?" #trigger
	"trigger_timing" : preload("res://sounds/claw/timing.ogg"), #"This will take perfect timing!" #trigger
	}
const action_sounds = { #sound effects, hit sounds
	0 : preload("res://sounds/claw/left_foot.ogg"), #footstep 1
	1 : preload("res://sounds/claw/right_foot.ogg"), #footstep 2
	2 : preload("res://sounds/claw/1110048.ogg"), # hit
	3 : preload("res://sounds/claw/1110049.ogg"), # hit 2
	4 : preload("res://sounds/claw/1110050.ogg"), # hit 3
	5 : preload("res://sounds/claw/1110051.ogg"), # hit 4
	6 : preload("res://sounds/claw/dry_gunshot.ogg"), #empty pistol
	7 : preload("res://sounds/claw/dynamite_throw.ogg"), #dynamite throw
	8 : preload("res://sounds/claw/empty_magic.ogg"), #empty magic
	9 : preload("res://sounds/claw/fall_death.ogg"), #death by hit
	10 : preload("res://sounds/generic/death_spikes.ogg"), #death by spikes
	11 : preload("res://sounds/generic/death_liquid.ogg"), #death by liquid
	12 : preload("res://sounds/claw/fire_sword.ogg"), #fire sword attack
	13 : preload("res://sounds/claw/ice_sword.ogg"), #ice sword attack 
	14 : preload("res://sounds/claw/lightning_sword.ogg"), #lightning sword attack
	15 : preload("res://sounds/claw/land.ogg"), #hard landing 
	16 : preload("res://sounds/claw/sword_swish.ogg"), #sword swipe sound
	17 : preload("res://sounds/claw/left_swing.ogg"), #punch sound
	18 : preload("res://sounds/claw/uppercut.ogg"), #hook, kick sound
	19 : preload("res://sounds/claw/grunt.ogg"), #pickup sound
	20 : preload("res://sounds/claw/grunt_throw.ogg"), #throw sound
	21 : preload("res://sounds/generic/click.ogg"), #switch ranged type
	22 : preload("res://sounds/claw/gunshot.ogg"), #pistol shot
	23 : preload("res://sounds/claw/1002.ogg"), #"magic claw"
	}
const Sword_Projectile = preload("res://objects/generic/sword_projectile.tscn")
const Pistol_Bullet = preload("res://objects/generic/pistol_bullet.tscn")
const Magic_Projectile = preload("res://objects/generic/magic_projectile.tscn")
const Dynamite_Projectile = preload("res://objects/generic/dynamite_projectile.tscn")
const Player_Glitter_Material = preload("res://objects/generic/player_glitter_material.tres")


export(int) var health = 100 setget set_health
export(int) var pistol = 10 setget set_pistol
export(int) var magic = 5 setget set_magic
export(int) var dynamite = 3 setget set_dynamite
export(int) var lives = 3 setget set_lives

#---normal variables---
var gravity := 42.0 # or set by the level init
var climb_speed := CLIMB
var show_labels := false
var damage_cooldown := 0.0
var active_state #state
var previous_state #state
var next_state_name := "" #used in states
var on_ladder := false
var on_ladder_top := false
var on_two_ladders := false
var on_elevator := false
var on_elevator_area := false
var on_floor := false
var falling := false
var above_ladder_top := false
var ladder_x_pos := 0.0
var orientation = Orientations.RIGHT setget set_orientation
var powerup = Powerup_enum.NONE setget set_powerup
var motion : Vector2
var action_time := 0.0
var floor_velocity := Vector2.ZERO
var max_floor_y_velocity := 0.0
var snap_vector := Vector2.ZERO
var active_ranged = Ranged.PISTOL
var run_boost_charge : float #note: camera moves back a bit in the original when the boost is triggered
var boosted := false
var object_in_swipe_range := false
var objects_in_range := [] 
var enemy_in_close_range := false
var enemies_in_range := []
var crates_in_close_range := false
var crates_in_range := []
var liftable_in_close_range := false
var liftables_in_range := []
var color_material = preload("res://sprites/claw/invulnerable.tres") #for the invulnerable effect #const?
var current_switcher := 0
var melee_attack := 0 #0: none, 1: swipe, 2: punch, 3: kick, 4: hook, 5: air-swipe, 6: crouch-swipe
var scanned := false
var magic_sword := false
var attacking := false
var overlap_local : Rect2 #for showing overlaps between hitboxes
var knockback = KnockBackSide.NONE
var lifting := false
var lifted_object
var hit_effect = preload("res://objects/generic/hit_effect.tscn").instance()
var snap := Vector2.ZERO
var powerup_time := 0


#nodes
onready var animation = $Animation
onready var edge_check_m = $EdgeCheckM
onready var edge_check_l= $EdgeCheckL
onready var edge_check_r = $EdgeCheckR
onready var wall_check = $WallCheck
onready var floor_check = $FloorCheck
onready var collision_standing = $CollisionStanding
onready var collision_crouch = $CollisionCrouch
onready var area_check = $AreaCheck
onready var attack_air = $AttackAreas/AttackAir
onready var attack_crouch = $AttackAreas/AttackCrouch
onready var attack_hook = $AttackAreas/AttackHook
onready var attack_kick = $AttackAreas/AttackKick
onready var attack_punch = $AttackAreas/AttackPunch
onready var attack_sword = $AttackAreas/AttackSword
onready var player_sounds = $PlayerSounds
onready var player_sounds_2 = $PlayerSounds2
onready var player_sounds_3 = $PlayerSounds3
onready var player_voice = $PlayerVoice
onready var attack_areas = $AttackAreas
onready var player_glitter = $PlayerGlitter
onready var invuln_switcher = $InvulnSwitcher
onready var exclamation = $Exclamation
onready var powerup_timer = $PowerupTimer
onready var object_range_check = $ObjectRangeCheck
onready var melee_range_check = $MeleeRangeCheck
onready var liftable_check = $LiftableCheck
onready var projectile_spawns = $ProjectileSpawns
onready var lift_positions = $LiftPositions
onready var lift_position_1 = $LiftPositions/Lift1
onready var lift_position_2 = $LiftPositions/Lift2
onready var lift_position_charge = $LiftPositions/Charge
onready var camera = $Camera2D
onready var state_list = {
	"Crouch" : $State/Crouch,
	"Crouch_Attack" : $State/Crouch_Attack,
	"Crouch_Pistol" : $State/Crouch_Pistol,
	"Crouch_Magic" : $State/Crouch_Magic,
	"Crouch_Dynamite" : $State/Crouch_Dynamite,
	"Idle" : $State/Idle,
	"Idle_Attack" : $State/Idle_Attack,
	"Idle_Pistol" : $State/Idle_Pistol,
	"Idle_Magic" : $State/Idle_Magic,
	"Idle_Dynamite" :$State/Idle_Dynamite,
	"Death_Damage" : $State/Death_Damage,
	"Death_Spikes" : $State/Death_Spikes,
	"Jump" : $State/Jump,
	"Move" : $State/Move,
	"Land" : $State/Land,
	"Lift" : $State/Lift,
	"Stun" : $State/Stun,
	"Damage" : $State/Damage,
	"Climb": $State/Climb,
	"Noclip": $State/Noclip,
	}

#--------------OVERRIDES---------------
func get_class() -> String:
	return "Player"


func is_class(name) -> bool:
	return name == "Player" or .is_class(name)


# -------------SETTERS/GETTERS-------------
func set_health(value) -> void:
	health = clamp(value, 1, 100)


func set_pistol(value) -> void:
	pistol = clamp(value, 0, 99)


func set_magic(value) -> void:
	magic = clamp(value, 0, 99)


func set_dynamite(value) -> void:
	dynamite = clamp(value, 0, 99)


func set_lives(value) -> void:
	lives = clamp(value, 0, 9)


func set_orientation(value) -> void:
	if value != orientation:
		orientation = value
		flip_checks()
		run_boost_charge = 0.0

func set_powerup(value) -> void:
	powerup = value
	magic_sword = powerup in [Powerup_enum.FIRE_SWORD, Powerup_enum.ICE_SWORD, Powerup_enum.LIGHTNING_SWORD]
	
	#check original if picking up the same powerup plays the voice line again
	#also doublecheck catnip not having a voiceline
	#if powerup != Powerup_enum.NONE:
	if not powerup in [Powerup_enum.NONE, Powerup_enum.CATNIP]: 
		exclamation.visible = true
		if magic_sword: #this will break if the dialogue array changes #**#**#
			var type = "fire_sword" if powerup == 5 else "ice_sword" if powerup == 6 else "lightning_sword"
			Utils.decide_player(player_voice, dialogue["powerup_%s" % type])
		elif powerup != Powerup_enum.NONE:
			Utils.decide_player(player_voice, dialogue["powerup"])

# -------------OVERRIDE METHODS-------------
	
func _ready() -> void:
	z_index = Settings.PLAYER_Z
	player_sounds.set_volume_db(Settings.EFFECTS_VOLUME)
	player_sounds_2.set_volume_db(Settings.EFFECTS_VOLUME)
	player_sounds_3.set_volume_db(Settings.EFFECTS_VOLUME)
	player_voice.set_volume_db(Settings.EFFECTS_VOLUME)
	for state_node in $State.get_children():
		if state_node.is_class("State"):
			state_node.connect("finished", self, "_change_state")
	active_state = state_list["Idle"]
	previous_state = state_list["Idle"]
	invuln_switcher.connect("timeout", self, "_on_color_switch")
	player_voice.connect("finished", self, "_on_dialogue_end")
	add_child(hit_effect)
	add_to_group("player")
	player_glitter.material = Player_Glitter_Material


func _process(delta) -> void:
	if Input.is_action_just_pressed("ui_debug"):
		show_labels = !show_labels
		$Labels.visible = show_labels
	
	if Input.is_action_just_pressed("ui_noclip"):
		if active_state.name != "Noclip":
			_change_state("Noclip")
		else:
			_change_state("Idle")
		
	if Input.is_action_just_pressed("ui_switch") and !attacking:
		change_ammo()
		
	if damage_cooldown > 0:
		damage_cooldown = max(damage_cooldown - delta, 0)
		
	if on_elevator:
		max_floor_y_velocity = max(max_floor_y_velocity, abs(get_floor_velocity().y))
	else:
		max_floor_y_velocity = 0



func _physics_process(delta):
	if show_labels:
		update_labels()
	
	if !(active_state.name in ["Damage", "Climb", "Noclip", 
			"Swing", "Death_Damage", "Death_Spikes", "Death_Liquid"]):
		motion.y = motion.y + (gravity * delta) if motion.y < MAXVELOCITY else MAXVELOCITY

	#bandaid "fix" for fast elevator up speeds
	#still breaks on extreme cases like "teleporting" elevators like the ones near the end of level 14
	#the player teleports when the elevator goes back to the starting point
	#also has weird behaviors on jumping at high up speeds
	motion.y = max_floor_y_velocity if (floor_velocity != Vector2.ZERO 
					and active_state.name != "Jump") else motion.y
	
	snap = Vector2.DOWN * 4 if !active_state.name in ["Jump", "Climb"] else Vector2.ZERO
	motion = move_and_slide_with_snap(motion, snap, Vector2.UP)
	
	#temp (?) fix for jiggling physicsbodies when moving laterally
	#(seems to be caused by small changes in position.y float values after calling 
	#move_and_slide functions)
	
	for x in get_slide_count():
		var collision = get_slide_collision(x)
		if collision.collider.is_class("CrumblingPlatform") and !collision.collider.activated:
			collision.collider.activate()

	#this doesn't happen in the original, running against a wall still charges the boost
	#I guess that makes sense for that secret area at the beginning of level 11
#	if is_on_wall() and active_state.name == "Move": #kill boost when running into a wall 
#		if run_boost_charge != 0.0: run_boost_charge = 0.0
#		if run_speed == SPEED_BOOST: run_speed = SPEED
#		if jump_height == JUMP_BOOST: jump_height = JUMP
	
	on_floor = is_on_floor()
	if on_floor:
		floor_velocity = get_floor_velocity() 
	else:
		floor_velocity = Vector2.ZERO
	
	active_state._update(delta) 
	
	if floor_velocity == Vector2.ZERO:
		on_elevator = on_elevator_area
	else:
		on_elevator = true
	
	#To avoid glitchy movement. Can't round the elevator movement because it's based on tween
	if !on_elevator: 
		position = position.round()
	
	boosted = run_boost_charge >= BOOST_START


# -------------LOCAL METHODS-------------

func set_stance_collision(standing : bool, crouching : bool) -> void:
	collision_standing.call_deferred("set_disabled", standing)
	collision_crouch.call_deferred("set_disabled", crouching)


func update_labels() -> void:
	get_node("Labels").get_node("PositionLabel").text = "Pos: %s" % global_position
	get_node("Labels").get_node("MotionLabel").text = "Motion: %s" % motion
	get_node("Labels").get_node("FloorLabel").text = "On Floor: %s" % on_floor
	get_node("Labels").get_node("FloorVLabel").text = "Floor Vel: %s" % floor_velocity
	#get_node("Labels").get_node("FloorVLabel").text = "above_ladder_top: %s" % above_ladder_top
	#get_node("Labels").get_node("SnapLabel").text = "Snap Vector: %s" % snap_vector
	get_node("Labels").get_node("SnapLabel").text = "Animation: %s" % animation.animation
	get_node("Labels").get_node("StateLabel").text = "State: %s" % active_state.name
	get_node("Labels").get_node("ElevatorLabel").text = "On Elevator: %s" % on_elevator
	#get_node("Labels").get_node("ElevatorLabel").text = "On Ceiling: %s" % sis_on_ceiling()
	#get_node("Labels").get_node("ElevatorLabel").text = "Ranged: %s" % active_ranged
	get_node("Labels").get_node("LadderLabel").text = "Powerup: %s" % Powerup_enum.keys()[powerup]
	get_node("Labels").get_node("LadderTopLabel").text = "In LadderTop: %s" % on_ladder_top


func get_jump_height() -> float:
	if powerup == Powerup_enum.CATNIP:
		return JUMP_CATNIP
	else:
		if boosted:
			return JUMP_BOOST
		else:
			return JUMP


func get_jump_time() -> float:
	if powerup == Powerup_enum.CATNIP:
		if boosted:
			return JUMP_TIME_BOOST
		else:
			return JUMP_TIME
	else:
		return JUMP_TIME_CATNIP


func get_run_speed() -> float:
	if powerup == Powerup_enum.CATNIP:
		return SPEED_CATNIP
	else:
		if boosted:
			return SPEED_BOOST
		else:
			return SPEED


func use_pickup(pickup : Pickup) -> void:
	pickup._on_pickup() #do stuff defined in the pickup
	#increase values
	if pickup.is_class("Restore"):
		match pickup.type:
			"Ammo":
				var x
				match pickup.size:
					"Small":
						x = 5
					"Medium":
						x = 10
					"Large":
						x = 25
				pistol = min(pistol + x, 99)
				if active_ranged == Ranged.PISTOL:
					emit_signal("ammo_updated", pistol)
			"Magic":
				var x
				match pickup.size:
					"Small":
						x = 5
					"Medium":
						x = 10
					"Large":
						x = 25
				magic = min(magic + x, 99)
				if active_ranged == Ranged.MAGIC:
					emit_signal("ammo_updated", magic)
			"Dynamite":
				dynamite = min(dynamite + 5, 99)
				if active_ranged == Ranged.DYNAMITE:
					emit_signal("ammo_updated", dynamite)
			"Health_Food":
				health = min(health + 5, 100)
				emit_signal("health_updated", health)
			"Health":
				var x
				match pickup.size:
					"Small":
						x = 10
					"Medium":
						x = 15
					"Large":
						x = 25
				health = min(health + x, 100)
				emit_signal("health_updated", health)
			"Extra_Life":
				lives = min(lives + 1, 9)
				emit_signal("lives_updated", lives)
			
	#set the powerup and the timer
	elif pickup.is_class("Powerup"):
		if pickup.type in [Powerup_enum.CATNIP, 2] and powerup != Powerup_enum.CATNIP: #2 = catnip_red
			climb_speed = CLIMB_CATNIP
			run_boost_charge = 0.0
			player_glitter.emitting = true 
		elif pickup.type == Powerup_enum.GHOST and powerup != Powerup_enum.GHOST:
			animation.modulate.a = 0.5
		elif pickup.type == Powerup_enum.INVULNERABLE and powerup != Powerup_enum.INVULNERABLE:
			animation.material = color_material
			invuln_switcher.wait_time = 0.1
			invuln_switcher.one_shot = false
			invuln_switcher.start()
		#if extending an active powerup
		if ((powerup == pickup.type) or (powerup == Powerup_enum.CATNIP and pickup.type == 2)): #2 = catnip_red
			# if the powerup is the same type as the one had and it's not reusable
			if pickup.stack_duration: #if the powerup can stack
				update_powerup_timer(clamp(powerup_time + pickup.duration, 0, 999))
			else:
				update_powerup_timer(clamp(pickup.duration, 0, 999))
		else: #start a new powerup timer
			update_powerup_timer(pickup.duration)
			if powerup != Powerup_enum.NONE:
				end_powerup() 
			set_powerup(pickup.type if pickup.type != 2 else Powerup_enum.CATNIP) #2 = catnip_red
			emit_signal("powerup_collected")


func change_ammo() -> void:
	var ammo : int
	match active_ranged:
		Ranged.PISTOL:
			active_ranged = Ranged.MAGIC
			ammo = magic
		Ranged.MAGIC:
			active_ranged = Ranged.DYNAMITE
			ammo = dynamite
		Ranged.DYNAMITE:
			ammo = pistol
			active_ranged = Ranged.PISTOL
	emit_signal("ranged_changed", Ranged.keys()[active_ranged].to_lower(), ammo)
	player_sounds.stream = action_sounds[21]
	player_sounds.play()


func flip_checks() -> void:
	for elem in attack_areas.get_children() + projectile_spawns.get_children() + lift_positions.get_children():
		elem.position.x *= (-1) #move to the opposite side
		elem.rotation_degrees += 180 if !elem.is_class("Position2D") else 0 #rotate if it's not a projectile spawn point
		#^ maybe it's faster to just let it rotate the points, dunno
	object_range_check.position.x *= (-1)
	melee_range_check.position.x *= (-1)
	liftable_check.position.x *= (-1)
	if is_instance_valid(lifted_object):
		lifted_object._flip_anim(orientation == -1)


func end_powerup() -> void:
	match powerup:
		Powerup_enum.CATNIP:
			climb_speed = CLIMB
			animation.speed_scale = 1.0
			player_glitter.emitting = false
		Powerup_enum.GHOST:
			animation.modulate.a = 1
		Powerup_enum.INVULNERABLE:
			animation.material = null
			invuln_switcher.stop()
		_:
			pass


#doesn't check if /another/ line is being played, I don't think it's necessary but test later
#(does check if the /same/ line is being played)
func on_voice_trigger(audio) -> void:
	if !(player_voice.stream == audio and player_voice.playing): #don't force the currently playing line
		exclamation.visible = true
		player_voice.stream = audio
		player_voice.play()


#voice line triggers
#doesn't happen during crouch, not on jump, not on empty
func on_pistol_fired() -> void: 
	randomize()
	if randi()%101 <= Settings.DYNAMITE_USE_VOICELINE_CHANCE * 100: #33% chance of saying something
		on_voice_trigger(dialogue["fire_pistol"])
	
	
#ALSO HAPPENS DURING CROUCH, NOT ON JUMP, NOT WHEN EMPTY
func on_dynamite_prepared() -> void:
	randomize()
	if randi()%101 <= Settings.PISTOL_USE_VOICELINE_CHANCE * 100: #33% chance of saying something
		on_voice_trigger(dialogue["fire_dynamite"])


#all these spawn_projectile methods can be improved by having a pool of pre-instantiated objects
#and setting them up instead of always creating a new instance. Requires to change the behavior of 
#current projectiles of despawning with queue_free when they hit terrain or a single enemy 
#in the case of bullets.
#soon(tm)

#(assumes powerup is one of the three sword powerups)
#check if the original has 2d sound for the sword projectile
func spawn_sword_projectile(stance : int) -> void:
	if powerup in [Powerup_enum.FIRE_SWORD, Powerup_enum.ICE_SWORD, Powerup_enum.LIGHTNING_SWORD]:
		var projectile = Sword_Projectile.instance()
		projectile.type = powerup
		var id = 12 if projectile.type == Powerup_enum.FIRE_SWORD else 13 if projectile.type == Powerup_enum.ICE_SWORD else 14
		Utils.decide_player([player_sounds, player_sounds_2, player_sounds_3], action_sounds[id]) 
		var node_name = "SwordStanding" if stance == 1 else "SwordCrouch" if stance == 2 else "SwordAir"
		var _rotation = 180 if orientation == Orientations.LEFT else 0
		emit_signal("projectile_fired", projectile, 
				projectile_spawns.get_node(node_name).global_position, 
				orientation, 
				_rotation,
				null)


func spawn_pistol_projectile(stance : int) -> void:
	var projectile = Pistol_Bullet.instance()
	var node_name = "PistolStanding" if stance == 1 else "PistolCrouch" if stance == 2 else "PistolAir"
	Utils.decide_player([player_sounds, player_sounds_2, player_sounds_3], action_sounds[22]) 
	emit_signal("projectile_fired", projectile,
			projectile_spawns.get_node(node_name).global_position,
			orientation,
			null,
			null)


func spawn_magic_projectile(stance : int) -> void:
	var projectile = Magic_Projectile.instance()
	var node_name = "MagicClawStanding" if stance == 1 else "MagicClawCrouch" if stance == 2 else "MagicClawAir"
	var _rotation = 180 if orientation == Orientations.LEFT else 0
	Utils.decide_player([player_sounds, player_sounds_2, player_sounds_3], action_sounds[23]) 
	emit_signal("projectile_fired", projectile,
			projectile_spawns.get_node(node_name).global_position,
			orientation,
			_rotation,
			null)


func spawn_dynamite_projectile(stance : int, charge : Vector2) -> void:
	var projectile = Dynamite_Projectile.instance()
	var node_name = "DynamiteStanding" if stance == 1 else "DynamiteCrouch" if stance == 2 else "DynamiteAir"
	Utils.decide_player([player_sounds, player_sounds_2, player_sounds_3], action_sounds[7]) 
	emit_signal("projectile_fired", projectile,
			projectile_spawns.get_node(node_name).global_position,
			-orientation,
			null,
			charge)


func get_active_hitbox() -> CollisionShape2D:
	return collision_standing if !collision_standing.disabled else collision_crouch

#_type isn't used here? it is used on enemies
func on_hit(_type: int, source : CollisionObject2D, damage : int, point : Vector2 = position) -> void:
	#print("%s hit for %s at point %s by %s" % [_type, damage, point, source.name])
	if !powerup == Powerup_enum.INVULNERABLE and damage_cooldown <= 0:
		damage_cooldown = DAMAGE_STUN_COOLDOWN
		hit_effect.position = to_local(point)
		hit_effect.play("claw_%s" % str(randi()%3+1)) 
		hit_effect.z_index = Settings.PLAYER_Z+1
		if is_on_floor():
			#left or right
			knockback = KnockBackSide.RIGHT if source.global_position.x < global_position.x else KnockBackSide.LEFT
		else:
			knockback = KnockBackSide.NONE
		_on_damage_taken(source, damage)
	else:
		print("Can't take damage on cooldown // Invincible status")


func update_powerup_timer(value) -> void:
	powerup_time = value
	emit_signal("powerup_timer_update", powerup_time) 
	powerup_timer.start(1.0)

# -------------SIGNAL METHODS-------------
func _change_state(state_name) -> void:
	next_state_name = state_name
	active_state._on_exit()
	previous_state = active_state
	active_state = state_list[state_name]
	active_state._on_enter()
	next_state_name = ""
	#only running off a ledge after running should keep the charge while not boosted
	if !boosted:
		#note: this used to be fall and move but now jump and fall got merged
		#gotta test this now
		if active_state != state_list["Jump"] and previous_state == state_list["Move"]: 
			run_boost_charge = 0.0 #this resets the speed boosts in physics process
	else: #but while boosted, both jumping and falling should keep the momentum
		if !active_state.name in ["Jump", "Fall", "Move"]:
			run_boost_charge = 0.0


func _on_area_entered(area) -> void:
	var area_owner = area.get_parent()
	match area.name:
		"LadderBody":
			on_ladder = true
			ladder_x_pos = area.global_position.x
		"LadderTop":
			on_ladder_top = true
			ladder_x_pos = area.global_position.x
		_:
			if (area_owner.is_class("Pickup") and !area_owner.is_class("Teleporter")):
				#don't use health items if health is full
				if !(health == 100 and (area_owner.type in ["Health", "Health_Food"])):
					use_pickup(area.get_parent())
				if area_owner.is_class("Treasure"):
					emit_signal("treasure_collected", area_owner)
				elif area_owner.is_class("EndItem"):
					emit_signal("end_item_collected")
			elif area_owner.is_class("Teleporter"):
				use_pickup(area.get_parent())
				emit_signal("teleporter_taken", area_owner)
			else:
				print("No action for this area '%s'" % area.name)


func _on_area_exited(area) -> void:
	if area.name == "LadderBody":
		on_two_ladders = false
		for body in get_node("AreaCheck").get_overlapping_areas():  #check if the player is in another ladder when
			if body.name == "LadderBody" and body != area:			#exiting the one who called this method
				on_two_ladders = true								#body != area because for some reason the original ladder 
		on_ladder = on_two_ladders									#is in the overlapping areas array after "exiting" that area
	elif area.name == "LadderTop":
		on_ladder_top = false


func _on_damage_taken(_source: CollisionObject2D, _damage : int) -> void: 
	health = max(health - _damage, 0)
	emit_signal("health_updated", health)
	#print("Player Damage: %s" % _damage)
	#print("Damage Source: %s" % source.name)
	if health == 0:
		on_death(Settings.Damage_Types.COMBAT)
	else:
		_change_state("Damage")
	#else:
		#print("Can't take damage during cooldown")


func on_death(cause : int) -> void:
	powerup_time = 0
	_on_powerup_timer_end()
	match cause:
		Settings.Damage_Types.SPIKES:
			health = 0 
			emit_signal("health_updated", health)
			_change_state("Death_Spikes")
			print("Death by Spikes")
		Settings.Damage_Types.LIQUID:
			health = 0
			emit_signal("health_updated", health)
			_change_state("Death_Liquid")
			print("Death by Liquid")
		Settings.Damage_Types.COMBAT:
			health = 0
			emit_signal("health_updated", health)
			_change_state("Death_Damage")
			print("Death by Combat")
		_:
			print("Death by... something")
	if lives == 0:
		#game over #implement this when there's a menu to return to
		print("Game over")
	else:
		lives -= 1
		emit_signal("health_updated", health)
		emit_signal("lives_updated", lives)
		#emit respawn transition signal here?


func _on_body_entered(body) -> void:
	if body.name == "ElevatorBody":
		on_elevator_area = true


func _on_body_exited(body) -> void:
	if body.name == "ElevatorBody":
		on_elevator_area = false


#signals from ObjectRangeCheck, if there's a crate or enemy in swipe range (also barrels, the original does that)
func _on_longrange_body_entered(body) -> void:
	objects_in_range.append(body)
	object_in_swipe_range = !objects_in_range.empty()


func _on_longrange_body_exited(body) -> void:
	objects_in_range.erase(body)
	object_in_swipe_range = !objects_in_range.empty()


#signals from MeleeRangeCheck, if there's an enemy in close melee range (punch, kick, hook)
func _on_closerange_body_entered(body) -> void:
	if body.is_class("Crate"):
		if !enemy_in_close_range:
			crates_in_close_range = !crates_in_range.empty()
	else:
		enemies_in_range.append(body)
		enemy_in_close_range = !enemies_in_range.empty()


func _on_closerange_body_exited(body) -> void:
	if body.is_class("Crate"):
		crates_in_range.erase(body)
		crates_in_close_range = !crates_in_range.empty()
	else:
		enemies_in_range.erase(body)
		enemy_in_close_range = !enemies_in_range.empty()


func _on_liftablecheck_body_entered(body: Node) -> void:
	#enemies also can't be lifted in certain states (while attacking at least)
	if body.is_class("Enemy") and body.throwable: 
		liftables_in_range.append(body)
	elif !body.exploding and !body.lifted:
		liftables_in_range.append(body)
	liftable_in_close_range = !liftables_in_range.empty()


func _on_liftablecheck_body_exited(body: Node) -> void:
	liftables_in_range.erase(body)
	liftable_in_close_range = !liftables_in_range.empty()


#-1 seconds on counter
func _on_powerup_timer_end() -> void:
	powerup_time -= 1
	if powerup_time <= 0:
		emit_signal("powerup_timer_end") #hide the timer hud
		end_powerup() 
		powerup_timer.stop()
		set_powerup(Powerup_enum.NONE)
	else:
		emit_signal("powerup_timer_update", powerup_time) 
		powerup_timer.start(1.0)


func _on_color_switch() -> void:
	current_switcher += 1
	current_switcher %= 5
	animation.material.set_shader_param("switcher", current_switcher)


#called by the player_sounds finished signal to automatically hide the thingy when the dialogue line ends
func _on_dialogue_end() -> void:
	exclamation.visible = false


#func _draw() -> void:
#	draw_rect(overlap_local, Color.purple, true)


#called when any of the active attack areas intersect an enemy/object
func _on_check_enemy_hit(body) -> void:
	var attack_area : CollisionShape2D 
	match melee_attack: #get the right attack_area node
		0: return
		1: attack_area = attack_sword
		2: attack_area = attack_punch #kick and punch also have the same area in the original
		3: attack_area = attack_kick #but since it is kinda irrelevant I'll leave them as they are*
		4: attack_area = attack_hook 	#(*accurate only to the sprite, not the original)
		5: attack_area = attack_sword #attack_air #these use the same area (this and crouch
		6: attack_area = attack_crouch # are accurate to the original)
	var damage = ATTACK_DAMAGE[melee_attack] if powerup != Powerup_enum.CATNIP else 10
	if !body.is_class("Crate"):
		var overlap = Utils.contact_point_2_rect(attack_area, body.get_active_hitbox())
		overlap_local = Rect2(to_local(overlap.position), overlap.size)
		if body.has_method("on_hit"):
			
			body.on_hit(Settings.Damage_Types.COMBAT, self, damage, Utils.rect_corner_to_center(overlap).position)
	else:
		if body.has_method("on_break"):
			body.on_break()


#note: juggling a dead enemy can also trigger the on kill voiceline
#still not sure about the chances 
func _on_enemy_kill() -> void:
	#chance to say the voiceline
	randomize()
	if randi()%101 <= Settings.ENEMY_KILL_VOICELINE_CHANCE * 100:
		on_voice_trigger(dialogue["enemy_kill_%s" % str(randi()%10+1)])
	#print("player: enemy killed by bullet")
