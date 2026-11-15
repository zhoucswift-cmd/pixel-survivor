extends Node2D
## 无头冒烟测试：模拟按键/鼠标，检查移动方向、动画状态与射击特效。
## 运行: godot --headless --path . res://tools/smoke_test.tscn

var player: CharacterBody2D


func _ready() -> void:
	player = load("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(160, 100)
	# 站着不动时身体朝向跟着鼠标；测试里钉死朝下，保证输出稳定
	player.forced_aim = Vector2.DOWN
	await _frames(3)
	print("start     -> anim=%s" % _anim())

	# 朝向由鼠标决定：移动时把瞄准方向设成移动方向，方便看动画对不对
	player.forced_aim = Vector2.RIGHT
	Input.action_press("move_right")
	await _frames(20)
	print("right     -> pos=%s anim=%s" % [player.position.snapped(Vector2.ONE), _anim()])
	Input.action_release("move_right")
	await _frames(2)

	player.forced_aim = Vector2.UP
	Input.action_press("move_up")
	await _frames(20)
	print("up        -> pos=%s anim=%s" % [player.position.snapped(Vector2.ONE), _anim()])
	Input.action_release("move_up")
	await _frames(2)

	player.forced_aim = Vector2(-1, 1).normalized()
	Input.action_press("move_left")
	Input.action_press("move_down")
	await _frames(20)
	print("left+down -> pos=%s anim=%s" % [player.position.snapped(Vector2.ONE), _anim()])
	Input.action_release("move_left")
	Input.action_release("move_down")
	player.forced_aim = Vector2.DOWN
	await _frames(3)
	print("released  -> anim=%s" % _anim())

	# 射击：冷却 / 播放 shoot_* / 生成枪口特效
	player.position = Vector2(160, 100)
	player._cooldown = 0.0
	player._try_shoot("right")
	await _frames(1)
	print("shoot     -> anim=%s flash=%s" % [_anim(), _flash_count() > 0])
	await _frames(30)
	print("after 0.5s-> anim=%s flash=%s" % [_anim(), _flash_count() > 0])

	player._cooldown = 0.0
	player._try_shoot("down")
	await _frames(1)
	print("shoot2    -> anim=%s flash=%s" % [_anim(), _flash_count() > 0])

	# 准心：开火时张开，0.12s 后收回
	var crosshair: CanvasLayer = load("res://scenes/crosshair.tscn").instantiate()
	add_child(crosshair)
	await _frames(1)
	print("crosshair -> frame=%d" % crosshair.current_frame())
	crosshair.kick()
	await _frames(1)
	print("kick      -> frame=%d" % crosshair.current_frame())
	await get_tree().create_timer(0.2).timeout
	print("after kick-> frame=%d" % crosshair.current_frame())

	# 血量：扣血 / 夹紧 / 回血
	print("health    -> %d / %d" % [player.health, player.max_health])
	player.take_damage(30.0)
	print("damage 30 -> %d" % player.health)
	player.take_damage(90.0)
	print("damage 90 -> %d (clamped)" % player.health)
	player.heal(15.0)
	print("heal 15   -> %d" % player.health)

	# 血条三色阈值：>50% 绿、20~50% 黄、<20% 红
	var bar: Control = Control.new()
	bar.set_script(load("res://scripts/health_bar.gd"))
	add_child(bar)
	print("bar color -> 100%%=%s 51%%=%s 50%%=%s 20%%=%s 19%%=%s" % [
		bar.color_name(1.0), bar.color_name(0.51), bar.color_name(0.5),
		bar.color_name(0.2), bar.color_name(0.19),
	])

	# 僵尸：类型数值 / 同一格抓击 / 被霰弹枪打死
	var zombie: CharacterBody2D = load("res://scenes/zombie.tscn").instantiate()
	add_child(zombie)
	await _frames(2)
	print("zombie    -> %s move=%.1fx(%.0fpx/s) atk=%.1f/s(%.2fs) range=%d格 dmg=%.0f hp=%.0f" % [
		zombie.type.display_name, zombie.type.move_speed, zombie.move_speed,
		zombie.type.attack_speed, zombie.attack_interval,
		zombie.attack_range_tiles, zombie.damage, zombie.health])

	player.position = Vector2(160, 100)
	player.set_health(100.0)
	zombie.position = Vector2(166, 100)  # 和玩家同一格
	await _frames(30)
	print("hit 1     -> player hp=%.0f (同一格)" % player.health)
	await _frames(60)
	print("hit 2     -> player hp=%.0f (1 秒后，攻速 0.8/s)" % player.health)

	# 武器数值
	print("weapon    -> %s dmg=%.0f rate=%.1f/s mag=%d range=%d格 reload=%.1fs ammo=%d" % [
		player.weapon.display_name, player.weapon.damage, player.weapon.fire_rate,
		player.weapon.magazine, player.weapon.range_tiles,
		player.weapon.reload_time, player.ammo])

	# 射击范围（90°、3 格，朝右）
	player._facing = "right"
	player.forced_aim = Vector2.RIGHT
	print("range     -> 前40=%s 后40=%s 前60=%s 斜(20,35)=%s" % [
		player.is_in_shot_range(player.global_position + Vector2(40, 0)),
		player.is_in_shot_range(player.global_position + Vector2(-40, 0)),
		player.is_in_shot_range(player.global_position + Vector2(60, 0)),
		player.is_in_shot_range(player.global_position + Vector2(20, 35)),
	])
	zombie.position = player.position + Vector2(40, 0)  # 40px < 3 格（48px）
	await _frames(2)
	player._cooldown = 0.0
	player._try_shoot("right")
	await _frames(2)
	var gore := 0
	for child in get_children():
		if String(child.name).begins_with("ZombieDeath"):
			gore += 1
	print("shoot 1   -> zombie freed=%s gore=%d ammo=%d（80 伤一发打死 50 血）" % [
		(not is_instance_valid(zombie)), gore, player.ammo])

	# 打空弹匣 → 自动换弹 3 秒
	for i in 6:
		player._cooldown = 0.0
		player._try_shoot("right")
		await _frames(1)
	print("empty     -> ammo=%d reloading=%s" % [player.ammo, player.is_reloading()])
	await get_tree().create_timer(3.2).timeout
	print("reloaded  -> ammo=%d / %d" % [player.ammo, player.weapon.magazine])

	await get_tree().create_timer(0.8).timeout
	var stains := 0
	for child in get_children():
		if child is Sprite2D:
			stains += 1
	print("gore      -> stains=%d" % stains)

	# 第二把武器：突击步枪
	player.equip(1)
	print("rifle     -> %s dmg=%.0f rate=%.1f/s mag=%d range=%.0fpx cone=%.0f° auto=%s multi=%s" % [
		player.weapon.short_name, player.weapon.damage, player.weapon.fire_rate,
		player.weapon.magazine, player.shot_range_px(),
		rad_to_deg(player.cone_half_angle() * 2.0),
		str(player.weapon.automatic), str(player.weapon.multi_hit)])
	player.equip(0)

	# 地形：井盖瓦片 + 地图对象层里的刷怪点
	var meadow: Node2D = load("res://scenes/meadow.tscn").instantiate()
	add_child(meadow)
	await _frames(2)
	var ground: TileMapLayer = meadow.get_node("Ground")
	var spawns: Array = meadow.spawns
	print("terrain   -> cells=%d spawns=%d" % [ground.get_used_cells().size(), spawns.size()])
	print("wells     -> %d 个刷怪井盖（%s ...）" % [spawns.size(), str(spawns[0]["name"]) if spawns.size() > 0 else "-"])

	get_tree().quit()


func _anim() -> String:
	return player.get_node("AnimatedSprite2D").animation


func _flash_count() -> int:
	var count := 0
	for child in player.get_children():
		if child.name.begins_with("MuzzleFlash"):
			count += 1
	return count


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
