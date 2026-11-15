extends SceneTree
## 场景流转自检：开局在基地 / 走到边上出现提示 / 按 E 去草地 / 草地边上按 E 回基地。
## 运行: godot --headless --path . --script res://tools/travel_test.gd

func _initialize() -> void:
	print("main_scene -> %s" % ProjectSettings.get_setting("run/main_scene"))

	# 开局：基地
	change_scene_to_file("res://scenes/base.tscn")
	await process_frame
	await process_frame
	var base := current_scene
	print("开局场景   -> %s" % base.name)

	var player: CharacterBody2D = base.get_node("Player")
	var label: Label = base.get_node("HUD/Travel")

	# 场地中央：没提示
	player.position = Vector2(240, 240)
	await process_frame
	print("场中央     -> at_edge=%s 提示='%s'" % [str(base.at_edge()), label.text])

	# 走到边上：有提示
	player.position = Vector2(24, 240)
	await process_frame
	print("走到边上   -> at_edge=%s 提示='%s'" % [str(base.at_edge()), label.text])

	# 按 E → 去草地
	var ev := InputEventKey.new()
	ev.keycode = KEY_E
	ev.physical_keycode = KEY_E
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 6:
		await process_frame
	print("按 E 之后  -> %s" % current_scene.name)

	# 草地边上按 E → 回基地
	var meadow := current_scene
	var mp: CharacterBody2D = meadow.get_node("Player")
	mp.position = Vector2(24, 160)
	await process_frame
	print("草地边上   -> at_edge=%s 提示='%s'" % [
		str(meadow.at_edge()), meadow.get_node("HUD/Travel").text])

	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_E
	ev2.physical_keycode = KEY_E
	ev2.pressed = true
	Input.parse_input_event(ev2)
	for i in 6:
		await process_frame
	print("再按 E     -> %s" % current_scene.name)

	quit()
