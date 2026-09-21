#!/usr/bin/env python3
"""物品贴图 QC：1) 棋盘格拼贴图 2) 按 DISPLAY_SCALE=2 贴回底图原位，肉眼核断层。"""
import json
import os
import sys
from PIL import Image

ROOT = os.getcwd()
ITEMS = os.path.join(ROOT, "godot", "assets", "items")
CROPS = os.path.join(ROOT, "vibe_images", "items_crops")

manifest = json.load(open(os.path.join(CROPS, "manifest.json"), encoding="utf-8"))
names = [n for n, _, _ in manifest
         if os.path.exists(os.path.join(ITEMS, f"item_{n}.png"))]

CELL = 160
cols = 6
rows = (len(names) + cols - 1) // cols
sheet = Image.new("RGB", (cols * CELL, rows * (CELL + 16)), (30, 30, 36))
d = ImageDraw = __import__("PIL.ImageDraw", fromlist=["ImageDraw"]).ImageDraw(sheet)
for i, n in enumerate(names):
    im = Image.open(os.path.join(ITEMS, f"item_{n}.png")).convert("RGBA")
    k = min((CELL - 12) / im.width, (CELL - 12) / im.height)
    big = im.resize((int(im.width * k), int(im.height * k)), Image.NEAREST)
    x = (i % cols) * CELL + (CELL - big.width) // 2
    y = (i // cols) * (CELL + 16) + (CELL - big.height) // 2
    sheet.paste(big, (x, y), big)
    d.text(((i % cols) * CELL + 4, (i // cols) * (CELL + 16) + CELL + 2), n, fill=(255, 255, 255))
sheet.save(os.path.join(ROOT, "vibe_images", "_items_final_qc.png"))

# 贴回原位：底图对应区域先压暗 20%，再叠 2x 放大的物品
mock = {}
for n, s, box in manifest:
    if n not in names:
        continue
    if s not in mock:
        mock[s] = Image.open(os.path.join(ROOT, "godot", "assets", "bg", f"room-{s}.png")).convert("RGBA")
    im = Image.open(os.path.join(ITEMS, f"item_{n}.png")).convert("RGBA")
    base = mock[s]
    x0, y0, x1, y1 = box
    region = base.crop((x0, y0, x1, y1))
    dark = region.point(lambda p: int(p * 0.75))
    base.paste(dark, (x0, y0))
    big = im  # 贴图已是 2px 方块的屏幕像素，1x 贴回原位
    px = x0 + (x1 - x0 - big.width) // 2
    py = y1 - big.height
    base.paste(big, (px, py), big)
for s, im in mock.items():
    im.convert("RGB").save(os.path.join(ROOT, "vibe_images", f"_items_mock_{s}.png"))
print("qc done:", len(names), "items")
