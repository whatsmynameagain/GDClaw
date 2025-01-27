extends Node

#mix of user settings and global variables

#temp pseudo global enum(s), should figure out how to actually make it global sometime
#don't use value 0, it's used by death tiles
enum Damage_Types {THROW, SPIKES, LIQUID, COMBAT, OTHER, FIRE = 5, ICE, LIGHTNING}
enum Powerups {CATNIP = 1, CATNIP_RED, GHOST, INVULNERABLE,
	 FIRE_SWORD, ICE_SWORD, LIGHTNING_SWORD}

#user settings
var EFFECTS_VOLUME = -20
var MUSIC_VOLUME  = -20

#global variables #not const in case they are modifiable in game options eventually?
var PLAYER_Z = 14
var ENEMY_Z = 15
var TILEMAP_Z = 0
var BG_OBJECT_Z = 1#testing
var FG_OBJECT_Z = 30
var SWORD_PROJECTILE_SPEED = Vector2(800, 0)
var SWORD_PROJECTILE_DAMAGE = 100
var PISTOL_PROJECTILE_SPEED = Vector2(800, 0)
var PISTOL_DAMAGE = 10 #?
var MAGIC_PROJECTILE_SPEED = Vector2(800, 0)
var MAGIC_DAMAGE = 25 #?
var DYNAMITE_PROJECTILE_SPEED = Vector2(400, -800)  #450 -850#not perfect, seems to be close enough
var DYNAMITE_FUSE_TIME = 1.25
var DYNAMITE_DAMAGE = 25
var DYNAMITE_CHARGE_TIME = 2.25
var DAMAGE_KNOCKBACK = 80
var KEG_DAMAGE = 20 #(?)
var KEG_Z = FG_OBJECT_Z
var CRATE_BACK_Z = BG_OBJECT_Z
var CRATE_FRONT_Z = FG_OBJECT_Z
var PICKUP_Z = 15 #loot
var PICKUP_BG_Z = 13 #floating pickups
var PICKUP_IMPULSE_RANGE_X = 200
var PICKUP_IMPULSE_RANGE_Y = 200
var PICKUP_IMPULSE_X_MULTIPLIER = 1
var PICKUP_IMPULSE_Y_MULTIPLIER = 1
var PICKUP_IMPULSE_SINGLE_CRATE = Vector2(0 * PICKUP_IMPULSE_X_MULTIPLIER, -400 * PICKUP_IMPULSE_Y_MULTIPLIER) 
var THROW_MIN_IMPULSE = Vector2(200, -625) #pretty ok
var THROW_MAX_IMPULSE = Vector2(500, -825) #pretty ok
var THROW_CHARGE_TIME = 3
var THROW_DAMAGE = 10 #(?)
var LIFT_MOVEMENT_SPEED = 60 #(?)
var MAX_OBJECT_SIZE = 100 #death tiles, ladders
var ENEMY_THROW_RECOVERY_TIME = 1 #time after an enemy
var MELEE_ATTACK_SCAN_TIME = 0.1 #time the attack hitboxes are enabled
var PISTOL_USE_VOICELINE_CHANCE = 0.33 #chance to play a voiceline when firing #not fully checked
var DYNAMITE_USE_VOICELINE_CHANCE = 0.33 #same as above
var ENEMY_KILL_VOICELINE_CHANCE = 0.33 #chance to play a voiceline on pistol kill #not checked
var ENEMY_PATROL_WAIT_CHANCE = 0.5 #seems to be right
var ENEMY_PATROL_VOICE_CHANCE = 0.5 #not tested
var ENEMY_CONTACT_DAMAGE = 5 #not tested
var LEDGE_VOICE_CHANCE = 0.5 #not tested
var ENEMY_OFFICER_MELEE_DAMAGE = 10 #not tested
