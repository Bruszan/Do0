extends PlayerState

var grab_pos := Vector3.ZERO
var aim_direction := Vector3.ZERO

func enter(previous_state_path: String, data := {}) -> void:
	player.gravity = 0.0
	player.velocity = Vector3.ZERO
	printt("edgegrab", player._wall_raycast.get_collider(), player._hand_raycast.get_collider())
	player._gobot.edge_grab()
	
	grab_pos.x = player._wall_raycast.get_collision_point().x
	grab_pos.y = player._hand_raycast.get_collision_point().y - 0.75
	grab_pos.z = player._wall_raycast.get_collision_point().z
	player.position = grab_pos
	
	var wall_angle = atan2(player._wall_raycast.get_collision_normal().x, player._wall_raycast.get_collision_normal().z)
	player._player_pivot.rotate_y(player._player_pivot.rotation.angle_to(player._wall_raycast.get_collision_normal()) - PI/2)  

func physics_update(_delta: float) -> void:
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = player.get_horizontal_input()
	
	#printt(horizontal_input.dot(-player._wall_raycast.get_collision_normal()), horizontal_input, -player._wall_raycast.get_collision_normal())
	if horizontal_input.dot(player._wall_raycast.get_collision_normal()) > 0.0:
		var aim_angle = player._wall_raycast.get_collision_normal().signed_angle_to(horizontal_input, Vector3.UP)
		aim_direction = horizontal_input
		player._gobot.edge_aim(remap(aim_angle, -PI/2, PI/2, 0, 1))		
		#print(aim_angle)
	else:
		aim_direction = Vector3.ZERO
		player._gobot.edge_grab()
		
	if Input.is_action_just_pressed("Jump"):
		print(aim_direction)
		player.set_speed_to_direction(aim_direction, player.wall_jump_velocity, player.wall_jump_y_velocity)
		finished.emit(JUMPING)
	elif Input.is_action_pressed("Slide"):
		finished.emit(FALLING)
