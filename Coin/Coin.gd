extends Area3D

@export var hud : CanvasLayer
const ROT_SPEED = 200 #Number of degrees the coin rotates every frame

# Called when the node enters the scene tree for the first time.
func _ready():
	print(hud.get_node("Label"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate_y(deg_to_rad(ROT_SPEED)*delta)


func _on_body_entered(body):
	owner.collect_coin(self)
	hud.get_node("Label").text = str(owner.get_coin_count())+"/"+str(owner.get_total_coin_count())
	queue_free()
