"""用 TopDownFantasy-Forest 的素材生成草地地图：草地 + 泥土小路/空地（带柔和的草土过渡边缘）。

做三件事：
  1. 重做 `assets/tiles/grass_tiles.png`（128x48 / 8 列 x 3 行 / 24 格）
     - 1~4   : 草地（纯草 / 小草 / 蕨草 / 深色草）
     - 5~8   : 纯泥土（几种碎石变体，取自素材包）
     - 9~23  : 程序生成的草土过渡块（4 条边 + 4 个角 + 凹角，共 15 种邻接组合）
     - 24    : 泥土 + 草丛（取自素材包）
  2. 重写 `tiled/meadow.tmj` 的 Grass 层（20x20），泥土边缘自动挑过渡块
  3. 颜色全部取自素材包：草 163,179,21 / 草暗 112,128,26 / 深描边 75,67,23 / 土 164,97,43

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
SRC_COLS = 8

GRASS = (163, 179, 21)
GRASS_DARK = (112, 128, 26)
OUTLINE = (75, 67, 23)
DIRT = (164, 97, 43)
DIRT_DARK = (140, 80, 36)

# 图集 1~8 / 24 直接用素材包里的格子
PLAIN_GRASS = 9      # 1
DECOR_GRASS = [5, 13, 21]   # 2 3 4
PLAIN_DIRT = [6, 7, 14, 15]  # 5 6 7 8
DIRT_DECOR = 22      # 24

# 地图上的逻辑 id
T_GRASS = 1
T_DECOR = [2, 3, 4]
T_DIRT = [5, 6, 7, 8]
T_EDGE_BASE = 9      # 9 + (mask-1)，mask 1..15
T_DIRT_DECOR = 24

GRASS_MASK = 1       # 1~15 的 bitmap：N=1 E=2 S=4 W=8 表示「这一边是草地」


def src_tile(sheet: Image.Image, tid: int) -> Image.Image:
    gx, gy = tid % SRC_COLS, tid // SRC_COLS
    return sheet.crop((gx * 16, gy * 16, gx * 16 + 16, gy * 16 + 16))


def make_edge_tile(mask: int, rng: random.Random) -> Image.Image:
    """生成一块「泥土 + 某几边草地」的过渡块。"""
    img = Image.new("RGBA", (16, 16), DIRT + (255,))
    px = img.load()

    # 泥土上的细碎噪点
    for _ in range(6):
        px[rng.randrange(16), rng.randrange(16)] = DIRT_DARK + (255,)

    depth = {
        "N": [rng.randint(2, 5) for _ in range(16)],
        "S": [rng.randint(2, 5) for _ in range(16)],
        "W": [rng.randint(2, 5) for _ in range(16)],
        "E": [rng.randint(2, 5) for _ in range(16)],
    }

    for y in range(16):
        for x in range(16):
            grass_at = False
            border_at = False
            # 北
            if mask & 1:
                d = depth["N"][x]
                if y < d:
                    grass_at = True
                elif y == d:
                    border_at = True
            # 南
            if mask & 4:
                d = depth["S"][x]
                if y > 15 - d:
                    grass_at = True
                elif y == 15 - d:
                    border_at = True
            # 西
            if mask & 8:
                d = depth["W"][y]
                if x < d:
                    grass_at = True
                elif x == d:
                    border_at = True
            # 东
            if mask & 2:
                d = depth["E"][y]
                if x > 15 - d:
                    grass_at = True
                elif x == 15 - d:
                    border_at = True

            if border_at and not grass_at:
                px[x, y] = OUTLINE + (255,)
            elif grass_at:
                # 草地靠外亮、靠里暗一点
                px[x, y] = GRASS + (255,)

    # 草地内侧再压一条暗草边，看起来更厚。
    # 注意：贴图边界外的像素当作草地（不描边），否则每块贴图四周都会出现一圈直边阴影
    for y in range(16):
        for x in range(16):
            if px[x, y][:3] != GRASS:
                continue
            for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 16 and 0 <= ny < 16):
                    continue          # 出界 = 还是草地
                if px[nx, ny][:3] in (GRASS, GRASS_DARK):
                    continue
                px[x, y] = GRASS_DARK + (255,)
                break

    return img


def build_atlas() -> None:
    sheet = Image.open(SRC).convert("RGBA")
    rng = random.Random(7)
    out = Image.new("RGBA", (128, 48), (0, 0, 0, 0))

    tiles: dict[int, Image.Image] = {}
    tiles[1] = src_tile(sheet, PLAIN_GRASS)
    for i, tid in enumerate(DECOR_GRASS):
        tiles[2 + i] = src_tile(sheet, tid)
    for i, tid in enumerate(PLAIN_DIRT):
        tiles[5 + i] = src_tile(sheet, tid)
    for mask in range(1, 16):
        tiles[T_EDGE_BASE + mask - 1] = make_edge_tile(mask, rng)
    tiles[T_DIRT_DECOR] = src_tile(sheet, DIRT_DECOR)

    for tid, img in tiles.items():
        out.alpha_composite(img, (((tid - 1) % 8) * 16, ((tid - 1) // 8) * 16))
    out.save(ATLAS_OUT)
    print(f"saved {ATLAS_OUT} ({len(tiles)} tiles)")


def paint() -> list[int]:
    rng = random.Random(20261116)
    dirt = [[False] * W for _ in range(H)]

    # 蜿蜒小路（2 格宽）
    for y in range(1, H - 1):
        t = (y - 1) / (H - 2)
        x = 10 + math.sin(t * math.pi * 1.6) * 5.0 - t * 5.0
        for dx in (0, 1):
            cx = int(round(x)) + dx
            if 0 <= cx < W:
                dirt[y][cx] = True

    # 岔路
    for i, y in enumerate(range(9, 17)):
        x = 12 + i
        if 0 <= x < W:
            dirt[y][x] = True

    # 两块泥土空地
    for (ox, oy, r) in [(4, 5, 2.8), (15, 14, 2.4)]:
        for y in range(H):
            for x in range(W):
                if (x - ox) ** 2 + (y - oy) ** 2 <= r * r:
                    dirt[y][x] = True

    grid = [[T_GRASS] * W for _ in range(H)]

    # 泥土格：按四邻是不是草地挑过渡块
    for y in range(H):
        for x in range(W):
            if not dirt[y][x]:
                continue
            mask = 0
            if y > 0 and not dirt[y - 1][x]:
                mask |= 1
            if x < W - 1 and not dirt[y][x + 1]:
                mask |= 2
            if y < H - 1 and not dirt[y + 1][x]:
                mask |= 4
            if x > 0 and not dirt[y][x - 1]:
                mask |= 8
            # 地图边界外侧也算草地，这样贴边不会出现硬边
            if y == 0:
                mask |= 1
            if x == W - 1:
                mask |= 2
            if y == H - 1:
                mask |= 4
            if x == 0:
                mask |= 8
            if mask == 0:
                grid[y][x] = rng.choice(T_DIRT)
            else:
                grid[y][x] = T_EDGE_BASE + mask - 1

    # 草地点缀
    for y in range(H):
        for x in range(W):
            if grid[y][x] == T_GRASS and rng.random() < 0.14:
                grid[y][x] = rng.choice(T_DECOR)

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
    write_map(paint())


if __name__ == "__main__":
    main()
