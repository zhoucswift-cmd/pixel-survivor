"""生成基地背景图的制作模板：1036x582，标出「平台遮住的部分」和「会被看到的部分」。

背景图在场景里放在世界 (-278, -51)，所以：
  图片像素 (278, 51) = 世界 (0, 0) = 平台左上角
  平台 480x480 → 图片 (278,51) ~ (758,531)

运行: python tools/make_city_template.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(r"C:\game\test")
W, H = 1036, 582
PLATFORM = (278, 51, 278 + 480, 51 + 480)

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img, "RGBA")

# 会被看到的部分：深蓝半透明
d.rectangle((0, 0, W - 1, H - 1), fill=(30, 40, 60, 120))

# 平台区域（会被屋顶挡住，可以随便画）
d.rectangle(PLATFORM, fill=(200, 30, 120, 110))

# 16px 网格（对齐瓦片用）
for x in range(0, W, 16):
    c = (255, 255, 255, 26) if x % 80 else (255, 255, 255, 64)
    d.line((x, 0, x, H - 1), fill=c)
for y in range(0, H, 16):
    c = (255, 255, 255, 26) if y % 80 else (255, 255, 255, 64)
    d.line((0, y, W - 1, y), fill=c)

# 平台边界
d.rectangle(PLATFORM, outline=(255, 80, 160, 255), width=3)

img.save(ROOT / "docs" / "city_background_template.png")
print(f"saved docs/city_background_template.png {W}x{H}")
