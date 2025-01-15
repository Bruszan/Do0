class_name Level
extends Node3D

@onready var coins := $Coins.get_children()
var collected : Array[bool]

var total_coins := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	total_coins = $Coins.get_child_count()
	collected.resize(total_coins)
	collected.fill(false)
	var collected_count = get_coin_count()
	printt(self, coins, collected_count)
	print(collected)

func collect_coin(coin) -> void:
	collected[coins.find(coin)] = true
	printt(collected.count(true), collected)
	
func get_coin_count() -> int:
	return collected.count(true)
	
func get_total_coin_count() -> int:
	return total_coins
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
