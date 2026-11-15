"""生成 Tiled 的 tileset(.tsx) 与 20x20 草地地图(.tmj)。

瓦片集：assets/tiles/grass_tiles.png（16×16，8 列 × 3 行 = 24 块，其中 #16/#17 是井盖）
输出：tiled/grass.tsx、tiled/meadow.tmj
"""
import json
import random
from pathlib import Path

ROOT = Path(r"C:\game\test")
TILE = 16
MAP_W, MAP_H = 20, 20
TILESET_IMG = "../assets/tiles/grass_tiles.png"

# 每种瓦片的抽取权重：0=纯草 1-2=草丛 3/9=草丛+花 4-6=花 7/15=石子 8=密草 10/13=深色 14=另一版草底
WEIGHTS = {
    0: 0.34,   # grass
    14: 0.16,  # grass_b
    8: 0.12,   # grass_dense
    1: 0.10,   # tuft_a
    2: 0.08,   # tuft_b
    3: 0.03,   # tuft + flower
    9: 0.02,   # tuft + flower y
    4: 0.02,   # flower w
    5: 0.02,   # flower y
    6: 0.02,   # two flowers
    7: 0.02,   # pebble
    15: 0.01,  # two pebbles
    12: 0.02,  # flower + tuft
    10: 0.01,  # dark patch
    13: 0.01,  # dark patch + tuft
    11: 0.01,  # pebble + tuft
}

# 井盖数量（每个井盖都是一个刷怪点）
WELL_COUNT = 5
PLAYER_START_CELL = (10, 10)

TSX = """<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.12.2" name="grass" tilewidth="{tw}" tileheight="{th}" spacing="0" margin="0" tilecount="{count}" columns="{cols}">
 <image source="{img}" width="{iw}" height="{ih}"/>
 <terraintypes>
  <terrain name="Grass" tile="0"/>
 </terraintypes>
{terrain_tiles}
</tileset>
"""


def build_tsx() -> str:
    # 旧版地形写法（Tiled 1.5+ 仍可读取并会自动转成 Wang set）：
    # terrain = 四个角的类型索引，四角都是 0（唯一的 Grass），probability 控制随机权重
    terrain = {
        0: 0.30, 14: 0.16, 8: 0.12, 1: 0.12, 2: 0.10,
        3: 0.03, 9: 0.02, 4: 0.02, 5: 0.02, 6: 0.02,
        7: 0.02, 15: 0.01, 12: 0.02, 10: 0.02, 13: 0.01, 11: 0.01,
    }
    lines = []
    for tile_id, prob in terrain.items():
        lines.append(f' <tile id="{tile_id}" terrain="0,0,0,0" probability="{prob}"/>')
    return TSX.format(
        tw=TILE, th=TILE, count=24, cols=8,
        img=TILESET_IMG, iw=128, ih=48,
        terrain_tiles="\n".join(lines),
    )


def pick_well_cells(rng: random.Random) -> list[tuple[int, int]]:
    """随机挑 5 个井盖格子：离玩家出生点、彼此都留出距离。"""
    cells: list[tuple[int, int]] = []
    tries = 0
    while len(cells) < WELL_COUNT and tries < 500:
        tries += 1
        x = rng.randrange(2, MAP_W - 2)
        y = rng.randrange(2, MAP_H - 2)
        if max(abs(x - PLAYER_START_CELL[0]), abs(y - PLAYER_START_CELL[1])) < 3:
            continue
        if any(max(abs(x - cx), abs(y - cy)) < 4 for cx, cy in cells):
            continue
        cells.append((x, y))
    return cells


def build_map() -> dict:
    rng = random.Random(20261115)
    ids = list(WEIGHTS)
    weights = [WEIGHTS[i] for i in ids]

    data = []
    for y in range(MAP_H):
        for x in range(MAP_W):
            tile = rng.choices(ids, weights=weights, k=1)[0]
            data.append(tile + 1)  # firstgid = 1

    # 三片小花丛，让草地不至于太均匀
    for cx, cy in ((4, 5), (13, 9), (9, 15)):
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                x, y = cx + dx, cy + dy
                if 0 <= x < MAP_W and 0 <= y < MAP_H and rng.random() < 0.55:
                    data[y * MAP_W + x] = rng.choice([4, 5, 6, 12]) + 1

    # 井盖（盖着）：瓦片 id 16 -> GID 17
    well_cells = pick_well_cells(rng)
    for wx, wy in well_cells:
        data[wy * MAP_W + wx] = 17

    # 每个井盖一个刷怪点（对象层 Spawns）
    spawn_objects = []
    for i, (wx, wy) in enumerate(well_cells, start=1):
        spawn_objects.append({
            "height": 0,
            "id": i,
            "name": f"well_{i}",
            "point": True,
            "properties": [
                {"name": "kind", "type": "string", "value": "zombie_spawn"},
                {"name": "tile_id", "type": "int", "value": 17},
            ],
            "rotation": 0,
            "type": "",
            "visible": True,
            "width": 0,
            "x": (wx + 0.5) * TILE,
            "y": (wy + 0.5) * TILE,
        })

    return {
        "compressionlevel": -1,
        "height": MAP_H,
        "infinite": False,
        "layers": [
            {
                "data": data,
                "height": MAP_H,
                "id": 1,
                "name": "Grass",
                "opacity": 1,
                "type": "tilelayer",
                "visible": True,
                "width": MAP_W,
                "x": 0,
                "y": 0,
            },
            {
                "draworder": "topdown",
                "id": 2,
                "name": "Buildings",
                "objects": [],
                "opacity": 1,
                "type": "objectgroup",
                "visible": True,
                "x": 0,
                "y": 0,
            },
            {
                "draworder": "topdown",
                "id": 3,
                "name": "Spawns",
                "objects": spawn_objects,
                "opacity": 1,
                "type": "objectgroup",
                "visible": True,
                "x": 0,
                "y": 0,
            },
        ],
        "nextlayerid": 4,
        "nextobjectid": len(spawn_objects) + 1,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.12.2",
        "tileheight": TILE,
        "tilesets": [{"firstgid": 1, "source": "grass.tsx"}],
        "tilewidth": TILE,
        "type": "map",
        "version": "1.10",
        "width": MAP_W,
    }


def main() -> None:
    tiled_dir = ROOT / "tiled"
    tiled_dir.mkdir(parents=True, exist_ok=True)

    tsx_path = tiled_dir / "grass.tsx"
    tsx_path.write_text(build_tsx(), encoding="utf-8")

    map_path = tiled_dir / "meadow.tmj"
    data = build_map()
    map_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    counts = {}
    for gid in data["layers"][0]["data"]:
        counts[gid - 1] = counts.get(gid - 1, 0) + 1
    wells = [o["name"] + "@" + str((o["x"], o["y"])) for o in data["layers"][2]["objects"]]
    print(f"tileset -> {tsx_path}")
    print(f"map     -> {map_path}  ({MAP_W}x{MAP_H}, {len(data['layers'][0]['data'])} tiles)")
    print("wells   ->", ", ".join(wells))
    print("tile usage:", dict(sorted(counts.items())))


if __name__ == "__main__":
    main()
