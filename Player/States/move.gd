extends PlayerState

func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	var horizontal_velocity = horizontal_input * horizontal_speed
	#print(horizontal_input.x)
	
	#print(horizontal_velocity, "  |  ", player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001)))
	#Handle which animation will be played
	if horizontal_speed/player.ground_top_speed > 0.5: player._gobot.run()
	else: player._gobot.walk()
	
	if horizontal_input:
		#Condition to have the player rotation snap when not moving
		#if player.velocity.x <= 1 and player.velocity.z <= 1:
			#player._player_pivot.rotation.y = atan2(direction.x, direction.z)
		#else:
		#The direction which the player will rotate to
		#var rotate_dir = atan2(horizontal_input.x, horizontal_input.z)
		#player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 25 * _delta)
			
		#Tries to get the desired speed
		#Assign a variable before so that velocity can change on all axis at the same time using Vector3 move_toward()
		var h = horizontal_input * player.ground_top_speed
		horizontal_speed = get_horizontal_speed()
	
		#var real_velo = player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001))
		#var real_x = real_velo.x / cos(player.get_floor_angle()) * -player.get_floor_normal().x
		#var real_z = real_velo.z / cos(player.get_floor_angle()) * -player.get_floor_normal().z
		#var real_y = real_velo.y / -sin(player.get_floor_angle())
		
		if horizontal_input.dot(player.velocity) >= 0.0:
			# player is moving toward velocity
			if horizontal_speed <= player.ground_top_speed:
				#print("acelera   ",  player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_accel * _delta).length())
				player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_accel * _delta)
			else:
				print("muy rapido")
				player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_friction * _delta) 
		else:
			# player is trying to move away
			#print("desacelera   ", player.velocity.move_toward(Vector3(h.x, 0, h.z), _delta).length())
			player.velocity = Vector3.ZERO
			#player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_decel * _delta)
	else:
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.ground_friction * _delta)
		
	#if player.get_floor_angle():
		#player.velocity *= Vector3.UP.direction_to(player.get_floor_normal())
	#print(get_horizontal_speed())
	
	if Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_just_pressed("Slide"):
		finished.emit(SLIDING)
	elif not player.is_on_floor():
		finished.emit(FALLING)
	elif player.velocity == Vector3.ZERO:
		finished.emit(IDLE)
	elif Global.on_water:
		finished.emit(DIVING)
