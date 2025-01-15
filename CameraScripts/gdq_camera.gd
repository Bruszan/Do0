extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0, 0.01) var mouse_sensitivity := 0.25
@export_range(0.0, 10.0, 0.1) var analog_sensitivity := 4.0
@export_range(0.0, 2.0, 0.1) var vertical_ratio := 0.5
@export var auto_turn := false
@export_range(0.00, 1.00, 0.01) var auto_sensitivity := 0.00 if not auto_turn else 0.05
@export var tilt_upper_limit := PI / 2.0
@export var tilt_lower_limit := -PI / 2.0
@export var initial_length := 5.0
@export var initial_height := 2.0
@export var lock_distance := 4.5
@export var lock_height := 3.0

var _camera_input_direction := Vector2.ZERO

@onready var _camera_pivot: Node3D = %CameraTwist
@onready var _camera_arm = $SpringArm3D

var target_rotation := 0.0
var ang_base := 0.0

## Gyro
var Gyro=SDLGyro.new()
var uncalibrated_gyro := Vector3.ZERO
@export_range(0.0, 1.0, 0.01) var gyro_sensitivity := 0.0002

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_arm.spring_length = initial_length
	position.y = initial_height
	
	Gyro.sdl_init()
	Gyro.controller_init()

func target_camera_rotation():
	_camera_input_direction.y = 0.0
	if target_rotation >= PI: target_rotation = target_rotation - 2*PI
	elif target_rotation <= -PI: target_rotation = target_rotation + 2*PI
	_camera_pivot.rotation.y = lerp_angle(global_rotation.y, target_rotation, ease(20 * get_process_delta_time(), -0.5))
	print("reset ", global_rotation.y, "  ", target_rotation)
	if abs(abs(target_rotation) - abs(global_rotation.y)) <= 0.01:
		print("true")
		target_rotation = 0.0

func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	
func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
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
	
	## Camera reset function
	if Input.is_action_just_pressed("Reset_Camera"):
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		## This two lines is to replicate Mario 64 DS's camera reset which could be selected with analog inputs
		## I think there is still an opportunity to make a tanky camera control while holding this button
		if owner.get_horizontal_input(): #If the player is holding a direction it will rotate to that direction
			print("direcao reseta")
			ang_base = atan2(owner.get_horizontal_input().x, owner.get_horizontal_input().z) 
		else: #If not holding any direction, the camera will reset to the player's direction
			ang_base = owner._player_pivot.global_rotation.y
			
		## It would be better to use tweens if it didn't do rotations wrong
		#var lerp = lerp_angle(rotation.y, ang_base, 1 * get_process_delta_time())    
		#CameraTween.tween_property(_camera_pivot, "global_rotation:y", ang_base, 0.2)
		#CameraTween.tween_property(_camera_pivot, "rotation:x", deg_to_rad(10), 0.2)
		target_rotation = ang_base
		print("cabo")
	
	
		
		
func _physics_process(delta: float) -> void:
	Global.debug.add_debug_property("Camera Rotation", _camera_pivot.rotation, 1)
	Gyro.gamepad_polling()
	
	uncalibrated_gyro.x = Gyro.get_calibrated_gyro()[0]
	uncalibrated_gyro.y = Gyro.get_calibrated_gyro()[1]
	uncalibrated_gyro.z = Gyro.get_calibrated_gyro()[2]
	
	## Targetting the camera for an angle, used for resetting the camera
	if target_rotation: target_camera_rotation()
	else:
		_camera_pivot.rotation.x += _camera_input_direction.y * delta
		_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
		_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO
	
	if Global.locked:
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera_arm, "spring_length", lock_distance, 1)
		CameraTween.tween_property(self, "position:y", lock_height, 1)
	else:
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera_arm, "spring_length", initial_length, 1)
		CameraTween.tween_property(self, "position:y", initial_height, 1)
