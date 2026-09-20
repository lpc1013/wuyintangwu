#!/usr/bin/env python3
"""即梦原图 → 游戏精灵贴图的落位脚本。

用法（在仓库根目录）：
    # 一只一张就够，另外五帧（stepL / stepR / hop / soak / rest）全由 walk 推出
    python godot/tools/sprite_from_ai.py --batch vibe_images/ai_raw   # 目录里放 <物种id>.webp
    python godot/tools/sprite_from_ai.py <原图> <物种id> [姿态] [--canvas 72x96] [--colors 28]

为什么要按方块缩：即梦画的「像素风」其实是高分辨率图上的大方块（实测原图 1728×2304、
方块约 4px，等于 432×576 的逻辑网格）。缩到非方块整数倍的尺寸会把方块劈成大小不一的块，
边缘发糊；只有先把包围盒对齐到方块网格、再按方块的整数倍整除缩放，每一格才正好是源图的一个方块。
"""

import argparse
import json
import math
import os
import re
import sys
from collections import Counter
from PIL import Image

BG_LO = 226          # 近白底：三通道都高于这个值才算背景候选
ALPHA_CUT = 128      # 缩放后 alpha 低于此值直接砍掉，免得留一圈半透明毛边


def measure_block(im: Image.Image, step: int = 7) -> int:
    """横向同色游程按「覆盖像素数」取众数，即源图方块边长。

    直接取最短游程会被 webp 噪声骗到 2px，所以要按面积加权。
    """
    px = im.load()
    w, h = im.size
    runs = Counter()
    for y in range(0, h, step):
        n = 1
        for x in range(1, w):
            if px[x, y] == px[x - 1, y]:
                n += 1
            else:
                if n > 1:
                    runs[n] += n
                n = 1
    if not runs:
        return 4
    best = max(runs.items(), key=lambda kv: kv[1])[0]
    return best if 2 <= best <= 64 else 4


def key_out(im: Image.Image) -> Image.Image:
    """从四边泛洪抠掉近白背景：只抠与边框连成一片的白，身上白布不会被误伤。"""
    im = im.convert("RGBA")
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
        if r < BG_LO or g < BG_LO or b < BG_LO:
            continue
        seen.add((x, y))
        stack.append((x + 1, y))
        stack.append((x - 1, y))
        stack.append((x, y + 1))
        stack.append((x, y - 1))
    for x, y in seen:
        px[x, y] = (0, 0, 0, 0)
    return im


