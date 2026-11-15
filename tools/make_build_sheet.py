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

PAPER = (206, 220, 240, 255)      # 抬头浅底
PAPER_D = (28, 62, 122, 255)      # 蓝图纸底
PAPER_L = (222, 232, 245, 255)    # 白色图线
PA_GRID = (52, 96, 168, 255)      # 淡蓝网格
PA_HEAD = (30, 70, 140, 255)      # 标题文字
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


# 蓝图尺寸：像一张报纸（比人物躯干还宽一点）
PAPER_W, PAPER_H = 16, 11


def draw_blueprint(px, cx, cy, direction):
    """一张摊开的蓝图：蓝纸 + 白色工程图线（边框、网格、矩形、圆、尺寸线）。"""
    cx, cy = int(round(cx)), int(round(cy))
    x0 = cx - PAPER_W // 2
    y0 = cy - PAPER_H // 2

    # 纸边（深色描边）
    for x in range(PAPER_W):
        for y in range(PAPER_H):
            if x in (0, PAPER_W - 1) or y in (0, PAPER_H - 1):
                put(px, x0 + x, y0 + y, OUTLINE)

    # 蓝底
    for x in range(1, PAPER_W - 1):
        for y in range(1, PAPER_H - 1):
            put(px, x0 + x, y0 + y, PAPER_D)

    # 抬头（浅蓝横条 + 标题线）
    for x in range(1, PAPER_W - 1):
        put(px, x0 + x, y0 + 1, PAPER)
    for x in range(2, 9):
        put(px, x0 + x, y0 + 2, PA_HEAD)

    # 网格（淡蓝）
    for y in range(4, PAPER_H - 2, 3):
        for x in range(1, PAPER_W - 1):
            put(px, x0 + x, y0 + y, PA_GRID)
    for x in range(3, PAPER_W - 1, 5):
        for y in range(4, PAPER_H - 2):
            put(px, x0 + x, y0 + y, PA_GRID)

    # 图形 1：矩形平面图
    for x in range(3, 9):
        put(px, x0 + x, y0 + 5, PAPER_L)
        put(px, x0 + x, y0 + 9, PAPER_L)
    for y in range(5, 10):
        put(px, x0 + 3, y0 + y, PAPER_L)
        put(px, x0 + 8, y0 + y, PAPER_L)

    # 图形 2：一个圆（俯视图）
    for dx, dy in ((0, -2), (0, 2), (-2, 0), (2, 0), (-1, -1), (1, -1), (-1, 1), (1, 1)):
        put(px, x0 + 13 + dx, y0 + 7 + dy, PAPER_L)
    put(px, x0 + 13, y0 + 7, PAPER_L)

    # 尺寸线 + 刻度
    for x in range(3, 17):
        put(px, x0 + x, y0 + 10, PAPER_L)
    for x in (3, 9, 16):
        put(px, x0 + x, y0 + 9, PAPER_L)
        put(px, x0 + x, y0 + 11, PAPER_L)


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

            # 蓝图在两手中间稍微往上一点，然后把手画在纸上面，像双手捧着
            mid_x = sum(h[0] for h in hands) / len(hands)
            mid_y = sum(h[1] for h in hands) / len(hands)
            draw_blueprint(px, mid_x, mid_y + 2, direction)

            gun_px = gun.load()
            for yy in range(32):
                for xx in range(32):
                    if is_skin(gun_px[xx, yy]):
                        px[xx, yy] = gun_px[xx, yy]

            out.paste(frame, (i * 32, 0))

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]}")


if __name__ == "__main__":
    main()
