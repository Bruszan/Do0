class_name Player extends CharacterBody3D

@onready var _player_pivot = $PlayerPivot
@onready var _gobot = $PlayerPivot/GobotSkin
@onready var _skeleton = $PlayerPivot/GobotSkin/gobot/Armature/Skeleton3D
@onready var _camera_pivot = $CameraTwist
@onready var _camera_pitch = $CameraTwist
@onready var _camera = $CameraTwist/SpringArm3D/Camera3D

@onready var _wall_raycast = $PlayerPivot/WallRayCast3D
@onready var _hand_raycast = $PlayerPivot/HandRayCast3D

@onready var _water_detector = $WaterDetection
# This enum lists all the possible states the character can be in.
enum States {IDLE, RUNNING, JUMPING, FALLING, WALLING, EDGING}

# This variable keeps track of the character's current state.
var state: States = States.IDLE

var temp_velocity := Vector3.ZERO
@export var rotate_speed := 40.0
var velocity_dir := 0.0

@export_group("Ground Movement Parameters")
@export var ground_top_speed := 30.0
@export var ground_accel := 80.0
@export var ground_decel := 160.0
@export var ground_friction := 80.0
## Speed is reduced by this value per second when over the top ground speed
@export var overspeed_decel := 30

@export_group("Jump Parameters")

@export var jump_height := 7.2
@export var jump_time_to_peak := 0.39
@export var jump_time_to_descent := 0.43

## The jump presented in Sakurai's games. See his video on Jump mechanics to know more
@export var sakurai_jump := false
@export var sakurai_jump_velocity := 24.0
## The default is the same as Smash Ultimate
@export var sakurai_jump_duration := (1.0 / 60.0) * 4.0
@export var sakurai_jump_gravity := 120.0
@export var sakurai_gravity := 80.0

@export_group("Air Movement Parameters")
@export var air_accel := ground_accel
##Deceleration in the air if there is no input
@export var has_air_friction := false
@export var air_friction := 10.0

@onready var jump_velocity := (jump_height * 2.0) / jump_time_to_peak
@onready var jump_gravity := (jump_height * -2.0) / pow(jump_time_to_peak, 2)
@onready var fall_gravity := (jump_height * -2.0) / pow(jump_time_to_descent, 2)

@export_group("Slide Parameters")
@export var fall_to_slope_factor := 2.0
#@export var jump_slope_velocity := 50.0
@export var slope_factor := 50.0
@export var slide_boost := 10.0
@export var slide_friction := 2.0
@export var drift_turn_factor := 1.2

@export_group("Wall Jump Parameters")
@export var wall_fall_gravity := 10.0
@export var wall_jump_y_velocity := 8.0
@export var wall_jump_velocity := 10.0

@export_group("Swimming Parameters")
@export var swim_speed := 10.0
@export var swim_friction := 100.0
@export var swim_rot_turn := 2.0

@onready var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)

@onready var horizontal_direction := horizontal_velocity.normalized()
@onready var horizontal_speed := Vector3(velocity.x, 0, velocity.z).length()

var direction := Vector3(0.0, 0.0, 0.0)
var elapsed := 0.0
var camera_reset := false
var ang_base := 0.0
var r_direction := Vector3(0.0, 0.0, 0.0)
var aim_direction := 0.0
var shoot_mode := false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var world_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity := jump_gravity

func _ready():
	_hand_raycast.set_process(false)
	print("fatherson")
	
func _process(delta):
	pass

func get_horizontal_input() -> Vector3:
	var raw_input = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	return -Vector3(raw_input.x, 0, raw_input.y).rotated(Vector3.UP, _camera_pivot.rotation.y)

func _get_camera_oriented_input() -> Vector3:
	var raw_input = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)

	var input := Vector3.ZERO
	# This is to ensure that diagonal input isn't stronger than axis aligned input
	input.x = -raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = -raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)

	input = _camera_pivot.global_transform.basis * input
	input.y = 0.0
	return input

func get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0, velocity.z)
	
func get_horizontal_speed() -> float:
	return Vector3(velocity.x, 0, velocity.z).length()

func add_horizontal_speed(speed: float) -> void:
	var speedx = velocity.x + velocity.x / get_horizontal_speed() * speed
	var speedz = velocity.z + velocity.z / get_horizontal_speed() * speed
	velocity = Vector3(speedx, velocity.y, speedz)
	
func set_speed_to_direction(h_direction: Vector3, xspeed: float, yspeed: float) -> void:
	velocity = Vector3(h_direction.x * xspeed, yspeed, h_direction.z * xspeed)
func add_speed_to_direction(h_direction: Vector3, xspeed: float, yspeed: float) -> void:
	velocity = get_real_velocity() + Vector3(h_direction.x * xspeed, yspeed, h_direction.z * xspeed)

#func cap_horizontal_speed(speed_cap: float) -> void:
	#var cappedx = velocity.x / get_horizontal_speed() * speed_cap
	#var cappedz = velocity.z / get_horizontal_speed() * speed_cap
	#velocity = Vector3(cappedx, velocity.y, cappedz)
	
