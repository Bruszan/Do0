extends Node3D

@export var _player : Player
@onready var _camera_pivot: Node3D = %CameraTwist
@export var _camera_arm : SpringArm3D
@export var _camera : Camera3D
@export var target_when_colliding : Node3D
var camera_attach := false

@export_group("Camera")
@export_range(0.0, 1.0, 0.001) var mouse_sensitivity := 0.01
@export_range(0.0, 10.0, 0.1) var analog_sensitivity := 5.0
@export_range(0.0, 2.0, 0.1) var vertical_ratio := 0.5
@export var auto_turn := false
@export_range(0.00, 10.00, 0.01) var auto_sensitivity := 0.00 if not auto_turn else 0.05
@export var tilt_upper_limit := PI / 2.0
@export var tilt_lower_limit := -PI / 2.0
@export var initial_fov := 75.0
@export var initial_height := 2.0
@export var lock_fov := 50.0
@export var lock_height := 3.0
@export var lerp_h_pos := 25.0
@export var lerp_v_pos := 8.0
@export var air_lerp_v_pos := 0.5
## The strength of the angle auto correction when running on slopes
@export var auto_pitch_str := 1.0

var _camera_input_direction := Vector2.ZERO
var player_is_using_mouse := false
var reset_finished := true

var target_rotation := 0.0
var ang_base := 0.0

## Gyro
var Gyro=SDLGyro.new()
var uncalibrated_gyro := Vector3.ZERO
@export_range(0.0, 1.0, 0.01) var gyro_sensitivity := 0.0002

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera.fov = initial_fov
	
	Gyro.sdl_init()
	Gyro.controller_init()

func target_camera_rotation():
	_camera_input_direction.y = 0.0
	if target_rotation >= PI: target_rotation = target_rotation - 2*PI
	elif target_rotation <= -PI: target_rotation = target_rotation + 2*PI
	_camera_pivot.rotation.y = lerp_angle(global_rotation.y, target_rotation, ease(5 * get_process_delta_time(), 0.5))
	print("reset ", global_rotation.y, "  ", target_rotation)
	var target_diff = target_rotation - global_rotation.y
	if target_diff >= -0.01 and target_diff <= 0.01:
		print("cabo")
		target_rotation = 0.0

func _process(delta: float) -> void: 
	Global.debug.add_debug_property("FPS", Engine.get_frames_per_second(), 1)
	## The actual Camera3D target (alternative to SpringArm3D)
	if camera_attach:
		#printt(_camera.position.z, _camera_arm.get_hit_length())
		_camera.position.z = _camera_arm.get_hit_length()
		#print(_camera_arm.get_hit_length())
	if _camera_arm.get_hit_length() >= _camera_arm.spring_length: 
		camera_attach = false
	#global_position.x = lerp(global_position.x, _player.global_position.x, abs(_player.global_position.x - global_position.x) * lerp_h_pos * delta)
	global_position.x = _player.global_position.x
	global_position.z = _player.global_position.z
	# Lerp the vertical position using Asymptotic Averaging
	var v_target = _player.global_position.y + initial_height
	var actual_lerp_v_pos = abs(v_target - global_position.y) * air_lerp_v_pos
	if _player.is_on_floor(): actual_lerp_v_pos = lerp_v_pos
	global_position.y = lerp(global_position.y, v_target, actual_lerp_v_pos * delta) 
	#position.y = _player.global_position.y + initial_height
	Global.debug.add_debug_property("Camera Rotation", _camera_pivot.rotation, 1)
	Gyro.gamepad_polling()
	
	uncalibrated_gyro.x = Gyro.get_calibrated_gyro()[0]
	uncalibrated_gyro.y = Gyro.get_calibrated_gyro()[1]
	uncalibrated_gyro.z = Gyro.get_calibrated_gyro()[2]
	
	if Input.is_action_pressed("Reset_Camera") and not Input.is_action_just_pressed("Reset_Camera"): 
		target_rotation = _player._player_pivot.global_rotation.y
	
	## Targetting the camera for an angle, used for resetting the camera
	if target_rotation and reset_finished: target_camera_rotation()
	elif not player_is_using_mouse:
		_camera_pivot.rotation.x -= _camera_input_direction.y * delta
		_camera_pivot.rotation.x = clamp(rotation.x, -PI/2+0.001, PI/2)
		_camera_pivot.rotation.y -= _camera_input_direction.x * delta

