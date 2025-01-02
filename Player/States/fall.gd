extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO
var fall_speed := 0.0

func enter(previous_state_path: String, data := {}) -> void:
	if player.sakurai_jump: player.gravity = player.sakurai_gravity
	else: player.gravity =- player.fall_gravity
	#player._gobot.fall()

	printt("fall", player._gobot._state_machine.get_current_node())
	
	#Enable and reset the raycast
	player._hand_raycast.set_process(true)
	player._wall_raycast.position.y = 0.7
	player._hand_raycast.position = Vector3(0, 1.5, 0.9)

func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()
	
func is_edge_grabbable() -> bool:
	if player._hand_raycast.is_colliding():
		player._wall_raycast.set_process(true)
		player._wall_raycast.position.y = player._hand_raycast.get_collision_point().y - 0.01
		if player._wall_raycast.is_colliding():
			print(Vector3(player._wall_raycast.get_collision_point().x, player._hand_raycast.get_collision_point().y, player._wall_raycast.get_collision_point().z))
			return true
		else:
			player._wall_raycast.set_process(false)
			return false
	else:
		player._wall_raycast.set_process(false)
		return false

func physics_update(_delta: float) -> void:
	
	if player._gobot._state_machine.get_current_node() == "JumpFlip":
		#printt(player._gobot._state_machine.get_current_play_position() + _delta, player._gobot._state_machine.get_current_length())
		if player._gobot._state_machine.get_current_play_position() + _delta >= player._gobot._state_machine.get_current_length():
			player._gobot.fall()
	else: player._gobot.fall()
	
	if player.is_on_floor():
		print("chão  ", fall_speed)
		print("Jump Time to Descent: ", elapsed)
		elapsed = 0.0
		if Input.is_action_pressed("Slide"):
			var slide_speed = fall_speed * player.fall_to_slope_factor * sin(player.get_floor_angle()) * -player.get_floor_normal()
			player.velocity += Vector3(slide_speed.x, 0, slide_speed.z)
			printt("fall",player.get_horizontal_speed())
			finished.emit(SLIDING)
		elif player.velocity:
			finished.emit(RUNNING)
		else:
			finished.emit(IDLE)
	elif is_edge_grabbable():
		finished.emit(EDGING)
	#elif player.is_on_wall() and not abs(player.get_wall_normal().y):
		#finished.emit(WALLING)
	elif Global.on_water:
		finished.emit(DIVING)
			
	# Get the input direction and handle the movement/deceleration.
	var horizontal_input = player.get_horizontal_input()
	#var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	#var horizontal_input = -player._camera_pivot.global_basis.z * input_dir.y + -player._camera_pitch.global_basis.x * input_dir.x
	#Normalize is making analog range being wrong
	var horizontal_speed = get_horizontal_speed()
	var horizontal_velocity = horizontal_input * horizontal_speed
	
	#print(horizontal_speed)
	if horizontal_input:
		if horizontal_speed > player.ground_top_speed:
			h = horizontal_input * horizontal_speed
		else:
			h = horizontal_input * player.ground_top_speed
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
		
		#var rotate_dir = atan2(player.velocity.x, player.velocity.z)
		#player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 30 * _delta)
	elif player.has_air_friction:
		#Desaccelerate if there is no direction being input (optional)
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.air_friction * _delta)
		
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
		#print(player._player_pivot.rotation.y, "  ", atan2(direction.x, direction.z))
	
	#Variable for calculations when getting out of falling state like slope boost or fall damage
	fall_speed = player.velocity.y
	
	# Wall Jump
	if player.is_on_wall() and Input.is_action_just_pressed("Jump"):
		printt("WallJump...", player.velocity)
		#player.velocity *= Vector3(-player.get_wall_normal().x, 1, -player.get_wall_normal().z)
		var real_h_velo = Vector3(player.get_real_velocity().x, 0.0, player.get_real_velocity().z)
		var wall_jump_dir := player.get_wall_normal()
		#var wall_jump_dir := (real_h_velo + player.get_wall_normal() * player.wall_jump_velocity).normalized()
		# These two lines tries to replicate Deadlock's Wall Jump
		# First it checks if the player is holding a direction against the wall
		if horizontal_input.dot(player.get_wall_normal()) > 0.0:
			# Then the direction which speed will be added will be between
			# the direction of the normal predicted wall jump and the input direction
			wall_jump_dir = (wall_jump_dir + horizontal_input).normalized()
		printt(player.get_wall_normal(), wall_jump_dir, player.velocity)
		#player.velocity = player.velocity.bounce(player.get_wall_normal())
		player.add_speed_to_direction(wall_jump_dir.normalized(), player.wall_jump_velocity, player.wall_jump_y_velocity)
		player.velocity.y = player.wall_jump_y_velocity
		printt("WallJump!", player.velocity)

func exit() -> void:
	#if player.sakurai_jump: player.gravity = player.sakurai_gravity
	player._hand_raycast.set_process(false)   
