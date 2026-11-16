extends Node2D
## 草地上的 EMBER MAPLE（余烬枫）装饰树：
## 树干挡路，玩家走到树前面时盖住树，走到树后面时被树挡住。
## `stage` 只是用来选 5 张图里的哪一张（0 种子 / 1 幼苗 / 2 小树 / 3 大枫树 / 4 树桩），没有成长逻辑。

const TILE := 16.0

@export var stage := 3

var _player: Node2D = null
var _sprite: Sprite2D = null
var _shape: CollisionShape2D = null


func _ready() -> void:
	z_index = -1
	_player = get_tree().get_first_node_in_group("player")
	_sprite = $Sprite
	_shape = $Body/Shape
	if _sprite != null:
		_sprite.frame = clampi(stage, 0, 4)
	# 只有小树以上才挡路，种子 / 幼苗 / 树桩不挡
	if _shape != null:
		_shape.disabled = stage < 2


func _process(_delta: float) -> void:
	if _player == null:
		return
	# 玩家比树根低 = 站在树前面：树画在后面（-1）
	# 玩家比树根高 = 站在树后面：树画在玩家前面（玩家 z_index 是 1，所以树用 2）
	var want := -1 if _player.global_position.y + 6.0 > global_position.y else 2
	if want != z_index:
		z_index = want
