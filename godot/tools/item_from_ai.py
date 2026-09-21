#!/usr/bin/env python3
"""即梦白底重绘 → 可摆放物品贴图。

用法（仓库根目录）：
    python godot/tools/item_from_ai.py            # 全量：items_raw 里有什么就落什么
    python godot/tools/item_from_ai.py tetsubin   # 只落指定几件

尺寸立意：底图 896×512 的方块是 2px，物品按「原框一半的逻辑分辨率」出图，
游戏里统一乘 DISPLAY_SCALE=2 显示——方块大小与背景严丝合缝，不会像程序画的
物件那样跟背景断层。所以每件物品的画布 = manifest 里裁切框向上取偶 / 2。

抠底沿用 sprite_from_ai 那套：四边泛洪只吃连片近白底，方块网格对齐后整倍缩。
"""

import json
import math
import os
import sys
from collections import Counter

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sprite_from_ai import measure_block, key_out, snap_bbox, shrink, quantize, place

ROOT = os.getcwd()
CROPS = os.path.join(ROOT, "vibe_images", "items_crops")
RAW = os.path.join(ROOT, "vibe_images", "items_raw")
OUT = os.path.join(ROOT, "godot", "assets", "items")

# 白毛巾这类物品跟白底一个色相，泛洪抠白会把主体啃穿——这几件让即梦出绿幕底
GREEN_KEY = {"towel_stack", "towel_basket", "stool_towel", "andon_snow"}


