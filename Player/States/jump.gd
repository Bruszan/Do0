extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO
var height := 0.0
var initial_height := 0.0
var jump_velocity := 0.0

#Changes velocity depending on the ground angle (Sonic physics)
#Probably only makes sense if there is also physics on slopes when moving
#That's why this will probably be only used when sliding, which will have slope physics
func slope_jump() -> Vector3:
	var real_velo = player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001))
	var real_x = real_velo.x - jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().x
	var real_z = real_velo.z - jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().z 
	var real_y = real_velo.y + jump_velocity * cos(player.get_floor_angle())
	return Vector3(real_x, real_y, real_z)

func enter(previous_state_path: String, data := {}) -> void:
	initial_height = player.position.y
	player.gravity =- player.jump_gravity
	
	if player.sakurai_jump: 
		Global.sakurai_jump_timer = 0.0
		jump_velocity = player.sakurai_initial_jump_height / player.sakurai_initial_jump_duration + player.jump_gravity/2 * player.sakurai_initial_jump_duration
	else: 
		jump_velocity = player.jump_velocity
	#Play animation
	player._gobot.jump()
	
	#print("squat  ", player.get_horizontal_speed())
	if previous_state_path == "Slide" and player.is_on_floor():
		player.velocity = slope_jump()
	elif previous_state_path == "WallSlide":
		printt(player.velocity, player.get_wall_normal() * player.wall_jump_velocity)
		var temp_vely := player.velocity.y
		# Jump the opposite direction of the wall, maintaining velocity
		player.velocity = player.get_real_velocity() + player.get_wall_normal() * player.wall_jump_velocity
		player.velocity.y = temp_vely + player.wall_jump_y_velocity
		printt(player.velocity,"?")
		# Unique mechanice which the player gets more horizontal speed when lower on vertical speed
		#player.add_horizontal_speed(max(0, player.wall_jump_y_velocity - player.velocity.y)*2.0)
	else:
		print("jump!")
		#Jump always the same velocity
		player.velocity.y = jump_velocity
	
	printt("jump", player.velocity)
	
	#Enable and reset the raycast
	player._hand_raycast.set_process(true)
	player._wall_raycast.position.y = 0.7
	player._hand_raycast.position = Vector3(0, 1.5, 1)
	
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
	height = player.position.y - initial_height
	var horizontal_input = player.get_horizontal_input()
	# Get the input direction and handle the movement/deceleration.
	var horizontal_speed = get_horizontal_speed()
	var horizontal_velocity = horizontal_input * horizontal_speed
	
	## Horizontal movement
	
	# If the player has lower air speed than the max, accelerate
	# If the player has more air speed than the max, maintain it
	#if horizontal_input:
		#if horizontal_speed > player.air_top_speed:
			#print("ta rapido no ar")
			#h = horizontal_input * horizontal_speed
		#else:
			#h = horizontal_input * player.air_top_speed
		##Apply the aerial movement
		#player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
	#elif player.has_air_friction:
		##Desaccelerate if there is no direction being input (very experimental and optional)
		#player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_friction * _delta)
	
	# Trying to replicate Sonic's jump on boost games
	# Will always try to reach the max air speed, which is lower than the max ground speed
	# So the lower the jump is, the less speed that the player loses
	h = horizontal_input * player.air_top_speed
	player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
	
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
	
	
	
	Global.sakurai_jump_timer += _delta
	elapsed += _delta
	
	#Temporary if to apply sakurai jump instead of normal jump
	if player.sakurai_jump:
		if not Input.is_action_pressed("Jump"):
			player.gravity = player.fall_gravity
			Global.sakurai_jump_timer = 0.0
		
		if Global.sakurai_jump_timer > player.sakurai_initial_jump_duration:
			print("sakurou")
			player.velocity.y = sqrt(0 - 2.0 * -player.gravity * (player.sakurai_jump_height - player.sakurai_initial_jump_height))
			player._gobot.jump_flip()
	else:
		#Change the gravity for the player to fall
		if Input.is_action_just_released("Jump"):
			print("descendo")
			player.velocity.y *= 0
		
		#Play flip animation when the player reaches the maximum height of the ground jump

		if player.velocity.y - player.gravity * _delta <= 0 and Input.is_action_pressed("Jump"):
			player._gobot.jump_flip()
	
	# Wall Jump
	#if player.is_on_wall() and Input.is_action_just_pressed("Jump"):
		#printt("WallJump...", player.velocity)
		##player.velocity *= Vector3(-player.get_wall_normal().x, 1, -player.get_wall_normal().z)
		#var real_h_velo = Vector3(player.get_real_velocity().x, 0.0, player.get_real_velocity().z)
		#var wall_jump_dir := player.get_wall_normal()
		##var wall_jump_dir := (real_h_velo + player.get_wall_normal() * player.wall_jump_velocity).normalized()
		## These two lines tries to replicate Deadlock's Wall Jump
		## First it checks if the player is holding a direction against the wall
		#if horizontal_input.dot(player.get_wall_normal()) > 0.0:
			## Then the direction which speed will be added will be between
			## the direction of the normal predicted wall jump and the input direction
			#wall_jump_dir = (wall_jump_dir + horizontal_input).normalized()
		#printt(player.get_wall_normal(), wall_jump_dir, player.velocity)
		##player.velocity = player.velocity.bounce(player.get_wall_normal())
		#player.add_speed_to_direction(wall_jump_dir.normalized(), player.wall_jump_velocity, player.wall_jump_y_velocity)
		#player.velocity.y = player.wall_jump_y_velocity
		#printt("WallJump!", player.velocity)
	
	if player.velocity.y <= 0:
		height = player.position.y - initial_height
		print(height, " Jump Time to Peak: ", elapsed)
		#print(player._gobot._state_machine.get_current_node())
		elapsed = 0.0
		Global.sakurai_jump_timer = 0.0
		finished.emit(FALLING)
	#elif player.is_on_wall() and not abs(player.get_wall_normal().y):
		#finished.emit(WALLING)
	elif Global.on_water:
		finished.emit(DIVING)
	elif player.is_on_floor():
		if Input.is_action_pressed("Slide"):
			finished.emit(SLIDING)
		if player.velocity.x == 0 and player.velocity.z == 0:
			finished.emit(IDLE)
		else:
			finished.emit(RUNNING)
	elif player.is_on_wall() and not abs(player.get_wall_normal().y) and Input.is_action_just_pressed("Jump"):
		finished.emit(WALLING)
	
func exit() -> void: pass
