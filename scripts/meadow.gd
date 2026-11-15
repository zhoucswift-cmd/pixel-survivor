extends Node2D
## 读取 Tiled 导出的 .tmj 地图，把瓦片填进 TileMapLayer，并读出对象层里的刷怪点。
## Tiled 是地形编辑的唯一来源：改完地图重新运行即可，不需要手动搬运数据。
##
## 地图里的 GID 从 firstgid(=1) 开始，对应瓦片集里第 (gid-1) 块，
## 按 8 列换算成 atlas 坐标。

const TILE_SIZE := Vector2i(16, 16)

@export_file("*.tmj") var map_path: String = "res://tiled/meadow.tmj"
@export var layer_path: NodePath = ^"Ground"

## 对象层里的点：{ "name", "layer", "position", "properties" }
var spawns: Array[Dictionary] = []

@onready var _layer: TileMapLayer = get_node(layer_path)


func _ready() -> void:
	load_map(map_path)


func load_map(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("无法读取地图文件：%s" % path)
		return

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("地图 JSON 解析失败：%s" % path)
		return

	_fill(parsed)


## 按名字取一个刷怪点，找不到返回空字典
func get_spawn(spawn_name: String) -> Dictionary:
	for spawn: Dictionary in spawns:
		if spawn.get("name", "") == spawn_name:
			return spawn
	return {}


## 井盖瓦片（#16 盖着 / #17 开盖）
const WELL_CLOSED := Vector2i(0, 2)
const WELL_OPEN := Vector2i(1, 2)


## 切换某个井盖格子的状态：有僵尸出来时显示开盖，空了盖回去
func set_well_open(cell: Vector2i, open: bool) -> void:
	if _layer == null:
		return
	_layer.set_cell(cell, 0, WELL_OPEN if open else WELL_CLOSED)


func _fill(map: Dictionary) -> void:
	var source: TileSetAtlasSource = _layer.tile_set.get_source(0)
	var columns := int(source.texture.get_width() / TILE_SIZE.x)
	var width: int = int(map.get("width", 0))
	var firstgid := 1
	for ts: Dictionary in map.get("tilesets", []):
		firstgid = int(ts.get("firstgid", 1))
		break

	_layer.clear()
	spawns.clear()

	for layer: Dictionary in map.get("layers", []):
		match String(layer.get("type", "")):
			"tilelayer":
				_fill_tiles(layer, width, columns, firstgid)
			"objectgroup":
				_read_objects(layer)


func _fill_tiles(layer: Dictionary, width: int, columns: int, firstgid: int) -> void:
	var data: Array = layer.get("data", [])
	for i in data.size():
		var gid := int(data[i])
		if gid == 0:
			continue
		var tile_id := gid - firstgid
		var coords := Vector2i(i % width, i / width)
		var atlas := Vector2i(tile_id % columns, tile_id / columns)
		_layer.set_cell(coords, 0, atlas)


func _read_objects(layer: Dictionary) -> void:
	var layer_name := String(layer.get("name", ""))
	for obj: Dictionary in layer.get("objects", []):
		var props := {}
		for prop: Dictionary in obj.get("properties", []):
			props[String(prop.get("name", ""))] = prop.get("value", null)
		spawns.append({
			"name": String(obj.get("name", "")),
			"layer": layer_name,
			"position": Vector2(float(obj.get("x", 0)), float(obj.get("y", 0))),
			"properties": props,
		})
