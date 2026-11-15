extends Node2D
## 基地场景：30x30 的楼顶水泥平台 + 建造系统 + HUD。

@onready var _map: Node2D = $Map
@onready var _player: CharacterBody2D = $Player
@onready var _builder: Node2D = $Builder
@onready var _health_bar: Control = $HUD/Health
@onready var _health_text: Label = $HUD/HealthText
@onready var _ammo_label: Label = $HUD/Ammo
@onready var _palette: Control = $HUD/Palette


func _ready() -> void:
	# 出生点来自 Tiled 的 Spawns 层
	var spawn: Dictionary = _map.get_spawn("base_spawn")
	_player.position = spawn.get("position", Vector2(240, 340))

	# 基地是 30x30 格 = 480x480：放宽玩家活动范围和相机限制
	_player.bounds = Rect2(24, 24, 432, 432)
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.limit_right = 480
	camera.limit_bottom = 480

	_player.health_changed.connect(_on_health_changed)
	_player.ammo_changed.connect(_on_ammo_changed)
	_on_health_changed(_player.health, _player.max_health)
	_on_ammo_changed(_player.ammo, _player.weapon.magazine)

	_builder.setup(_map, _player)
	_palette.setup(_builder)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			get_tree().change_scene_to_file("res://scenes/main.tscn")


func _process(_delta: float) -> void:
	_ammo_label.text = _player.ammo_display()


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.set_health(current, maximum)
	_health_text.text = "%d / %d" % [roundi(current), roundi(maximum)]


func _on_ammo_changed(current: int, maximum: int) -> void:
	_ammo_label.text = "%d / %d" % [current, maximum]
