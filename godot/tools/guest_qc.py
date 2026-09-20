# -*- coding: utf-8 -*-
"""名册贴图的落位质检：把 assets/animals 下每只客人的 6 张姿态拼成一张对比图，
同时量化三件事——脚线漂移、包围盒与不透明占比、以及 poseΔ（同物种内两张最像的
姿态之间的像素差占比）。

poseΔ 用像素差而非剪影重合度：走路周期六张的轮廓本来就挨得近，剪影重合度全员
96% 以上，区分不出「腿换了个位置」和「干脆复制了一份」。差的那部分集中在
y=80~95 的脚部带上，所以 poseΔ 低到 1~2% 也未必是错——水豚是「温吞哲学派」，
迈步幅度小是设定；真出问题是 poseΔ 恰好 0%，那两张就是同一张画。

用法：python godot/tools/guest_qc.py [物种id ...]
不给名单就查全部；输出 vibe_images/_guest_qc.png（下划线开头，不入库）。
"""
import os
import sys
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
ANIM = os.path.join(ROOT, "assets", "animals")
OUT = os.path.join(ROOT, "..", "vibe_images", "_guest_qc.png")
POSES = ["walk", "stepL", "stepR", "hop", "rest", "soak"]
CELL = (72, 96)
PAD = 4
## 两两姿态的最小像素差：低于这个比例就说明两张画的其实是同一个姿势，六张里掺了水。
## 实测全员最低是水豚的 1.8%（脚部 70 个像素），所以这条线只能贴着 0 放。
DUP_DIFF = 0.005


def stats(path):
    im = Image.open(path).convert("RGBA")
    a = im.getchannel("A")
    bbox = a.getbbox() or (0, 0, 0, 0)
    opaque = sum(1 for p in a.getdata() if p > 16)
    return im, bbox, opaque / float(CELL[0] * CELL[1])


def rgba_of(im):
    return list(im.getdata())


def closest_pair(items):
    """返回差异最小的那一对姿态，以及差异像素占两张并集的比例。
    items 是 [(姿态名, RGBA 列表)]，缺文件的姿态不进这张表，所以名字只能带在条目里。
    比剪影重合度更严：走路周期六张的轮廓本来就挨得近，只有像素差能分出
    「腿换了位置」和「干脆复制了一份」。"""
    best = (None, None, 2.0)
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            a, b = items[i][1], items[j][1]
            u = d = 0
            for pa, pb in zip(a, b):
                ta, tb = pa[3] <= 16, pb[3] <= 16
                if ta and tb:
                    continue
                u += 1
                if ta != tb or max(abs(pa[0] - pb[0]), abs(pa[1] - pb[1]),
                                   abs(pa[2] - pb[2])) > 32:
                    d += 1
            if u and d / float(u) < best[2]:
                best = (items[i][0], items[j][0], d / float(u))
    return best


def main():
    ids = sys.argv[1:] or sorted({f.split("_")[0] for f in os.listdir(ANIM) if f.endswith(".png")})
    sheet = Image.new("RGBA", (len(POSES) * (CELL[0] + PAD) + PAD,
                              len(ids) * (CELL[1] + PAD) + PAD), (28, 20, 34, 255))
    rows = []
    for r, sid in enumerate(ids):
        boxes, fills, missing, masks = [], [], [], []
        for c, pose in enumerate(POSES):
            path = os.path.join(ANIM, "%s_%s.png" % (sid, pose))
            if not os.path.exists(path):
                missing.append(pose)
                continue
            im, bbox, fill = stats(path)
            masks.append((pose, rgba_of(im)))
            if bbox[2] - bbox[0] > 0:
                boxes.append(bbox)
                fills.append(fill)
            x = PAD + c * (CELL[0] + PAD)
            y = PAD + r * (CELL[1] + PAD)
            for by in range(0, CELL[1], 8):
                for bx in range(0, CELL[0], 8):
                    dark = ((bx // 8) + (by // 8)) % 2
                    for py in range(8):
                        for px in range(8):
                            im.putpixel((bx + px, by + py),
                                        (70, 60, 80, 255) if dark else (44, 36, 52, 255))
            im.alpha_composite(Image.open(path).convert("RGBA"), (0, 0))
            sheet.alpha_composite(im, (x, y))
        top = min(b[1] for b in boxes)
        foot = max(b[3] for b in boxes)
        left = min(b[0] for b in boxes)
        right = max(b[2] for b in boxes)
        foot_spread = max(b[3] for b in boxes) - min(b[3] for b in boxes)
        pa, pb, dv = closest_pair(masks) if len(masks) > 1 else ("", "", 2.0)
        rows.append((sid, len(boxes), missing, (left, top, right, foot), foot_spread,
                     min(fills), max(fills), "%.1f%% %s/%s" % (dv * 100, pa, pb), dv))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    sheet.save(OUT)
    print("sheet ->", os.path.normpath(OUT), sheet.size)
    print("%-6s %-5s %-6s %-22s %-6s %-18s %s" % (
        "id", "poses", "foot±", "union bbox", "fill%", "poseΔ", "missing"))
    dups = []
    for sid, n, missing, ub, fs, fmin, fmax, pose_delta, dv in rows:
        flag = ""
        if missing:
            flag = " ".join(missing)
        elif n < len(POSES):
            flag = "全透明"
        print("%-6s %-5s %-6s %-22s %-6s %-18s %s" % (
            sid, "%d/6" % n, "%dpx" % fs, str(ub), "%.1f-%.1f" % (fmin * 100, fmax * 100),
            pose_delta, flag))
        if dv < DUP_DIFF:
            dups.append((sid, pose_delta))
    if dups:
        print("\n姿态撞脸（两张几乎逐像素相同）：")
        for sid, delta in dups:
            print("  %-6s %s" % (sid, delta))


main()
