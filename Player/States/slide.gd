extends PlayerState

var initial_velocity := Vector3.ZERO

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.slide()
	print(player.get_horizontal_speed())
	print("slide")
	if player.get_horizontal_speed() <= player.ground_top_speed:
		print("BOOOST")
		#player.add_horizontal_speed(player.slide_boost)
		print(player.get_horizontal_speed())
	#player.velocity = Vector3(player.velocity.x*player.slide_boost, player.velocity.y, player.velocity.z*player.slide_boost)
	initial_velocity = player.velocity

func update(_delta: float) -> void:
	#With this it's accelerating without an max speed to apply
	#And also try to find a way to convert vertical velocity into horizontal when starting the slide
	#Vector3 value for substracting speed and getting slope physics, formula taken from Sonic physics
	var slide_accel = player.slope_factor * sin(player.get_floor_angle()) * -player.get_floor_normal() * _delta
	#print(slide_accel)
	if player.get_floor_angle():
		#Accelerates non-stop with slide_accel, 
		player.velocity -= Vector3(slide_accel.x, player.velocity.y, slide_accel.z)
	else:
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.slide_friction * _delta)
	
	var slide_friction = player.slope_factor * player.get_floor_angle()
	#The max speed when sliding, based on the slope angle
	#Accelerate until it reaches slide_speed
	#player.velocity = player.velocity.move_toward(Vector3(slide_speed.x, player.velocity.y, slide_speed.z), slide_friction * _delta)
	
	#The direction which the player will rotate to
	var rotate_dir = atan2(player.velocity.x, player.velocity.z)
	player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 25 * _delta)
	
	#Slide script so that it can also be used as a drift to change the player's direction while maintaining speed
	#Input for the player to drift while sliding
	var input_vec = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var input_vec3 = Vector3(input_vec.x, 0 , input_vec.y)
	var horizontal_input = Vector3(input_vec.x, 0, input_vec.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	var input_dir = atan2(input_vec.x, input_vec.y)
	var slide_dir = atan2(horizontal_input.x, horizontal_input.y)
	var rotation_dir = atan2(player.rotation.x, player.rotation.z)
	var current_dir = atan2(player.velocity.x, player.velocity.z)
	var vel_vector = player.velocity.rotated(Vector3.UP, slide_dir)
	
	#For rotating the player's velocity to the direction being input, the turn speed is dependant on the current velocity
	#var h = horizontal_input * player.get_horizontal_speed()
	#player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.drift_turn_speed * _delta)
	
	#player.velocity = player.velocity.move_toward(player.velocity.rotated(Vector3.UP, player.velocity.angle_to(horizontal_input)), player.drift_turn_speed * _delta)
	printt("debug", sign(input_vec.x), player.velocity.angle_to(horizontal_input), player.velocity.angle_to(horizontal_input)*sign(input_vec.x))
	var clamp_ang = clamp(remap(player.velocity.angle_to(horizontal_input)*sign(input_vec.x), -PI/2, PI/2, -1, 1), -1, 1)
	#var clamp_ang = clamp(player.velocity.angle_to(horizontal_input) / (PI/2*sign(horizontal_input.x)), -1, 1)
	#printt(horizontal_input.x, player.velocity.angle_to(horizontal_input), clamp_ang)
	player.velocity = player.velocity.rotated(Vector3.UP, -clamp_ang * player.drift_turn_speed * _delta)
	#printt(player.get_horizontal_speed(), -clamp_ang * player.drift_turn_speed * _delta)
	
	if player.velocity == Vector3.ZERO:
		finished.emit(IDLE)
	elif Input.is_action_just_pressed("Slide"):
		finished.emit(RUNNING)
	elif Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif not player.is_on_floor():
		print("euvocair")
		finished.emit(FALLING)
