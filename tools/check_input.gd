extends SceneTree
## 验证输入映射：注入真实的按键/鼠标事件，检查对应 action 是否触发。


func _initialize() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "shoot", "reload", "weapon_wheel"]:
		var names: Array[String] = []
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				names.append(OS.get_keycode_string(e.physical_keycode))
			elif e is InputEventMouseButton:
				names.append("Mouse%d" % e.button_index)
		print("%-10s -> %s" % [action, str(names)])

	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	print("press D   -> move_right=%s" % Input.is_action_pressed("move_right"))

	var key_up := InputEventKey.new()
	key_up.physical_keycode = KEY_D
	key_up.pressed = false
	Input.parse_input_event(key_up)
	await process_frame

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	print("click LMB -> shoot=%s" % Input.is_action_pressed("shoot"))

	var r := InputEventKey.new()
	r.keycode = KEY_R
	r.physical_keycode = KEY_R
	r.pressed = true
	Input.parse_input_event(r)
	await process_frame
	print("press R   -> reload=%s" % Input.is_action_pressed("reload"))

	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	Input.parse_input_event(tab)
	await process_frame
	print("press TAB -> weapon_wheel=%s" % Input.is_action_pressed("weapon_wheel"))

	quit()
