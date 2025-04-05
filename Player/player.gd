class_name Player extends CharacterBody3D

@onready var _player_pivot := $PlayerPivot
@onready var _gobot := $PlayerPivot/GobotSkin
@onready var _skeleton := $PlayerPivot/GobotSkin/gobot/Armature/Skeleton3D
@onready var _camera_pivot := get_parent().find_child("CameraTwist")
@onready var _camera_pitch := get_parent().find_child("CameraPitch")
@onready var _camera := $CameraTwist/SpringArm3D/Camera3D

@onready var _direction_target := $DirectionTarget

@onready var _wall_raycast := $PlayerPivot/WallRayCast3D
@onready var _hand_raycast := $PlayerPivot/HandRayCast3D

@onready var _water_detector := $WaterDetection
# This enum lists all the possible states the character can be in.
enum States {IDLE, RUNNING, JUMPING, FALLING, WALLING, EDGING}

# This variable keeps track of the character's current state.
var state: States = States.IDLE

var temp_velocity := Vector3.ZERO
@export var rotate_speed := 40.0
var rotation_ang := 0.0
@export var rotation_dir := Rotation_Dir.VELOCITY
enum Rotation_Dir {
	NOTHING,
	VELOCITY,
	INPUT,
	VELOCINPUT,
}

@export_group("Ground Movement Parameters")
@export var ground_top_speed := 25.0
## Parameters incase of having initial speed or accel when moving
@export var base_speed := 0.0
@export var use_base_accel := false
@export var base_accel := 5.0 if use_base_accel else 0.0
@export var ground_accel := 80.0
#@export var time_to_top_speed := 0.5
#@onready var ground_accel := (ground_top_speed - base_speed) / time_to_top_speed
#@export var time_to_stop := 0.5
@export var ground_friction := 30.0
#@onready var ground_friction := ground_top_speed / time_to_stop
@export var time_to_brake := 0.1
## Speed which the player decelerates when going against velocity direction
@export var ground_decel := 150.0
#@onready var ground_decel := ground_top_speed / time_to_stop
## Speed is reduced by this value per second when over the top ground speed
@export var overspeed_decel := 30.0

@export_group("Jump Parameters")

@export var jump_height := 7.2
@export var jump_time_to_peak := 0.39
@export var jump_time_to_descent := 0.43

@onready var jump_velocity := (jump_height * 2.0) / jump_time_to_peak
@onready var jump_gravity := (jump_height * -2.0) / pow(jump_time_to_peak, 2)
@onready var fall_gravity := (jump_height * -2.0) / pow(jump_time_to_descent, 2)
## The jump presented in Sakurai's games. See his video on Jump mechanics to know more
@export var sakurai_jump := false
## The default is the same as Smash Ultimate
@export var sakurai_initial_jump_duration := (1.0 / 60.0) * 4.0
@export var sakurai_initial_jump_height := 5.0
@export var sakurai_jump_height := 8.0

@export_group("Air Movement Parameters")
@export var air_top_speed := 20.0
@export var air_accel := 28.0
##Deceleration in the air if there is no input
@export var has_air_friction := false
@export var air_friction := 10.0

@export_group("Slide Parameters")
@export var fall_to_slope_factor := 2.0
#@export var jump_slope_velocity := 50.0
@export var slope_factor := 50.0
@export var slide_boost := 10.0
@export var slide_friction := 2.0
@export var drift_turn_factor := 1.2

@export_group("Wall Jump Parameters")
@export var wall_friction := 20.0
@export var wall_jump_y_velocity := 30.0
@export var wall_jump_velocity := 20.0
@export var wall_jump_air_accel := 10.0

@export_group("Swimming Parameters")
@export var swim_speed := 10.0
@export var swim_accel := 20.0
@export var swim_friction := 100.0
@export var swim_rot_turn := 2.0

@onready var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)

@onready var horizontal_direction := horizontal_velocity.normalized()
var horizontal_speed = func(): return Vector3(velocity.x, 0, velocity.z).length()
var h_input : Vector3
var h_speed : float
var h_velocity : Vector3

