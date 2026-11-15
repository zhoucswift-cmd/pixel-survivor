"""僵尸精灵表的带标签预览（每行一个动画）。"""
from PIL import Image, ImageDraw, ImageFont

SRC = r"C:\game\test\assets\zombie_sheet.png"
OUT = r"C:\game\test\docs\zombie_preview.png"

FRAME = 32
SCALE = 5
LABELS = [
    ("idle_down", 1), ("walk_down", 4), ("attack_down", 3),
    ("idle_up", 1), ("walk_up", 4), ("attack_up", 3),
    ("idle_left", 1), ("walk_left", 4), ("attack_left", 3),
    ("idle_right", 1), ("walk_right", 4), ("attack_right", 3),
]

sheet = Image.open(SRC).convert("RGBA")
cols = max(c for _, c in LABELS)
cell = FRAME * SCALE
pad = 6
label_w = 130
W = label_w + cols * (cell + pad) + pad
H = len(LABELS) * (cell + pad) + pad + 24

canvas = Image.new("RGB", (W, H), (30, 32, 40))
draw = ImageDraw.Draw(canvas)
try:
    font = ImageFont.truetype("consola.ttf", 14)
    small = ImageFont.truetype("consola.ttf", 9)
except Exception:
    font = ImageFont.load_default()
    small = font

draw.text((pad, 4), "zombie_sheet.png (32x32, 32 frames)", font=font, fill=(235, 238, 245))

idx = 0
for row, (name, count) in enumerate(LABELS):
    y = 22 + pad + row * (cell + pad)
    draw.text((pad, y + cell // 2 - 8), name, font=font, fill=(205, 214, 232))
    for c in range(count):
        tile = sheet.crop((idx * FRAME, 0, idx * FRAME + FRAME, FRAME))
        big = tile.resize((cell, cell), Image.NEAREST)
        x = label_w + pad + c * (cell + pad)
        for gy in range(0, cell, SCALE * 4):
            for gx in range(0, cell, SCALE * 4):
                shade = 56 if ((gx // (SCALE * 4)) + (gy // (SCALE * 4))) % 2 == 0 else 46
                draw.rectangle([x + gx, y + gy, x + gx + SCALE * 4 - 1, y + gy + SCALE * 4 - 1],
                               fill=(shade, shade + 4, shade + 10))
        canvas.paste(big, (x, y), big)
        draw.rectangle([x, y, x + cell, y + cell], outline=(84, 90, 106))
        draw.text((x + 2, y + 2), str(idx), font=small, fill=(255, 220, 120))
        idx += 1

canvas.save(OUT, "PNG")
print("saved", OUT, canvas.size)
