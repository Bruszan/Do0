extends Node3D

@export var initial_distance := 6.0
@export var initial_height := 2.0
@export var initial_pitch := deg_to_rad(-20)

@export var lock_distance := 1.5
@export var lock_height := 2.5

@export var mouse_sensitivity := 0.1
@export var analog_sensitivity := 2
@export var vertical_ratio := 0.5
@export var auto_sensitivity := 1
@export var gyro_sensitivity := 0.03

@onready var _camera_arm = $Camera_Pitch/SpringArm3D

var Yaw := 0.0
var Pitch := 0.0
var auto_input := 0.0
var target_rotation := 0.0
var lastone := 0.0
var uncalibrated_gyro := Vector3.ZERO

var orientation
var Gyro=SDLGyro.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	_camera_arm.position.z = initial_distance
	_camera_arm.position.y = initial_height
	$Camera_Pitch.rotation.x = initial_pitch
	Gyro.sdl_init()
	Gyro.controller_init()#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var _camera_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	#Make camera controller match player's position
	_camera_tween.tween_property(self, "position:x", get_parent().position.x, 0)
	_camera_tween.tween_property(self, "position:z", get_parent().position.z, 0)
	if get_parent().is_on_floor():_camera_tween.tween_property(self, "position:y", get_parent().position.y, 1)
	else:_camera_tween.tween_property(self, "position:y", get_parent().position.y, 3)

	#if get_parent().velocity.y > 0: _camera_tween.tween_property(_camera_arm, "position:y", 0, 3)
	#else: _camera_tween.tween_property(_camera_arm, "position:y", initial_height, 3)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Input.is_action_just_pressed("ui_cancel"): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Gyro.gamepad_polling()
	
	uncalibrated_gyro.x = Gyro.get_calibrated_gyro()[0]
	uncalibrated_gyro.y = Gyro.get_calibrated_gyro()[1]
	uncalibrated_gyro.z = Gyro.get_calibrated_gyro()[2]
	
	if target_rotation:
		Yaw = 0.0
		if target_rotation >= PI: target_rotation = target_rotation - 2*PI
		elif target_rotation <= -PI: target_rotation = target_rotation + 2*PI
		rotation.y = lerp_angle(rotation.y, target_rotation, 15 * delta)
		print("reset ", rotation.y, "  ", target_rotation)
		if abs(abs(target_rotation) - abs(rotation.y)) <= 0.01:
			print("true")
			target_rotation = 0.0
		
	rotate_y(Yaw*delta)
	$Camera_Pitch.rotate_x(Pitch*delta)
	$Camera_Pitch.rotation.x = clamp(
		$Camera_Pitch.rotation.x, -PI/2, PI/2)
	
	Yaw = 0.0
	Pitch = 0.0
	
	#print(Quaternion.from_euler($Camera_Pitch.rotation))
	#Tentar fazer com que a câmera mude de posição dependendo do ângulo do Camera_Pitch
	#Quando o Camera_Pitch estiver 0 graus a câmera deve estar na altura e distância inicial
	#Quando o Camera_Pitch atingir o limite de -90 ou 90 graus, decidir a altura e distância
	#$Camera_Pitch/Camera3D.position.z = clamp(6+ $Camera_Pitch.rotation.x*-1, 3, 20)
	#Já é certo que a altura da câmera deve ser de 0 quando Camera_Pitch for -90 graus
	#$Camera_Pitch/Camera3D.position.y = clamp((PI/2 / $Camera_Pitch.rotation.x)+2, 0, 2.5)
	#print($Camera_Pitch.rotation, "  Distancia: ", $Camera_Pitch/Camera3D.position.z, "  Altura: ", $Camera_Pitch/Camera3D.position.y)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Yaw -= event.relative.x * mouse_sensitivity
			Pitch -= event.relative.y * mouse_sensitivity
			#print("X ", event.relative.x, " Y ",event.relative.y)
	if event is InputEventJoypadMotion:
		var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.2)
		#if $Eu.$Global.camera_mode != "strafe":
		#The auto camera rotation when inputting left or right on the left stick, only for joypads
		#auto_input = input_dir.x * auto_sensitivity
		var r_input_dir = Input.get_vector("R_Left", "R_Right", "R_Forward", "R_Back", 0.2)
		
		#Manual input
		if not Global.locked:
			Yaw -= (r_input_dir.x * analog_sensitivity + auto_input)
			Pitch -= vertical_ratio * (r_input_dir.y * analog_sensitivity)
		else: Pitch = uncalibrated_gyro.x * gyro_sensitivity
		#if(camera != "tank") : Pitch = - input_dir.y * analog_sensitivity
		#print("X ", input_dir.x, " Y ", input_dir.y)
	
	if Input.is_action_just_pressed("Lock"):
		print("lockei")
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera_arm, "position:z", lock_distance, 1)
		CameraTween.tween_property(_camera_arm, "position:y", lock_height, 1)
		
	if Input.is_action_pressed("Lock"): Global.locked = true
	else: Global.locked = false
		
	if Input.is_action_just_released("Lock"):
		print("deslockei")
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property(_camera_arm, "position:z", initial_distance, 1)
		CameraTween.tween_property(_camera_arm, "position:y", initial_height, 1)
