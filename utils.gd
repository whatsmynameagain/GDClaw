extends Node


#manages the sprites for a given num value (showing 0s depending on how many digits there are on the counter)
#used for hud elements and booty scene scores
static func update_sprites(value : int, digits : int, base : Node2D, sprites : Dictionary) -> void:
	var element_array = base.get_node("Sprites").get_children()
	if str(value).length() < digits: #if there are less digits than the amount of sprites 
		for i in range(element_array.size() - str(value).length()):
			element_array[i].texture = sprites[0]
	var x := 0
	for i in range(element_array.size() - str(value).length(), element_array.size()):
		if !str(value).length() <= x:
			element_array[i].texture = sprites[int(str(value)[x])]
		x += 1


#checks whether a given audiostreamplayer is currently playing. If so, creates a temporary one
#if not, plays the given stream on that inactive player
#can't set the type of the sound_player argument to AudioStreamPlayer because there's also the 2D version
static func decide_player(sound_player, stream : Resource) -> void:
	assert(sound_player is AudioStreamPlayer or sound_player is AudioStreamPlayer2D)
	if sound_player.playing:
		var temp_player
		if sound_player is AudioStreamPlayer:
			temp_player = AudioStreamPlayer.new()
		else:
			temp_player = AudioStreamPlayer2D.new()
		sound_player.owner.add_child(temp_player)
		temp_player.connect("finished", temp_player, "queue_free")
		temp_player.set_volume_db(Settings.EFFECTS_VOLUME)
		temp_player.set_stream(stream) 
		temp_player.play()
	else:
		sound_player.set_stream(stream) 
		sound_player.play()


#returns the center point of the overlapping area between two collision rectangles (not rect2s)
func contact_point_2_rect(r1: CollisionShape2D, r2 : CollisionShape2D) -> Rect2:
	var r1P : Dictionary = rect_2d_points(r1.shape, r1.global_position)
	var r2P : Dictionary = rect_2d_points(r2.shape, r2.global_position)
	var point_intersect = {
		"l" : max(r1P["l"], r2P["l"]), 
		"u" : max(r1P["u"],r2P["u"]), 
		"r" : min(r1P["r"],r2P["r"]), 
		"d" : min(r1P["d"],r2P["d"])}
	return rect_point_c2c(point_intersect["l"], point_intersect["u"], point_intersect["r"], point_intersect["d"], true)


#center to corner or viceversa from points
func rect_point_c2c(l : float, u : float, r : float, d : float, c : bool) -> Rect2:
	#unlike a rectangleshape2d's extents, rect2s don't grow symmetrically but from a corner
	#so it needs the whole value, not half that will get mirrored
	var size_x = abs(r - l)
	var size_y = abs(d - u)
	var size = Vector2(size_x, size_y)
	#and the position needs to be adjusted
	var pos_x = (l + r)/2 #get middle point position and adjust by half the rect's size
	var pos_y = (u + d)/2
	match c:
		true: 
			pos_x -= abs(r - l)/2 
			pos_y -= abs(d - u)/2
		false:
			pos_x += abs(r - l)/2 
			pos_y += abs(d - u)/2
	var pos = Vector2(pos_x, pos_y) 
	return Rect2(pos, size)


#corner to center from rect
func rect_corner_to_center(rect : Rect2) -> Rect2: #pretty sure gdscript passes rect2s by copy(?)
	rect.position.x += rect.size.x / 2
	rect.position.y += rect.size.y / 2
	return rect


#center to corner from rect
func rect_center_to_corner(rect : Rect2) -> Rect2: 
	rect.position.x -= rect.size.x / 2
	rect.position.y -= rect.size.y / 2
	return rect


#returns the four position points of a rectangleshape2d
func rect_2d_points(rect : RectangleShape2D, pos : Vector2) -> Dictionary:
	var l = pos.x - rect.extents.x
	var r = pos.x + rect.extents.x
	var u = pos.y - rect.extents.y
	var d = pos.y + rect.extents.y
	return {"l":float(l), "u":float(u), "r":float(r),"d":float(d)}
