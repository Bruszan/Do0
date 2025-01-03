extends Node3D

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export_range(0.0, 10.0) var analog_sensitivity := 4.0
@export_range(0.0, 2.0) var vertical_ratio := 0.5
@export_range(0.0, 1.0) var auto_sensitivity := 0.05
@export var tilt_upper_limit := PI / 2.0
@export var tilt_lower_limit := -PI / 2.0
@export var initial_length := 5.0
@export var initial_height := 2.0
@export var lock_distance := 4.0
@export var lock_height := 3.0

var _camera_input_direction := Vector2.ZERO

@onready var _camera_pivot: Node3D = %CameraTwist
@onready var _camera_arm = $SpringArm3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_arm.spring_length = initial_length
	position.y = initial_height

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
	if event is InputEventJoypadMotion:
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.2)
		#if $Eu.$Global.camera_mode != "strafe":
		#The auto camera rotation when inputting left or right on the left stick, only for joypads
		var auto_input = input_dir.x * auto_sensitivity
		var r_input_dir = Input.get_vector("R_Left", "R_Right", "R_Forward", "R_Back", 0.2)
		
		#Manual input
		var Yaw = r_input_dir.x * analog_sensitivity + auto_input
		var Pitch = vertical_ratio * (r_input_dir.y * analog_sensitivity)
		_camera_input_direction = Vector2(Yaw, Pitch)
	
func _process(delta: float) -> void:
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
