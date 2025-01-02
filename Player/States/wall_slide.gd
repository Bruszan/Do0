extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.wall_slide()
	#player.vel_rotation = false
	printt("wall", player.get_wall_normal())
	player._player_pivot.global_rotation.y = atan2(player.get_wall_normal().x, player.get_wall_normal().z) + PI/2

func physics_update(_delta: float) -> void:
	Global.sakurai_jump_timer += _delta
	
	if player.velocity.y < 0:
		player.gravity = player.wall_fall_gravity
	elif Global.sakurai_jump_timer > player.sakurai_jump_duration:
		player.gravity = player.sakurai_jump_gravity
		
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	
	#printt(player._player_pivot.rotation.y,horizontal_input.dot(player.get_wall_normal()))
	
	if horizontal_input.dot(player.get_wall_normal()) > 0.0:
		player.set_collision_mask_value(1, false)
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(horizontal_input.x, player.velocity.y, horizontal_input.z), player.air_accel * _delta)
		
	if not player.is_on_wall() or Input.is_action_just_pressed("Slide") or player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Jump"): finished.emit(JUMPING)
	
func exit() -> void:
	if player.sakurai_jump: player.gravity = player.sakurai_gravity
	player.set_collision_mask_value(1, true)
	player.vel_rotation = true
