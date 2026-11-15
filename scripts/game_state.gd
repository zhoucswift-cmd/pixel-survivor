extends Node
## 跨场景的小状态：从草地回基地时让玩家出现在楼梯上；背包资源；当前穿的衣服。

var base_spawn_at_stairs := false

## 资源（击杀僵尸掉落）
var cloth := 0
var rope := 0

## 可穿的衣服：id -> 颜色
const JACKET_COLORS := {
	"blue": Color8(63, 111, 181),
	"red": Color8(181, 63, 63),
	"green": Color8(74, 150, 88),
	"yellow": Color8(214, 178, 62),
}

## 当前穿的哪件
var equipped_jacket := "blue"


func add_item(item: String, amount := 1) -> void:
	match item:
		"cloth":
			cloth += amount
		"rope":
			rope += amount


func reset_items() -> void:
	cloth = 0
	rope = 0


## 当前衣服的颜色
func jacket_color() -> Color:
	return JACKET_COLORS.get(equipped_jacket, JACKET_COLORS["blue"])
