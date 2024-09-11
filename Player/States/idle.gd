extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player._gobot.idle()
	print("idle")

func update(_delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, player.ground_friction)
	player.velocity.z = move_toward(player.velocity.z, 0, player.ground_friction)
	
	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_just_pressed("Jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("Left") or Input.is_action_pressed("Right") or Input.is_action_pressed("Forward") or Input.is_action_pressed("Back"):
		finished.emit(RUNNING)
