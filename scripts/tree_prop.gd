extends Node2D
## 草地上的小街道绿化树：树干挡路，玩家走到树前面时盖住树，走到树后面时被树挡住。

const TILE := 16.0

var _player: Node2D = null


func _ready() -> void:
	z_index = -1
	_player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if _player == null:
		return
	# 玩家比树根低 = 站在树前面：树画在后面（-1）
	# 玩家比树根高 = 站在树后面：树画在玩家前面（玩家 z_index 是 1，所以树用 2）
	var want := -1 if _player.global_position.y + 6.0 > global_position.y else 2
	if want != z_index:
		z_index = want
