"""把导出的精灵表放大并加标签，方便肉眼检查像素画。"""
from PIL import Image, ImageDraw, ImageFont

SRC = r"C:\game\test\assets\character_sheet.png"
OUT = r"C:\game\test\docs\preview.png"

FRAME = 32
SCALE = 6
LABELS = [
    ("idle_down", 1), ("walk_down", 4), ("shoot_down", 2),
    ("idle_up", 1), ("walk_up", 4), ("shoot_up", 2),
    ("idle_left", 1), ("walk_left", 4), ("shoot_left", 2),
    ("idle_right", 1), ("walk_right", 4), ("shoot_right", 2),
]

sheet = Image.open(SRC).convert("RGBA")
cols = max(c for _, c in LABELS)
rows = len(LABELS)

cell = FRAME * SCALE
pad = 8
label_w = 150
W = label_w + cols * (cell + pad) + pad
H = rows * (cell + pad) + pad + 26

canvas = Image.new("RGBA", (W, H), (32, 34, 44, 255))
draw = ImageDraw.Draw(canvas)
try:
    font = ImageFont.truetype("consola.ttf", 15)
    small = ImageFont.truetype("consola.ttf", 10)
except Exception:
    font = ImageFont.load_default()
    small = font

draw.text((pad, 5), "character_sheet.png  (32x32, 28 frames)", font=font, fill=(235, 238, 245, 255))

idx = 0
for r, (name, count) in enumerate(LABELS):
    y = 26 + pad + r * (cell + pad)
    draw.text((pad, y + cell // 2 - 8), f"{name} x{count}", font=font, fill=(205, 214, 232, 255))
    for c in range(count):
        src = sheet.crop((idx * FRAME, 0, idx * FRAME + FRAME, FRAME))
        big = src.resize((cell, cell), Image.NEAREST)
        x = label_w + pad + c * (cell + pad)
        for gy in range(0, cell, SCALE * 4):
            for gx in range(0, cell, SCALE * 4):
                shade = 58 if ((gx // (SCALE * 4)) + (gy // (SCALE * 4))) % 2 == 0 else 46
                draw.rectangle([x + gx, y + gy, x + gx + SCALE * 4 - 1, y + gy + SCALE * 4 - 1],
                               fill=(shade, shade + 4, shade + 12, 255))
        canvas.alpha_composite(big, (x, y))
        draw.rectangle([x, y, x + cell, y + cell], outline=(90, 96, 115, 255))
        draw.text((x + 2, y + 2), str(idx), font=small, fill=(255, 220, 120, 210))
        idx += 1

canvas.convert("RGB").save(OUT, "PNG")
print("saved", OUT, canvas.size)
