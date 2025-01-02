extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.idle()
	printt("idle")

func physics_update(_delta: float) -> void:
	player.velocity = player.velocity.move_toward(Vector3.ZERO, player.ground_friction)
	
	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("Left") or Input.is_action_pressed("Right") or Input.is_action_pressed("Forward") or Input.is_action_pressed("Back"):
		finished.emit(RUNNING)
	elif Input.is_action_pressed("Slide") and player.get_floor_angle():
		finished.emit(SLIDING)
	elif Global.on_water:
		finished.emit(DIVING)
