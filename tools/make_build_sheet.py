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

PAPER = (232, 226, 208, 255)    # 米白图纸
PAPER_D = (186, 178, 156, 255)
PAPER_L = (58, 106, 168, 255)   # 蓝图线条
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


def draw_blueprint(px, cx, cy, direction):
    """一卷蓝图：米白纸 + 蓝图线条 + 深色描边。"""
    cx, cy = int(round(cx)), int(round(cy))
    if direction in (2, 3):   # 左右：横着拿
        w, h = 8, 5
    else:                     # 上下：竖着拿
        w, h = 5, 8
    x0, y0 = cx - w // 2, cy - h // 2
    for x in range(w):
        for y in range(h):
            edge = x in (0, w - 1) or y in (0, h - 1)
            put(px, x0 + x, y0 + y, OUTLINE if edge else PAPER)
    # 内部再压一圈浅灰，显得是卷起的纸
    for x in range(1, w - 1):
        put(px, x0 + x, y0 + 1, PAPER_D)
    # 蓝图线条
    if w > h:
        for x in range(2, w - 2, 2):
            put(px, x0 + x, y0 + 2, PAPER_L)
            put(px, x0 + x, y0 + 3, PAPER_L)
    else:
        for y in range(3, h - 1, 2):
            put(px, x0 + 1, y0 + y, PAPER_L)
            put(px, x0 + 2, y0 + y, PAPER_L)


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

            draw_blueprint(px, hands[0][0] + ox, hands[0][1] + oy, direction)
            draw_wrench(px, hands[-1][0] + ox, hands[-1][1] + oy, direction)

            out.paste(frame, (i * 32, 0))

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main()
