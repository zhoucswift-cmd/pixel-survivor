extends Node2D
## 演示场景：Tiled 草地地形 + 血条 HUD + 玩家 + 5 个井盖刷怪。
## 井盖位置由地图对象层提供（Spawns 里的 well_1..well_5），僵尸从井盖里刷出来。
## 调试：H 扣 10 血、J 回 10 血；F1 开关瓦片网格。
## 带上 `--shot` 启动参数时会自动截图到 res://docs/screenshots/ 并退出（用于自检）。

@onready var _player: CharacterBody2D = $Player
@onready var _spawner: Node2D = $ZombieSpawner
@onready var _crosshair: CanvasLayer = $Crosshair
@onready var _travel_label: Label = $HUD/Travel
@onready var _meadow: Node2D = $Meadow
@onready var _grid: Node2D = $Grid
@onready var _health_bar: Control = $HUD/Health
@onready var _health_text: Label = $HUD/HealthText
@onready var _ammo_label: Label = $HUD/Ammo
@onready var _items_label: Label = $HUD/Items

## 截图时用固定瞄准方向（名字后缀 -> 向量）
const AIM_BY_NAME := {
	"down": Vector2.DOWN,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"right": Vector2.RIGHT,
}

## 玩家出生点（死亡后回到这里）
var player_start := Vector2(160, 160)
## 草地上撒几棵树（截图模式不撒，画面干净）
const TREE_SCENE := preload("res://scenes/tree.tscn")
@export var tree_count := 7
## 截图模式下不跑刷怪器，避免僵尸乱入
var _capture_mode := false


func _ready() -> void:
	_capture_mode = OS.get_cmdline_user_args().has("--shot")

	_player.shot_fired.connect(_crosshair.kick)
	_player.health_changed.connect(_on_health_changed)
	_player.died.connect(_on_player_died)
	_on_health_changed(_player.health, _player.max_health)

	if _capture_mode:
		await _capture_shots()
	else:
		_scatter_trees()
		_spawner.start(_meadow)


## 在草地上随机撒几棵绿化树：避开出生点、井盖、消防栓和彼此
func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var used := {}
	# 出生点附近 2 格不种
	var start_cell := Vector2i(floori(player_start.x / 16.0), floori(player_start.y / 16.0))
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			used[start_cell + Vector2i(dx, dy)] = true
	# 井盖附近 1 格不种
	for spawn: Dictionary in _meadow.spawns:
		if not String(spawn.get("name", "")).begins_with("well"):
			continue
		var p: Vector2 = spawn["position"]
		var c := Vector2i(floori(p.x / 16.0), floori(p.y / 16.0))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				used[c + Vector2i(dx, dy)] = true
	# 消防栓位置不种
	var hydrant := get_node_or_null("Hydrant")
	if hydrant != null:
		used[Vector2i(floori(hydrant.position.x / 16.0), floori(hydrant.position.y / 16.0))] = true

	var placed := 0
	var tries := 0
	while placed < tree_count and tries < 400:
		tries += 1
		var cell := Vector2i(rng.randi_range(1, MEADOW_BOARD - 2), rng.randi_range(1, MEADOW_BOARD - 3))
		if used.has(cell):
			continue
		used[cell] = true
		var tree: Node2D = TREE_SCENE.instantiate()
		# 每棵随机挑一张（幼苗 ~ 大枫树），纯装饰
		tree.stage = rng.randi_range(1, 3)
		# 树根落在格子底边中间，树冠往上 3 格
		tree.position = Vector2(cell.x * 16.0 + 8.0, cell.y * 16.0 + 16.0)
		add_child(tree)
		placed += 1
	print("草地种树：%d 棵" % placed)


## 草地是 20x20 格，离边界 2 格内可以回基地
const EDGE_MARGIN := 2
const MEADOW_BOARD := 20


func at_edge() -> bool:
	var cell := Vector2i(floori(_player.position.x / 16.0), floori(_player.position.y / 16.0))
	return cell.x <= EDGE_MARGIN or cell.y <= EDGE_MARGIN \
		or cell.x >= MEADOW_BOARD - 1 - EDGE_MARGIN or cell.y >= MEADOW_BOARD - 1 - EDGE_MARGIN


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and at_edge():
		# 回到基地时出现在楼梯上
		GameState.base_spawn_at_stairs = true
		get_tree().change_scene_to_file("res://scenes/base.tscn")
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				_player.take_damage(10.0)
			KEY_J:
				_player.heal(10.0)


## 弹量/换弹状态每帧刷新（换弹时显示倒计时）
func _process(_delta: float) -> void:
	_ammo_label.text = _player.ammo_display()
	_items_label.text = "CLOTH %d   ROPE %d   STONE %d   WOOD %d" % [GameState.cloth, GameState.rope, GameState.stone, GameState.wood]
	var edge := at_edge()
	_travel_label.visible = edge
	_travel_label.text = "E - BACK TO BASE" if edge else ""
	# 霰弹枪靠扇形提示，不显示准心（武器资源里的 show_crosshair）
	_crosshair.visible = _player.weapon.show_crosshair


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.set_health(current, maximum)
	_health_text.text = "%d / %d" % [roundi(current), roundi(maximum)]


## 玩家死亡后 1.5 秒回出生点，并给 1.5 秒无敌 + 把附近僵尸推开（演示用）
func _on_player_died() -> void:
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(_player):
		_player.respawn(player_start)
		_push_zombies_away(player_start, 72.0)


