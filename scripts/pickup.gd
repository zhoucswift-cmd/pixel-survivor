extends Area2D
## 地上的掉落物：玩家走过去自动捡起，加到 GameState 的背包里。
## 画在血迹上面（z_index 3），上方暂时显示物品名字。

const TEXTURES := {
	"cloth": "res://assets/base/cloth.png",
	"rope": "res://assets/base/rope.png",
	"stone": "res://assets/base/stone.png",
	"wood": "res://assets/base/wood.png",
	"grass": "res://assets/base/grass.png",
	"flower": "res://assets/base/flower.png",
}
const COLORS := {
	"cloth": Color(0.96, 0.94, 0.84, 0.95),
	"rope": Color(1.0, 0.86, 0.6, 0.95),
	"stone": Color(0.86, 0.88, 0.92, 0.95),
	"wood": Color(0.94, 0.78, 0.56, 0.95),
	"grass": Color(0.72, 0.95, 0.62, 0.95),
	"flower": Color(1.0, 0.76, 0.86, 0.95),
}

@export var item := "cloth"

var _t := 0.0
@onready var _sprite: Sprite2D = $Sprite
@onready var _name_label: Label = $Name


func _ready() -> void:
	if TEXTURES.has(item):
		_sprite.texture = load(TEXTURES[item])
	if COLORS.has(item):
		_name_label.add_theme_color_override("font_color", COLORS[item])
	_name_label.text = item.to_upper()
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)


## 上下轻浮，看着像掉在地上
func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 3.5) * 1.2


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_item(item, 1)
	queue_free()
