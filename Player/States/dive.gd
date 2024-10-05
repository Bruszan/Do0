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
	
	
func update(_delta: float) -> void:
	
	if swim_input:
		player._gobot.swim()
		printt(swim_input.length(), swim_input, v_rot_angle, player._camera_pitch.rotation.x)
		#Rotate the player based on its verticality
		player._player_pivot.rotation.x = lerp(player._player_pivot.rotation.x, v_rot_angle, player.swim_turn * _delta)
		player.velocity = player.velocity.move_toward(swim_input * player.swim_speed, player.ground_accel * _delta)
		#printt(swim_input, player.velocity)
	else: 
		player._gobot.float()
		player._player_pivot.rotation.x = lerp(player._player_pivot.rotation.x, 0.0, 5 * _delta)
		player.velocity = player.velocity.move_toward(Vector3.ZERO, player.swim_friction * _delta)
		
	#Change states
	if not Global.on_water:
		finished.emit(FALLING)

## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	# Get the horizontal input direction
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	# Grab the axis separately so that it's not normalized
	var input_xdir = Input.get_axis("Left", "Right")
	var input_ydir = Input.get_axis("Forward", "Back")
	# Have the camera pitch influence the vertical input based on the forward an back input
	var vertical_input =- input_ydir * sin(player._camera_pitch.rotation.x)
	
	# Adjusting only the forward and back input to the camera pitch for the horizontal input
	input_ydir *= cos(player._camera_pitch.rotation.x)
	var horizontal_input = Vector3(input_xdir, 0, input_ydir).rotated(Vector3.UP, player._camera_pivot.rotation.y)
	
	# Adding the horizontal velocity
	swim_input = horizontal_input

	# Descobrir o cosseno apenas com o vetor x (horizontal)
	var cos = horizontal_input.length()/sqrt(pow(horizontal_input.length(), 2))
	# Descobrir o seno sabendo o valor desse cosseno
	var sin = sqrt(1-pow(cos, 2))
	
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
	
	# Find the angle the player should rotate to
	v_rot_angle =- atan2(swim_input.y, Vector3(swim_input.x, 0, swim_input.z).length())
	#v_rot_angle =- swim_input.y * PI/2

func exit() -> void:
	player.set_motion_mode(0)
	player._player_pivot.rotation.x = 0.0
	player._camera_pivot.position.y = player._camera_pivot.initial_height
	
	player.velocity.y = 0
