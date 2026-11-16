"""把游戏里的素材导出成 Tiled 资源，并生成一张空白的大世界地图。

产出：
  tiled/props.tsx  —— 「Collection of Images」图块集：树 / 灌木 / 蘑菇 / 圆木 / 芦苇 / 石头 / 水塘
                      + 家具（床、三个工作台、楼梯）+ 资源掉落物
  tiled/world.tmj  —— 100x100 格（1600x1600 px）的世界地图，带
                      Ground（草地，已经铺满）/ Props（物件层）/ Spawns（刷怪点）三个图层，
                      引用 grass.tsx + base.tsx + props.tsx 三套图块集

在 Tiled 里打开 `tiled/world.tmj` 就能用这三套素材开画了。
运行: python tools/make_tiled_world.py
"""
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(r"C:\game\test")
TILED = ROOT / "tiled"

W = H = 100
TILE = 16

# props.tsx 里列出的素材（相对 tiled/ 的路径）
PROPS = [
    ("../assets/forest/tree_a.png", 70, 98),
    ("../assets/forest/tree_b.png", 70, 94),
    ("../assets/forest/tree_c.png", 33, 74),
    ("../assets/forest/tree_d.png", 35, 70),
    ("../assets/forest/bush.png", 35, 27),
    ("../assets/forest/log.png", 40, 32),
    ("../assets/forest/mushrooms.png", 13, 13),
    ("../assets/forest/reeds.png", 50, 43),
    ("../assets/forest/rock.png", 19, 32),
    ("../assets/forest/pond.png", 48, 48),
    ("../assets/base/bed.png", 16, 32),
    ("../assets/base/toolbench.png", 32, 16),
    ("../assets/base/clothingbench.png", 32, 16),
    ("../assets/base/carpentrybench.png", 32, 16),
    ("../assets/base/stairs.png", 48, 80),
    ("../assets/base/cloth.png", 16, 16),
    ("../assets/base/rope.png", 16, 16),
    ("../assets/base/stone.png", 16, 16),
    ("../assets/base/wood.png", 16, 16),
    ("../assets/base/grass.png", 16, 16),
    ("../assets/base/flower.png", 16, 16),
]

GRASS_TILES = 24
BASE_TILES = 24


def write_props_tsx() -> None:
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<tileset version="1.10" tiledversion="1.12.2" name="props" tilewidth="{TILE}" tileheight="{TILE}"'
        f' tilecount="{len(PROPS)}" columns="0">',
        ' <grid orientation="orthogonal" width="1" height="1"/>',
    ]
    for i, (src, w, h) in enumerate(PROPS):
        lines.append(f' <tile id="{i}">')
        lines.append(f'  <image width="{w}" height="{h}" source="{escape(src)}"/>')
        lines.append(" </tile>")
    lines.append("</tileset>")
    (TILED / "props.tsx").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("saved tiled/props.tsx")


def write_world_tmj() -> None:
    # 先算「哪些格子是泥土」，再按四邻挑过渡图块（和草地地图的规则一致）
    import math
    import random

    rng = random.Random(2026)
    dirt = [[False] * W for _ in range(H)]

    # 一条 5 格宽、蜿蜒南北的泥土路
    for y in range(H):
        cx = W // 2 + int(16 * math.sin(y / 14.0))
        for x in range(cx - 2, cx + 3):
            if 0 <= x < W:
                dirt[y][x] = True
    # 两片泥土空地
    for (ox, oy) in [(16, 14), (78, 74)]:
        for y in range(oy - 5, oy + 6):
            for x in range(ox - 6, ox + 7):
                if 0 <= x < W and 0 <= y < H and (x - ox) ** 2 / 36 + (y - oy) ** 2 / 25 <= 1.0:
                    dirt[y][x] = True

    data = [1] * (W * H)
    for y in range(H):
        for x in range(W):
            if not dirt[y][x]:
                # 草地上随机点缀草丛 / 蕨草
                data[y * W + x] = rng.choice([1, 1, 1, 2, 3, 4])
                continue
            mask = 0
            if y == 0 or not dirt[y - 1][x]:
                mask |= 1
            if x == W - 1 or not dirt[y][x + 1]:
                mask |= 2
            if y == H - 1 or not dirt[y + 1][x]:
                mask |= 4
            if x == 0 or not dirt[y][x - 1]:
                mask |= 8
            if mask == 0:
                data[y * W + x] = rng.choice([5, 6, 7, 8])
            else:
                data[y * W + x] = 9 + mask - 1

    layer = {
        "data": data,
        "height": H,
        "id": 1,
        "name": "Grass",
        "opacity": 1,
        "type": "tilelayer",
        "visible": True,
        "width": W,
        "x": 0,
        "y": 0,
    }
    props = {
        "draworder": "topdown",
        "id": 2,
        "name": "Props",
        "objects": [],
        "opacity": 1,
        "type": "objectgroup",
        "visible": True,
        "x": 0,
        "y": 0,
    }
    spawns = {
        "draworder": "topdown",
        "id": 3,
        "name": "Spawns",
        "objects": [],
        "opacity": 1,
        "type": "objectgroup",
        "visible": True,
        "x": 0,
        "y": 0,
    }
    tmj = {
        "compressionlevel": -1,
        "height": H,
        "infinite": False,
        "layers": [layer, props, spawns],
        "nextlayerid": 4,
        "nextobjectid": 1,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.12.2",
        "tileheight": TILE,
        "tilesets": [
            {"firstgid": 1, "source": "grass.tsx"},
            {"firstgid": 1 + GRASS_TILES, "source": "base.tsx"},
            {"firstgid": 1 + GRASS_TILES + BASE_TILES, "source": "props.tsx"},
        ],
        "tilewidth": TILE,
        "type": "map",
        "version": "1.10",
        "width": W,
    }
    import json

    (TILED / "world.tmj").write_text(
        json.dumps(tmj, indent=1, ensure_ascii=False), encoding="utf-8"
    )
    print("saved tiled/world.tmj")


def main() -> None:
    write_props_tsx()
    write_world_tmj()


if __name__ == "__main__":
    main()
