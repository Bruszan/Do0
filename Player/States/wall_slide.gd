extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.wall_slide()
	player.rotation_dir = player.Rotation_Dir.NOTHING
	printt("wall", player.get_wall_normal())
	player._player_pivot.global_rotation.y = atan2(player.get_wall_normal().x, player.get_wall_normal().z) - PI

func physics_update(_delta: float) -> void:
	#printt(player._player_pivot.rotation.y,horizontal_input.dot(player.get_wall_normal()))
	var real_velo = player.get_real_velocity().normalized()
	player.velocity.x -= real_velo.x * player.wall_friction * _delta
	player.velocity.z -= real_velo.z * player.wall_friction * _delta
	#player.velocity.y -= player.wall_friction * _delta
	
	if player.is_on_floor(): finished.emit(RUNNING)
	elif not player.is_on_wall() or player.h_input.dot(player.get_wall_normal()) >= 0.0: finished.emit(FALLING)
	elif Input.is_action_just_pressed("Jump"): finished.emit(WALL_JUMPING)
	
	
func exit() -> void:
	player.rotation_dir = player.Rotation_Dir.VELOCITY
