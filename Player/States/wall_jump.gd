extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO
var height := 0.0
var initial_height := 0.0
var jump_velocity := 0.0
var wall_jump_dir : Vector3
var wall_normal : Vector3

func enter(previous_state_path: String, data := {}) -> void:
	#Play animation
	player._gobot.wall_jump()
	initial_height = player.position.y
	player.gravity =- player.jump_gravity
	
		#Enable and reset the raycast
	player._hand_raycast.set_process(true)
	player._wall_raycast.position.y = 0.7
	player._hand_raycast.position = Vector3(0, 1.5, 1)
	
	# Wall Jump
	
	# Experimental mechanich which the player gets more horizontal speed when lower on vertical speed
	# player.add_horizontal_speed(max(0, player.wall_jump_y_velocity - player.velocity.y)*2.0)
		
	printt("WallJump...", player.velocity)
	var real_h_velo = Vector3(player.get_real_velocity().x, 0.0, player.get_real_velocity().z)
	if previous_state_path == "EdgeGrab": wall_jump_dir = player.h_input.normalized()
	else: wall_jump_dir = player.get_wall_normal()

	# This condition tries to replicate Deadlock's Wall Jump
	# First it checks if the player is holding a direction against the wall
	if player.h_input.dot(player.get_wall_normal()) > 0.0:
	# Then the direction which speed will be added will be between
		# the direction of the normal predicted wall jump and the input direction
		wall_jump_dir = (wall_jump_dir + player.h_input).normalized()
	
	printt(player.get_wall_normal(), wall_jump_dir, player.velocity)
	var temp_vely = player.velocity.y
	player.add_speed_to_direction(wall_jump_dir.normalized(), player.wall_jump_velocity, player.wall_jump_y_velocity)
	# Add to the current vertical velocity
	#player.velocity.y = max(temp_vely + player.wall_jump_y_velocity, player.wall_jump_y_velocity)
	player.velocity.y = player.wall_jump_y_velocity
	printt("WallJump!", player.velocity)

func physics_update(_delta: float) -> void:
	height = player.position.y - initial_height
	# Get the input direction and handle the movement/deceleration.
	var horizontal_speed = get_horizontal_speed()
	
	## Horizontal movement
	# If the player has lower air speed than the max, accelerate
	# If the player has more air speed than the max, maintain it
	if player.h_input:
		if horizontal_speed > player.air_top_speed:
			print("ta rapido no ar")
			h = player.h_input * horizontal_speed
		else:
			h = player.h_input * player.air_top_speed
	#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.wall_jump_air_accel * _delta)
	elif player.has_air_friction:
		#Desaccelerate if there is no direction being input (very experimental and optional)
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.wall_jump_air_accel * _delta)
	
	Global.sakurai_jump_timer += _delta
	elapsed += _delta
	
	if player.velocity.y <= 0:
		height = player.position.y - initial_height
		print(height, " Jump Time to Peak: ", elapsed)
		#print(player._gobot._state_machine.get_current_node())
		elapsed = 0.0
		Global.sakurai_jump_timer = 0.0
		finished.emit(FALLING)

	# Manage states
	elif Global.on_water:
		finished.emit(DIVING)
	elif player.is_on_floor():
		if Input.is_action_pressed("Slide"):
			finished.emit(SLIDING)
		if player.velocity.x == 0 and player.velocity.z == 0:
			finished.emit(IDLE)
		else:
			finished.emit(RUNNING)
	elif player.is_on_wall() and not abs(player.get_wall_normal().y):
		if player.h_input.dot(player.get_wall_normal()) < 0.0:
			finished.emit(WALLING)
		elif InputBuffer.is_action_press_buffered("Jump"):
			## There is no wall jump state (yet?)
			finished.emit(WALL_JUMPING)

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

func exit() -> void: pass
