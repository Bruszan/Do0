class_name PlayerState extends State

const IDLE = "Idle"
const RUNNING = "Move"
const SLIDING = "Slide"
const JUMPING = "Jump"
const FALLING = "Fall"
const WALLING = "WallSlide"
const WALL_JUMPING = "WallJump"
const EDGING = "EdgeGrab"
const DIVING = "Dive"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")

func _on_water_detection_area_entered(area):
	finished.emit(DIVING)

func _on_water_detection_area_exited(area):
	finished.emit(FALLING)
