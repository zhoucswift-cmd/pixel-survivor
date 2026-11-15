extends Node
## 跨场景的小状态：楼梯出生点、背包资源、穿在身上的装备、做出来的装备。

var base_spawn_at_stairs := false

## 资源（击杀僵尸掉落）
var cloth := 0
var rope := 0

## 装备栏：每个槽位放的是哪件物品 id（空字符串 = 没穿）
var equipped := {
	"hat": "",
	"jacket": "",
	"pants": "",
	"boots": "",
}

## 已经做出来的可穿戴物（id -> true）
var owned := {}

## 可穿戴物品的颜色（换装时就按这个颜色刷角色贴图）
const ITEM_COLORS := {
	"shirt_blue": Color8(63, 111, 181),
	"shirt_red": Color8(181, 63, 63),
	"shirt_green": Color8(74, 150, 88),
	"pants_dark": Color8(54, 60, 82),
	"boots_brown": Color8(112, 74, 46),
}


func add_item(item: String, amount := 1) -> void:
	match item:
		"cloth":
			cloth += amount
		"rope":
			rope += amount


func reset_items() -> void:
	cloth = 0
	rope = 0


## 够不够付这份材料
func can_afford(cost: Dictionary) -> bool:
	for key: String in cost:
		if int(get(key)) < int(cost[key]):
			return false
	return true


## 扣材料（调用前先 can_afford）
func spend(cost: Dictionary) -> void:
	for key: String in cost:
		set(key, int(get(key)) - int(cost[key]))


func owns(id: String) -> bool:
	return owned.get(id, false)


func add_owned(id: String) -> void:
	owned[id] = true


## 某个槽位当前穿的颜色（没穿返回透明）
func slot_color(slot: String) -> Color:
	var id: String = equipped.get(slot, "")
	if id == "" or not ITEM_COLORS.has(id):
		return Color(0, 0, 0, 0)
	return ITEM_COLORS[id]


func equip(slot: String, id: String) -> void:
	equipped[slot] = id


func unequip(slot: String) -> void:
	equipped[slot] = ""


## 装备状态签名（玩家用它判断要不要重新刷贴图）
func look_signature() -> String:
	return "%s|%s|%s|%s" % [equipped["hat"], equipped["jacket"], equipped["pants"], equipped["boots"]]
