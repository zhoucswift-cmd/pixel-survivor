extends Node2D
## 井盖刷怪：地图上每个井盖（Tiled 对象层 Spawns 里的 well_* 点）都是一个刷怪点。
## 每个井盖**总共只放 5 只**僵尸，每 3 秒放一只；5 只放完就永久停刷（不管僵尸死没死）。
## 井盖还有自己的僵尸活着时显示“开盖”瓦片，全死了（或放完空着）就盖回去。

const ZOMBIE_SCENE := preload("res://scenes/zombie.tscn")
const TILE := 16.0

## 出怪间隔（秒）
@export var spawn_interval := 3.0
## 每个井盖的僵尸总量（放完不再刷）
@export var spawn_limit_per_well := 5

var _meadow: Node2D = null
var _wells: Array[Dictionary] = []
var _running := false


func start(meadow: Node2D) -> void:
	_meadow = meadow
	_wells.clear()

	var index := 0
	for spawn: Dictionary in meadow.spawns:
		if not String(spawn.get("name", "")).begins_with("well"):
			continue
		var pos: Vector2 = spawn["position"]
		_wells.append({
			"cell": Vector2i(floori(pos.x / TILE), floori(pos.y / TILE)),
			"position": pos,
			"spawned": 0,            # 已经放了几只（到 5 就停）
			"zombies": [],           # 还活着的
			# 每个井盖错开一点，出怪有节奏
			"timer": spawn_interval * (1.0 + index * 0.15),
		})
		index += 1

	_running = true
	print("井盖刷怪点：%d 个，每井共 %d 只，间隔 %.1fs" % [
		_wells.size(), spawn_limit_per_well, spawn_interval])


func stop() -> void:
	_running = false


## 还剩多少只没放（调试/测试用）
func remaining(well_index: int) -> int:
	if well_index < 0 or well_index >= _wells.size():
		return 0
	return maxi(spawn_limit_per_well - int(_wells[well_index].spawned), 0)


func _process(delta: float) -> void:
	if not _running:
		return

	for well: Dictionary in _wells:
		# 配额用完了，这个井盖再也不刷
		if well.spawned >= spawn_limit_per_well:
			continue
		well.timer -= delta
		if well.timer > 0.0:
			continue
		well.timer = spawn_interval
		_spawn_one(well)


func _spawn_one(well: Dictionary) -> void:
	_prune(well)

	var zombie: CharacterBody2D = ZOMBIE_SCENE.instantiate()
	zombie.position = well.position
	get_parent().add_child(zombie)
	zombie.died.connect(_on_zombie_died.bind(well, zombie))
	well.zombies.append(zombie)
	well.spawned += 1
	_update_tile(well)


## 僵尸死亡只影响存活列表和井盖状态，不补位
func _on_zombie_died(well: Dictionary, zombie: Node) -> void:
	if well.zombies.has(zombie):
		well.zombies.erase(zombie)
	_update_tile(well)


func _prune(well: Dictionary) -> void:
	var alive: Array = []
	for zombie in well.zombies:
		if is_instance_valid(zombie):
			alive.append(zombie)
	well.zombies = alive


func _update_tile(well: Dictionary) -> void:
	if _meadow == null or not _meadow.has_method("set_well_open"):
		return
	_meadow.set_well_open(well.cell, well.zombies.size() > 0)
