extends SceneTree
## 井盖刷怪测试：5 个井盖，每个总共只放 5 只、每 3 秒一只，放完就不再刷（死了也不补）。
## 运行: godot --headless --path . --script res://tools/spawn_test.gd
## 测试里把间隔调成 0.2s 加速。

func _initialize() -> void:
	var main: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	var spawner: Node2D = main.get_node("ZombieSpawner")
	var meadow: Node2D = main.get_node("Meadow")
	var ground: TileMapLayer = meadow.get_node("Ground")
	var wells: Array = meadow.spawns

	print("wells     -> %d 个刷怪井盖" % wells.size())
	for w in wells:
		print("            %s @ %s" % [w["name"], str(w["position"])])

	# 加速：0.2 秒一只
	spawner.spawn_interval = 0.2
	spawner.start(meadow)

	await _wait(2.0)
	print("after 2s  -> %d 只（%d 井 × 每井 5 只 = %d）" % [
		_zombies().size(), wells.size(), wells.size() * 5])

	await _wait(1.0)
	print("after 3s  -> %d 只（配额放完，不再增加）" % _zombies().size())
	print("wells open-> %d / %d" % [_open_wells(wells, ground), wells.size()])

	# 全打死：不应该再补
	for z in _zombies():
		z.take_damage(999.0)
	await _wait(1.5)
	print("killed    -> %d 只（死了也不补）" % _zombies().size())
	print("wells open-> %d / %d（全盖回去）" % [_open_wells(wells, ground), wells.size()])

	await _wait(2.0)
	print("after 3.5s-> %d 只（确认不再刷）" % _zombies().size())

	quit()


func _zombies() -> Array:
	return get_nodes_in_group("zombies")


func _open_wells(wells: Array, ground: TileMapLayer) -> int:
	var count := 0
	for w in wells:
		var pos: Vector2 = w["position"]
		var cell := Vector2i(floori(pos.x / 16.0), floori(pos.y / 16.0))
		if ground.get_cell_atlas_coords(cell) == Vector2i(1, 2):
			count += 1
	return count


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
