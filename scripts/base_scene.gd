extends Node2D
## 基地场景：30x30 的楼顶水泥平台 + 建造系统。
## 基地没有战斗，所以 HUD 不显示血条和弹药，只保留建造栏和边缘提示。

@onready var _map: Node2D = $Map
@onready var _player: CharacterBody2D = $Player
@onready var _builder: Node2D = $Builder
@onready var _palette: Control = $HUD/Palette
@onready var _travel_label: Label = $HUD/Travel

## 离女儿墙多少格之内算“到边上了”
const EDGE_MARGIN := 2
const BOARD := 30


func _ready() -> void:
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
	_palette.setup(_builder)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and at_edge():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			get_tree().change_scene_to_file("res://scenes/main.tscn")


## 玩家是不是走到了平台边缘
func at_edge() -> bool:
	var cell := Vector2i(floori(_player.position.x / 16.0), floori(_player.position.y / 16.0))
	return cell.x <= EDGE_MARGIN or cell.y <= EDGE_MARGIN \
		or cell.x >= BOARD - 1 - EDGE_MARGIN or cell.y >= BOARD - 1 - EDGE_MARGIN


func _process(_delta: float) -> void:
	var edge := at_edge()
	_travel_label.visible = edge
	_travel_label.text = "E - GO DOWNTOWN" if edge else ""