func _physics_process(delta):
	Global.debug.add_debug_property("Velocity", velocity, 1)
	Global.debug.add_debug_property("Speed", Vector3(velocity.x, 0, velocity.z).length(), 1)
	# Add the gravity.
	if not is_on_floor() and not Global.on_water:
		velocity.y -= gravity * delta

	move_and_slide()
	#Rotate the player to its velocity direction
	if get_horizontal_velocity():
		velocity_dir = atan2(velocity.x, velocity.z)
	if velocity_dir != _player_pivot.rotation.y:
		_player_pivot.rotation.y = lerp_angle(_player_pivot.rotation.y, velocity_dir, rotate_speed*delta)
	##Old script below
	
	#Enters camera's shoot mode when shooting, like in Risk of Rain 2
	#if shoot_mode:
		#elapsed += delta
		#print(elapsed)
		#if elapsed <= 3:
			#$Global.camera_mode = "strafe"
		#else: 
			#elapsed = 0.0
			#$Global.camera_mode = "free"
			#shoot_mode = false
			
	#var head = Quaternion.from_euler(_skeleton.global_rotation) * _skeleton.get_bone_pose_rotation(24)
	#print(head)
	#Trying to make the head follow the direction of the camera (like Demon's Souls remake)
	#var head = _skeleton.global_transform * _skeleton.get_bone_global_pose(24)
	#head = head.looking_at($Camera_Twist.basis.x)
	#print(head, "   ", vector3i)
	#_skeleton.set_bone_global_pose_override(24, _skeleton.global_transform.affine_inverse() * head, 1.0, true)
	#_skeleton.set_bone_pose_rotation(24, vector3i * 0)
	#print(_skeleton.get_bone_pose_rotation(24), "  ", vector3i)
	#_skeleton.set_bone_pose_rotation(24, head)
	
	##If there is a direction being input to aim, rotate the head/gun to it
	if aim_direction:
		#print("aim ", $Head.rotation.y, "  ", aim_direction)
		if Global.camera_mode == "strafe":
			$Head.rotation.y = lerp_angle($Head.rotation.y, aim_direction, 30*delta)
			$Head.rotation.x = lerp_angle($Head.rotation.x, -$Camera_Twist/Camera_Pitch.rotation.x - deg_to_rad(10), 30*delta)
			if abs($Head.rotation.y - aim_direction) <= 0.01:
				print("chegay")
				aim_direction = 0.0
		elif Global.camera_mode == "free":
			#Rotate head by the direction of the right stick and limit it to just 180 degrees in relation to the body
			#$Head.rotation.y = clampf(aim_direction + int(_player_pivot.rotation.y/PI) 
									#* PI, _player_pivot.rotation.y - PI/2, _player_pivot.rotation.y + PI/2)
							#Head direction should be the angle in relation to player's body
			#var head_direction :=  aim_direction + int(_player_pivot.rotation.y/PI) * PI
			#print(aim_direction, "  ", head_direction, "  ", $Head.rotation.y, "  ", _player_pivot.rotation.y)
			if Global.locked: _camera_pivot.target_rotation = lerp_angle(_camera_pivot.rotation.y, aim_direction-PI, 30*delta)
			#$Head.rotation.y = aim_direction
			
			#Rotate the body if the head reach a rotation larger than 90 degrees compared to the body
			#if abs(abs($Head.rotation.y) - abs(_player_pivot.rotation.y)) >= PI/2: _player_pivot.rotation.y = $Head.rotation.y - PI/2
		elif Global.camera_mode != "strafe": $Head.rotation.y = lerp_angle($Head.rotation.y, _player_pivot.rotation.y, 20*delta)
		#print($Head.rotation.y, "  ", _player_pivot.rotation.y)

func _unhandled_input(event):
	#if Input.is_action_just_pressed("Pause"): 
		#Global.paused = not Global.paused
		#if Global.paused: 
			#temp_velocity = velocity
			#velocity = Vector3.ZERO
		#else: velocity = temp_velocity
		
	if Input.is_action_just_pressed("Reset"):
		position = Vector3.ZERO
		velocity = Vector3.ZERO
	
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if Global.camera_mode == "strafe": aim_direction = _camera_pivot.rotation.y - PI
	
	if event is InputEventJoypadMotion:
		#$Global.camera_mode = "free"
		if Global.camera_mode == "free":
			var r_input_dir = Input.get_vector("R_Left", "R_Right", "R_Forward", "R_Back", 0.2)
			r_direction = Vector3(r_input_dir.x, 0, r_input_dir.y).rotated(Vector3.UP, _camera_pivot.rotation.y).normalized()
			aim_direction = atan2(r_direction.x, r_direction.z)
		elif Global.camera_mode == "strafe":
			aim_direction = _camera_pivot.rotation.y - PI
			
	if Input.is_action_pressed("Shoot"): shoot_mode = true
		
	#Reset camera to the direction the player is facing
	if Input.is_action_pressed("Reset_Camera"):
		_camera_pivot.rotation.x = lerp_angle(_camera_pivot.rotation.x,
															deg_to_rad(-10),
															20 * get_process_delta_time())
		if direction: #If the player is holding a direction it will rotate to that direction
			ang_base = atan2(direction.x, direction.z) 
		else: #If not holding any direction, the camera will reset to the player's direction
			ang_base = _player_pivot.rotation.y
		
		_camera_pivot.target_rotation = ang_base - PI
		
		print(_camera_pivot.target_rotation)
		
		#var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		#CameraTween.tween_property($Camera_Twist, "rotation:y", target_rotation, 1)
		#CameraTween.tween_property($Camera_Twist/Camera_Pitch, "rotation:x", deg_to_rad(-10), 1)
		#camera_reset = true
		
	#if Input.is_action_just_pressed("Left"): #Test deadzone not working
		#print(Input.get_action_strength("Left"))
	
	if Input.is_action_pressed("Lock"): Global.locked = true
	else: Global.locked = false

func _on_water_detection_area_entered(area):
	Global.on_water = true
	print("moiado")

func _on_water_detection_area_exited(area):
	Global.on_water = false
	print("desmoiado")
