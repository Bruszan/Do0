extends PlayerState

func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	var horizontal_velocity = horizontal_direction * horizontal_speed
	
	#Handle which animation will be played
	if horizontal_speed/player.walk_top_speed > 0.5: player._gobot.run()
	else: player._gobot.walk()
	
	if horizontal_direction:
		##Condition to have the player rotation snap when not moving
		#if player.velocity.x <= 1 and player.velocity.z <= 1:
			#player._player_pivot.rotation.y = atan2(direction.x, direction.z)
		#else:
		#The direction which the player will rotate to
		var rotate_dir = atan2(horizontal_direction.x, horizontal_direction.z)
		player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 25 * _delta)
			
	#Tries to get the desired speed
	#Assign a variable before so that velocity can change on all axis at the same time using Vector3 move_toward()
	var h = horizontal_direction * player.walk_top_speed
	
	if horizontal_direction:
		if player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), _delta).length() >= horizontal_speed:
			#print("acelera")
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.accel * _delta)
		else:
			#print("desacelera")
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.decel * _delta)
	else:
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.friction * _delta)
		
	print(get_horizontal_speed())
	
	if Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif not player.is_on_floor():
		finished.emit(FALLING)
	elif player.velocity == Vector3.ZERO:
		finished.emit(IDLE)
