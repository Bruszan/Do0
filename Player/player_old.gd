class_name Player_Old extends CharacterBody3D

@onready var _player_pivot = $GobotSkin
@onready var _skeleton = $GobotSkin/gobot/Armature/Skeleton3D

# This enum lists all the possible states the character can be in.
enum States {IDLE, RUNNING, JUMPING, FALLING}

# This variable keeps track of the character's current state.
var state: States = States.IDLE

@export var walk_speed := 10.0
@export var air_speed := 5.0
@export var JUMP_VELOCITY := 7.0
@export var ANGULAR_SPEED := 5.0

var direction := Vector3(0.0, 0.0, 0.0)
var elapsed := 0.0
var camera_reset := false
var ang_base := 0.0
var r_direction := Vector3(0.0, 0.0, 0.0)
var aim_direction := 0.0
var shoot_mode := false
var vector3i

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	vector3i = quaternion
	

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y > 0:
			$GobotSkin.jump()
			gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		elif velocity.y < 0:
			$GobotSkin.fall()
			gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2
	move_and_slide()

func _process(delta):
	#Make camera controller match player's position
	$Camera_Twist.position = lerp($Camera_Twist.position, position, 30 * delta)
	
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
			#$Head.rotation.y = clampf(aim_direction + int(_player_pivot.rotation.y/PI) * PI, _player_pivot.rotation.y - PI/2, _player_pivot.rotation.y + PI/2)
			#var head_direction :=  aim_direction + int(_player_pivot.rotation.y/PI) * PI #Head direction should be the angle in relation to player's body
			#print(aim_direction, "  ", head_direction, "  ", $Head.rotation.y, "  ", _player_pivot.rotation.y)
			if Global.locked: $Camera_Twist.target_rotation = lerp_angle($Camera_Twist.rotation.y, aim_direction-PI, 30*delta)
			#$Head.rotation.y = aim_direction
			
			#Rotate the body if the head reach a rotation larger than 90 degrees compared to the body
			#if abs(abs($Head.rotation.y) - abs(_player_pivot.rotation.y)) >= PI/2: _player_pivot.rotation.y = $Head.rotation.y - PI/2
		elif Global.camera_mode != "strafe": $Head.rotation.y = lerp_angle($Head.rotation.y, _player_pivot.rotation.y, 20*delta)
		print($Head.rotation.y, "  ", _player_pivot.rotation.y)
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back", 0.1)
	direction = Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, $Camera_Twist.rotation.y)
	#Normalize is making analog range being wrong
	if direction:
		#print(direction)
		#Condition to have the player rotation snap when not moving
		#if(velocity.x <= 1 and velocity.z <= 1):
			#rotation.y = atan2(direction.x, direction.z)
		#else:
		#Handle if the player model will rotate to the input direction depending of player state
		if not Global.locked: _player_pivot.rotation.y = lerp_angle(_player_pivot.rotation.y,
																	atan2(direction.x, direction.z),
																	30 * delta)
		elif Global.camera_mode == "strafe": _player_pivot.rotation.y = lerp_angle(_player_pivot.rotation.y,
																					$Camera_Twist.rotation.y - PI,
																					10 * delta)
		#Do the movement
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
		#print(direction.is_normalized())
		#print(rotation.y, "  ", atan2(direction.x, direction.z))
		if is_on_floor(): 
			if abs(velocity.x)/walk_speed > 0.5 or abs(velocity.z)/walk_speed > 0.5: $GobotSkin.run()
			else: $GobotSkin.walk()
	else: #To stop the player from moving when releasing a direction
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
		if is_on_floor(): $GobotSkin.idle()

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
	
	if Input.is_action_just_pressed("Lock"):
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property($Camera_Twist/Camera_Pitch/Camera3D, "position:z", 3, 1)
		CameraTween.tween_property($Camera_Twist/Camera_Pitch/Camera3D, "position:y", 2.5, 1)
		
	if Input.is_action_just_released("Lock"):
		var CameraTween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_parallel(true)
		CameraTween.tween_property($Camera_Twist/Camera_Pitch/Camera3D, "position:z", 6, 1)
		CameraTween.tween_property($Camera_Twist/Camera_Pitch/Camera3D, "position:y", 3, 1)
		
	if Input.is_action_pressed("Lock"): Global.locked = true
	else: Global.locked = false
		
	# Handle jump.
	if Input.is_action_pressed("Jump") and velocity.y >= 0 and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
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
