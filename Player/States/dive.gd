extends PlayerState

# The swim controls just like Genshin Impact, the player can move on all horizontal directions
# and the vertical direction is based on camera pitch or a button press

var swim_input := Vector3.ZERO
var vertical_angle := 0.0
var v_rot_angle := 0.0

func enter(previous_state_path: String, data := {}) -> void:
	player.set_motion_mode(1)
	#player._gobot.dive()
	printt("dive")
	player._camera_pivot.position.y = 2.0
	player.rotate_speed = player.swim_rot_turn
	
	
func physics_update(_delta: float) -> void:
	# Handle the animation and rotation
	if player.velocity.length() >= 0.5: 
		player._gobot.swim()
		#Rotate the player based on its verticality
		# Find the angle the player should rotate to
		v_rot_angle =- atan2(player.velocity.y, Vector3(player.velocity.x, 0, player.velocity.z).length())
		player._player_pivot.rotation.x = lerp(player._player_pivot.rotation.x, v_rot_angle, player.swim_rot_turn * _delta)
	else: 
		player._gobot.float()
		player._player_pivot.rotation.x = lerp(player._player_pivot.rotation.x, 0.0, 5 * _delta)
	
	# Handle the velocity
	if swim_input and player.velocity.length() <= player.ground_top_speed:
		printt(swim_input.length(), swim_input, v_rot_angle, player._camera_pitch.rotation.x)
		player.velocity = player.velocity.move_toward(swim_input * player.swim_speed, player.ground_accel * _delta)
		#printt(swim_input, player.velocity)
	else: player.velocity = player.velocity.move_toward(Vector3.ZERO, player.swim_friction * _delta)
	
	#Change states
	if not Global.on_water:
		player.set_motion_mode(0)
		player.velocity.y = 0.0
		if player.is_on_floor(): finished.emit(RUNNING)
		elif Input.is_action_pressed("Slide"): player.velocity.y =- player.swim_speed
		elif Input.is_action_just_pressed("Jump"):
			finished.emit(JUMPING)
		
## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	# Grab the axis separately so that it's not normalized
	var input_xdir = Input.get_axis("Left", "Right")
	var input_ydir = Input.get_axis("Forward", "Back")
	
	# Get the horizontal input direction
	var h_input_length = Input.get_vector("Left", "Right", "Forward", "Back", 0.1).length()
	#var h_input_length = Vector2(input_xdir, input_ydir).normalized().length()
	# Have the camera pitch influence the vertical input based on the forward an back input
	var vertical_input = input_ydir * sin(player._camera_pitch.rotation.x)
	# Multiply so that it ascends and descends the same as the movement input
	vertical_input *= h_input_length
	
	# Adjusting only the forward and back input to the camera pitch for the horizontal input
	input_ydir *= cos(player._camera_pitch.rotation.x)
	var horizontal_input = -player._camera_pivot.global_basis.z * input_ydir + -player._camera_pitch.global_basis.x * input_xdir
	
	# Adding the horizontal velocity
	swim_input = horizontal_input
	
	# Overwrite the vertical input if one of those buttons are pressed
	# Normalizing with the already set horizontal swim input, max length will be 0.5
	if Input.is_action_pressed("Jump"):
		vertical_input = 1
	if Input.is_action_pressed("Slide"):
		vertical_input = -1
	# Deadzone to avoid vertical input that is not intended
	#if vertical_input < 0.1 and vertical_input > -0.1: vertical_input = 0.0
	
	# Adding the vertical velocity
	swim_input.y = vertical_input
	
	# Normalize it at last
	swim_input = swim_input.normalized()
	
	# Multiply the horizontal swim_input by the horizontal input length
	swim_input *= Vector3(h_input_length, 1.0, h_input_length)
	#printt(h_input_length, input_ydir)
	#v_rot_angle =- swim_input.y * PI/2
	#v_rot_angle =- atan2(vertical_input, Vector3(swim_input.x, 0, swim_input.z).length())

func exit() -> void:
	player.set_motion_mode(0)
	player._player_pivot.rotation.x = 0.0
	player._camera_pivot.position.y = player._camera_pivot.initial_height
	
	player.velocity.y = 0
	player.rotate_speed = 30.0
