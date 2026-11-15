from PIL import Image

src = Image.open(r"C:\game\test\assets\character_sheet.png").convert("RGBA")
idxs = [0, 1, 5, 7, 8, 12, 14, 15, 19, 21, 22, 26]
S = 14
cell = 32 * S
pad = 8
out = Image.new("RGB", (len(idxs) * (cell + pad) + pad, cell + 2 * pad), (40, 42, 52))
for i, idx in enumerate(idxs):
    f = src.crop((idx * 32, 0, idx * 32 + 32, 32)).resize((cell, cell), Image.NEAREST)
    out.paste(f, (pad + i * (cell + pad), pad), f)
out.save(r"C:\game\test\docs\zoom.png")
print(out.size)
