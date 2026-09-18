"""抹除生成器烙在素材右下角的 "Qoder AI生成" 水印。

素材为 1792x1024 母图与 896x512 游戏用图两套，水印框按比例同步。
做法：把水印框左侧等宽区域水平镜像覆盖过来，木纹/榻榻米的横向纹理因此连续。
"""

from PIL import Image, ImageDraw
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# (x0, y0, x1, y1) —— 以 896x512 为基准，母图按 2 倍取
BOX_896 = (626, 432, 890, 502)
MASTERS = [
    "开始界面.png",
    "大池.png",
    "石泉.png",
    "休息茶室.png",
    "后院温泉.png",
    "scene_02_indoor.png",
    "scene_03_rotenburo.png",
    "jimeng-2026-08-01-2628-像素风日式温泉前台俯视平面图，包含小型温泉区域，无任何动物角色，无任何文字标识，....png",
]
ASSETS = [
    "title.png", "room-ooike.png", "room-indoor.png", "room-rotenburo.png",
    "room-ishiyu.png", "room-backyard.png", "room-chashitsu.png", "map-gate.png",
]


def scale(box: tuple, k: float, size: tuple) -> tuple:
    x0, y0, x1, y1 = (int(round(v * k)) for v in box)
    x1 = min(x1, size[0])
    y1 = min(y1, size[1])
    return x0, y0, x1, y1


def patch(path: Path, box: tuple) -> tuple:
    im = Image.open(path).convert("RGB")
    x0, y0, x1, y1 = scale(box, 1.0, im.size)
    w = x1 - x0
    src = (max(0, x0 - w), y0, x0, y1)
    if src[2] - src[0] < w:
        raise SystemExit(f"{path.name}: 左侧可用宽度不足")
    band = im.crop(src).transpose(Image.FLIP_LEFT_RIGHT)
    out = im.copy()
    out.paste(band.resize((w, y1 - y0)), (x0, y0))
    out.save(path)
    return x0, y0, x1, y1


def main() -> None:
    dry = "--dry-run" in sys.argv
    targets = [(ROOT / "Spring" / n, 2.0) for n in MASTERS]
    targets += [(ROOT / "godot" / "assets" / "bg" / n, 1.0) for n in ASSETS]
    sheet = Image.new("RGB", (460, 110 * len(targets)), (18, 14, 24))
    draw = ImageDraw.Draw(sheet)
    for i, (path, k) in enumerate(targets):
        if not path.exists():
            print("缺失", path)
            continue
        im = Image.open(path).convert("RGB")
        x0, y0, x1, y1 = scale(BOX_896, k, im.size)
        if dry:
            marked = im.copy()
            ImageDraw.Draw(marked).rectangle([x0, y0, x1, y1], outline=(0, 255, 255), width=3)
            after = marked
        else:
            after_x = patch(path, BOX_896)
            after = Image.open(path).convert("RGB")
            ImageDraw.Draw(after).rectangle(list(after_x), outline=(255, 0, 255), width=2)
        crop = after.crop((after.size[0] - 460, after.size[1] - 100, after.size[0], after.size[1]))
        crop = crop.resize((460, 100), Image.NEAREST)
        sheet.paste(crop, (0, i * 110 + 10))
        draw.text((2, i * 110), f"{path.name[:34]} box={x0},{y0},{x1},{y1}", fill=(255, 220, 120))
    out = ROOT / "vibe_images" / "_dewatermark_qc.png"
    sheet.save(out)
    print(("预览 " if dry else "已抹除 ") + str(out))


main()
