"""从背景图自动拟合池区矩形：分割青绿色水面 → 连通域 → 外接框，
再按安全内缩量收缩，输出可直接粘进 scripts/game_manager.gd 的坐标。

用法：
    python godot/tools/fit_pools.py                 # 打印建议框 + 生成叠框校验图
    python godot/tools/fit_pools.py --min-area 900  # 调整噪点门限
"""

from PIL import Image, ImageDraw
import numpy as np
import os
import sys
from collections import deque

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(os.path.dirname(__file__), "fit_pools_sheet.png")

# 每个房间的搜索窗 (x0, y0, x1, y1)：池子只可能出现在这个区间内。
# 夜景露天池的天空与积雪和水色几乎同色，纯色相分割无法区分，只能靠作者先验。
TARGETS = {
    "ooike": ("assets/bg/room-ooike.png", (60, 60, 840, 340)),
    "indoor": ("assets/bg/room-indoor.png", (60, 180, 840, 370)),
    "rotenburo": ("assets/bg/room-rotenburo.png", (140, 235, 760, 425)),
    "ishiyu": ("assets/bg/room-ishiyu.png", (60, 95, 840, 405)),
    "backyard": ("assets/bg/room-backyard.png", (110, 150, 730, 400)),
}

# 池面安全内缩：水面分割出来的外接框通常含池壁高光，向内收一点避免客人贴边
INSET_X = 0.06
INSET_Y = 0.10


def water_mask(arr: np.ndarray) -> np.ndarray:
    r, g, b = arr[..., 0].astype(int), arr[..., 1].astype(int), arr[..., 2].astype(int)
    mx = arr.max(2).astype(int)
    mn = arr.min(2).astype(int)
    chroma = mx - mn
    # 水面：蓝绿明显强于红，且不是高亮白沫
    return (g > r + 12) & (b > r + 4) & (g > 70) & (mx < 245) & (chroma > 18)


def components(mask: np.ndarray, min_area: int):
    seen = np.zeros_like(mask)
    h, w = mask.shape
    boxes = []
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
                continue
            q = deque([(x, y)])
            seen[y, x] = True
            n = 0
            x0 = x1 = x
            y0 = y1 = y
            while q:
                cx, cy = q.popleft()
                n += 1
                x0 = min(x0, cx); x1 = max(x1, cx)
                y0 = min(y0, cy); y1 = max(y1, cy)
                for nx in (cx - 1, cx + 1):
                    for ny in (cy - 1, cy + 1):
                        if 0 <= nx < w and 0 <= ny < h and mask[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            q.append((nx, ny))
            if n >= min_area:
                boxes.append((x0, y0, x1 - x0 + 1, y1 - y0 + 1, n))
    return sorted(boxes, key=lambda t: -t[4])


def merge(boxes, gap: int = 24):
    """把互相重叠或仅隔一条蒸汽/高光的分割块并成一个池框。"""
    rects = [[x, y, x + w, y + h] for x, y, w, h, _ in boxes]
    changed = True
    while changed:
        changed = False
        for i in range(len(rects)):
            for j in range(i + 1, len(rects)):
                a, b = rects[i], rects[j]
                if a[0] - gap <= b[2] and b[0] - gap <= a[2] and a[1] - gap <= b[3] and b[1] - gap <= a[3]:
                    rects[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    del rects[j]
                    changed = True
                    break
            if changed:
                break
    return [(x, y, r - x, b - y, (r - x) * (b - y)) for x, y, r, b in rects]


def shrink(box) -> tuple:
    x, y, w, h, _ = box
    dx, dy = w * INSET_X, h * INSET_Y
    return (int(round(x + dx)), int(round(y + dy)), int(round(w - 2 * dx)), int(round(h - 2 * dy)))


def main() -> None:
    min_area = 1200
    for i, a in enumerate(sys.argv):
        if a == "--min-area":
            min_area = int(sys.argv[i + 1])

    cells = []
    for rid, (rel, win) in TARGETS.items():
        im = Image.open(os.path.join(ROOT, rel)).convert("RGB")
        arr = np.asarray(im)
        mask = water_mask(arr)
        wx0, wy0, wx1, wy1 = win
        mask[:wy0, :] = False
        mask[wy1:, :] = False
        mask[:, :wx0] = False
        mask[:, wx1:] = False
        boxes = merge(components(mask, min_area))
        fitted = [shrink(b) for b in boxes[:4]]
        print(f'{rid}: ' + ', '.join(f'Rect2({x},{y},{w},{h})' for x, y, w, h in fitted))
        overlay = im.convert("RGBA")
        layer = Image.new("RGBA", overlay.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        for x, y, w, h in fitted:
            d.rectangle([x, y, x + w, y + h], fill=(80, 220, 255, 70), outline=(80, 220, 255, 255), width=2)
            d.text((x + 3, y + 3), f"{w}x{h}", fill=(255, 240, 120, 255))
        for x, y, w, h, _ in boxes[:4]:
            d.rectangle([x, y, x + w, y + h], outline=(255, 60, 180, 255), width=1)
        overlay.alpha_composite(layer)
        cells.append((rid, overlay.convert("RGB")))

    cell = (448, 256)
    sheet = Image.new("RGB", (cell[0] * 2, cell[1] * 2), (24, 17, 37))
    d = ImageDraw.Draw(sheet)
    for i, (rid, im) in enumerate(cells):
        px, py = (i % 2) * cell[0], (i // 2) * cell[1]
        sheet.paste(im.resize(cell, Image.BOX), (px, py))
        d.text((px + 4, py + 4), rid, fill=(255, 255, 255))
    sheet.save(OUT)
    print("wrote", OUT, "(cyan = 建议池框, magenta = 原始分割外接框)")


if __name__ == "__main__":
    main()
