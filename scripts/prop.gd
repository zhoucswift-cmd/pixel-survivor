extends Node2D
## 场景道具（树 / 灌木 / 蘑菇 / 木头 / 芦苇 / 石头 / 水塘）。
## 图片底部对齐到节点原点；玩家在它前面时它画在人物后面，玩家在后面时它盖住人物。

@export var tex_path := ""
## 碰撞体尺寸（0 = 不挡路）
@export var collide := Vector2.ZERO
@export var collide_offset := Vector2(0, -6)
## 只有「在地面之上、永远在人物后面」的道具（比如水塘）
@export var always_behind := false
@export var front_z := 4

var _player: Node2D = null
var _sprite: Sprite2D = null


func _ready() -> void:
	z_index = -1 if always_behind else -1
	_player = get_tree().get_first_node_in_group("player")
	_sprite = $Sprite
	if tex_path != "":
		_sprite.texture = load(tex_path)
	if _sprite.texture != null:
		var size := _sprite.texture.get_size()
		_sprite.centered = true
		_sprite.position = Vector2(0, -size.y * 0.5)
	if collide != Vector2.ZERO:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = collide
		shape.shape = rect
		shape.position = collide_offset
		body.add_child(shape)
		add_child(body)


func _process(_delta: float) -> void:
	if always_behind or _player == null:
		return
	# 玩家比道具底部低 = 站在前面：道具在后面
	# 玩家比道具底部高 = 站在后面：道具盖住玩家（玩家 z_index=1，枪是 3，所以用 4）
	var want := -1 if _player.global_position.y + 6.0 > global_position.y else front_z
	if want != z_index:
		z_index = want
