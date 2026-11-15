"""四方向走路 + 射击的 GIF 预览（把枪口火焰直接合成进去）。"""
from PIL import Image

SRC = r"C:\game\test\assets\character_sheet.png"
FLASH = r"C:\game\test\assets\muzzle_flash.png"
OUT = r"C:\game\test\docs\walk_cycle.gif"
SCALE = 2
PAD = 8
SIZE = 32 * SCALE
CANVAS = SIZE + PAD * 2
BG = (43, 51, 45)
DURATION = 110

# 枪口在 32x32 精灵里的位置（与 player.gd 的 MUZZLE_OFFSETS 对应）
MUZZLE = {
    "down": (16.5, 26.0),
    "up": (22.5, 8.0),
    "left": (3.0, 17.5),
    "right": (29.0, 17.5),
}

sheet = Image.open(SRC).convert("RGBA")
flash_sheet = Image.open(FLASH).convert("RGBA")
flash_img = flash_sheet.crop((0, 0, 24, 24))  # 第一帧，最大的爆闪

DIRS = [("down", 0), ("up", 7), ("left", 14), ("right", 21)]
frames = []


def frame_with(idx, flash_dir=None):
    cell = Image.new("RGBA", (32 * SCALE, 32 * SCALE), (0, 0, 0, 0))
    sprite = sheet.crop((idx * 32, 0, idx * 32 + 32, 32)).resize((SIZE, SIZE), Image.NEAREST)
    cell.alpha_composite(sprite)
    if flash_dir:
        fx, fy = MUZZLE[flash_dir]
        big = flash_img.resize((24 * SCALE, 24 * SCALE), Image.NEAREST)
        # 24x24 火焰的中心在 (12,12)，对齐到枪口
        cell.alpha_composite(big, (int((fx + 0.5 - 12) * SCALE), int((fy + 0.5 - 12) * SCALE)))
    out = Image.new("RGB", (CANVAS, CANVAS), BG)
    out.paste(cell, (PAD, PAD), cell)
    return out


for _ in range(2):
    for name, base in DIRS:
        frames.append(frame_with(base))                     # idle
        for i in range(1, 5):
            frames.append(frame_with(base + i))             # walk
        frames.append(frame_with(base + 5, flash_dir=name))  # shoot 第 1 帧 + 枪口火焰
        frames.append(frame_with(base + 6))                  # shoot 第 2 帧

durations = [DURATION] * len(frames)
for i, f in enumerate(frames):
    if i % 8 in (5, 6):
        durations[i] = 150

frames[0].save(OUT, save_all=True, append_images=frames[1:], duration=durations,
               loop=0, optimize=True, disposal=2)
print("saved", OUT, len(frames), "frames")
