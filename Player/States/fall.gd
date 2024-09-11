extends PlayerState

var elapsed := 0.0
var h := Vector3.ZERO
var fall_speed := 0.0

func enter(previous_state_path: String, data := {}) -> void:
	player.gravity =- player.fall_gravity
	print("fall")

func get_horizontal_speed() -> float:
	return Vector3(player.velocity.x, 0, player.velocity.z).length()

func update(_delta: float) -> void:
	elapsed += _delta
	if player.is_on_floor():
		print("chão  ", player.velocity.y)
		print("Jump Time to Descent: ", elapsed)
		elapsed = 0.0
		if Input.is_action_pressed("Slide"):
			printt("fall",player.get_horizontal_speed())
			var slide_speed = fall_speed * player.fall_to_slide_factor * sin(player.get_floor_angle()) * -player.get_floor_normal() * get_process_delta_time()
			player.velocity += Vector3(slide_speed.x, 0, slide_speed.z)
			finished.emit(SLIDING)
		elif player.velocity:
			finished.emit(RUNNING)
		else:
			finished.emit(IDLE)
			
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	var horizontal_input = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	#Normalize is making analog range being wrong
	var horizontal_speed = get_horizontal_speed()
	var horizontal_velocity = horizontal_input * horizontal_speed
	
	#print(horizontal_speed)
	if horizontal_input:
		if horizontal_speed > player.ground_top_speed:
			h = horizontal_input * horizontal_speed
		else:
			h = horizontal_input * player.ground_top_speed
		#Apply the aerial movement
		player.velocity = player.velocity.move_toward(Vector3(h.x, player.velocity.y, h.z), player.air_accel * _delta)
		
		var rotate_dir = atan2(player.velocity.x, player.velocity.z)
		player._player_pivot.rotation.y = lerp_angle(player._player_pivot.rotation.y, rotate_dir, 30 * _delta)
	elif player.smash_air_decel:
		#Desaccelerate if there is no direction being input (optional)
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), player.air_decel * _delta)
		
	#This is the first script I tried that seemed to replicate Odyseey's Vectoring technique
	#player.velocity.x = clampf(player.velocity.x + horizontal_direction.x * player.air_accel, -player.walk_speed, player.walk_speed)
	#player.velocity.z = clampf(player.velocity.z + horizontal_direction.z * player.air_accel, -player.walk_speed, player.walk_speed)
		#print(player._player_pivot.rotation.y, "  ", atan2(direction.x, direction.z))
		
	fall_speed = player.velocity.y
