"""把角色表的脚改小一点、腿加长一行。

做法：每帧找到靴子（棕色）最高的那一行，把它整行换成裤子颜色（腿多一行、靴子少一行），
再把每只靴子最外侧的一列换成描边色，让脚看起来窄一点。

运行: python tools/fix_legs.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(r"C:\game\test")
SHEETS = ["character_sheet.png", "character_sheet_gun.png"]

BOOT_LIGHT = (92, 60, 38, 255)
BOOT_DARK = (68, 44, 28, 255)
LEG_LIGHT = (54, 62, 92, 255)
LEG_DARK = (40, 46, 70, 255)
OUTLINE = (26, 22, 38, 255)
## 是否把脚也削窄（先只加长腿、缩小脚的高度）
NARROW = True


def fix_frame(frame: Image) -> None:
    px = frame.load()
    boots = [(x, y) for y in range(32) for x in range(32)
             if px[x, y] in (BOOT_LIGHT, BOOT_DARK)]
    if not boots:
        return
    top = min(y for _, y in boots)

    # 1) 靴子最高的一行 -> 裤子颜色（腿加长一行）
    for x in range(32):
        c = px[x, top]
        if c == BOOT_LIGHT:
            px[x, top] = LEG_LIGHT
        elif c == BOOT_DARK:
            px[x, top] = LEG_DARK

    # 2) 靴子行：每只脚最外侧的靴子像素换成描边色（脚变窄一格）
    if not NARROW:
        return
    for y in range(top + 1, 32):
        cols = [x for x in range(32) if px[x, y] in (BOOT_LIGHT, BOOT_DARK)]
        if not cols:
            continue
        groups = [[cols[0]]]
        for x in cols[1:]:
            if x == groups[-1][-1] + 1:
                groups[-1].append(x)
            else:
                groups.append([x])
        for g in groups:
            if len(g) >= 3:
                px[g[0], y] = OUTLINE
                px[g[-1], y] = OUTLINE


def main() -> None:
    for name in SHEETS:
        path = ROOT / "assets" / name
        im = Image.open(path).convert("RGBA")
        out = im.copy()
        for i in range(28):
            frame = out.crop((i * 32, 0, (i + 1) * 32, 32))
            fix_frame(frame)
            out.paste(frame, (i * 32, 0))
        out.save(path)
        print(f"fixed {name}")


if __name__ == "__main__":
    main()
