"""把草地地图里的井盖全部去掉：删掉 well_* 刷怪点，并把井盖瓦片（id 17）换成普通草地。

运行: python tools/remove_wells.py
"""
import json
from pathlib import Path

MAP = Path(r"C:\game\test\tiled\meadow.tmj")
WELL_TILE = 17      # 关闭状态的井盖
GRASS_TILE = 1      # 普通草地


def main() -> None:
    data = json.loads(MAP.read_text(encoding="utf-8"))

    removed_objects = 0
    replaced_tiles = 0
    for layer in data["layers"]:
        if layer.get("type") == "objectgroup":
            objects = layer.get("objects", [])
            keep = [o for o in objects if not str(o.get("name", "")).startswith("well")]
            removed_objects += len(objects) - len(keep)
            layer["objects"] = keep
        elif layer.get("type") == "tilelayer":
            layer["data"] = [
                GRASS_TILE if v == WELL_TILE else v for v in layer["data"]
            ]
            replaced_tiles += sum(1 for v in layer["data"] if v == WELL_TILE)

    MAP.write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"removed {removed_objects} well objects, replaced {replaced_tiles} tiles")


if __name__ == "__main__":
    main()
