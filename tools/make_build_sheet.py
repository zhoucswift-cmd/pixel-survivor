"""生成建造模式角色表：空手身体 + 双手捧着一张蓝白相间的图纸，四个方向都有。

做法：
1. 以 character_sheet_unarmed.png（身体 + 手）为底；
2. 用 gun 层的 cel 图算每一帧两只手的中点；
3. 在中点前方画一张蓝白条纹的图纸，再在图纸左右两边画上手。

输出 assets/character_sheet_build.png（896x32，28 帧，和角色表同布局）。
运行: python tools/make_build_sheet.py
"""
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(r"C:\game\test")
ASEPRITE = Path(r"C:\game\Aseprite.v1.3.17\Aseprite.exe")
LUA = ROOT / "tools" / "dump_gun_frames.lua"
SOURCE = ROOT / "assets" / "character.aseprite"
UNARMED = ROOT / "assets" / "character_sheet_unarmed.png"
OUTPUT = ROOT / "assets" / "character_sheet_build.png"

OUTLINE = (26, 22, 38, 255)
PAPER = (232, 236, 244, 255)      # 白条纹
PAPER_D = (40, 86, 160, 255)       # 蓝条纹
PAPER_L = (150, 190, 235, 255)     # 高光
SKIN = (242, 196, 158, 255)        # 手
SKIN_D = (214, 158, 118, 255)

# 蓝图尺寸：像一张摊开的报纸
PAPER_W, PAPER_H = 16, 11


def draw_blueprint(px, cx, cy, direction):
    """蓝白相间的图纸：每 2 列换一次色，深色描边。"""
    cx, cy = int(round(cx)), int(round(cy))
    x0 = cx - PAPER_W // 2
    y0 = cy - PAPER_H // 2

    for x in range(PAPER_W):
        for y in range(PAPER_H):
            if x in (0, PAPER_W - 1) or y in (0, PAPER_H - 1):
                put(px, x0 + x, y0 + y, OUTLINE)
            else:
                stripe = ((x - 1) // 2) % 2
                put(px, x0 + x, y0 + y, PAPER_D if stripe == 0 else PAPER)

    # 上下各压一条浅色边，像纸的卷边
    for x in range(1, PAPER_W - 1):
        put(px, x0 + x, y0 + 1, PAPER_L if x % 3 else PAPER)
    return x0, y0


def draw_hands(px, x0, y0):
    """两只手按在图纸的左右两边。"""
    for side in (0, 1):
        hx = x0 + 1 if side == 0 else x0 + PAPER_W - 3
        hy = y0 + PAPER_H // 2 - 2
        for dx in range(2):
            for dy in range(4):
                put(px, hx + dx, hy + dy, SKIN)
        put(px, hx, hy + 4, SKIN_D)
        put(px, hx + 1, hy + 4, SKIN_D)


def is_skin(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r >= 190 and g >= 130 and b >= 90 and r > g > b


def put(px, x, y, color):
    if 0 <= x < 32 and 0 <= y < 32:
        px[int(x), int(y)] = color


def hands_of(image: Image):
    """找出这一帧两只手的位置（左上 / 右半个 x）。"""
    px = image.load()
    pts = [(x, y) for y in range(32) for x in range(32) if is_skin(px[x, y])]
    if not pts:
        return []
    out = []
    for group in ([p for p in pts if p[0] < 16], [p for p in pts if p[0] >= 16]):
        if group:
            out.append((sum(p[0] for p in group) / len(group),
                        sum(p[1] for p in group) / len(group)))
    return out


def dump_gun_frames(tmp: Path) -> None:
    text = LUA.read_text(encoding="utf-8").replace("C:/game/test/docs/", tmp.as_posix() + "/")
    patched = tmp / "dump.lua"
    patched.write_text(text, encoding="utf-8")
    subprocess.run([str(ASEPRITE), "-b", str(SOURCE), "--script", str(patched)],
                   check=True, capture_output=True)


def main() -> None:
    sheet = Image.open(UNARMED).convert("RGBA")
    out = sheet.copy()

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        dump_gun_frames(tmp)

        for i in range(28):
            direction = i // 7
            frame = out.crop((i * 32, 0, (i + 1) * 32, 32))
            px = frame.load()

            gun = Image.open(tmp / f"_gunframe_{i + 1:02d}.png").convert("RGBA")
            hands = hands_of(gun)
            if not hands:
                hands = [(13.0, 20.0), (20.0, 20.0)]

            ox, oy = 0, 0
            if direction == 0:
                oy = 1
            elif direction == 1:
                oy = -1
            elif direction == 2:
                ox = -1
            else:
                ox = 1

            # 蓝图在身前，双手按在图纸左右两边
            mid_x = sum(h[0] for h in hands) / len(hands)
            mid_y = sum(h[1] for h in hands) / len(hands)
            x0, y0 = draw_blueprint(px, mid_x, mid_y + 2, direction)
            draw_hands(px, x0, y0)

            out.paste(frame, (i * 32, 0))

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main()
