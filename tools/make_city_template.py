"""生成基地背景图的制作模板：800x800，标出「平台遮住的部分」和「会被看到的部分」。

运行: python tools/make_city_template.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"C:\game\test")
W = H = 800
PLATFORM = (160, 160, 640, 640)   # 平台在图片里的位置（世界坐标 0,0 ~ 480,480）

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img, "RGBA")

# 会被看到的一圈：深蓝色半透明
d.rectangle((0, 0, W - 1, H - 1), fill=(30, 40, 60, 120))

# 平台区域：洋红半透明（这块会被屋顶挡住，随便画）
d.rectangle(PLATFORM, fill=(200, 30, 120, 110))

# 16px 网格（对齐瓦片用）
for x in range(0, W, 16):
    c = (255, 255, 255, 26) if x % 80 else (255, 255, 255, 64)
    d.line((x, 0, x, H - 1), fill=c)
for y in range(0, H, 16):
    c = (255, 255, 255, 26) if y % 80 else (255, 255, 255, 64)
    d.line((0, y, W - 1, y), fill=c)

# 平台边界（粗描边）
for w, col in ((3, (255, 80, 160, 255)),):
    d.rectangle(PLATFORM, outline=col, width=w)

# 四边中间的标记线（平台中心十字）
cx, cy = PLATFORM[0] + (PLATFORM[2] - PLATFORM[0]) // 2, PLATFORM[1] + (PLATFORM[3] - PLATFORM[1]) // 2
d.line((cx, 0, cx, H - 1), fill=(255, 255, 255, 40))
d.line((0, cy, W - 1, cy), fill=(255, 255, 255, 40))

img.save(ROOT / "docs" / "city_background_template.png")
print("saved docs/city_background_template.png")
