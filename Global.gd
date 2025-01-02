extends Node

var locked := false
var camera_mode = "free"
var Gyro := SDLGyro.new()
var sakurai_jump_timer := 0.0
var on_water := false
var debug : Debug
var paused := false
