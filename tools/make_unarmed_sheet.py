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

        for i in range(FRAMES):
            gun = Image.open(tmp / f"_gunframe_{i + 1:02d}.png").convert("RGBA")
            gp = gun.load()
            for y in range(32):
                for x in range(32):
                    c = gp[x, y]
                    if is_skin(c):
                        out_px[i * 32 + x, y] = c

    out.save(OUTPUT)
    print(f"saved {OUTPUT}  {out.size[0]}x{out.size[1]} ({FRAMES} frames)")


if __name__ == "__main__":
    main()
