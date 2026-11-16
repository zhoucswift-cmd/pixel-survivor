"""从 pixel_16_woods 素材表里抠出石头 / 草 / 花，做成游戏里的 16x16 资源贴图。

运行: python tools/make_woods_items.py
"""
from pathlib import Path

from PIL import Image

SHEET = Path(r"C:\game\pixel_16_woods v2 free\pixel_16_woods v2 free\free_pixel_16_woods.png")
OUT = Path(r"C:\game\test\assets\base")

# (格坐标, 输出文件名)
ITEMS = {
    "stone": (14, 2),
    "grass": (14, 3),
    "flower": (16, 3),
}


def extract(sheet: Image.Image, gx: int, gy: int) -> Image.Image:
    """把某个格子附近的图抠出来（按 alpha 包围盒裁掉空白），居中放进 16x16。"""
    # 只取这一格，避免把相邻格子里的东西一起带走
    box = (gx * 16, gy * 16, gx * 16 + 16, gy * 16 + 16)
    patch = sheet.crop(box)
    bbox = patch.getbbox()
    if bbox:
        patch = patch.crop(bbox)
    canvas = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    ox = (16 - patch.width) // 2
    oy = (16 - patch.height) // 2
    canvas.alpha_composite(patch, (max(ox, 0), max(oy, 0)))
    return canvas


def main() -> None:
    sheet = Image.open(SHEET).convert("RGBA")
    for name, (gx, gy) in ITEMS.items():
        img = extract(sheet, gx, gy)
        path = OUT / f"{name}.png"
        img.save(path)
        print(f"saved {path.name}")


if __name__ == "__main__":
    main()
