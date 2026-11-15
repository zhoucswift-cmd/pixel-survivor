extends SceneTree
## 基地自检：平台尺寸 / 女儿墙 / 出生点 / 建造-升级-拆除。
## 运行: godot --headless --path . --script res://tools/base_test.gd

func _initialize() -> void:
	var base: Node2D = load("res://scenes/base.tscn").instantiate()
	root.add_child(base)
	await process_frame
	await process_frame

	var map: Node2D = base.get_node("Map")
	var builder: Node2D = base.get_node("Builder")
	var ground: TileMapLayer = map.get_node("Ground")
	var player: CharacterBody2D = base.get_node("Player")

	var cells := ground.get_used_cells()
	var size := int(round(sqrt(float(cells.size()))))
	# 女儿墙 = 最外圈那 4*30-4 格，瓦片编号 7-12
	var parapet_atlas := [Vector2i(7, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)]
	var parapet := 0
	for cell: Vector2i in cells:
		if cell.x == 0 or cell.y == 0 or cell.x == size - 1 or cell.y == size - 1:
			if parapet_atlas.has(ground.get_cell_atlas_coords(cell)):
				parapet += 1

	print("平台      -> %dx%d 格（%d 块瓦片）" % [size, size, cells.size()])
	print("女儿墙    -> %d 块" % parapet)
	print("出生点    -> %s @ %s" % [
		map.spawns[0]["name"], str(map.spawns[0]["position"])])
	print("玩家出生  -> (%.0f, %.0f)" % [player.position.x, player.position.y])
	print("家具种类  -> %s" % str(builder.types.map(func(t): return t.short_name)))

	print("库存          -> %d" % builder.stock_of(0))
	print("放置(10,10)   -> %s，库存 %d" % [str(builder.place(Vector2i(10, 10), 0)), builder.stock_of(0)])
	print("重复放置      -> %s（应 false）" % str(builder.place(Vector2i(10, 10), 0)))
	print("设备瓦片上    -> %s（应 false）" % str(builder.place(Vector2i(6, 25), 0)))
	print("墙外          -> %s（应 false）" % str(builder.place(Vector2i(0, 5), 0)))
	print("升级          -> %s，等级 %d" % [
		str(builder.upgrade(Vector2i(10, 10))), builder.piece_at(Vector2i(10, 10)).level])
	print("再次升级      -> %s，等级 %d" % [
		str(builder.upgrade(Vector2i(10, 10))), builder.piece_at(Vector2i(10, 10)).level])
	print("满级后升级    -> %s（应 false）" % str(builder.upgrade(Vector2i(10, 10))))
	builder.rotate_at(Vector2i(10, 10), 1)
	var turned: Node2D = null
	for c: Vector2i in builder._pieces.keys():
		turned = builder._pieces[c]
		break
	print("旋转 90°      -> steps=%d，占地=%s，中心对齐原中心" % [
		turned.steps, str(builder.rotated_footprint(turned.data, int(turned.steps)))])
	print("回收          -> %s，库存 %d，剩余 %d" % [
		str(builder.recycle(turned.cell)), builder.stock_of(0), builder.piece_count()])
	print("存档文件      -> %s" % str(FileAccess.file_exists("user://base_layout.json")))

	quit()
