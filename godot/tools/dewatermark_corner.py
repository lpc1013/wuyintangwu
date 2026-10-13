"""抹掉生成器烙在 896×512 背景右下角的 "Qoder AI 生成" 灰字。

godot/tools/dewatermark.py 的镜像覆盖法在这里不管用：水印压着的常常是木栏、
榻榻米边、石板缝这类有结构的东西，整块镜像会把结构抹平成一条接缝。

改成逐像素把字"压回"背景：5×5 中值就是"这里本来该长什么样"，凡是跟中值差得
超过阈值的像素（字只有 1~2 格粗，中值一定落在背景上）都只保留 25% 的偏差——
字变成若有若无，木纹与石缝的对比几乎不动。跑三轮，每轮的字残余都会再被压一次。

母图（原 Spring/ 下 1792×1024 那批，Spring/ 目录已于 2026-10-13 移除）不在处理之列：
那套水印大得多、位置也不同，而且只作为素材库存在，游戏与网页壳都不引用它。
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ("title.png", "room-ooike.png", "room-indoor.png", "room-rotenburo.png",
          "room-ishiyu.png", "map-gate.png")

# 896×512 素材上实测的字框（贴右下角）
BOX = (816, 482, 896, 512)
DEVIATION = 8.0   # 与中值的亮度差阈值，低于此当作本来纹理
KEEP = 0.25       # 命中像素保留多少原偏差
PASSES = 3


def patch(path: Path) -> tuple:
    im = Image.open(path).convert("RGB")
    k = im.width / 896.0
    x0, y0, x1, y1 = (int(round(v * k)) for v in BOX)
    a = np.array(im).astype(np.float32)
    hits = []
    for _ in range(PASSES):
        med = np.array(Image.fromarray(a.astype(np.uint8)).filter(ImageFilter.MedianFilter(5))
                       ).astype(np.float32)
        mask = np.zeros(a.shape[:2], dtype=bool)
        mask[y0:y1, x0:x1] = True
        mask &= np.abs(a.mean(2) - med.mean(2)) > DEVIATION
        a[mask] = med[mask] + (a[mask] - med[mask]) * KEEP
        hits.append(int(mask.sum()))
    return Image.fromarray(a.astype(np.uint8)), hits, (x0, y0, x1, y1)


def main() -> None:
    dry = "--dry-run" in sys.argv
    sheet = Image.new("RGB", (450, 178 * len(ASSETS)), (18, 14, 24))
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(ASSETS):
        path = ROOT / "godot" / "assets" / "bg" / name
        img, hits, box = patch(path)
        w, h = img.size
        k = w / 896.0
        crop = img.crop((w - int(150 * k), h - int(56 * k), w, h)).resize((450, 168), Image.NEAREST)
        sheet.paste(crop, (0, i * 178 + 14))
        draw.text((2, i * 178), f"{name} 命中={hits} box={box}", fill=(255, 220, 120))
        if not dry:
            img.save(path)
        print(name, hits, box)
    out = ROOT / "vibe_images" / "_dewatermark_corner_qc.png"
    sheet.save(out)
    print(("预览 " if dry else "已抹除 ") + str(out))


main()
