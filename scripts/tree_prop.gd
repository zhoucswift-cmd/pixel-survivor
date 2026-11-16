extends Node2D
## EMBER MAPLE（余烬枫）：一棵会长的树。
## 5 个阶段：0 种子 / 1 幼苗 / 2 小树 / 3 大枫树 / 4 树桩
## - 阶段 0~2 会自己慢慢长大（每 GROW_SECONDS 秒长一级）
## - 长到 3（大枫树）后可以按 E 砍，掉木头并变成树桩（4）
## - 树桩过 REGROW_SECONDS 秒重新发芽，从幼苗（1）重新长
## 树干挡路，玩家站到树前面时树画在人物后面，反之盖住人物。

const TILE := 16.0
const STAGE_SEED := 0
const STAGE_SPROUT := 1
const STAGE_SMALL := 2
const STAGE_MATURE := 3
const STAGE_STUMP := 4

## 每级生长时间（秒）
@export var grow_seconds := 22.0
## 树桩重新发芽的时间（秒）
@export var regrow_seconds := 45.0
## 砍一棵成熟树掉多少木头
@export var wood_per_chop := 3
## 起始阶段（_scatter_trees 会随机）
@export var stage := STAGE_SMALL

signal chopped(wood: int)

var _player: Node2D = null
var _sprite: Sprite2D = null
var _shape: CollisionShape2D = null
var _timer := 0.0


func _ready() -> void:
	z_index = -1
	_player = get_tree().get_first_node_in_group("player")
	_sprite = $Sprite
	_shape = $Body/Shape
	_apply_stage()


func _process(delta: float) -> void:
	# 生长 / 再生计时
	if stage <= STAGE_SMALL:
		_timer += delta
		if _timer >= grow_seconds:
			_timer = 0.0
			stage += 1
			_apply_stage()
	elif stage == STAGE_STUMP:
		_timer += delta
		if _timer >= regrow_seconds:
			_timer = 0.0
			stage = STAGE_SPROUT
			_apply_stage()

	if _player == null:
		return
	# 玩家比树根低 = 站在树前面：树画在后面（-1）
	# 玩家比树根高 = 站在树后面：树画在玩家前面（玩家 z_index 是 1，所以树用 2）
	var want := -1 if _player.global_position.y + 6.0 > global_position.y else 2
	if want != z_index:
		z_index = want


## 成熟的树才能砍；砍完变树桩
func can_chop() -> bool:
	return stage == STAGE_MATURE


func chop() -> int:
	if not can_chop():
		return 0
	stage = STAGE_STUMP
	_timer = 0.0
	_apply_stage()
	chopped.emit(wood_per_chop)
	return wood_per_chop


func _apply_stage() -> void:
	if _sprite != null:
		_sprite.frame = clampi(stage, 0, 4)
	# 只有小树以上才有树干碰撞，幼苗/种子不挡路
	if _shape != null:
		_shape.disabled = stage < STAGE_SMALL
	# 树桩矮一点，碰撞也小一点
	if _shape != null:
		_shape.position = Vector2(0, -4 if stage == STAGE_STUMP else -6)
