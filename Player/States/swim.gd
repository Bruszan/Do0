extends PlayerState

var h := Vector3.ZERO

func enter(previous_state_path: String, data := {}) -> void:
	#player._gobot.swim()
	printt("swim")

func physics_update(_delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = -player._camera_pivot.global_basis.z * input_dir.y + -player._camera_pitch.global_basis.x * input_dir.x
	#Normalize is making analog range being wrong
	var horizontal_speed = Vector3(player.velocity.x, 0, player.velocity.z).length()

	
	if horizontal_input:
		#Not using this since the main script is already handling rotation based on velocity
		#player._player_pivot.rotation = Vector3(player._camera_pivot.rotation.x, player._camera_pitch.rotation.y, player._camera_pivot.rotation.z)
		h = horizontal_input * player.swim_speed

		player.velocity = player.velocity.move_toward(Vector3(h.x, h.y, h.z), player.air_accel * _delta)
	else:
		player.velocity = player.velocity.move_toward(Vector3.ZERO, player.swim_friction * _delta)
	
	#Change states
	if Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)

func exit() -> void:
	player.set_motion_mode(0)
	player._player_pivot.rotation = Vector3.ZERO
