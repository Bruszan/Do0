class_name Debug extends Control

var properties : Array
var fps_ms = 16
@onready var container = $PanelContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.debug = self
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Debug"):
		visible = not visible
		get_viewport().set_input_as_handled()
		
func add_debug_property(id: StringName, value, time_in_frames) -> void:
	if properties.has(id):
		if Time.get_ticks_msec() / fps_ms % time_in_frames == 0:
			var target = container.find_child(id, true, false) as Label
			target.text = id + ": " + str(value)
	else:
		var property = Label.new()
		container.add_child(property)
		property.name = id
		property.text = id + ": " + str(value)
		properties.append(id)
