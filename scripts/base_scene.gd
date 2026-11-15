extends Node2D
## 基地场景：30x30 的楼顶水泥平台 + 建造系统。
## 基地没有战斗，所以 HUD 不显示血条和弹药，只保留建造栏。

@onready var _map: Node2D = $Map
@onready var _player: CharacterBody2D = $Player
@onready var _builder: Node2D = $Builder
@onready var _palette: Control = $HUD/Palette
@onready var _travel: Label = $HUD/Travel

## 离女儿墙多少格之内算“到边上了”
const EDGE_MARGIN := 2
const BOARD := 30
## 楼梯那 3x5 格的区域（世界坐标），站在里面按 E 就下楼
const STAIRS_RECT := Rect2(416, 336, 48, 80)
## 离床多远之内能按 E 躺上去
const BED_REACH := 26.0

var _sleeping_piece: Node2D = null
var _wake_position := Vector2.ZERO


func _ready() -> void:
	if GameState.base_spawn_at_stairs:
		# 刚从草地回来：直接站在楼梯上
		GameState.base_spawn_at_stairs = false
		_player.position = STAIRS_RECT.get_center() + Vector2(0, 12)
	else:
		# 出生点来自 Tiled 的 Spawns 层
		var spawn: Dictionary = _map.get_spawn("base_spawn")
		_player.position = spawn.get("position", Vector2(240, 340))

	# 基地是 30x30 格 = 480x480：放宽玩家活动范围和相机限制
	_player.bounds = Rect2(24, 24, 432, 432)
	# 相机可以多看平台外 160px，走到边上就能看到楼下的城市
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_left = -160
	camera.limit_top = -160
	camera.limit_right = 640
	camera.limit_bottom = 640

	# 基地里不能使用武器：不能开枪、朝向跟移动、手里也没有枪
	_player.set_armed(false)

	_builder.setup(_map, _player)
	_builder.build_mode_changed.connect(_on_build_mode_changed)
	_palette.setup(_builder)


func _on_build_mode_changed(active: bool) -> void:
	# 躺着的时候按 Tab：先起床再进建造模式
	if active and _sleeping_piece != null:
		_wake_up()
	_player.set_build_mode(active)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# 躺着的时候按 E 起来
		if _sleeping_piece != null:
			_wake_up()
			return
		# 站在床旁边按 E 躺上去
		var bed := _bed_near_player()
		if bed != null:
			_lie_down(bed)
			return
		# 走进楼梯里按 E 就下楼（去草地那张图）
		if in_stairs():
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			return
	# 基地边缘不再用 E 出地图（连提示都没有），只有 B 这个调试快捷键还能切场景
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			get_tree().change_scene_to_file("res://scenes/main.tscn")


## 玩家旁边的床（没有就返回 null）
func _bed_near_player() -> Node2D:
	for piece: Node2D in _builder.all_pieces():
		var data: BaseFurniture = piece.data
		if data == null or data.occupied_texture == null:
			continue
		var fp := Vector2(data.footprint) * 16.0
		if int(piece.steps) % 2 == 1:
			fp = Vector2(fp.y, fp.x)
		var rect := Rect2(piece.position - fp * 0.5, fp).grow(BED_REACH)
		if rect.has_point(_player.position):
			return piece
	return null


## 躺到床上
func _lie_down(bed: Node2D) -> void:
	_sleeping_piece = bed
	_wake_position = _player.position
	_player.velocity = Vector2.ZERO
	_player.visible = false
	_player.set_physics_process(false)
	# 相机跟着挪到床上，画面里能看到整个人躺着
	_player.position = bed.position + Vector2(0, -6)
	bed.set_occupied(true)
	# 睡着的时候不让进建造模式
	_builder.set_build_locked(true)


## 起床
func _wake_up() -> void:
	if _sleeping_piece == null:
		return
	_sleeping_piece.set_occupied(false)
	_sleeping_piece = null
	_builder.set_build_locked(false)
	_player.position = _wake_position
	_player.visible = true
	_player.set_physics_process(true)


## 玩家是不是站在楼梯里
func in_stairs() -> bool:
	return STAIRS_RECT.has_point(_player.position)


func _process(_delta: float) -> void:
	# 躺着：只提示起来
	if _sleeping_piece != null:
		_travel.visible = true
		_travel.text = "E - GET UP"
		return

	# 站在床旁边：提示躺下
	if _bed_near_player() != null:
		_travel.visible = true
		_travel.text = "E - SLEEP"
		return

	# 站进楼梯里才提示按 E 下楼
	var inside := in_stairs()
	_travel.visible = inside
	_travel.text = "E - GO DOWN" if inside else ""


## 玩家是不是走到了平台边缘
func at_edge() -> bool:
	var cell := Vector2i(floori(_player.position.x / 16.0), floori(_player.position.y / 16.0))
	return cell.x <= EDGE_MARGIN or cell.y <= EDGE_MARGIN \
		or cell.x >= BOARD - 1 - EDGE_MARGIN or cell.y >= BOARD - 1 - EDGE_MARGIN
""
