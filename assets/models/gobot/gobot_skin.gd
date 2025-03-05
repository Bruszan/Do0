class_name GobotSkin extends Node3D

## Emitted when Gobot's feet hit the ground will running.
signal foot_step
## Gobot's MeshInstance3D model.
@export var gobot_model: MeshInstance3D
## Determines whether blinking is enabled or disabled.
@export var blink = true : set = _set_blink
@export var _left_eye_mat_override : String
@export var _right_eye_mat_override : String
@export var _open_eye: CompressedTexture2D
@export var _close_eye: CompressedTexture2D

@onready var _animation_tree: AnimationTree = %AnimationTree
@onready var _animation_player: AnimationPlayer = $gobot/AnimationPlayer
@onready var _state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get(
		"parameters/StateMachine/playback"
)

@onready var _flip_shot_path: String = "parameters/FlipShot/request"
@onready var _hurt_shot_path: String = "parameters/HurtShot/request"

@onready var _blink_timer = %BlinkTimer
@onready var _closed_eyes_timer = %ClosedEyesTimer

@export var _left_eye_mat: StandardMaterial3D 
@export var _right_eye_mat: StandardMaterial3D

func _ready():
	_blink_timer.connect(
			"timeout",
			func():
				_left_eye_mat.albedo_texture = _close_eye
				_right_eye_mat.albedo_texture = _close_eye
				_closed_eyes_timer.start(0.2)
	)

	_closed_eyes_timer.connect(
			"timeout",
			func():
				_left_eye_mat.albedo_texture = _open_eye
				_right_eye_mat.albedo_texture = _open_eye
				_blink_timer.start(randf_range(1.0, 8.0))
	)
	#$gobot/Armature/Skeleton3D/LookAtModifier3D.target_node = get_viewport().get_camera_3d().get_path()

func set_head_target(target_path : String) -> void: 
	printt("New Head Target",target_path)
	$gobot/Armature/Skeleton3D/LookAtModifier3D.target_node = target_path

func _set_blink(state: bool):
	if blink == state:
		return
	blink = state
	if blink:
		_blink_timer.start(0.2)


## Sets the model to a neutral, action-free state.
func idle():
	_state_machine.travel("Idle")
	
## Sets the model to a running animation or forward movement.
func run():
	_state_machine.travel("Run")

## Sets the model to a walking animation or forward movement.
func walk():
	_state_machine.travel("Walk")
	
## Sets the model to a sliding animation.
func slide():
	_state_machine.travel("Slide")
	
func slide_right():
	_state_machine.travel("Slide_Right")

## Sets the model to an upward-leaping animation, simulating a jump.
func jump():
	_state_machine.travel("Jump")
	
## Sets the model to an upward-leaping animation, simulating a jump.
func jump_flip():
	_state_machine.travel("JumpFlip")

## Sets the model to a downward animation, imitating a fall.
func fall():
	_state_machine.travel("Fall")

## Sets the model to an edge-grabbing animation.
func edge_grab():
	_state_machine.travel("EdgeGrab")
	#_animation_tree.set_callback_mode_process(2)
	
## Sets the model to an edge-grabbing animation.
func edge_aim(pos : float):
	if not _state_machine.get_current_node() == "EdgeAim":
		_state_machine.travel("EdgeAim", false)
	pos -= _state_machine.get_current_play_position()
	_animation_tree.advance(pos)
	printt(pos)
	#_state_machine.start("EdgeAim")
	#print(_animation_player.speed_scale)
	#_animation_player.seek(pos)
	
## Sets the model to a wall-sliding animation.
func wall_slide():
	print("grudei")
	_state_machine.travel("WallSlide")

### Plays a one-shot front-flip animation.
### This animation does not play in parallel with other states.
#func flip():
	#_animation_tree.set(_flip_shot_path, true)

## Sets the model to a water floating animation.
func float():
	_state_machine.travel("Float")

## Sets the model to a water floating animation.
func swim():
	_state_machine.travel("Swim")
	
## Makes a victory sign.
func victory_sign():
	_state_machine.travel("VictorySign")

## Plays a one-shot hurt animation.
## This animation plays in parallel with other states.
func hurt():
	_animation_tree.set(_hurt_shot_path, true)
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.2)
