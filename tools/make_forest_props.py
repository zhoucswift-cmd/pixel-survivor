"""从 TopDownFantasy-Forest 里抠出场景用的道具贴图（树 / 灌木 / 蘑菇 / 木头 / 芦苇 / 石头 / 水塘）。

运行: python tools/make_forest_props.py
"""
from pathlib import Path

from collections import deque

from PIL import Image

DECO = Path(r"C:\game\TopDownFantasy-Forest\Decorations\Decorations.png")
TILES = Path(r"C:\game\TopDownFantasy-Forest\Tiles\Tileset.png")
OUT = Path(r"C:\game\test\assets\forest")

# 名字 -> (来源, 裁剪框)
CROPS = {
    "tree_a": (DECO, (4, 136, 84, 254)),
    "tree_b": (DECO, (86, 138, 166, 252)),
    "tree_c": (DECO, (168, 158, 212, 252)),
    "tree_d": (DECO, (214, 158, 252, 252)),
    "bush": (DECO, (10, 0, 50, 32)),
    "log": (DECO, (62, 0, 122, 34)),
    "mushrooms": (DECO, (158, 4, 190, 26)),
    "reeds": (DECO, (62, 62, 118, 110)),
    "rock": (DECO, (158, 110, 196, 142)),
    "pond": (TILES, (0, 160, 48, 208)),
}


def drop_specks(img: Image.Image, keep_ratio: float = 0.12) -> Image.Image:
    """去掉零散的小碎片（只保留最大的几块连通区域）。"""
    w, h = img.size
    px = img.load()
    seen = [[False] * h for _ in range(w)]
    comps: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if seen[x][y] or px[x, y][3] == 0:
                continue
            comp = []
            q = deque([(x, y)])
            seen[x][y] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[nx][ny] and px[nx, ny][3] > 0:
                        seen[nx][ny] = True
                        q.append((nx, ny))
            comps.append(comp)
    if not comps:
        return img
    biggest = max(len(c) for c in comps)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    opx = out.load()
    for comp in comps:
        if len(comp) < biggest * keep_ratio:
            continue
        for (x, y) in comp:
            opx[x, y] = px[x, y]
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cache: dict[Path, Image.Image] = {}
    for name, (src, box) in CROPS.items():
        if src not in cache:
            cache[src] = Image.open(src).convert("RGBA")
        img = cache[src].crop(box)
        img = drop_specks(img)
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
        img.save(OUT / f"{name}.png")
        print(f"{name}.png  {img.size}")


if __name__ == "__main__":
    main()
