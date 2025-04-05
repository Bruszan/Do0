extends PlayerState

var h := Vector3.ZERO
var accel_stable := 0.0
var bonus_speed : float
var horizontal_speed : float

func enter(previous_state_path: String, data := {}) -> void:
	horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	
	player._gobot.set_head_target(player._direction_target.get_path(), 4, -0.5)

func physics_update(_delta: float) -> void:
	if player.base_speed and horizontal_speed < player.base_speed: 
		player.velocity = player.get_horizontal_input().normalized() * player.base_speed
		print("base speed", Vector3(player.velocity.x, 0, player.velocity.z).length())
	Global.debug.add_debug_property("Bonus Speed", bonus_speed, 1)
	horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()
	#var horizontal_input = player._camera.global_basis.x * input_dir.y + player._camera.global_basis.x * input_dir.x
	#horizontal_input.y = 0.0
	#horizontal_input = horizontal_input.normalized()
	#Normalize is making analog range being wrong
	
	#print(horizontal_velocity, "  |  ", player.get_real_velocity().snapped(Vector3(0.001, 0.001, 0.001)))
	#Handle which animation will be played
	if horizontal_speed/player.ground_top_speed > 0.5: player._gobot.run()
	else: player._gobot.walk()
	
	bonus_speed = horizontal_speed - player.ground_top_speed if horizontal_speed > player.ground_top_speed else 0.0
	
	if player.h_input:
		# Make the DirectionTarget node go to the input direction, so that the head can follow it
		player._direction_target.position = player.h_input.normalized()
		
		bonus_speed = max(bonus_speed - player.overspeed_decel * _delta, 0.0)
		#Tries to get the desired speed
		#Assign a variable before so that velocity can change on all axis at the same time using Vector3 move_toward()
		h = player.h_input * (player.ground_top_speed + bonus_speed)
		# This is incase you want the player to maintain over the top speed
		#if horizontal_speed <= player.ground_top_speed:
			#h = horizontal_input * player.ground_top_speed
		#else:
			#h = horizontal_input * horizontal_speed
		
		if player.h_input.dot(player.velocity) <= 0.0:
			# player is trying to move away from velocity
			#print("desacelera   ", player.velocity.move_toward(Vector3(h.x, 0, h.z), _delta).length())
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_decel * _delta)
		else:
			#print("acelera   ", player.velocity.move_toward(Vector3(h.x, 0, h.z), _delta).length())
			# player is moving toward velocity
			player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.ground_accel * _delta)
	else:
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.ground_friction * _delta)
	
	
	if InputBuffer.is_action_press_buffered("Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_just_pressed("Slide"):
		finished.emit(SLIDING)
	elif not player.is_on_floor():
		finished.emit(FALLING)
	elif player.velocity == Vector3.ZERO:
		finished.emit(IDLE)
	elif Global.on_water:
		finished.emit(DIVING)
		
func exit() -> void:
	player._gobot.clear_head_target()
