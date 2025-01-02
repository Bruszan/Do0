extends PlayerState

var h := Vector3.ZERO

func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func physics_update(_delta: float) -> void:

	var horizontal_input = player.get_horizontal_input()
	#var horizontal_input = player._camera.global_basis.x * input_dir.y + player._camera.global_basis.x * input_dir.x
	#horizontal_input.y = 0.0
	#horizontal_input = horizontal_input.normalized()
	#Normalize is making analog range being wrong
	var horizontal_speed = player.get_horizontal_speed()
	#print(horizontal_input.x)
	
	#print(horizontal_velocity, "  |  ", player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001)))
	#Handle which animation will be played
	if horizontal_speed/player.ground_top_speed > 0.5: player._gobot.run()
	else: player._gobot.walk()
	
	if horizontal_input:
		#Tries to get the desired speed
		#Assign a variable before so that velocity can change on all axis at the same time using Vector3 move_toward()
		h = horizontal_input * player.ground_top_speed
		# This is incase you want the player to maintain over the top speed
		#if horizontal_speed <= player.ground_top_speed:
			#h = horizontal_input * player.ground_top_speed
		#else:
			#h = horizontal_input * horizontal_speed
		
		if horizontal_input.dot(player.velocity) <= 0.0:
			# player is trying to move away
			#print("desacelera   ", player.velocity.move_toward(Vector3(h.x, 0, h.z), _delta).length())
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_decel * _delta)
		elif horizontal_speed >= player.ground_top_speed:
			# player is moving over the top ground speed
			# make it go back to top ground speed by groud friction value
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_friction * _delta) 
		else:
			# player is moving toward velocity
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_accel * _delta) 
		
			
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
	elif player.velocity == Vector3.ZERO and not Global.paused:
		finished.emit(IDLE)
	elif Global.on_water:
		finished.emit(DIVING)
