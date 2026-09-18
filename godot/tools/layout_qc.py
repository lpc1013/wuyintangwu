"""把 scripts/game_manager.gd 里的池区/出生点/案内图锚点画到背景上，
生成叠框校验图。坐标只有一份真相：直接解析配置表，不再手工复制。

用法：python godot/tools/layout_qc.py
"""
from PIL import Image, ImageDraw
import os
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
CONFIG = os.path.join(ROOT, "scripts", "game_manager.gd")

RE_ROOM = re.compile(r'"(\w+)":\s*\{(.*?)\n\t\},', re.S)
RE_POOLS = re.compile(r'"pools":\s*\[(.*?)\]', re.S)
RE_SPAWNS = re.compile(r'"spawns":\s*\[(.*?)\]', re.S)
RE_ANCHOR = re.compile(r'"map_anchor":\s*Vector2\(([^)]*)\)')
RE_RECT = re.compile(r'Rect2\(([^)]*)\)')
RE_VEC = re.compile(r'Vector2\(([^)]*)\)')


def nums(text: str):
    return [int(float(v)) for v in text.split(",")]


def parse_config():
    src = open(CONFIG, encoding="utf-8").read()
    rooms, anchors = {}, {}
    for rid, body in RE_ROOM.findall(src):
        pools = [tuple(nums(g)) for g in RE_RECT.findall(RE_POOLS.search(body).group(1))]
        spawns = [tuple(nums(g)) for g in RE_VEC.findall(RE_SPAWNS.search(body).group(1))]
        rooms[rid] = {"bg": "assets/bg/room-%s.png" % rid, "pools": pools, "spawns": spawns}
        m = RE_ANCHOR.search(body)
        if m:
            anchors[rid] = tuple(nums(m.group(1)))
    return rooms, anchors


ROOMS, MAP_ANCHORS = parse_config()

CYAN = (80, 220, 255, 90)
CYAN_LINE = (80, 220, 255, 255)
MAGENTA = (255, 60, 180, 255)
YELLOW = (255, 220, 60, 255)


def overlay_room(cfg):
    im = Image.open(os.path.join(ROOT, cfg["bg"])).convert("RGBA")
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for (x, y, w, h) in cfg["pools"]:
        d.rectangle([x, y, x + w, y + h], fill=CYAN, outline=CYAN_LINE, width=2)
    for (x, y) in cfg["spawns"]:
        d.polygon([(x, y - 7), (x + 7, y), (x, y + 7), (x - 7, y)], outline=MAGENTA, width=2)
    im.alpha_composite(layer)
    return im.convert("RGB")


def overlay_map():
    im = Image.open(os.path.join(ROOT, "assets/bg/map-gate.png")).convert("RGB")
    d = ImageDraw.Draw(im)
    for rid, (x, y) in MAP_ANCHORS.items():
        d.ellipse([x - 14, y - 14, x + 14, y + 14], outline=YELLOW, width=2)
        d.text((x + 18, y - 6), rid, fill=YELLOW)
    return im


def main():
    panels = [(rid, overlay_room(cfg)) for rid, cfg in ROOMS.items()]
    panels.append(("map", overlay_map()))
    panels.append(("title", Image.open(os.path.join(ROOT, "assets/bg/title.png")).convert("RGB")))
    cell = (448, 256)
    cols, rows = 2, 4
    sheet = Image.new("RGB", (cell[0] * cols, cell[1] * rows), (24, 17, 37))
    d = ImageDraw.Draw(sheet)
    for i, (rid, im) in enumerate(panels):
        px, py = (i % cols) * cell[0], (i // cols) * cell[1]
        sheet.paste(im.resize(cell, Image.BOX), (px, py))
        d.text((px + 4, py + 4), rid, fill=(255, 255, 255))
    out = os.path.join(os.path.dirname(__file__), "layout_qc_sheet.png")
    sheet.save(out)
    print("wrote", out)


if __name__ == "__main__":
    main()
