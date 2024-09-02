extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO

func enter(previous_state_path: String, data := {}) -> void:
	#Changes velocity depending on the ground angle (Sonic physics)
	#Probably only makes sense if there is also physics on slopes when moving
	#That's why this will probably be only used when sliding, which will have slope physics
	var real_x = player.get_real_velocity().x - player.jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().x
	var real_z = player.get_real_velocity().z - player.jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().z
	var real_y = player.get_real_velocity().y + player.jump_velocity * cos(player.get_floor_angle())
	player.velocity = Vector3(real_x, real_y, real_z)
	#Jump always the same velocity
	#player.velocity.y = player.jump_velocity
	player.gravity =- player.jump_gravity
	print("jump  ", player.velocity)
	
func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = get_horizontal_speed()
	var horizontal_velocity = horizontal_direction * horizontal_speed
	
	print(horizontal_speed)
	if horizontal_direction:
		if horizontal_speed > player.walk_top_speed:
			h = horizontal_direction * horizontal_speed
		else:
			h = horizontal_direction * player.walk_top_speed
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
		
		#Attempt to have a formula for turn_speed that makes the rotation finish when velocity reaches the desired direction
		var turn_speed := (get_horizontal_speed() / player.air_accel) * _delta
		#Handle if the player model will rotate to the input direction depending of player state
		player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y,
																	atan2(horizontal_direction.x, horizontal_direction.z),
																	5 * _delta)
	elif player.smash_air_decel:
		#Desaccelerate if there is no direction being input (optional)
		player.velocity.x = move_toward(player.velocity.x, 0, player.air_decel * _delta)
		player.velocity.z = move_toward(player.velocity.z, 0, player.air_decel * _delta)
	
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
	
	if Input.is_action_just_released("Jump"):
		print("soltei")
		player.gravity =- player.fall_gravity * 2
	
	elapsed += _delta
	
	if player.velocity.y <= 0:
		print("Jump Time to Peak: ", elapsed)
		elapsed = 0.0
		finished.emit(FALLING)
		
	
		#print(player._player_pivot.rotation.y, "  ", atan2(direction.x, direction.z))
	#print(player.horizontal_speed)