## 复活时把出生点附近的僵尸推出这个半径，避免一睁眼又被围死
func _push_zombies_away(pos: Vector2, radius: float) -> void:
	for zombie in get_tree().get_nodes_in_group("zombies"):
		var to: Vector2 = zombie.global_position - pos
		if to.length() < radius:
			var dir := to.normalized() if to.length() > 0.1 else Vector2.RIGHT
			zombie.global_position = pos + dir * radius


func _capture_shots() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	_player.set_physics_process(false)
	var sprite: AnimatedSprite2D = _player.get_node("AnimatedSprite2D")

	# 截图用的临时僵尸（不接刷怪器）
	var zombie: CharacterBody2D = load("res://scenes/zombie.tscn").instantiate()
	add_child(zombie)
	zombie.set_physics_process(false)
	var zombie_sprite: AnimatedSprite2D = zombie.get_node("AnimatedSprite2D")

	# 普通截图关掉调试网格，后面单独出带网格 / 低血量的图
	_grid.visible = false
	var shots := [
		["idle_down", 0, Vector2(168, 190), "", Vector2(206, 214)],
		["walk_left", 1, Vector2(152, 214), "", Vector2(100, 214)],
		["walk_up", 2, Vector2(190, 230), "", Vector2(190, 180)],
		["shoot_right", 0, Vector2(140, 210), "right", Vector2(226, 210)],
	]
	await get_tree().create_timer(0.3).timeout
	for shot: Array in shots:
		_player.position = shot[2]
		_player._cooldown = 0.0
		await get_tree().process_frame

		# 准心用屏幕坐标，这里把「想瞄准的世界位置」按相机偏移换算过去
		# 截图时固定瞄准方向，避免跟着系统鼠标乱转
		var parts := String(shot[0]).split("_")
		var facing_name: String = parts[parts.size() - 1]
		_player.forced_aim = AIM_BY_NAME.get(facing_name, Vector2.DOWN)
		_player._update_gun()  # 截图模式停了物理，手动同步枪的角度

		var camera: Camera2D = _player.get_node("Camera2D")
		var view := get_viewport().get_visible_rect().size
		var camera_offset := camera.get_screen_center_position() - view * 0.5
		_crosshair.forced_position = shot[4] - camera_offset

		if String(shot[3]).is_empty():
			sprite.play(String(shot[0]))
			sprite.frame = int(shot[1])
		else:
			_player._try_shoot(String(shot[3]))
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://docs/screenshots/%s.png" % shot[0])

	# 射击范围指示：一只在扇形内（红圈），一只在范围外（白圈）
	await get_tree().create_timer(0.45).timeout
	var zombie_b: CharacterBody2D = load("res://scenes/zombie.tscn").instantiate()
	add_child(zombie_b)
	zombie_b.set_physics_process(false)
	_player.position = Vector2(160, 200)
	_player._facing = "right"
	_player.forced_aim = Vector2(1.0, -0.5).normalized()  # 斜上方，展示扇形自由角度
	_player._update_gun()
	var cam2: Camera2D = _player.get_node("Camera2D")
	var view2 := get_viewport().get_visible_rect().size
	var off2 := cam2.get_screen_center_position() - view2 * 0.5
	_crosshair.forced_position = _player.global_position + _player.shot_direction() * 44.0 - off2
	sprite.play("idle_right")
	sprite.frame = 0
	zombie.position = Vector2(196, 200)    # 正前方 36px，在 90° 扇形内
	zombie_b.position = Vector2(120, 200)  # 背后 40px，不在范围内
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/aim_range.png")
	# 僵尸抓击画面（等上一张的枪口特效散掉）
	await get_tree().create_timer(0.5).timeout
	_player.position = Vector2(168, 216)
	sprite.play("idle_right")
	sprite.frame = 0
	zombie.position = Vector2(206, 216)
	zombie_sprite.play("attack_left")
	zombie_sprite.frame = 1
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/zombie_attack.png")

	# 僵尸爆血
	zombie.visible = false
	var gore: Node2D = load("res://scenes/zombie_death.tscn").instantiate()
	gore.position = Vector2(206, 216)
	add_child(gore)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/zombie_death.png")
	gore.queue_free()
	zombie.visible = true

	# 带瓦片网格的截图（等枪口特效散掉再拍）
	await get_tree().create_timer(0.9).timeout
	_grid.visible = true
	_player.position = Vector2(150, 214)
	zombie.position = Vector2(70, 70)
	_crosshair.forced_position = Vector2(210, 150)
	sprite.play("idle_down")
	sprite.frame = 0
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/tile_grid.png")

	# 三档血条颜色：绿 / 黄 / 红
	_grid.visible = false
	for state: Array in [["health_green", 100.0], ["health_yellow", 40.0], ["health_red", 10.0]]:
		_player.set_health(float(state[1]))
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/%s.png" % state[0])

	# 武器轮盘
	_player.set_health(100.0)
	Input.warp_mouse(Vector2(824, 360))  # 指向右侧槽位（RIFLE）
	var wheel: Control = $WeaponWheel/Wheel
	wheel.open_wheel()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/weapon_wheel.png")
	wheel.close_wheel()

	# 步枪：准心 + 瞄准线（有目标 → 红线）
	_player.equip(1)
	_player.position = Vector2(150, 200)
	_player._facing = "right"
	_player.forced_aim = Vector2.RIGHT
	_player._update_gun()
	sprite.play("idle_right")
	sprite.frame = 0
	zombie.position = Vector2(250, 200)
	zombie.visible = true
	var cam3: Camera2D = _player.get_node("Camera2D")
	var view3 := get_viewport().get_visible_rect().size
	var off3 := cam3.get_screen_center_position() - view3 * 0.5
	_crosshair.forced_position = Vector2(250, 200) - off3
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/rifle_aim.png")
	_player.equip(0)

	get_tree().quit()
