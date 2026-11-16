"""用 TopDownFantasy-Forest 的图集生成一张好看的草地地图（草地 + 泥土小路 + 草丛）。

同时做两件事：
  1. 重做 `assets/tiles/grass_tiles.png`（仍然 128x48 / 8 列 x 3 行 / 24 格）
  2. 重写 `tiled/meadow.tmj` 的 Grass 层（20x20），保持地图尺寸和 layers 结构不变

运行: python tools/make_forest_meadow.py
"""
import json
import math
import random
from pathlib import Path

from PIL import Image

SRC = Path(r"C:\game\TopDownFantasy-Forest\Tiles\Tileset.png")
ATLAS_OUT = Path(r"C:\game\test\assets\tiles\grass_tiles.png")
MAP_OUT = Path(r"C:\game\test\tiled\meadow.tmj")

W = H = 20
COLS = 8  # 源图集列数

# 新图集 24 格各自用源图的哪一格（0-based）
# 只用「整块完全不透明」的源格子（其它格子四周是透明的，铺开会有黑块）
ATLAS = [
    9,   # 1  纯草地
    5,   # 2  草地 + 小草
    13,  # 3  草地 + 蕨草
    21,  # 4  草地 + 深色草丛
    9,   # 5  纯草地
    5,   # 6
    13,  # 7
    21,  # 8
    6,   # 9  泥土（纯）
    7,   # 10 泥土（碎石）
    14,  # 11 泥土（石块）
    15,  # 12 泥土（碎石 2）
    22,  # 13 泥土 + 草
    23,  # 14 泥土（纯 2）
    9,   # 15
    6,   # 16
    7,   # 17
    13,  # 18
    21,  # 19
    22,  # 20
    15,  # 21
    14,  # 22
    5,   # 23
    23,  # 24
]

GRASS = 1
DIRT = [9, 10, 11, 12, 13, 14]
DECOR = [2, 3, 4, 6, 7, 8]


def build_atlas() -> None:
    sheet = Image.open(SRC).convert("RGBA")
    out = Image.new("RGBA", (128, 48), (0, 0, 0, 0))
    for i, tid in enumerate(ATLAS):
        gx, gy = tid % COLS, tid // COLS
        tile = sheet.crop((gx * 16, gy * 16, gx * 16 + 16, gy * 16 + 16))
        out.alpha_composite(tile, ((i % 8) * 16, (i // 8) * 16))
    out.save(ATLAS_OUT)
    print(f"saved {ATLAS_OUT}")


def paint_map() -> list[int]:
    rng = random.Random(20261116)
    grid = [[GRASS] * W for _ in range(H)]

    # --- 泥土小路：从上边中间蜿蜒到底部左侧，2 格宽 ---
    path = []
    for y in range(1, H - 1):
        t = (y - 1) / (H - 2)
        x = 10 + math.sin(t * math.pi * 1.6) * 5.0 - t * 5.0
        path.append((y, int(round(x))))
    for y, x in path:
        for dx in (0, 1):
            cx = x + dx
            if 1 <= cx < W - 1:
                grid[y][cx] = rng.choice(DIRT)

    # --- 岔路：从主路往右下引出一条 1 格宽的小路 ---
    for i, y in enumerate(range(9, 17)):
        x = 12 + i
        if 1 <= x < W - 1:
            grid[y][x] = rng.choice(DIRT)

    # --- 泥土空地：左上和右下各一块 ---
    for (ox, oy, r) in [(4, 5, 2.6), (15, 14, 2.2)]:
        for y in range(H):
            for x in range(W):
                if (x - ox) ** 2 + (y - oy) ** 2 <= r * r:
                    if 1 <= x < W - 1 and 1 <= y < H - 1:
                        grid[y][x] = rng.choice(DIRT)

    # --- 草地点缀（不盖住泥土和边缘） ---
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if grid[y][x] != GRASS:
                continue
            if rng.random() < 0.16:
                grid[y][x] = rng.choice(DECOR)

    return [grid[y][x] for y in range(H) for x in range(W)]


def write_map(data: list[int]) -> None:
    tmj = json.loads(MAP_OUT.read_text(encoding="utf-8"))
    for layer in tmj["layers"]:
        if layer.get("type") == "tilelayer" and layer.get("name") == "Grass":
            layer["data"] = data
    MAP_OUT.write_text(json.dumps(tmj, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"saved {MAP_OUT}")


def main() -> None:
    build_atlas()
    write_map(paint_map())


if __name__ == "__main__":
    main()
