# -*- coding: utf-8 -*-
"""把 ROOMS 里的 pools / lots 叠到背景图上，肉眼核对地面块是否真的落在留白处。
运行：python godot/tools/lot_qc.py
输出：vibe_images/_lot_qc_<room>.png
"""
import re
from PIL import Image, ImageDraw

ROOT = "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal"
SRC = ROOT + "/godot/scripts/game_manager.gd"
GRID = 16

text = open(SRC, encoding="utf-8").read()
block = text[text.index("const ROOMS"):]
rooms = {}
for name, body in re.findall(r'"(\w+)":\s*\{(.*?)\n\t\},', block, re.S):
    pools = [tuple(map(int, m)) for m in re.findall(r'Rect2\((\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)', body)]
    lots_part = body[body.index('"lots"'):] if '"lots"' in body else ""
    lots = [tuple(map(int, m)) for m in re.findall(r'Rect2\((\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)', lots_part)]
    spawns = [tuple(map(int, m)) for m in re.findall(r'Vector2\((\d+),\s*(\d+)\)', body[:body.index('"lots"')] if '"lots"' in body else body)]
    rooms[name] = (pools, lots, spawns)

for room, (pools, lots, spawns) in rooms.items():
    im = Image.open("%s/godot/assets/bg/room-%s.png" % (ROOT, room)).convert("RGBA")
    ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    for x in range(0, im.width, GRID):
        d.line([(x, 0), (x, im.height)], fill=(255, 255, 255, 22), width=1)
    for y in range(0, im.height, GRID):
        d.line([(0, y), (im.width, y)], fill=(255, 255, 255, 22), width=1)
    for (x, y, w, h) in pools:
        d.rectangle([x, y, x + w - 1, y + h - 1], outline=(80, 220, 255, 255), width=2)
    for i, (x, y, w, h) in enumerate(lots):
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=(90, 255, 140, 60), outline=(90, 255, 140, 255), width=2)
        d.text((x + 3, y + 2), "L%d %dx%d" % (i, w, h), fill=(230, 255, 235, 255))
    for (sx, sy) in spawns:
        d.ellipse([sx - 5, sy - 5, sx + 5, sy + 5], outline=(255, 80, 200, 255), width=2)
    out = Image.alpha_composite(im, ov)
    out.save("%s/vibe_images/_lot_qc_%s.png" % (ROOT, room))
    print(room, "pools", pools, "lots", lots, "spawns", spawns)
