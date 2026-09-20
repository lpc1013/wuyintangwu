# -*- coding: utf-8 -*-
"""名册贴图的落位质检：把 assets/animals 下每只客人的姿态拼成一张对比图（走路周期
六张 + 茶室专用的 sit 一张），同时量化三件事——脚线漂移、包围盒与不透明占比、
以及 poseΔ（同物种内走路周期里两张最像的姿态之间的像素差占比）。

poseΔ 只算走路周期那六张：sit 和它们本来就长得不一样，混进去只会抬高基线，反倒
掩盖走路六张里真正掺水的那对。sit 只盯一条——剪影不能比 walk 还高，产线把内容塞进
固定画布，原图画高了客人一坐下就当场长大一号；像不像坐下、颜色串没串，看拼条那一列。

soak 从「rest 改色占位」升级成第八张即梦原图以后也上了一条自己的闸：画布底边就是水面，
墨迹顶行报出来给肉眼复核（顶到第 0 行才算坏事——那是毛巾被画布裁掉了）。头顶心心原来
挂在席位上方 34 像素，是按走路图的第 14 行调的，泡澡图爱把毛巾画得更高，所以引擎现在
自己按差值抬特效，越线不再是缺陷。

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

## 茶室专用的第七张，只和 walk 比，不进 poseΔ 的两两矩阵。
SIT = "sit"
## sit 的剪影高 / walk 的剪影高，上限。产线把内容塞进固定画布，原图画得比站姿高，
## 客人一坐下就当场长大一号——这是唯一能从数字上坐实的毛病。
## 下盘宽比与配色交叠两条曾经也在这儿把关，25 张全肉眼看过一遍：没有一张是没坐下的，
## 两条指标量的其实都只是「蹲下来之后面积重新分布了多少」——大耳朵把宽比压下去，
## 坐垫和正脸把配色交叠压下去，误伤率百分之百，于是只留这一条。
SIT_GROW = 1.10

## soak 的墨迹顶行高于这条线就单独标出来：走路图的墨迹上沿在第 14 行，头顶的爱心
## 特效（guest.gd 的 EMOTE_INK_ROW）照着它调，泡澡原图爱把毛巾、大耳朵画得更高。
## 引擎现在会按差值自己把特效抬上去，所以越线只是「这张画得比站姿高」的提示；
## 真要出问题的是顶到第 0 行——那说明毛巾被画布裁掉了一截。
SOAK_TOP = 14


def stats(path):
    im = Image.open(path).convert("RGBA")
    a = im.getchannel("A")
    bbox = a.getbbox() or (0, 0, 0, 0)
    opaque = sum(1 for p in a.getdata() if p > 16)
    return im, bbox, opaque / float(CELL[0] * CELL[1])


def rgba_of(im):
    return list(im.getdata())


def silhouette_height(path):
    """不透明像素的包围盒高度（getbbox 的下边是开区间，别越界）。"""
    a = Image.open(path).convert("RGBA").getchannel("A")
    bb = a.getbbox() or (0, 0, 0, 0)
    return bb[3] - bb[1]


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


def paste_cell(sheet, path, r, c):
    """把一张姿态贴到第 r 行第 c 列，底下先铺一层棋盘格，好一眼看出透明区没被填死。"""
    im = Image.new("RGBA", CELL, (0, 0, 0, 0))
    for by in range(0, CELL[1], 8):
        for bx in range(0, CELL[0], 8):
            dark = ((bx // 8) + (by // 8)) % 2
            for py in range(8):
                for px in range(8):
                    im.putpixel((bx + px, by + py),
                                (70, 60, 80, 255) if dark else (44, 36, 52, 255))
    im.alpha_composite(Image.open(path).convert("RGBA"), (0, 0))
    sheet.alpha_composite(im, (PAD + c * (CELL[0] + PAD), PAD + r * (CELL[1] + PAD)))


def main():
    ids = sys.argv[1:] or sorted({f.split("_")[0] for f in os.listdir(ANIM) if f.endswith(".png")})
    sheet = Image.new("RGBA", ((len(POSES) + 1) * (CELL[0] + PAD) + PAD,
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
            paste_cell(sheet, path, r, c)
        sit = None
        sit_path = os.path.join(ANIM, "%s_%s.png" % (sid, SIT))
        if os.path.exists(sit_path):
            paste_cell(sheet, sit_path, r, len(POSES))
            wk = silhouette_height(os.path.join(ANIM, "%s_walk.png" % sid))
            sit = silhouette_height(sit_path) / float(wk or 1)
        # soak 的墨迹顶行单独量：union bbox 里那一条被走路六张压着，看不出泡澡这张自己顶到哪
        soak_top = None
        soak_path = os.path.join(ANIM, "%s_soak.png" % sid)
        if os.path.exists(soak_path):
            sb = Image.open(soak_path).convert("RGBA").getchannel("A").getbbox()
            soak_top = sb[1] if sb else CELL[1]
        top = min(b[1] for b in boxes)
        foot = max(b[3] for b in boxes)
        left = min(b[0] for b in boxes)
        right = max(b[2] for b in boxes)
        foot_spread = max(b[3] for b in boxes) - min(b[3] for b in boxes)
        pa, pb, dv = closest_pair(masks) if len(masks) > 1 else ("", "", 2.0)
        rows.append((sid, len(boxes), missing, (left, top, right, foot), foot_spread,
                     min(fills), max(fills), "%.1f%% %s/%s" % (dv * 100, pa, pb), dv, sit,
                     soak_top))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    sheet.save(OUT)
    print("sheet ->", os.path.normpath(OUT), sheet.size)
    print("%-6s %-5s %-6s %-22s %-6s %-18s %-8s %-7s %s" % (
        "id", "poses", "foot±", "union bbox", "fill%", "poseΔ", "sit高比", "soak顶", "missing"))
    dups, bad_sit, high_soak, tall_soak = [], [], [], []
    for sid, n, missing, ub, fs, fmin, fmax, pose_delta, dv, sit, soak_top in rows:
        flag = []
        if missing:
            flag.append(" ".join(missing))
        elif n < len(POSES):
            flag.append("全透明")
        if sit is None:
            flag.append("缺 sit")
            sit_col = "-"
        else:
            sit_col = "%.2f" % sit
            if sit > SIT_GROW:
                bad_sit.append((sid, sit))
        if soak_top is None:
            flag.append("缺 soak")
            soak_col = "-"
        else:
            soak_col = "%dpx" % soak_top
            if soak_top <= 0:
                high_soak.append((sid, soak_top))
            elif soak_top < SOAK_TOP:
                tall_soak.append((sid, soak_top))
        print("%-6s %-5s %-6s %-22s %-6s %-18s %-8s %-7s %s" % (
            sid, "%d/6" % n, "%dpx" % fs, str(ub), "%.1f-%.1f" % (fmin * 100, fmax * 100),
            pose_delta, sit_col, soak_col, " ".join(flag)))
        if dv < DUP_DIFF:
            dups.append((sid, pose_delta))
    if dups:
        print("\n姿态撞脸（两张几乎逐像素相同）：")
        for sid, delta in dups:
            print("  %-6s %s" % (sid, delta))
    if bad_sit:
        print("\n坐下长大一号（sit 剪影比 walk 还高，换一张 alt 重落）：")
        for sid, grow in bad_sit:
            print("  %-6s 高比 %.2f（线 %.2f）" % (sid, grow, SIT_GROW))
    if high_soak:
        print("\n画布裁到头（soak 墨迹贴着画布顶边，毛巾或耳朵被切了，换 alt 重落）：")
        for sid, top in high_soak:
            print("  %-6s 顶行 %dpx" % (sid, top))
    if tall_soak:
        print("\n画得比站姿高（soak 墨迹越过第 %d 行，特效锚点由引擎自动抬，仅供肉眼复核）：" % SOAK_TOP)
        for sid, top in tall_soak:
            print("  %-6s 顶行 %dpx" % (sid, top))


main()
