"""从 TopDownFantasy-Forest 里抠出场景用的道具贴图（树 / 灌木 / 蘑菇 / 木头 / 芦苇 / 石头 / 水塘）。

运行: python tools/make_forest_props.py
"""
from pathlib import Path

from PIL import Image

DECO = Path(r"C:\game\TopDownFantasy-Forest\Decorations\Decorations.png")
TILES = Path(r"C:\game\TopDownFantasy-Forest\Tiles\Tileset.png")
OUT = Path(r"C:\game\test\assets\forest")

# 名字 -> (来源, 裁剪框)
CROPS = {
    "tree_a": (DECO, (154, 158, 202, 242)),
    "tree_b": (DECO, (0, 160, 56, 242)),
    "tree_c": (DECO, (98, 160, 152, 242)),
    "bush": (DECO, (10, 0, 50, 32)),
    "log": (DECO, (62, 0, 122, 34)),
    "mushrooms": (DECO, (158, 4, 190, 26)),
    "reeds": (DECO, (62, 62, 118, 110)),
    "rock": (DECO, (158, 110, 196, 142)),
    "pond": (TILES, (0, 160, 48, 208)),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cache: dict[Path, Image.Image] = {}
    for name, (src, box) in CROPS.items():
        if src not in cache:
            cache[src] = Image.open(src).convert("RGBA")
        img = cache[src].crop(box)
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        img.save(OUT / f"{name}.png")
        print(f"{name}.png  {img.size}")


if __name__ == "__main__":
    main()
