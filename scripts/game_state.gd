extends Node
## 跨场景的小状态：楼梯出生点、背包资源、穿在身上的装备、做出来的装备。

var base_spawn_at_stairs := false

## 资源（击杀僵尸掉落）
var cloth := 0
var rope := 0

## 装备栏：每个槽位放的是哪件物品 id（空字符串 = 没穿）
## 开局就穿着布帽 / T恤 / 长裤 / 布鞋
var equipped := {
	"hat": "casual_hat",
	"jacket": "casual_top",
	"pants": "casual_pants",
	"boots": "casual_shoes",
}

## 已经做出来的可穿戴物（id -> true）；这四件开局就有
var owned := {
	"casual_hat": true,
	"casual_top": true,
	"casual_pants": true,
	"casual_shoes": true,
}

## 每件装备的防护值 / 耐久上限
const EQUIP_STATS := {
	"casual_hat": {"def": 2, "dur": 40},
	"casual_top": {"def": 3, "dur": 60},
	"casual_pants": {"def": 3, "dur": 65},
	"casual_shoes": {"def": 2, "dur": 45},
}

## 每件装备当前耐久（id -> int）
var durability := {}


func _ready() -> void:
	# 开局/重新进游戏时把身上的装备耐久补满
	for id: String in owned:
		if EQUIP_STATS.has(id):
			durability[id] = int(EQUIP_STATS[id]["dur"])

## 可穿戴物品的颜色（换装时就按这个颜色刷角色贴图）
const ITEM_COLORS := {
	"casual_hat": Color8(198, 176, 128),
	"casual_top": Color8(110, 160, 210),
	"casual_pants": Color8(84, 92, 116),
	"casual_shoes": Color8(126, 84, 52),
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
	if EQUIP_STATS.has(id):
		durability[id] = int(EQUIP_STATS[id]["dur"])


## 某个槽位当前穿的颜色（没穿返回透明）
func slot_color(slot: String) -> Color:
	var id: String = equipped.get(slot, "")
	if id == "" or not ITEM_COLORS.has(id):
		return Color(0, 0, 0, 0)
	return ITEM_COLORS[id]


func equip(slot: String, id: String) -> void:
	equipped[slot] = id
	if EQUIP_STATS.has(id) and not durability.has(id):
		durability[id] = int(EQUIP_STATS[id]["dur"])


func unequip(slot: String) -> void:
	equipped[slot] = ""


## 总防护值（各槽位相加）
func total_defense() -> int:
	var total := 0
	for slot: String in equipped:
		var id: String = equipped[slot]
		if id != "" and EQUIP_STATS.has(id):
			total += int(EQUIP_STATS[id]["def"])
	return total


## 某件装备当前耐久 / 上限
func durability_of(id: String) -> int:
	return int(durability.get(id, 0))


func max_durability_of(id: String) -> int:
	return int(EQUIP_STATS.get(id, {}).get("dur", 0))


## 受击磨损：每件装备各掉 amount 点，耐久归零就消失；返回坏掉的 id
func wear_equipment(amount := 1) -> Array:
	var broken := []
	for slot: String in equipped:
		var id: String = equipped[slot]
		if id == "" or not EQUIP_STATS.has(id):
			continue
		durability[id] = maxi(0, durability_of(id) - amount)
		if durability[id] <= 0:
			equipped[slot] = ""
			owned.erase(id)
			durability.erase(id)
			broken.append(id)
	return broken


## 装备状态签名（玩家用它判断要不要重新刷贴图）
func look_signature() -> String:
	return "%s|%s|%s|%s" % [equipped["hat"], equipped["jacket"], equipped["pants"], equipped["boots"]]
