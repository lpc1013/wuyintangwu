"""把标题页匾额上的「花見温泉」改刻成招牌「雾隐汤屋」。

背景图是 AI 生成的像素画，匾额文字烧在图里，Godot 侧盖不住，只能回炉改图。
做法：先按行把字下面的木纹补回来（同一行里没被字压住的木色做左右线性插值，
横向纹理因此不丢），再把字体放大四倍渲染、缩回原尺寸、二值化，得到不带灰边的
像素字，最后用匾额原有的墨色压上去——墨里掺一点底下的木色，让笔画也透木纹。

跑完记得 `--headless --path godot --import` 让 Godot 重新导入这张 PNG。
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "bg", "title.png")
CACHE = os.path.join(ROOT, "tools", "_cache", "title_plaque_src.png")
TEXT = "雾隐汤屋"
FONT = "C:/Windows/Fonts/STKAITI.TTF"
SIZE = 26
THRESHOLD = 25
INK = (33, 17, 11)

# 匾额内可涂改的矩形：左右避开雕花，上下避开边框暗部
BAND = (398, 145, 498, 169)


def lum(p):
    return 0.3 * p[0] + 0.6 * p[1] + 0.1 * p[2]


def wood_rows(px, x0, x1, y0, y1):
    """逐行收集没被字压住的木色像素，供补纹用。"""
    rows = {}
    for y in range(y0, y1):
        pts = [(x, px[x, y]) for x in range(x0, x1)
               if lum(px[x, y]) >= 95 and px[x, y][0] > px[x, y][2]]
        rows[y] = pts
    # 整行都被字糊住时借最近一行的样本
    for y in range(y0, y1):
        if len(rows[y]) >= 6:
            continue
        near = sorted(range(y0, y1), key=lambda k: abs(k - y))
        for k in near:
            if len(rows[k]) >= 6:
                rows[y] = list(rows[k])
                break
    return rows


def erase(im):
    px = im.load()
    x0, y0, x1, y1 = BAND
    rows = wood_rows(px, x0, x1, y0, y1)
    for y in range(y0, y1):
        pts = rows[y]
        for x in range(x0, x1):
            if lum(px[x, y]) >= 95 and px[x, y][0] > px[x, y][2]:
                continue
            left = [p for p in pts if p[0] <= x]
            right = [p for p in pts if p[0] >= x]
            if left and right:
                a, b = left[-1], right[0]
                t = 0.5 if b[0] == a[0] else (x - a[0]) / (b[0] - a[0])
                px[x, y] = tuple(int(round(a[1][i] * (1 - t) + b[1][i] * t)) for i in range(3))
            elif pts:
                px[x, y] = (left or right)[-1][1]
    return im


def glyph(text, size, threshold):
    """4 倍超采样再压回 1 倍，二值化后就是干净的像素字。"""
    font = ImageFont.truetype(FONT, size * 4)
    pad = 16
    m = Image.new("L", (size * 4 * (len(text) + 1) + pad * 2, size * 4 + pad * 2), 0)
    ImageDraw.Draw(m).text((pad, pad), text, fill=255, font=font)
    m = m.crop(m.getbbox())
    m = m.resize((max(1, round(m.width / 4)), max(1, round(m.height / 4))), Image.LANCZOS)
    return m.point(lambda v: 255 if v > threshold else 0)


def stamp(im, mask):
    px = im.load()
    x0, y0, x1, y1 = BAND
    ox = x0 + ((x1 - x0) - mask.width) // 2
    oy = y0 + ((y1 - y0) - mask.height) // 2
    on = {(x, y): True for y in range(mask.height) for x in range(mask.width)
          if mask.getpixel((x, y)) > 0}
    for y in range(mask.height):
        for x in range(mask.width):
            if (x, y) not in on:
                continue
            wx, wy = ox + x, oy + y
            if not (x0 <= wx < x1 and y0 <= wy < y1):
                continue
            base = px[wx, wy]
            px[wx, wy] = tuple(int(round(INK[i] * 0.92 + base[i] * 0.08)) for i in range(3))
    # 笔画下缘提亮一格，做出刻进木头里的那道边
    for y in range(mask.height):
        for x in range(mask.width):
            if (x, y) in on or (x, y - 1) not in on:
                continue
            wx, wy = ox + x, oy + y + 1
            if not (x0 <= wx < x1 and y0 <= wy < y1) or (wx, wy - oy) in on:
                continue
            c = px[wx, wy]
            px[wx, wy] = tuple(min(255, int(v * 1.13) + 5) for v in c)
    return im


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else SRC
    if not os.path.exists(CACHE):
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        Image.open(src).save(CACHE)
    im = Image.open(CACHE).convert("RGB")
    im = erase(im)
    im = stamp(im, glyph(TEXT, SIZE, THRESHOLD))
    im.save(src)
    print("匾额已改刻：%s → %s" % (src, TEXT))


if __name__ == "__main__":
    main()
