extends PlayerState

func update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	var horizontal_velocity = horizontal_direction * horizontal_speed
	
	#Handle which animation will be played
	if horizontal_speed/player.walk_speed > 0.5: player._gobot.run()
	else: player._gobot.walk()
	
	if horizontal_direction:
		##Condition to have the player rotation snap when not moving
		#if player.velocity.x <= 1 and player.velocity.z <= 1:
			#player._player_pivot.rotation.y = atan2(direction.x, direction.z)
		#else:
		#The direction which the player will rotate to
		var rotate_dir = atan2(horizontal_direction.x, horizontal_direction.z)
		player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 25 * _delta)
		
		#print(horizontal_direction.x * player.walk_speed, "  ", horizontal_speed)
		
		#Desaccelerate the player if he's over the max speed on the ground
		#The correct thing would be for this to work only when the player is trying to gain more speed
		
			#player.velocity = horizontal_direction * player.walk_speed
			#This one below has acceleration but decreases speed when turning
	player.velocity = player.velocity.move_toward(horizontal_direction * player.walk_speed, player.accel * _delta)
	
	print(horizontal_speed)
	if Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif not player.is_on_floor():
		finished.emit(FALLING)
	elif player.velocity.x == 0 and player.velocity.z == 0:
		finished.emit(IDLE)
		
	#print(player.horizontal_speed)
