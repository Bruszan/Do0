extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.slide()
	printt("slide",player.get_horizontal_speed())
	#player.floor_snap_length = 1.0
	if player.get_horizontal_velocity():
		if player.get_horizontal_speed() <= player.ground_top_speed + player.slide_boost:
			if player.get_horizontal_speed() >= player.ground_top_speed:
				var actual_boost = player.ground_top_speed + player.slide_boost - player.get_horizontal_speed()
				player.add_horizontal_speed(actual_boost)
			else: player.add_horizontal_speed(player.slide_boost)
			printt("BOOST", player.get_horizontal_speed())
	#player.velocity = Vector3(player.velocity.x*player.slide_boost, player.velocity.y, player.velocity.z*player.slide_boost)

func transform_align_with_floor(floor_normal: Vector3):
	var xform : Transform3D
	xform = player._player_pivot.global_transform
	xform.basis.y = floor_normal
	xform.basis.x = -xform.basis.z.cross(floor_normal)
	xform.basis = xform.basis.orthonormalized()
	return xform

func physics_update(_delta: float) -> void:

	#With this it's accelerating without an max speed to apply
	#And also try to find a way to convert vertical velocity into horizontal when starting the slide
	#Vector3 value for substracting speed and getting slope physics, formula taken from Sonic physics (guide)
	var slide_accel = player.slope_factor * sin(player.get_floor_angle()) * -player.get_floor_normal() * _delta
	#print(slide_accel)
	if player.is_on_floor():
		if player.get_floor_angle():
			#Accelerates non-stop with slide_accel, 
			player.velocity -= Vector3(slide_accel.x, player.velocity.y, slide_accel.z)
		else:
			player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.slide_friction * _delta)
	
		var slide_friction = player.slope_factor * player.get_floor_angle()
		#The max speed when sliding, based on the slope angle
		#Accelerate until it reaches slide_speed
		#player.velocity = player.velocity.move_toward(Vector3(slide_speed.x, player.velocity.y, slide_speed.z), slide_friction * _delta)
	
	#Slide script so that it can also be used as a drift to change the player's direction while maintaining speed
	#Input for the player to drift while sliding
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = player._camera_pivot.global_basis.z * input_dir.y + player._camera_pivot.global_basis.x * input_dir.x
	
	##Rotating the player's velocity for drifting
	#For rotating the player's velocity to the direction being input like this, the turn speed is dependant on the current velocity
	#var h = horizontal_input * player.get_horizontal_speed()
	#player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.drift_turn_speed * _delta)
	
	#With this the velocity rotates constantly based on input related to the player's direction
	#Take note that turn_cap is the cap of the horizontal input angle the player can input (related to the player's direction) to reach max turn speed
	var turn_cap = PI/4
	var clamp_ang = clamp(remap(player.velocity.signed_angle_to(horizontal_input, Vector3.UP), -turn_cap, turn_cap, -1, 1), -1, 1)
	player.velocity = player.velocity.rotated(Vector3.UP, clamp_ang * player.drift_turn_factor * _delta)
	
	#The horizontal direction which the player will rotate to, in this case, velocity
	#var velocity_dir = atan2(player.velocity.x, player.velocity.z)
	#player._player_pivot.rotation.y = velocity_dir
	
	var angle_normal = -player.get_floor_normal() * player.get_floor_angle()
	##This should be a better way to rotate the player based on the floor normal because it only affects the rotation
	#player._player_pivot.rotation = Vector3(player.get_floor_normal().x, velocity_dir, player.get_floor_normal().z)
	##But I don't know how to get the rotation value for x and z yet, so I'm sticking with BornCG's method that affects the entire transform
	if player.is_on_floor(): player._player_pivot.global_transform = transform_align_with_floor(player.get_floor_normal())
	
	if player.velocity == Vector3.ZERO and not Global.paused:
		finished.emit(IDLE)
	elif Input.is_action_just_pressed("Slide"):
		finished.emit(RUNNING)
	elif InputBuffer.is_action_press_buffered("Jump"):
		finished.emit(JUMPING)
	elif not player.is_on_floor():
		print(player.velocity.y)
		player.gravity =- player.fall_gravity
		#finished.emit(FALLING)
	elif Global.on_water:
		finished.emit(DIVING)
		
func exit() -> void:
	player._player_pivot.global_transform = transform_align_with_floor(Vector3.UP)
