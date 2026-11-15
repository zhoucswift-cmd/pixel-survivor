from PIL import Image, ImageDraw

src = Image.open(r"C:\game\test\assets\crosshair.png").convert("RGBA")
S = 10
W, H = 13, 13
cell = W * S
pad = 10
GREEN = (67, 82, 69, 255)
BROWN = (138, 98, 57, 255)

out = Image.new("RGB", (pad + 3*(cell+pad), cell + 2*pad), (26, 27, 34))
items = [(0, GREEN), (0, BROWN), (1, GREEN)]
for i, (frame, bg) in enumerate(items):
    sprite = src.crop((frame*13, 0, frame*13+13, 13))
    panel = Image.new("RGBA", (W, H), bg)
    panel.alpha_composite(sprite)
    out.paste(panel.resize((cell, cell), Image.NEAREST).convert("RGB"), (pad + i*(cell+pad), pad))
out.save(r"C:\game\test\docs\crosshair_preview.png")
print("ok", out.size)
