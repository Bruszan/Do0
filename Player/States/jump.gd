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
	
	#Not have jump gravity if sakurai jump is true
	if player.sakurai_jump: 
		player.gravity = 0
		Global.sakurai_jump_timer = 0.0
		jump_velocity = player.sakurai_jump_velocity
	else: 
		player.gravity =- player.jump_gravity
		jump_velocity = player.jump_velocity
	#Play animation
	player._gobot.jump()
	
	print("squat  ", player.get_horizontal_speed())	
	if previous_state_path == "Slide":
		player.velocity = slope_jump()
	elif previous_state_path == "WallSlide":
		player.velocity += player.get_wall_normal() * player.wall_jump_velocity
		player.velocity.y += player.wall_jump_y_velocity
	else:
		print("jump!")
		#Jump always the same velocity
		player.velocity.y = jump_velocity
	print("jump  ", player.get_horizontal_speed())
	
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

func update(_delta: float) -> void:
	height = player.position.y - initial_height
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = get_horizontal_speed()
	var horizontal_velocity = horizontal_input * horizontal_speed
	
	#print(horizontal_speed)
	if horizontal_input:
		if horizontal_speed > player.ground_top_speed:
			print("ta rapido no ar")
			h = horizontal_input * horizontal_speed
		else:
			h = horizontal_input * player.ground_top_speed
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
		
		#var rotate_dir = atan2(player.velocity.x, player.velocity.z)
		#player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 30 * _delta)
	elif player.smash_air_decel:
		#Desaccelerate if there is no direction being input (optional)
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.air_decel * _delta)
	
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
	
	Global.sakurai_jump_timer += _delta
	elapsed += _delta
	
	#Temporary if to apply sakurai jump instead of normal jump
	if player.sakurai_jump:
		if not Input.is_action_pressed("Jump"):
			player.gravity = player.sakurai_jump_gravity
			Global.sakurai_jump_timer = 0.0
		
		if Global.sakurai_jump_timer > player.sakurai_jump_duration:
			player._gobot.jump_flip()
			player.gravity = player.sakurai_jump_gravity
	else:
		#Change the gravity for the player to fall
		if Input.is_action_just_released("Jump"):
			print("descendo")
			player.gravity =- player.fall_gravity * 3
		
		#Play flip animation when the player reaches the maximum height of the ground jump

		if player.velocity.y <= 0 and Input.is_action_pressed("Jump"):
			player._gobot.jump_flip()
	
	
	if player.velocity.y <= 0:
		height = player.position.y - initial_height
		print(height, " Jump Time to Peak: ", elapsed)
		#print(player._gobot._state_machine.get_current_node())
		elapsed = 0.0
		Global.sakurai_jump_timer = 0.0
		finished.emit(FALLING)
	elif player.is_on_wall() and not abs(player.get_wall_normal().y):
		finished.emit(WALLING)
	elif Global.on_water:
		finished.emit(DIVING)
	elif player.is_on_floor():
		if Input.is_action_pressed("Slide"):
			finished.emit(SLIDING)
		if player.velocity.x == 0 and player.velocity.z == 0:
			finished.emit(IDLE)
		else:
			finished.emit(RUNNING)
		#print(player._player_pivot.rotation.y, "  ", atan2(direction.x, direction.z))
	#print(player.horizontal_speed)
	
func exit() -> void: pass
	#if player.sakurai_jump: player.gravity = player.sakurai_gravity