def drop_closed_white(im):
    """抠完连片白底后，再清掉被提梁/壶身围死的纯白孤岛：只吃三通道全>245 的，
    米色碗心、奶油灯罩这类有色相偏移的不会被误伤。"""
    px = im.load()
    w, h = im.size
    seen = set()
    for sx, sy in [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + \
                  [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]:
        if (sx, sy) in seen:
            continue
        stack = [(sx, sy)]
        while stack:
            x, y = stack.pop()
            if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
                continue
            r, g, b, a = px[x, y]
            if a == 0 or r < 246 or g < 246 or b < 246:
                continue
            seen.add((x, y))
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    holes = []
    # 剩下的近白连通块：不挨着边框、面积小于一成画布的判为孤岛背景
    visited = set()
    for y0 in range(h):
        for x0 in range(w):
            if (x0, y0) in visited or (x0, y0) in seen:
                continue
            r, g, b, a = px[x0, y0]
            if a == 0 or r < 246 or g < 246 or b < 246:
                continue
            comp = [(x0, y0)]
            blob = []
            touches = False
            while comp:
                x, y = comp.pop()
                if (x, y) in visited or (x, y) in seen:
                    continue
                r, g, b, a = px[x, y]
                if a == 0 or r < 246 or g < 246 or b < 246:
                    continue
                visited.add((x, y))
                blob.append((x, y))
                if x == 0 or y == 0 or x == w - 1 or y == h - 1:
                    touches = True
                comp += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
            if blob and not touches and len(blob) < w * h * 0.1:
                holes.append(blob)
    for blob in holes:
        for x, y in blob:
            px[x, y] = (0, 0, 0, 0)
    return im


def key_out_green(im):
    px = im.load()
    w, h = im.size
    seen = set()
    stack = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)]
    stack += [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        r, g, b, _ = px[x, y]
        if not (g > 140 and r < g - 30 and b < g - 30):
            continue
        seen.add((x, y))
        stack.append((x + 1, y))
        stack.append((x - 1, y))
        stack.append((x, y + 1))
        stack.append((x, y - 1))
    for x, y in seen:
        px[x, y] = (0, 0, 0, 0)
    return im


def canvas_for(box, block=2):
    """画布 = 底图原框尺寸（向上取偶）：贴图内部 2px 方块、1x 显示，
    跟动物贴图（72×96 里方块 2px）同一规格，摆进场景不用额外缩放。"""
    x0, y0, x1, y1 = box
    w = math.ceil((x1 - x0) / block) * block
    h = math.ceil((y1 - y0) / block) * block
    return w, h


def mode_fit(im, w, h):
    """多数表决合块：BOX 平均会把相邻方块混成中间色，像素画一糊就穿帮；
    每格取众数颜色，边缘永远是硬方块。"""
    sw, sh = im.width, im.height
    px = im.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    op = out.load()
    for oy in range(h):
        y0 = oy * sh // h
        y1 = max(y0 + 1, (oy + 1) * sh // h)
        for ox in range(w):
            x0 = ox * sw // w
            x1 = max(x0 + 1, (ox + 1) * sw // w)
            cnt = Counter()
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    r, g, b, a = px[xx, yy]
                    if a >= 128:
                        cnt[(r, g, b)] += 1
            if cnt:
                op[ox, oy] = (*cnt.most_common(1)[0][0], 255)
    return out


def to_palette(im, pal):
    """把图钉死在原裁片调色板上：合块平均出的中间色一律吸附回真实色，
    即梦重绘的抖动杂色不会带进最终贴图。"""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
                continue
            best, bd = pal[0], None
            for c in pal:
                d = (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2
                if bd is None or d < bd:
                    best, bd = c, d
            px[x, y] = (*best, 255)
    return im


def crop_palette(src, box, k=14):
    bg = Image.open(os.path.join(ROOT, "godot", "assets", "bg",
                                 f"room-{src}.png")).convert("RGB").crop(tuple(box))
    q = bg.quantize(colors=k, dither=Image.Dither.NONE)
    pal = q.getpalette()
    n = q.getcolors()
    cols = [tuple(pal[3 * i:3 * i + 3]) for _, i in (n if isinstance(n, list) else [])]
    return cols or bg.resize((1, 1)).getpixel((0, 0))


def build_one(name, scene, box, colors=24):
    src = None
    for ext in (".png", ".webp", ".jpg"):
        p = os.path.join(RAW, name + ext)
        if os.path.exists(p):
            src = p
            break
    if src is None:
        return None
    im = Image.open(src).convert("RGBA")
    if name in GREEN_KEY:
        im = key_out_green(im)
    else:
        im = drop_closed_white(key_out(im))
    block = measure_block(im)
    cw, ch = canvas_for(box)
    lw, lh = cw // 2, ch // 2          # 逻辑尺寸：1px 方块的一格世界像素
    # 第一步永远按原方块整倍缩到 1px/块——这一步不省，边缘就不会被平均糊掉
    x0, y0, x1, y1 = snap_bbox(im, block)
    cut = quantize(shrink(im.crop((x0, y0, x1, y1)), block), colors)
    pal = crop_palette(scene, box)
    # 第二步合块到目标逻辑尺寸：先钉回底图调色板，再 BOX 合并，边缘软但颜色真实
    if cut.width > lw or cut.height > lh:
        k = min(lw / cut.width, lh / cut.height)
        cut = shrink(cut, max(1, round(1 / k)))
        if cut.width > lw or cut.height > lh:
            k = min(lw / cut.width, lh / cut.height)
            cut = cut.resize((max(1, round(cut.width * k)), max(1, round(cut.height * k))),
                             Image.BOX)
    cut = to_palette(cut, pal)
    cut = cut.resize((cut.width * 2, cut.height * 2), Image.NEAREST)  # 2px 方块，对齐动物规格
    os.makedirs(OUT, exist_ok=True)
    out, _, _ = place(cut, cw, ch)
    dst = os.path.join(OUT, f"item_{name}.png")
    out.save(dst)
    return dst


def main():
    manifest = json.load(open(os.path.join(CROPS, "manifest.json"), encoding="utf-8"))
    want = set(sys.argv[1:])
    done, missing = [], []
    for name, src_scene, box in manifest:
        if want and name not in want:
            continue
        dst = build_one(name, src_scene, box)
        (done if dst else missing).append(name)
    print("落位:", " ".join(done) or "-")
    print("缺原图:", " ".join(missing) or "-")


if __name__ == "__main__":
    main()