func _physics_process(delta: float) -> void:
	## Make the camera pitch adapt to the angle of the floor related to the camera direction
	if not _camera_input_direction.y and _player.is_on_floor():
		# Get the camera basis to compare with the floor normal
		var cam_basis = _camera_pivot.get_global_transform().basis.z
		# Remove the y axis because we don't need it, and then normalize it
		cam_basis = Vector3(cam_basis.x, 0, cam_basis.z).normalized()
		var target_pitch = _player.get_floor_angle() * 1.2
		# The dot is going between -0.7 and 0.7, so the camera will target 70% of the floor angle
		target_pitch *= cam_basis.dot(_player.get_floor_normal())
		# Make it proportional to the player speed to not make it distracting
		var speed_str = _player.get_horizontal_speed() / _player.ground_top_speed
		# 20 degrees will be added to the targeted pitch because it's the default angle
		# So looking up will have 20 degrees less pitch than looking down, which is fine
		_camera_pivot.rotation.x = lerp(_camera_pivot.rotation.x, target_pitch - deg_to_rad(20), auto_pitch_str * speed_str * delta)
	#if _player.get_floor_angle(): printt(_player.get_floor_angle(), cam_basis.dot(_player.get_floor_normal()), target_pitch, angle_pitch_str)
		
func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _unhandled_input(event: InputEvent) -> void:
	## Mouse camera input
	var player_is_using_mouse := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if player_is_using_mouse:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		rotation.x -= _camera_input_direction.y
		rotation.x = clamp(rotation.x, -PI/2+0.001, PI/2)
		rotation.y -= _camera_input_direction.x
		_camera_input_direction = Vector2.ZERO
	elif event is InputEventJoypadMotion:
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.2)
		#if $Eu.$Global.camera_mode != "strafe":
		#The auto camera rotation when inputting left or right on the left stick, only for joypads
		var auto_input = input_dir.x * auto_sensitivity
		var r_input_dir = Input.get_vector("R_Left", "R_Right", "R_Forward", "R_Back", 0.2)
		
		#Manual input
		var Yaw = r_input_dir.x * analog_sensitivity + auto_input
		var Pitch = vertical_ratio * (r_input_dir.y * analog_sensitivity)
		_camera_input_direction = Vector2(Yaw, Pitch)
	
	## Determine the angle which the camera will rotate
	if Input.is_action_just_pressed("Reset_Camera") and not target_rotation:
		var CameraResetTween := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		print("reseta?")
		## This two lines is to replicate Mario 64 DS's camera reset which could be selected with analog inputs
		## I think there is still an opportunity to make a tanky camera control while holding this button
		#if _player.get_horizontal_input(): #If the player is holding a direction it will rotate to that direction
			#print("direcao reseta")
			#ang_base = atan2(_player.get_horizontal_input().x, _player.get_horizontal_input().z) 
		#else: #If not holding any direction, the camera will reset to the player's direction
			#ang_base = _player._player_pivot.global_rotation.y

		## Just use quaternions to prevent rotation bugs
		CameraResetTween.tween_property(_camera_pivot, "quaternion", _player._player_pivot.quaternion, 0.2)
		#target_rotation = ang_base
		reset_finished = false
		CameraResetTween.finished.connect(func(): reset_finished = true)
		
	if Input.is_action_just_pressed("Lock"): _player._gobot.set_head_target(get_viewport().get_camera_3d().get_path(), 5, 1.5)
	if Input.is_action_pressed("Lock"):
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera, "fov", lock_fov, 1)
		#CameraTween.tween_property(self, "position:y",  lock_height, 1)
		Global.locked = true
		
	if Input.is_action_just_released("Lock"):
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera, "fov", initial_fov, 1)
		#CameraTween.tween_property(self, "position:y", initial_height, 1)
		_player._gobot.clear_head_target()
		Global.locked = false


func _on_area_3d_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	print("entrou body")
	camera_attach = true