def snap_bbox(im: Image.Image, block: int) -> tuple:
    """包围盒往外扩到方块网格线上，保证整除缩放后方块仍然等大。"""
    box = im.getbbox()
    if box is None:
        raise SystemExit("抠完底是全透明的，检查原图背景色")
    x0, y0, x1, y1 = box
    return ((x0 // block) * block, (y0 // block) * block,
            ((x1 + block - 1) // block) * block, ((y1 + block - 1) // block) * block)


def shrink(im: Image.Image, factor: int) -> Image.Image:
    """整倍 BOX 缩放：RGB 与 alpha 分开算，否则透明处的黑会渗进轮廓。"""
    w, h = im.width // factor, im.height // factor
    rgb = im.convert("RGB").resize((w, h), Image.BOX)
    a = im.getchannel("A").resize((w, h), Image.BOX)
    out = rgb.convert("RGBA")
    out.putalpha(a)
    px = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, al = px[x, y]
            px[x, y] = (r, g, b, 255) if al >= ALPHA_CUT else (0, 0, 0, 0)
    return out


def quantize(im: Image.Image, colors: int) -> Image.Image:
    """硬量化到有限色、无抖动：抖动会在像素画身上撒一片彩点。"""
    alpha = im.getchannel("A")
    out = im.convert("RGB").quantize(colors=colors, dither=Image.Dither.NONE).convert("RGBA")
    px = out.load()
    ap = alpha.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, _ = px[x, y]
            px[x, y] = (r, g, b, 255) if ap[x, y] >= ALPHA_CUT else (0, 0, 0, 0)
    return out


def place(im: Image.Image, cw: int, ch: int) -> tuple:
    """贴进目标画布：底边对齐、水平居中。只做平移，绝不重采样——脚掌线不漂。"""
    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    out.paste(im, ((cw - im.width) // 2, ch - im.height), im)
    return out, (cw - im.width) // 2, ch - im.height


def spans(row: list) -> list:
    """一行的不透明游程：忽略宽度不足 2 的噪声点。"""
    out = []
    s = None
    for x, a in enumerate(row):
        if a > 0:
            if s is None:
                s = x
        elif s is not None:
            if x - s >= 2:
                out.append((s, x))
            s = None
    if s is not None and len(row) - s >= 2:
        out.append((s, len(row)))
    return out


def foot_band(im: Image.Image) -> tuple:
    """从底边往上找出「两脚分开」的那一段：返回 (顶行 y, 两脚之间的分界列)。

    找不到就返回 None——裙子、尾巴或整块身子把两脚连成一片时，硬拆会撕出洞，
    那种物种宁可只有一张中立帧，也不要一帧好一帧坏。
    """
    px = im.load()
    w, h = im.size
    y0 = None
    for y in range(h - 1, max(0, h - 22), -1):
        sp = spans([px[x, y][3] for x in range(w)])
        if len(sp) == 2:
            y0 = y
        else:
            break
    if y0 is None or h - y0 < 3:
        return None
    sp = spans([px[x, y0][3] for x in range(w)])
    return (y0, (sp[0][1] + sp[1][0]) // 2)


def move_leg(im: Image.Image, band: tuple, which: int, lift: int,
             spread: int) -> Image.Image:
    """把一条腿整段搬走：which<0 动左、>0 动右、0 两脚一起。lift 往上收，spread 往外撑。

    只往上收是不够的——即梦把水豚画在长浴衣里，脚只有五像素，抬两格轮廓纹丝不动，
    玩家看到的还是原地滑行。真正读得出迈步的是「一只脚往外撑开」这一下剪影变化。
    只在画布内部搬：抬上去那几行压回身子下缘，腿像是收进肚子底下而不是被剪掉。
    """
    y0, split = band
    lift = min(lift, max(1, (im.height - y0) // 2))
    out = im.copy()
    px = out.load()
    w, h = im.size
    left = (range(0, split), -spread, lift)
    right = (range(split, w), spread, lift)
    legs = [left, right] if which == 0 else ([left] if which < 0 else [right])
    for rng, dx, dy in legs:
        xs = list(rng)
        strip = im.crop((xs[0], y0, xs[-1] + 1, h))
        for y in range(y0, h):
            for x in xs:
                px[x, y] = (0, 0, 0, 0)
        out.paste(strip, (xs[0] + dx, y0 - dy), strip)
    return out


def move_band(im: Image.Image, y0: int, dx: int, dy: int) -> Image.Image:
    """把 y0 以下那一片整体挪 (dx, dy)：脚分不出来时，拿浴衣下摆当腿用。

    下摆左右摆两格，读起来就是摇摆迈步；整只抬三格就是腾空。
    比「干脆没有第二帧」强得多——原地滑行比换错腿还显眼。
    """
    w, h = im.size
    px = im.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0))
    op = out.load()
    for y in range(max(0, y0), h):
        for x in range(w):
            op[x, y] = (0, 0, 0, 0)
    for y in range(max(0, y0), h):
        ny = y + dy
        if ny < 0 or ny >= h:
            continue
        for x in range(w):
            c = px[x, y]
            nx = x + dx
            if c[3] and 0 <= nx < w:
                op[nx, ny] = c
    return out


def squash(im: Image.Image, dy: int) -> Image.Image:
    """按底边锚定把整只压扁 dy 格：没有可收的脚时，这一下就是「坐下去了」。"""
    w, h = im.size
    px = im.load()
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    op = out.load()
    nh = h - dy
    for y in range(h):
        sy = h - 1 - int((h - 1 - y) * nh / h)
        for x in range(w):
            c = px[x, sy]
            if c[3]:
                op[x, y] = c
    return out


def derive_stride(walk: Image.Image, outdir: str, species: str) -> list:
    """由 walk 中立帧推出 stepL / stepR / hop 三张，返回落盘的文件名。"""
    band = foot_band(walk)
    made = []
    if band is None:
        # 脚连成一片：改成摆下摆，至少迈步这件事还看得出来
        for pose, dx in (("stepL", 2), ("stepR", -2)):
            img = move_band(walk, walk.height - 16, dx, 0)
            dst = os.path.join(outdir, f"{species}_{pose}.png")
            img.save(dst)
            made.append(os.path.basename(dst))
        dst = os.path.join(outdir, f"{species}_hop.png")
        move_band(walk, 0, 0, -3).save(dst)
        made.append(os.path.basename(dst))
        return made
    for pose, which, lift, spread in (
            ("stepL", -1, 3, 3), ("stepR", 1, 3, 3), ("hop", 0, 2, 0)):
        img = move_leg(walk, band, which, lift, spread)
        dst = os.path.join(outdir, f"{species}_{pose}.png")
        img.save(dst)
        made.append(os.path.basename(dst))
    return made


def derive_soak(walk: Image.Image, outdir: str, species: str) -> str:
    """泡汤帧：只留上半身，切齐画布底边当水线。

    程序化的 soak 也是这么画的——水线以下不画身子，改在底边压两行高光当水面。
    贴图要是继续用站姿整张，客人就像是站在池子里而不是泡着。
    """
    px = walk.load()
    w, h = walk.size
    band = foot_band(walk)
    # 露出水面的高度：从两脚分开的地方再往上退一大截，差不多到胸口
    cut = (band[0] if band else h) - 30
    top = next((y for y in range(h) if any(px[x, y][3] for x in range(w))), 0)
    upper = walk.crop((0, top, w, max(top + 8, cut)))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(upper, (0, h - upper.height), upper)
    op = out.load()
    for x in range(w):
        if op[x, h - 1][3] or op[x, h - 2][3]:
            op[x, h - 1] = (184, 235, 245, 190)
            op[x, h - 2] = (219, 247, 255, 115)
    dst = os.path.join(outdir, f"{species}_soak.png")
    out.save(dst)
    return os.path.basename(dst)


def derive_rest(walk: Image.Image, outdir: str, species: str) -> str:
    """茶室歇坐：两脚一起收上来并往外撑开。

    没有真正的盘腿图，先用「脚撑开 + 收进去」这个剪影顶一下——
    至少和站姿分得开，客人不会在榻榻米上直挺挺地戳着。
    """
    band = foot_band(walk)
    dst = os.path.join(outdir, f"{species}_rest.png")
    img = move_leg(walk, band, 0, 3, 5) if band else squash(walk, 3)
    img.save(dst)
    return os.path.basename(dst)


def landing_factor(src: str, block: int, cw: int, ch: int) -> int:
    """这张原图按产线规则会被缩到几倍：1 输出像素 = factor 原始像素。"""
    box = snap_bbox(key_out(Image.open(src)), block)
    k = max(1, math.ceil(max((box[2] - box[0]) / block / cw,
                             (box[3] - box[1]) / block / ch)))
    return block * k


def run_one(src: str, species: str, pose: str, cw: int, ch: int, colors: int,
            outdir: str, keep_debug: str = "", anchor: str = "") -> None:
    keyed = key_out(Image.open(src))
    block = measure_block(Image.open(src).convert("RGB"))
    box = snap_bbox(keyed, block)
    crop = keyed.crop(box)
    # 缩放倍率必须同时是方块边长的整数倍，且缩完要塞得进画布
    factor = landing_factor(src, block, cw, ch)
    # 站姿之外的那几张必须沿用自己 walk 的比例：产线是「塞满画布」，而坐姿的包围盒
    # 天生比站姿扁——同一只兔子 walk 用 24、sit 只要 20，客人一坐下就长大两成。
    # 取两者里更大的那个倍率，最多只是坐那张小一点，绝不会变大。
    grow_from = ""
    if pose != "walk" and anchor and os.path.exists(anchor):
        ablock = measure_block(Image.open(anchor).convert("RGB"))
        if ablock == block:
            af = landing_factor(anchor, block, cw, ch)
            if af > factor:
                grow_from = f" 锚定 walk={af}"
                factor = af
    mid = shrink(crop, factor)
    final, offx, offy = place(quantize(mid, colors), cw, ch)

    os.makedirs(outdir, exist_ok=True)
    dst = os.path.join(outdir, f"{species}_{pose}.png")
    final.save(dst)
    extra = []
    if pose == "walk":
        extra = derive_stride(final, outdir, species)
        soak = derive_soak(final, outdir, species)
        rest = derive_rest(final, outdir, species)
        extra += [v for v in (soak, rest) if v]
    print(f"OK {dst} block={block}px factor={factor} srcBox={box} "
          f"mid={mid.width}x{mid.height} canvas={cw}x{ch} pad=({offx},{offy})"
          + grow_from
          + (f" derived={extra}" if extra else ""))

    if keep_debug:
        os.makedirs(keep_debug, exist_ok=True)
        stem = os.path.join(keep_debug, f"{species}_{pose}")
        keyed.save(stem + "_keyed.png")
        mid.save(stem + "_mid.png")


RAWS = (".webp", ".png", ".jpg", ".jpeg")


def find_walk(base: str, raw_dir: str) -> str:
    """这只自己的 walk 原图落在哪儿：walk 批次就平铺在 raw_dir 下。找不到返回空串。"""
    for ext in RAWS:
        p = os.path.join(raw_dir, base + ext)
        if os.path.exists(p):
            return p
    return ""


def batch(indir: str, outdir: str, cw: int, ch: int, colors: int, pose: str = "walk",
          raw_dir: str = "vibe_images/ai_raw") -> int:
    """扫目录里的 <物种>.<ext>：walk 一只一张就够，另外五帧全由它推出来。

    其它姿态（sit）只落这一张，绝不去推派生帧——派生是给步态用的，
    坐下的图再撑一次脚只会把盘好的腿弄散；同时拿 raw_dir 里那只自己的 walk 原图
    当比例锚，坐下才不会长大一号。

    物种名对不对不在这儿把关——引擎只按 <物种>_walk.png 找文件，
    多出来的名字就是几张没人读的图，不会把游戏带坏。
    """
    done = []
    for name in sorted(os.listdir(indir)):
        base, ext = os.path.splitext(name)
        if ext.lower() not in RAWS:
            continue
        run_one(os.path.join(indir, name), base, pose, cw, ch, colors, outdir,
                anchor=find_walk(base, raw_dir))
        done.append(base)
    print(f"BATCH {len(done)} 只 {pose} 落位：{done}")
    if not done:
        print(f"BATCH {indir} 里没有图片，文件名要写成 <物种id>.webp")
    return 0


def read_roster(data_gd: str) -> list:
    """从 data.gd 里抠出物种名单：产图提示词必须跟着名单走，别手写两份对不上。

    按「哪一行开了新物种」切行号，而不是拿非贪婪正则一路框——
    条目之间夹一行 ## 注释，框选就会把下一只整个吞进上一只里（panda 与 chick 就这么丢了）。
    """
    src = open(data_gd, encoding="utf-8").read()
    body = src[src.index("const SPECIES"):]
    body = body[:body.index("const GAITS")]
    heads = [(m.start(), m.group(1)) for m in re.finditer(r'^\t"([a-z0-9]+)":\s*\{', body, re.M)]
    out = []
    for i, (pos, sid) in enumerate(heads):
        end = heads[i + 1][0] if i + 1 < len(heads) else len(body)
        blk = "\n".join(l for l in body[pos:end].splitlines() if not l.strip().startswith("##"))
        def field(key, default=""):
            fm = re.search(r'"%s":\s*"([^"]*)"' % key, blk)
            return fm.group(1) if fm else default
        sm = re.search(r'"size":\s*([\d.]+)', blk)
        feats = [k for k in ("mask", "horn", "comb", "spots2")
                 if re.search(r'"%s":\s*true' % k, blk)]
        beak = re.search(r'"beak":\s*"(#[0-9a-fA-F]{6})"', blk)
        out.append({"id": sid, "name": field("name"), "ear": field("ear"),
                    "tail": field("tail"), "body": field("body"), "belly": field("belly"),
                    "dark": field("dark"), "perso": field("perso"),
                    "feats": feats, "beak": beak.group(1) if beak else "",
                    "size": float(sm.group(1)) if sm else 1.0})
    return out


FEAT_CN = {"mask": "眼睛周围一圈深色眼罩斑", "horn": "头顶一对小牛角",
           "comb": "头顶一小撮锯齿状鸡冠", "spots2": "身上几块不规则深色斑"}


EAR_CN = {"round": "圆耳朵", "point": "尖耳朵", "long": "很长很直的两只长耳朵",
          "antler": "头顶一对小鹿角", "none": "没有耳朵轮廓"}
TAIL_CN = {"stub": "几乎看不见的小短尾", "curl": "卷绒球小尾巴",
           "fluffy": "一条蓬松大尾巴", "flat": "一片扁平的短尾",
           "fin": "小小的鳍状尾", "none": "看不见尾巴"}
## 扩员那十只的辨识点：光靠物种名让模型自由发挥，龟壳和腕足经常整个不出现，
## 三十只摆在一起时读不出是哪种动物。这一句按 id 定点补，比通用描述管用。
MARK_CN = {
    "slth": "两只前臂特别长，垂到手腕以外，爪尖是弯的",
    "hipp": "一张占满下半张脸的方厚大嘴，鼻孔顶在嘴背上",
    "koal": "一只很大的椭圆形黑鼻子，耳朵边缘一圈绒毛",
    "swan": "一条很长的 S 形脖颈，喙基有一小块黑色疣状突起",
    "owly": "两只占满半张脸的超大圆眼，脸上一个心形面盘",
    "turt": "背上一块深绿带方格纹的硬龟壳，壳压在浴衣外面",
    "octo": "脑袋圆鼓，底下四到五条粗短的腕足垂到地面，内侧浅色吸盘",
    "sqrl": "一条比身子还大的蓬松长尾巴竖在身后",
    "badg": "脸上从鼻尖到额头两道竖直的深浅相间条纹",
    "goat": "下巴一撮长胡子，一对向后弯的横纹羊角",
}
# 体型靠「占画面多高」传达：画布固定 72×96，倍率不再按物种变，
# 所以大小差异必须由构图给出来，否则青蛙和棕熊一样大
SIZE_CN = [(0.9, "很小一只，只占画面高度约五成，蹲在画面下方"),
           (1.1, "中等个头，占画面高度约六成半"),
           (1.25, "偏大一只，占画面高度约七成五"),
           (9.9, "壮硕一大只，几乎占满画面高度")]

## 姿态名 → （怎么摆, 允许出现的道具）。sit 是茶室专用的第七张：
## derive_rest 那张占位只是把脚撑开，客人坐在榻榻米上仍像站着，所以单独要一张真盘腿。
POSE_CN = {
    "walk": ("正面朝向观众直立站姿，双脚分开站稳，全身完整入画，不要侧身不要俯视",
             "没有任何道具"),
    "sit": ("正面朝向观众盘腿而坐，两膝向外摊开，双脚（前爪）收拢在身前，"
            "屁股压在一只方形坐垫上，双手自然搭在膝头，全身完整入画，不要侧身不要俯视",
            "唯一允许的道具是屁股下那只方形坐垫，坐垫面是橙褐色、中间一道深褐色束带，除此之外没有任何道具"),
}


def prompt_for(sp: dict, pose: str = "walk") -> str:
    frac = next(t for lo, t in SIZE_CN if sp["size"] < lo)
    look = [EAR_CN.get(sp["ear"], sp["ear"]), TAIL_CN.get(sp["tail"], sp["tail"])]
    look += [FEAT_CN[k] for k in sp["feats"] if k in FEAT_CN]
    if sp["beak"]:
        look.append(f"一张 {sp['beak']} 色的小尖喙")
    if sp["id"] in MARK_CN:
        look.append(MARK_CN[sp["id"]])
    stance, prop = POSE_CN[pose]
    bits = [
        "复古日式像素风游戏精灵图",
        f"{sp['name']}（{sp['perso']}）",
        stance,
        f"毛色 {sp['body']}，肚皮与口鼻 {sp['belly']}，耳朵内侧与描边 {sp['dark']}",
        "、".join(look),
        "身穿浅蓝白色日式浴衣，腰间系同色腰带",
        "大方块像素、粗深色描边、赛璐璐平涂、无渐变无抖动",
        f"纯白背景，画面里只有这一个角色，没有地面阴影没有文字，{prop}",
        frac,
    ]
    return "，".join(bits) + "。"


def emit_prompts(outdir: str, data_gd: str, json_out: str = "", raw_dir: str = "vibe_images/ai_raw",
                 pose: str = "walk") -> int:
    """给还没落位这个姿态的物种各印一条可直接粘进即梦的提示词。

    outdir 是「已落位」的判据目录（贴图所在地），raw_dir 只是告诉人去哪儿存原图——
    两者搞成一个，--outdir 一换就变成「一只都没落位」。
    json_out 是给浏览器自动化读的：控制台那份在 cp936 下会糊成一团，
    而且提示词本就没有重打一遍的必要。
    """
    todo = []
    for sp in read_roster(data_gd):
        if not os.path.exists(os.path.join(outdir, f"{sp['id']}_{pose}.png")):
            todo.append(sp)
    if json_out:
        with open(json_out, "w", encoding="utf-8") as f:
            json.dump([{"id": sp["id"], "name": sp["name"], "pose": pose,
                        "out": f"{pose}/{sp['id']}.webp" if pose != "walk" else f"{sp['id']}.webp",
                        "ref": ("" if pose == "walk"
                                else os.path.join(raw_dir, f"{sp['id']}.webp")),
                        "prompt": prompt_for(sp, pose)}
                       for sp in todo], f, ensure_ascii=False, indent=1)
        print(f"PROMPT {len(todo)} 条已写入 {json_out}")
    if not todo:
        print(f"PROMPT 全部 {len(read_roster(data_gd))} 个物种的 {pose} 都已落位，不用再生图")
        return 0
    print(f"PROMPT 还差 {len(todo)} 只的 {pose}（即梦：图片生成 · 5.0 Lite · 3:4 · 纯白底"
          + ("· 拿自己的 walk 原图当参考图）" if pose != "walk" else "）"))
    for sp in todo:
        print(f"\n[{sp['id']}] {sp['name']}  →  存成 {sp['id']}.webp 放进 {raw_dir}")
        print(prompt_for(sp, pose))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?", default="")
    ap.add_argument("species", nargs="?", default="")
    ap.add_argument("pose", nargs="?", default="walk")
    ap.add_argument("--canvas", default="72x96")
    ap.add_argument("--colors", type=int, default=28)
    ap.add_argument("--outdir", default="godot/assets/animals")
    ap.add_argument("--batch", default="", help="目录里放 <物种>.webp，一次跑完整个 --pose 套件")
    ap.add_argument("--pose", dest="art_pose", default="walk",
                    help="--prompts 与 --batch 处理哪个姿态，默认 walk")
    ap.add_argument("--prompts", action="store_true", help="列出还没落位的物种的即梦提示词")
    ap.add_argument("--prompts-json", default="", help="把待办提示词写成 UTF-8 JSON，给浏览器自动化读")
    ap.add_argument("--raw-dir", default="vibe_images/ai_raw",
                    help="walk 原图目录：提示文案去哪儿找它，非 walk 姿态就拿它当比例锚")
    ap.add_argument("--data", default="godot/scripts/data.gd", help="物种名单来源，配合 --prompts 用")
    ap.add_argument("--keep-debug", default="", help="顺手把中间产物写到这个目录，便于肉眼核对")
    args = ap.parse_args()

    cw, ch = (int(v) for v in args.canvas.lower().split("x"))
    if args.prompts or args.prompts_json:
        return emit_prompts(args.outdir, args.data, args.prompts_json, args.raw_dir,
                            args.art_pose)
    if args.batch:
        return batch(args.batch, args.outdir, cw, ch, args.colors, args.art_pose,
                     args.raw_dir)
    if not args.src or not args.species:
        raise SystemExit("要么给 <原图> <物种id> [姿态]，要么用 --batch <目录>")
    run_one(args.src, args.species, args.pose, cw, ch, args.colors,
            args.outdir, args.keep_debug, find_walk(args.species, args.raw_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
