extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.idle()

func physics_update(_delta: float) -> void:
	player.velocity = player.velocity.move_toward(Vector3.ZERO, player.ground_friction * _delta)
	
	if InputBuffer.is_action_press_buffered("Jump"):
		finished.emit(JUMPING)
	elif not player.is_on_floor():
		finished.emit(FALLING)
	elif player.h_input:
		finished.emit(RUNNING)
	elif Input.is_action_pressed("Slide") and player.get_floor_angle():
		finished.emit(SLIDING)
	elif Global.on_water:
		finished.emit(DIVING)
