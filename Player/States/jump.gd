extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO

func enter(previous_state_path: String, data := {}) -> void:
	print("squat  ", player.get_horizontal_speed())
	#Changes velocity depending on the ground angle (Sonic physics)
	#Probably only makes sense if there is also physics on slopes when moving
	#That's why this will probably be only used when sliding, which will have slope physics
	if previous_state_path == "Slide" and player.get_floor_angle():
		print(true)
		var real_velo = player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001))
		var real_x = real_velo.x - player.jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().x
		var real_z = real_velo.z - player.jump_velocity * sin(player.get_floor_angle()) * -player.get_floor_normal().z 
		var real_y = real_velo.y + player.jump_velocity * cos(player.get_floor_angle())
		player.velocity = Vector3(real_x, real_y, real_z)
	else:
		#Jump always the same velocity
		player.velocity.y = player.jump_velocity
	print("jump  ", player.get_horizontal_speed())
	player.gravity =- player.jump_gravity
	
func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
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
		
		var rotate_dir = atan2(player.velocity.x, player.velocity.z)
		player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 30 * _delta)
	elif player.smash_air_decel:
		#Desaccelerate if there is no direction being input (optional)
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.air_decel * _delta)
	
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
	
	if Input.is_action_just_released("Jump"):
		print("soltei")
		player.gravity =- player.fall_gravity * 2
	
	elapsed += _delta
	
	if player.velocity.y <= 0:
		print(player.position.y, " Jump Time to Peak: ", elapsed)
		elapsed = 0.0
		finished.emit(FALLING)
	elif player.is_on_floor():
		if Input.is_action_pressed("Slide"):
			finished.emit(SLIDING)
		if player.velocity.x == 0 and player.velocity.z == 0:
			finished.emit(IDLE)
		else:
			finished.emit(RUNNING)
		
	
		#print(player._player_pivot.rotation.y, "  ", atan2(direction.x, direction.z))
	#print(player.horizontal_speed)
