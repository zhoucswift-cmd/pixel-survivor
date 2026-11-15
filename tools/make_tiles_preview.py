"""生成草皮瓦片集的带编号预览图（给 README 和肉眼检查用）。"""
from PIL import Image, ImageDraw, ImageFont

SRC = r"C:\game\test\assets\tiles\grass_tiles.png"
OUT = r"C:\game\test\docs\grass_tiles_preview.png"

TILE = 16
SCALE = 8
COLS, ROWS = 8, 3
PAD = 6
LABEL = 18

sheet = Image.open(SRC).convert("RGBA")
cell = TILE * SCALE
W = COLS * (cell + PAD) + PAD
H = ROWS * (cell + PAD + LABEL) + PAD

canvas = Image.new("RGB", (W, H), (28, 30, 36))
draw = ImageDraw.Draw(canvas)
try:
    font = ImageFont.truetype("consola.ttf", 13)
except Exception:
    font = ImageFont.load_default()

for row in range(ROWS):
    for col in range(COLS):
        idx = row * COLS + col
        tile = sheet.crop((col * TILE, row * TILE, col * TILE + TILE, row * TILE + TILE))
        big = tile.resize((cell, cell), Image.NEAREST)
        x = PAD + col * (cell + PAD)
        y = PAD + row * (cell + PAD + LABEL)
        canvas.paste(big, (x, y), big)
        draw.rectangle([x, y, x + cell - 1, y + cell - 1], outline=(70, 76, 92))
        draw.text((x + 2, y + cell + 2), f"#{idx}", font=font, fill=(235, 240, 250))

canvas.save(OUT, "PNG")
print("saved", OUT, canvas.size)
