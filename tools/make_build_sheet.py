"""生成建造模式角色表：空手身体 + 手里拿着蓝图和扳手，四个方向都有。

做法：
1. 以 character_sheet_unarmed.png（身体 + 手）为底；
2. 用 gun 层的 cel 图找每一帧两只手的位置（肤色像素）；
3. 在靠左的手上画蓝图、靠右的手上画扳手，方向不同时朝向不同。

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

PAPER = (232, 236, 244, 255)    # 白条纹
PAPER_D = (40, 86, 160, 255)    # 蓝条纹
PAPER_L = (150, 190, 235, 255)  # 高光
WRENCH = (196, 202, 212, 255)
WRENCH_D = (120, 126, 138, 255)
OUTLINE = (26, 22, 38, 255)


def is_skin(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r >= 190 and g >= 130 and b >= 90 and r > g > b


def hands_of(image: Image):
    px = image.load()
    pts = [(x, y) for y in range(32) for x in range(32) if is_skin(px[x, y])]
    if not pts:
        return []
    left = [p for p in pts if p[0] < 16]
    right = [p for p in pts if p[0] >= 16]
    out = []
    for group in (left, right):
        if group:
            cx = sum(p[0] for p in group) / len(group)
            cy = sum(p[1] for p in group) / len(group)
            out.append((cx, cy))
    return out


def put(px, x, y, color):
    if 0 <= x < 32 and 0 <= y < 32:
        px[int(x), int(y)] = color


# 蓝图尺寸（横着的纸）
PAPER_W, PAPER_H = 13, 7


def draw_blueprint(px, cx, cy, direction):
    """横着的蓝白相间图纸：整张纸用蓝/白竖条纹，深色描边。"""
    cx, cy = int(round(cx)), int(round(cy))
    x0 = cx - PAPER_W // 2
    y0 = cy - PAPER_H // 2

    for x in range(PAPER_W):
        for y in range(PAPER_H):
            edge = x in (0, PAPER_W - 1) or y in (0, PAPER_H - 1)
            if edge:
                put(px, x0 + x, y0 + y, OUTLINE)
            else:
                # 蓝白相间：每 2 列换一次色
                stripe = ((x - 1) // 2) % 2
                put(px, x0 + x, y0 + y, PAPER_D if stripe == 0 else PAPER)
    # 顶部一条高光，像纸卷起
    for x in range(1, PAPER_W - 1):
        put(px, x0 + x, y0 + 1, PAPER_L if x % 2 == 0 else PAPER)


def draw_wrench(px, cx, cy, direction):
    """扳手：一根 2px 厚的杆 + 开口的 C 形头，指向外侧。"""
    cx, cy = int(round(cx)), int(round(cy))
    # 沿朝向的单位向量
    dirs = {0: (0, 1), 1: (0, -1), 2: (-1, 0), 3: (1, 0)}
    dx, dy = dirs[direction]
    perp = (dy, dx) if dx == 0 else (-dy, dx)   # 垂直方向（用来画杆的厚度）

    # 杆：从手往外 5 格，2px 厚
    for i in range(6):
        bx = cx + dx * i
        by = cy + dy * i
        put(px, bx, by, WRENCH)
        put(px, bx + perp[0], by + perp[1], WRENCH_D)

    # 头：在最外侧，C 形开口
    hx = cx + dx * 6
    hy = cy + dy * 6
    for s in (-1, 0, 1):
        put(px, hx + perp[0] * s, hy + perp[1] * s, WRENCH)
    put(px, hx + dx * 1 + perp[0] * -1, hy + dy * 1 + perp[1] * -1, WRENCH)
    put(px, hx + dx * 1 + perp[0] * 1, hy + dy * 1 + perp[1] * 1, WRENCH)
    put(px, hx + dx, hy + dy, OUTLINE)
    # 描边：杆两侧
    for i in range(6):
        put(px, cx + dx * i - perp[0], cy + dy * i - perp[1], OUTLINE)


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

            # 蓝图放两手中间，扳手在最外侧那只手
            mid_x = sum(h[0] for h in hands) / len(hands)
            mid_y = sum(h[1] for h in hands) / len(hands)
            draw_blueprint(px, mid_x + ox, mid_y + oy, direction)
            draw_wrench(px, hands[-1][0] + ox, hands[-1][1] + oy, direction)

            out.paste(frame, (i * 32, 0))

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main()
