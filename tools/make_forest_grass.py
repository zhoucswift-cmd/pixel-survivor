"""用 TopDownFantasy-Forest 的草皮重做草地贴图 `assets/tiles/grass_tiles.png`。

保持 128x48 / 8 列 x 3 行 / 24 格不变，所以 `grass_tileset.tres` 和 `meadow.tmj` 都不用改：
  index 0..9   (地图 id 1..10) 纯草地（几种带细碎纹理的变体 + 镜像）
  index 10..13 (地图 id 11..14) 带装饰的草地（蕨草 / 草丛）
  index 14..23 (地图 id 15..24) 纯草地

运行: python tools/make_forest_grass.py
"""
from pathlib import Path

from PIL import Image

SRC = Path(r"C:\game\TopDownFantasy-Forest\Tiles\Tileset.png")
OUT = Path(r"C:\game\test\assets\tiles\grass_tiles.png")

COLS = 8


def tile(sheet: Image.Image, tid: int) -> Image.Image:
    gx, gy = tid % COLS, tid // COLS
    return sheet.crop((gx * 16, gy * 16, gx * 16 + 16, gy * 16 + 16))


def flipped(img: Image.Image, fx: bool, fy: bool) -> Image.Image:
    out = img
    if fx:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    if fy:
        out = out.transpose(Image.FLIP_TOP_BOTTOM)
    return out


# 只有 9 是整块不透明、颜色均匀的纯草地（33 带上下渐变，铺开会有棋盘格）
PLAIN = [9]
# 带装饰的草地：蕨草 / 草丛 / 小叶
DECO = [5, 13, 21]


def main() -> None:
    sheet = Image.open(SRC).convert("RGBA")
    out = Image.new("RGBA", (128, 48), (0, 0, 0, 0))

    slots: list[Image.Image] = []

    # 0..9 纯草地（轮着用不同变体，再镜像出更多花色）
    for i in range(10):
        base = tile(sheet, PLAIN[i % len(PLAIN)])
        slots.append(flipped(base, i % 2 == 1, i % 3 == 2))

    # 10..13 带装饰
    for i in range(4):
        base = tile(sheet, DECO[i % len(DECO)])
        slots.append(flipped(base, i % 2 == 1, False))

    # 14..23 纯草地
    for i in range(10):
        base = tile(sheet, PLAIN[(i + 3) % len(PLAIN)])
        slots.append(flipped(base, i % 3 == 0, i % 2 == 1))

    for i, img in enumerate(slots):
        out.alpha_composite(img, ((i % COLS) * 16, (i // COLS) * 16))

    out.save(OUT)
    print(f"saved {OUT}")


if __name__ == "__main__":
    main()
