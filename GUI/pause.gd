extends Control

func _input(event):
	if event.is_action_pressed("Pause"): 
		get_tree().paused = not get_tree().paused
