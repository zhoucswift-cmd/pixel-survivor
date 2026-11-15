"""生成基地用的“空手”角色表：身体 + 手，没有枪。

做法：
1. 用 Aseprite 把 character.aseprite 的 gun 图层逐帧导出（手就在这一层）；
2. 只抠出肤色像素（手），贴到 character_sheet.png（无枪的身体）对应帧上；
3. 输出 assets/character_sheet_unarmed.png（896x32，28 帧）。

运行: python tools/make_unarmed_sheet.py
"""
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(r"C:\game\test")
ASEPRITE = Path(r"C:\game\Aseprite.v1.3.17\Aseprite.exe")
LUA = ROOT / "tools" / "dump_gun_frames.lua"
SOURCE = ROOT / "assets" / "character.aseprite"
PLAIN = ROOT / "assets" / "character_sheet.png"
OUTPUT = ROOT / "assets" / "character_sheet_unarmed.png"
FRAMES = 28


def is_skin(pixel) -> bool:
    r, g, b, a = pixel
    return a > 0 and r >= 190 and g >= 130 and b >= 90 and r > g > b


def strip_stray_skin(image: Image, max_y: int) -> None:
    """去掉脸以下的多余肤色像素（原画里肩侧和腰带上的小色块）。

    脸所在的行不动，其余肤色用四邻域最常见的非肤色补上。
    """
    from collections import Counter
    px = image.load()
    for y in range(max_y + 1, 32):
        for x in range(32):
            if not is_skin(px[x, y]):
                continue
            counts = Counter()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = min(31, max(0, x + dx)), min(31, max(0, y + dy))
                c = px[nx, ny]
                if c[3] > 0 and not is_skin(c):
                    counts[c] += 1
            if counts:
                px[x, y] = counts.most_common(1)[0][0]
            else:
                px[x, y] = (0, 0, 0, 0)


def dump_gun_frames(tmp: Path) -> None:
    # 让 Lua 把每一帧的 gun 层 cel 写到临时目录
    text = LUA.read_text(encoding="utf-8")
    text = text.replace("C:/game/test/docs/", tmp.as_posix() + "/")
    patched = tmp / "dump_gun_frames.lua"
    patched.write_text(text, encoding="utf-8")
    subprocess.run([str(ASEPRITE), "-b", str(SOURCE), "--script", str(patched)],
                   check=True, capture_output=True)


def main() -> None:
    plain = Image.open(PLAIN).convert("RGBA")
    out = plain.copy()
    out_px = out.load()

    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        dump_gun_frames(tmp)

        # 每个方向“脸”最低到第几行：朝上（背对）没有脸，全清
        face_bottom = {0: 16, 1: -1, 2: 16, 3: 16}

        for i in range(FRAMES):
            direction = i // 7
            frame = out.crop((i * 32, 0, (i + 1) * 32, 32))
            strip_stray_skin(frame, face_bottom[direction])
            out.paste(frame, (i * 32, 0))

            # 不把 gun 层的手贴回来：空手状态就是干净的躯干，避免肩侧/腰带上
            # 出现“浮空的手”那种色块

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]} ({FRAMES} frames)")


if __name__ == "__main__":
    main()
