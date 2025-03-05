extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.wall_slide()
	player.rotation_dir = player.Rotation_Dir.NOTHING
	printt("wall", player.get_wall_normal())
	player._player_pivot.global_rotation.y = atan2(player.get_wall_normal().x, player.get_wall_normal().z) + PI/2

func physics_update(_delta: float) -> void:
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	
	
	#printt(player._player_pivot.rotation.y,horizontal_input.dot(player.get_wall_normal()))
	
	if horizontal_input.dot(player.get_wall_normal()) > 0.0:
		player.set_collision_layer_value(1, false)
		var h = horizontal_input * player.ground_top_speed
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
		#Apply the aerial movement
		
	player.velocity -= player.get_real_velocity().normalized() * player.wall_friction * _delta
	
	if not player.is_on_wall() or Input.is_action_just_pressed("Slide") or player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_released("Jump"): finished.emit(JUMPING)
	
func exit() -> void:
	player.gravity = player.fall_gravity
	player.set_collision_layer_value(1, true)
	player.rotation_dir = player.Rotation_Dir.VELOCITY
