#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""三张背景右下角的拼接断裂修复，可重跑。

两种手法，按断裂的形态选：
  mirror   —— 那块矩形是从别处贴来的外来内容，纹理方向都对不上。拿邻近同宽的同质区域
              镜像平移过去，接缝处逐像素相同。镜像而非平移：平移会留 1 像素跳变。
  dissolve —— 图案其实连着，只是两张不同曝光的图沿一条直线叠在一起（竹篱脚、水洼边、
              半截脚掌都被切在这条线上）。把线以下翻上来按距离衰减盖回去：线上两侧
              完全相同，硬边消失；离线越远衰减到 0，竹篱上半截和屋檐不受影响。

默认只写到 vibe_images/_tmp/ 供肉眼验收，--apply 才写回 godot/assets/bg/。
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.join("godot", "assets", "bg")
TMP = os.path.join("vibe_images", "_tmp")

# (边界行, x 起, x 止, 消缝厚度)
TITLE_DISSOLVE = [
    (432, 706, 856, 14),   # 竹篱脚 + 水洼底 + 两只被切一半的脚掌
    (432, 620, 700, 10),   # 黑猫脚下那条亮带
    (472, 740, 896, 8),    # 同一条铺路石，上阴下阳的色温台阶
]

MIRROR = {
    "room-chashitsu.png": [((672, 432, 784, 512), (784, 432), "x")],
    "map-gate.png": [((656, 352, 896, 432), (656, 432), "y")],
}


def apply_mirror(im, ops):
    for (sx0, sy0, sx1, sy1), (dx, dy), axis in ops:
        patch = im.crop((sx0, sy0, sx1, sy1))
        flip = Image.FLIP_LEFT_RIGHT if axis == "x" else Image.FLIP_TOP_BOTTOM
        im.paste(patch.transpose(flip), (dx, dy))


def apply_dissolve(im, jobs):
    a = np.asarray(im.convert("RGB")).astype(float)
    for yb, x0, x1, depth in jobs:
        for k in range(depth):
            w = 1.0 - k / depth
            a[yb - 1 - k, x0:x1] *= 1.0 - w
            a[yb - 1 - k, x0:x1] += a[yb + k, x0:x1] * w
    return Image.fromarray(np.rint(a).astype(np.uint8))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="写回 godot/assets/bg/，否则只出 _tmp 预览")
    args = ap.parse_args()

    os.makedirs(TMP, exist_ok=True)
    for name in sorted(set(list(MIRROR) + ["title.png"])):
        src = os.path.join(ROOT, name)
        im = Image.open(src).convert("RGB")
        if name in MIRROR:
            apply_mirror(im, MIRROR[name])
        if name == "title.png":
            im = apply_dissolve(im, TITLE_DISSOLVE)
        if args.apply:
            im.save(src)
            print("applied", src)
        else:
            out = os.path.join(TMP, "fixed_" + name)
            im.save(out)
            print("preview", out, im.size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