var direction := Vector3(0.0, 0.0, 0.0)
var elapsed := 0.0
var camera_reset := false
var ang_base := 0.0
var r_direction := Vector3(0.0, 0.0, 0.0)
var aim_direction := 0.0
var shoot_mode := false

var gravity := jump_gravity

func _ready() -> void:
	_hand_raycast.set_process(false)
	print("fatherson")

func get_horizontal_input() -> Vector3:
	var raw_input = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	return Vector3(raw_input.x, 0, raw_input.y).rotated(Vector3.UP, _camera_pivot.rotation.y)

# This function is returning a weaker value on diagonal input
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
	var real_velo = get_real_velocity().normalized() * speed
	printt("adicionou?", Vector3(real_velo.x * speed, real_velo.y, real_velo.z * speed))
	velocity.x += real_velo.x
	velocity.z += real_velo.z
	
func set_speed_to_direction(h_direction: Vector3, xspeed: float, yspeed: float) -> void:
	velocity = Vector3(h_direction.x * xspeed, yspeed, h_direction.z * xspeed)
func add_speed_to_direction(h_direction: Vector3, xspeed: float, yspeed: float) -> void:
	velocity = get_real_velocity() + Vector3(h_direction.x * xspeed, yspeed, h_direction.z * xspeed)
	
func _process(delta:float):
	pass
	
func _physics_process(delta):
	h_velocity = Vector3(velocity.x, 0, velocity.z)
	h_speed = Vector3(velocity.x, 0, velocity.z).length()
	
	Global.debug.add_debug_property("Input", get_horizontal_input(), 1)
	Global.debug.add_debug_property("Velocity", velocity, 1)
	Global.debug.add_debug_property("H_Speed", Vector3(velocity.x, 0, velocity.z).length(), 1)
	Global.debug.add_debug_property("V_Speed", velocity.y, 1)
	# Add the gravity.
	if not is_on_floor() and not Global.on_water:
		velocity.y -= gravity * delta
	move_and_slide()
	#Rotate the player to its velocity directionrotation_dir == Rotation_Dir.INPUT:
	if rotation_dir == Rotation_Dir.INPUT:
		if h_input:
			rotation_ang = atan2(h_input.x, h_input.z)
		elif get_horizontal_velocity(): rotation_ang = atan2(velocity.x, velocity.z)
	elif rotation_dir == Rotation_Dir.VELOCITY:
		if get_horizontal_velocity():
			rotation_ang = atan2(velocity.x, velocity.z)
	elif rotation_dir == Rotation_Dir.VELOCINPUT:
		if h_input and get_horizontal_velocity():
			var cross_vec = h_input.cross(get_horizontal_velocity()).normalized()
			rotation_ang = atan2(cross_vec.x, cross_vec.z)
		elif h_input: rotation_ang = atan2(h_input.x, h_input.z)
		elif get_horizontal_velocity(): rotation_ang = atan2(velocity.x, velocity.z)
			
	if rotation_ang != _player_pivot.rotation.y:
		_player_pivot.rotation.y = lerp_angle(_player_pivot.rotation.y, rotation_ang, rotate_speed * delta)
	
	
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
			if Global.locked: _camera_pivot.target_rotation = lerp_angle(_camera_pivot.rotation.y, aim_direction-PI, 30*delta)
			
			#Rotate the body if the head reach a rotation larger than 90 degrees compared to the body
			#if abs(abs($Head.rotation.y) - abs(_player_pivot.rotation.y)) >= PI/2: _player_pivot.rotation.y = $Head.rotation.y - PI/2
		elif Global.camera_mode != "strafe": $Head.rotation.y = lerp_angle($Head.rotation.y, _player_pivot.rotation.y, 20*delta)
		#print($Head.rotation.y, "  ", _player_pivot.rotation.y)

func _unhandled_input(event):
	## Get the horizontal input to use on all the state scripts
	h_input = get_horizontal_input()
	
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
		

func _on_water_detection_area_entered(area):
	Global.on_water = true
	print("moiado")

func _on_water_detection_area_exited(area):
	Global.on_water = false
	print("desmoiado")
