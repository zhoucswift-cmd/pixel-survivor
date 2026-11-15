extends Node
## 跨场景的小状态：从草地回基地时让玩家出现在楼梯上；以及背包里的资源数量。

var base_spawn_at_stairs := false

## 资源（击杀僵尸掉落）
var cloth := 0
var rope := 0


func add_item(item: String, amount := 1) -> void:
	match item:
		"cloth":
			cloth += amount
		"rope":
			rope += amount


func reset_items() -> void:
	cloth = 0
	rope = 0
