"""生成基地（楼顶）的 Tiled 地图与 Godot TileSet。

瓦片集：assets/tiles/concrete_tiles.png（16×16，8 列 × 2 行 = 16 块）
输出：assets/tiles/concrete_tileset.tres（Godot）、tiled/base.tsx、tiled/base.tmj
平台：30×30 格（480×480 像素），四周一圈女儿墙（parapet）。
"""
import json
import random
from pathlib import Path

ROOT = Path(r"C:\game\test")
TILE = 16
SIZE = 30

# 瓦片编号（和 tools/make_concrete.lua 对应）
FLOOR = [0, 1, 2, 3, 6]      # 水泥地面变化
GRATE = 4                    # 排水格栅
DARK = 5                     # 暗色地面
PARAPET_H = 7
PARAPET_V = 8
CORNER_TL, CORNER_TR, CORNER_BL, CORNER_BR = 9, 10, 11, 12
HATCH = 13
AC = 14
VENT = 15

PLAYER_SPAWN_CELL = (15, 22)


def build_tileset_tres() -> str:
    lines = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        "",
        '[ext_resource type="Texture2D" path="res://assets/tiles/concrete_tiles.png" id="1_conc"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_conc"]',
        'texture = ExtResource("1_conc")',
        "texture_region_size = Vector2i(16, 16)",
    ]
    for i in range(16):
        lines.append(f"{i % 8}:{i // 8}/0 = 0")
    lines += [
        "",
        "[resource]",
        "tile_size = Vector2i(16, 16)",
        'sources/0 = SubResource("TileSetAtlasSource_conc")',
        "",
    ]
    return "\n".join(lines)


def build_tsx() -> str:
    return """<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.12.2" name="base" tilewidth="16" tileheight="16" spacing="0" margin="0" tilecount="16" columns="8">
 <image source="../assets/tiles/concrete_tiles.png" width="128" height="32"/>
</tileset>
"""


def build_map() -> dict:
    rng = random.Random(20261115)
    data = [[0] * SIZE for _ in range(SIZE)]

    # 地面
    for y in range(SIZE):
        for x in range(SIZE):
            r = rng.random()
            if r < 0.06:
                tile = GRATE
            elif r < 0.12:
                tile = DARK
            else:
                tile = rng.choice(FLOOR)
            data[y][x] = tile + 1  # firstgid = 1

    # 四周女儿墙
    for i in range(SIZE):
        data[0][i] = PARAPET_H + 1
        data[SIZE - 1][i] = PARAPET_H + 1
        data[i][0] = PARAPET_V + 1
        data[i][SIZE - 1] = PARAPET_V + 1
    data[0][0] = CORNER_TL + 1
    data[0][SIZE - 1] = CORNER_TR + 1
    data[SIZE - 1][0] = CORNER_BL + 1
    data[SIZE - 1][SIZE - 1] = CORNER_BR + 1

    # 楼顶设备：空调外机 / 通风口
    for (x, y) in ((4, 4), (25, 5), (6, 25), (23, 24)):
        data[y][x] = AC + 1
    for (x, y) in ((9, 4), (20, 3), (10, 26), (19, 26)):
        data[y][x] = VENT + 1

    # 上下楼梯的舱口（出生点）
    sx, sy = PLAYER_SPAWN_CELL
    data[sy][sx] = HATCH + 1

    flat = [gid for row in data for gid in row]

    spawns = [{
        "height": 0,
        "id": 1,
        "name": "base_spawn",
        "point": True,
        "properties": [{"name": "kind", "type": "string", "value": "player_spawn"}],
        "rotation": 0,
        "type": "",
        "visible": True,
        "width": 0,
        "x": (sx + 0.5) * TILE,
        "y": (sy + 0.5) * TILE,
    }]

    return {
        "compressionlevel": -1,
        "height": SIZE,
        "infinite": False,
        "layers": [
            {"data": flat, "height": SIZE, "id": 1, "name": "Ground",
             "opacity": 1, "type": "tilelayer", "visible": True, "width": SIZE, "x": 0, "y": 0},
            {"draworder": "topdown", "id": 2, "name": "Furniture", "objects": [],
             "opacity": 1, "type": "objectgroup", "visible": True, "x": 0, "y": 0},
            {"draworder": "topdown", "id": 3, "name": "Spawns", "objects": spawns,
             "opacity": 1, "type": "objectgroup", "visible": True, "x": 0, "y": 0},
        ],
        "nextlayerid": 4,
        "nextobjectid": 2,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.12.2",
        "tileheight": TILE,
        "tilesets": [{"firstgid": 1, "source": "base.tsx"}],
        "tilewidth": TILE,
        "type": "map",
        "version": "1.10",
        "width": SIZE,
    }


def main() -> None:
    assets = ROOT / "assets" / "tiles"
    tiled = ROOT / "tiled"
    tiled.mkdir(exist_ok=True)

    (assets / "concrete_tileset.tres").write_text(build_tileset_tres(), encoding="utf-8")
    (tiled / "base.tsx").write_text(build_tsx(), encoding="utf-8")
    data = build_map()
    (tiled / "base.tmj").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"tileset -> {assets / 'concrete_tileset.tres'}")
    print(f"map     -> {tiled / 'base.tmj'}  ({SIZE}x{SIZE} = {SIZE * TILE}x{SIZE * TILE}px)")
    print(f"spawn   -> {data['layers'][2]['objects'][0]['name']} @ "
          f"({data['layers'][2]['objects'][0]['x']}, {data['layers'][2]['objects'][0]['y']})")


if __name__ == "__main__":
    main()
