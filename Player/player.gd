class_name Player extends CharacterBody3D

@onready var _player_pivot = $GobotSkin
@onready var _gobot = $GobotSkin
@onready var _skeleton = $GobotSkin/gobot/Armature/Skeleton3D
@onready var _camera_pivot = $Camera_Twist
# This enum lists all the possible states the character can be in.
enum States {IDLE, RUNNING, JUMPING, FALLING}

# This variable keeps track of the character's current state.
var state: States = States.IDLE

@export var walk_top_speed := 10.0
@export var accel := 200.0
@export var decel := 2000.0
@export var friction := 100.0
@export var air_accel := 10.0
@export var smash_air_decel := false
@export var air_decel := 10.0
@export var jump_height := 5.0
@export var jump_time_to_peak := 0.6
@export var jump_time_to_descent := 0.4

@onready var jump_velocity := (jump_height * 2.0) / jump_time_to_peak
@onready var jump_gravity := (jump_height * -2.0) / pow(jump_time_to_peak, 2)
@onready var fall_gravity := (jump_height * -2.0) / pow(jump_time_to_descent, 2)

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
	pass
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y > 0:
			_gobot.jump()
		elif velocity.y < 0:
			_gobot.fall()
	move_and_slide()
	#print(get_floor_angle())

func _process(delta):
	#print(gravity)
	var _camera_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
	#Make camera controller match player's position
	_camera_tween.tween_property(_camera_pivot, "position:x", position.x, 0.5)
	_camera_tween.tween_property(_camera_pivot, "position:z", position.z, 0.5)
	#print(horizontal_velocity, "  ", horizontal_direction, "  ", horizontal_speed)
	if is_on_floor(): _camera_tween.tween_property(_camera_pivot, "position:y", position.y, 0.5)
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
			print("eae")
			#$Head.rotation.y = clampf(aim_direction + int(_player_pivot.rotation.y/PI) 
									#* PI, _player_pivot.rotation.y - PI/2, _player_pivot.rotation.y + PI/2)
							#Head direction should be the angle in relation to player's body
			#var head_direction :=  aim_direction + int(_player_pivot.rotation.y/PI) * PI
			#print(aim_direction, "  ", head_direction, "  ", $Head.rotation.y, "  ", _player_pivot.rotation.y)
			if Global.locked: $Camera_Twist.target_rotation = lerp_angle($Camera_Twist.rotation.y, aim_direction-PI, 30*delta)
			#$Head.rotation.y = aim_direction
			
			#Rotate the body if the head reach a rotation larger than 90 degrees compared to the body
			#if abs(abs($Head.rotation.y) - abs(_player_pivot.rotation.y)) >= PI/2: _player_pivot.rotation.y = $Head.rotation.y - PI/2
		elif Global.camera_mode != "strafe": $Head.rotation.y = lerp_angle($Head.rotation.y, _player_pivot.rotation.y, 20*delta)
		print($Head.rotation.y, "  ", _player_pivot.rotation.y)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if Global.camera_mode == "strafe": aim_direction = $Camera_Twist.rotation.y - PI
	
	if event is InputEventJoypadMotion:
		#$Global.camera_mode = "free"
		if Global.camera_mode == "free":
			var r_input_dir = Input.get_vector("R_Left", "R_Right", "R_Forward", "R_Back", 0.2)
			r_direction = Vector3(r_input_dir.x, 0, r_input_dir.y).rotated(Vector3.UP, $Camera_Twist.rotation.y).normalized()
			aim_direction = atan2(r_direction.x, r_direction.z)
		elif Global.camera_mode == "strafe":
			aim_direction = $Camera_Twist.rotation.y - PI
			
	if Input.is_action_pressed("Shoot"): shoot_mode = true
		
	#Reset camera to the direction the player is facing
	if Input.is_action_pressed("Reset_Camera"):
		$Camera_Twist/Camera_Pitch.rotation.x = lerp_angle($Camera_Twist/Camera_Pitch.rotation.x,
															deg_to_rad(-10),
															20 * get_process_delta_time())
		if direction: #If the player is holding a direction it will rotate to that direction
			ang_base = atan2(direction.x, direction.z) 
		else: #If not holding any direction, the camera will reset to the player's direction
			ang_base = _player_pivot.rotation.y
		
		$Camera_Twist.target_rotation = ang_base - PI
		
		print($Camera_Twist.target_rotation)
		
		#var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		#CameraTween.tween_property($Camera_Twist, "rotation:y", target_rotation, 1)
		#CameraTween.tween_property($Camera_Twist/Camera_Pitch, "rotation:x", deg_to_rad(-10), 1)
		#camera_reset = true
		
	#if Input.is_action_just_pressed("Left"): #Test deadzone not working
		#print(Input.get_action_strength("Left"))
