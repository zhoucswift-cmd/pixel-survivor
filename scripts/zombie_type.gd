class_name ZombieType
extends Resource
## 僵尸类型数据：一个 .tres 就是一种僵尸，僵尸实例读取它来决定数值。
## 目前只有「普通僵尸」，之后加新怪就再建一个 .tres。

@export var display_name: String = "僵尸"

## 移动速度：玩家基准速度（95 px/s）的倍数，0.6 = 57 px/s
@export_range(0.1, 3.0, 0.05) var move_speed := 0.6

## 攻速：每秒攻击次数，冷却 = 1 / attack_speed
@export_range(0.1, 5.0, 0.05) var attack_speed := 0.8

## 攻击距离：按 tile 算，0 = 必须和玩家在同一格
@export_range(0, 5, 1) var attack_range_tiles := 0

## 每次攻击的伤害
@export var damage := 12.0

## 血量
@export var max_health := 50.0
