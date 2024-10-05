extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.wall_slide()
	
	printt("wall", player.get_wall_normal())
	player._player_pivot.global_rotation.y = Vector3.UP.angle_to(player.get_wall_normal())

func update(_delta: float) -> void:
	Global.sakurai_jump_timer += _delta
	
	if player.velocity.y < 0:
		player.gravity = player.wall_fall_gravity
	elif Global.sakurai_jump_timer > player.sakurai_jump_duration:
		player.gravity = player.sakurai_jump_gravity
		
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	
	printt(player._player_pivot.rotation.y,horizontal_input.dot(player.get_wall_normal()))
	if not player.is_on_wall() or horizontal_input.dot(player.get_wall_normal()) > 0.0:
		if player.is_on_floor(): finished.emit(IDLE)
		else: finished.emit(FALLING)
	elif Input.is_action_just_pressed("Jump"): finished.emit(JUMPING)
	
func exit() -> void:
	if player.sakurai_jump: player.gravity = player.sakurai_gravity
