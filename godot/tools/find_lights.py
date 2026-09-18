"""在房间背景里找「本来就画好的灯」，把心点吐成 GDScript 数组。

夜间氛围要往灯笼、壁灯、石灯籠上叠暖光，但灯的位置烧在 AI 画的背景里，
手对坐标要一张张看图。这里按颜色找：发光的灯罩是画面里最亮的一小撮暖色
（R 高、G 中高、B 明显低于 R），连通成块后滤掉太碎（噪点）和太大（整片
夕阳、木地板）的，再按「亮度 × 面积 × 紧凑度」排序、把挨太近的并成一盏，
每间房只留分数最高的 TOP 处。

产出两张东西：终端里可直接粘进 ROOMS.lights 的数组，
以及 vibe_images/_tmp/lights_qc.png —— 六间房各画一张带序号的十字标记。
候选不等于结论：一块晒透的地板仍可能排在一盏昏暗壁灯前面，最终仍要看着
QC 图定夺。
"""
import os
from collections import deque
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = os.path.join(ROOT, "assets", "bg")
OUT = os.path.join(os.path.dirname(ROOT), "vibe_images", "_tmp")
ROOMS = ["room-ooike.png", "room-indoor.png", "room-rotenburo.png",
         "room-ishiyu.png", "room-backyard.png", "room-chashitsu.png"]
MIN_PIX = 14          # 小于这个像素数的亮块是噪点
MAX_PIX = 900         # 大于这个的是木地/天空大片高光，不是灯
TOP = 8               # 每间房只吐最有把握的几处，剩下的靠 QC 图复核
MERGE_DIST = 24       # 一盏灯笼常被自己的骨架劈成两半，靠得太近算一处


def hot(p):
    r, g, b = p[0], p[1], p[2]
    return r >= 215 and g >= 150 and r - b >= 70 and g - b >= 40


def blobs(im):
    px = im.load()
    w, h = im.size
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or not hot(px[x, y]):
                continue
            q = deque([(x, y)])
            seen[y][x] = True
            lum = 0
            x0, x1, y0, y1 = x, x, y, y
            n = 0
            while q:
                cx, cy = q.popleft()
                n += 1
                p = px[cx, cy]
                lum += 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
                x0, x1 = min(x0, cx), max(x1, cx)
                y0, y1 = min(y0, cy), max(y1, cy)
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and hot(px[nx, ny]):
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if not MIN_PIX <= n <= MAX_PIX:
                continue
            # 灯：小而圆、亮到发白；木地板的高光：长条、只是偏暖。
            # 面积给不了区分度，得让亮度和紧凑度说话。
            fill = n / float((x1 - x0 + 1) * (y1 - y0 + 1))
            bright = (lum / n / 255.0) ** 6
            out.append(((x0 + x1) // 2, (y0 + y1) // 2, bright * n * fill, n))
    return sorted(out, key=lambda b: -b[2])


def pick(cands):
    """分数从高到低收，太靠近的当作同一盏灯被骨架劈开的另一半。"""
    kept = []
    for x, y, _s, _n in cands:
        if any(abs(x - kx) < MERGE_DIST and abs(y - ky) < MERGE_DIST for kx, ky in kept):
            continue
        kept.append((x, y))
        if len(kept) >= TOP:
            break
    return kept


def main():
    os.makedirs(OUT, exist_ok=True)
    tiles = []
    for name in ROOMS:
        im = Image.open(os.path.join(BG, name)).convert("RGB")
        kept = pick(blobs(im))
        room = name[len("room-"):-len(".png")]
        print('"%s": "lights": [%s],' % (room,
                ", ".join("Vector2(%d, %d)" % (x, y) for x, y in kept)))
        d = ImageDraw.Draw(im)
        for i, (x, y) in enumerate(kept):
            r = 9
            d.line((x - r, y, x + r, y), fill=(0, 255, 0), width=1)
            d.line((x, y - r, x, y + r), fill=(0, 255, 0), width=1)
            d.rectangle((x - r, y - r, x + r, y + r), outline=(255, 0, 255))
            d.text((x + 11, y - 11), str(i + 1), fill=(255, 255, 0))
        tiles.append(im)
    sheet = Image.new("RGB", (900 * 2, 520 * ((len(tiles) + 1) // 2)), (18, 14, 22))
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % 2) * 900, (i // 2) * 520))
    sheet = sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS)
    sheet.save(os.path.join(OUT, "lights_qc.png"))
    print("QC:", sheet.size)


main()
